/* 
   GSCUPSPrintOperation.m

   Controls operations generating EPS, PDF or PS print jobs.

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Chad Hardin
   Date: June 2004

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#include <math.h>
#include <config.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSView.h>
#import <AppKit/NSPrinter.h>
#import <AppKit/NSPrintPanel.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSPrintOperation.h>
#import "GSGuiPrivate.h"
#import "GSCUPSPrintOperation.h"
#import "GSCUPSPrinter.h"
#undef __BLOCKS__
#include <cups/cups.h>

/* NSPrintJobFeatures contains PPD references such as Resolution/600dpi,
   rather than CUPS option strings. Only forward choices advertised by the
   selected printer, never arbitrary entries from the print-info dictionary. */
static int
GSCUPSAddFeature(id feature, NSPrinter *printer, int count,
                 cups_option_t **options)
{
  NSRange separator;
  NSString *keyword;
  NSString *choice;

  if ([feature isKindOfClass: [NSString class]] == NO)
    return count;
  separator = [feature rangeOfString: @"/"];
  if (separator.location == NSNotFound || separator.location == 0)
    return count;
  keyword = [feature substringToIndex: separator.location];
  choice = [feature substringFromIndex: NSMaxRange(separator)];
  if ([choice length] == 0)
    return count;
  /* IPP choices are checked by the translator below, so an unsupported
     explicit choice fails instead of silently reverting to the default. */
  if (!([printer respondsToSelector: @selector(_cupsSupportsIPPOption:)]
        && [printer _cupsSupportsIPPOption: keyword])
      && ![[printer stringListForKey: keyword inTable: @"PPD"] containsObject: choice])
    return count;

  return cupsAddOption([keyword UTF8String], [choice UTF8String], count,
                       options);
}


//A subclass of GSPrintOperation, NOT NSPrintOperation.
@implementation GSCUPSPrintOperation


// Required because the super class redefines the default
+ (id) allocWithZone: (NSZone*)z
{
  return NSAllocateObject (self, 0, z);
}

- (id)initWithView:(NSView *)aView
         printInfo:(NSPrintInfo *)aPrintInfo
{
  self = [super initWithView: aView
                   printInfo: aPrintInfo];
  if (self == nil)
    return nil;

  _path = [NSTemporaryDirectory()
	    stringByAppendingPathComponent: @"GSCUPSPrintJob-"];
  
  _path = [_path stringByAppendingString: 
		       [[NSProcessInfo processInfo] globallyUniqueString]];
           
  _path = [_path stringByAppendingPathExtension: @"ps"];
  
  RETAIN(_path);
  
  return self;
}
  


- (BOOL) _deliverSpooledResult
{
  NSString *name, *status;
  NSPrinter *printer = [[self printInfo] printer];
  NSDictionary *dict = [[self printInfo] dictionary];
  id features = [dict objectForKey: NSPrintJobFeatures];
  id value;
  cups_option_t *options = NULL;
  int count = 0;
  int copies = 1;
  int job;
  
  name = [printer name];
  status = [NSString stringWithFormat: _(@"Spooling to printer %@."), name];
  [[self printPanel] _setStatusStringValue: status];

  if ([features isKindOfClass: [NSDictionary class]])
    {
      NSEnumerator *enumerator = [features objectEnumerator];

      while ((value = [enumerator nextObject]) != nil)
        count = GSCUPSAddFeature(value, printer, count, &options);
    }

  value = [dict objectForKey: NSPrintPaperFeed];
  if ([value isEqual: NSPrintManualFeed])
    {
      value = [dict objectForKey: NSPrintManualFeed];
      if (value == nil)
        value = @"ManualFeed/True";
    }
  count = GSCUPSAddFeature(value, printer, count, &options);

  value = [dict objectForKey: NSPrintCopies];
  if ([value respondsToSelector: @selector(intValue)])
    copies = MAX(1, [value intValue]);
  count = cupsAddOption("copies",
    [[NSString stringWithFormat: @"%d", copies] UTF8String], count, &options);

  value = [dict objectForKey: NSPrintMustCollate];
  if ([value respondsToSelector: @selector(boolValue)])
    count = cupsAddOption("Collate", [value boolValue] ? "True" : "False",
                          count, &options);

  value = [dict objectForKey: NSPrintPaperName];
  if ([value isKindOfClass: [NSString class]] && [value length] > 0)
    count = cupsAddOption("PageSize", [value UTF8String], count, &options);

  if ([printer respondsToSelector: @selector(_cupsTranslateOptions:error:)])
    {
      NSMutableDictionary *legacy = [NSMutableDictionary dictionary];
      NSDictionary *translated;
      NSString *error = nil, *key;
      NSEnumerator *enumerator;
      int i;

      for (i = 0; i < count; i++)
        [legacy setObject: [NSString stringWithUTF8String: options[i].value]
                  forKey: [NSString stringWithUTF8String: options[i].name]];
      translated = [printer _cupsTranslateOptions: legacy error: &error];
      cupsFreeOptions(count, options);
      options = NULL;
      count = 0;
      if (translated == nil)
        {
          status = [NSString stringWithFormat: _(@"Spooling to printer %@ failed: %@"), name, error];
          [[self printPanel] _setStatusStringValue: status];
          NSLog(@"%@", status);
          return NO;
        }
      enumerator = [translated keyEnumerator];
      while ((key = [enumerator nextObject]) != nil)
        count = cupsAddOption([key UTF8String], [[translated objectForKey: key] UTF8String],
                              count, &options);
    }

  /* Page ranges, ordering, orientation, scaling and N-up have already been
     applied to the document by NSPrintOperation. Do not apply them again. */
  job = cupsPrintFile([name UTF8String], [_path UTF8String],
                      [_path UTF8String], count, options);
  cupsFreeOptions(count, options);

  /* A positive job ID means the spooler accepted the job, not that the
     printer has finished printing it. */
  if (job <= 0)
    {
      status = [NSString stringWithFormat:
        _(@"Spooling to printer %@ failed: %s"), name, cupsLastErrorString()];
      [[self printPanel] _setStatusStringValue: status];
      NSLog(@"%@", status);
      return NO;
    }
  return YES;
}

- (NSGraphicsContext*)createContext
{
  NSMutableDictionary *info;
  NSString *output;
  
  if (_context)
    {
      NSDebugMLLog(@"GSPrinting", @"Already had context, returning it.");
      return _context;
    }
  NSDebugMLLog(@"GSPrinting", @"Creating context.");

  info = [[self printInfo] dictionary];

  output = [info objectForKey: NSPrintSavePath];
  if (output)
    {
      ASSIGN(_path, output);
    }
    
  NSDebugMLLog(@"GSPrinting", @"_path is %@", _path); 
  
  [info setObject: _path 
           forKey: @"NSOutputFile"];

  if ([[[_path pathExtension] lowercaseString] isEqualToString: @"pdf"])
    {
      [info setObject: NSGraphicsContextPDFFormat
	       forKey: NSGraphicsContextRepresentationFormatAttributeName];
    }
  else
    {
      [info setObject: NSGraphicsContextPSFormat
	       forKey: NSGraphicsContextRepresentationFormatAttributeName];
    }
           
  _context = RETAIN([NSGraphicsContext graphicsContextWithAttributes: info]);

  return _context;
}

@end
