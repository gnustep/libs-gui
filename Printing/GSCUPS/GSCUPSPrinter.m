/** <title>GSCUPSPrinter</title>

   <abstract>Class representing a printer's or printer model's capabilities.</abstract>

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Chad Hardin <cehardin@mac.com>
   Date: October 2004
   
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

/* NB:
 * There are a few FIXMEs in the functionality left.
 * Parsing of the PPDs is somewhat suboptimal.
 * (I think it's best to leave optimisation until more of GNUstep is done).
 * The *OpenUI, *CloseUI, *OpenGroup and *CloseGroup are not processed.
 * (This is not required in the OpenStep standard, but could be useful).
 */

#import "config.h"
#import <Foundation/NSDebug.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import "AppKit/AppKitExceptions.h"
#import "AppKit/NSGraphics.h"
#import "GNUstepGUI/GSPrinting.h"
#import "GSCUPSPrinter.h"

#undef __BLOCKS__
#include <cups/cups.h>
#include <cups/ppd.h>

/* Destination media enumeration was introduced in CUPS 1.7. Older CUPS
   builds continue to use the PPD implementation. */
#if CUPS_VERSION_MAJOR > 1 || (CUPS_VERSION_MAJOR == 1 && CUPS_VERSION_MINOR >= 7)
#define GS_CUPS_HAS_IPP 1
#include <cups/pwg.h>

#else
#define GS_CUPS_HAS_IPP 0
#endif

@interface GSCUPSPrinter (Capabilities)

- (BOOL) _loadIPPCapabilities;

@end

#if GS_CUPS_HAS_IPP
/* Keep the connection local to a query, rather than retaining CUPS objects
   in NSPrinter, which supports archiving. Query the scheduler for queues so
   its filtering capabilities are included, not just the physical device. */
static http_t *
GSCUPSConnect(cups_dest_t *dest)
{
  http_t *http = cupsConnectDest(dest, 0, 5000, NULL, NULL, 0, NULL, NULL);

  if (http != NULL)
    httpSetTimeout(http, 5.0, NULL, NULL);
  return http;
}

static NSString *
GSCUPSResolution(ipp_attribute_t *attribute, int index, BOOL display)
{
  ipp_res_t units;
  int x, y;

  if (attribute == NULL || ippGetValueTag(attribute) != IPP_TAG_RESOLUTION)
    return nil;
  x = ippGetResolution(attribute, index, &y, &units);
  if (x <= 0 || y <= 0 || (units != IPP_RES_PER_INCH && units != IPP_RES_PER_CM))
    return nil;
  if (display && units == IPP_RES_PER_CM)
    {
      x = (int)(x * 2.54 + 0.5);
      y = (int)(y * 2.54 + 0.5);
    }
  if (display && x == y)
    return [NSString stringWithFormat: @"%ddpi", x];
  return [NSString stringWithFormat: @"%dx%d%s", x, y,
    !display && units == IPP_RES_PER_CM ? "dpcm" : "dpi"];
}

static void
GSCUPSSetValue(NSMutableDictionary *table, NSString *key, NSString *value)
{
  if (value != nil)
    [table setObject: [NSArray arrayWithObject: value] forKey: key];
}

static NSString *
GSCUPSMediaName(cups_size_t *size)
{
  pwg_media_t *media = pwgMediaForSize(size->width, size->length);

  if (media != NULL && media->ppd != NULL)
    return [NSString stringWithUTF8String: media->ppd];
  return [NSString stringWithUTF8String: size->media];
}

static void
GSCUPSAddMedia(cups_size_t *size, NSMutableArray *names,
              NSMutableDictionary *ppd, NSMutableDictionary *mapping,
              ipp_attribute_t *supported)
{
  NSString *name;
  NSString *value;
  pwg_media_t *media;
  double points = 72.0 / 2540.0;

  if (size->width <= 0 || size->length <= 0 || size->media[0] == 0
      || size->left < 0 || size->right < 0 || size->top < 0 || size->bottom < 0
      || size->left + size->right >= size->width
      || size->top + size->bottom >= size->length)
    return;
  name = GSCUPSMediaName(size);
  /* cups_size_t may contain a media-key identifying a tray/margin variant.
     The media job attribute instead needs a supported media-size-name. */
  media = pwgMediaForSize(size->width, size->length);
  if (supported != NULL && !ippContainsString(supported, size->media)
      && media != NULL && ippContainsString(supported, media->pwg))
    value = [NSString stringWithUTF8String: media->pwg];
  else
    value = [NSString stringWithUTF8String: size->media];
  if (name == nil || value == nil || [names containsObject: name])
    return;
  [names addObject: name];
  GSCUPSSetValue(ppd, [@"PaperDimension/" stringByAppendingString: name],
    [NSString stringWithFormat: @"%.6f %.6f", size->width * points, size->length * points]);
  GSCUPSSetValue(ppd, [@"ImageableArea/" stringByAppendingString: name],
    [NSString stringWithFormat: @"%.6f %.6f %.6f %.6f",
      size->left * points, size->bottom * points,
      (size->width - size->right) * points, (size->length - size->top) * points]);
  [mapping setObject: value forKey: name];
}

#endif



NSString *GSCUPSDummyPrinterName = @"GSCUPSDummyPrinter";

@implementation GSCUPSPrinter

//
// Class methods
//
+(void) initialize
{
  if (self == [GSCUPSPrinter class])
    {
      // Initial version
      [self setVersion:1];
    }
}

// Required because the super class redefines the default
+ (id) allocWithZone: (NSZone*)z
{
  return NSAllocateObject (self, 0, z);
}

//
// Finding an NSPrinter 
//
+ (NSPrinter*) printerWithName: (NSString*) name
{
  NSPrinter* printer;
  const char* ppdFile;

  if ([name isEqual: GSCUPSDummyPrinterName])
    {
      /* Create a dummy printer as a fallback.  */
static BOOL didWarn;
      NSString *ppdPath;

      if (!didWarn)
	{
	  NSLog(@"Creating a default printer since no default printer has "
		@"been set in CUPS.");
	  didWarn = YES;
	}

      ppdPath = [NSBundle
	pathForLibraryResource: @"Generic-PostScript_Printer-Postscript"
			ofType: @"ppd"
		   inDirectory: @"PostScript/PPD"];
      NSAssert(ppdPath,
	       @"Couldn't find the PPD file for the fallback printer.");

      printer = [(GSCUPSPrinter*)[self alloc]
		  initWithName: name
		      withType: @"Unknown"
		      withHost: @"Unknown"
		      withNote: @"Automatically Generated"];

      /* An unreadable fallback PPD is a warning here and the printer is
         returned without it, so the caller uses its defaults. */
      NS_DURING
        {
          [printer parsePPDAtPath: ppdPath];
        }
      NS_HANDLER
        {
          NSLog(@"Could not read the fallback PPD %@: %@",
                ppdPath, [localException reason]);
        }
      NS_ENDHANDLER

      return AUTORELEASE(printer);
    }

  printer = [[GSCUPSPrinter alloc]
                    initWithName: name
                        withType: @"Type Unknown"
                        withHost: @"Host Unknown"
                        withNote: @"No Note"];

  ppdFile = cupsGetPPD( [name UTF8String] );

  if( ppdFile )
    {
      /* The PPD CUPS provides may be unreadable; an unreadable PPD is a warning
         here and the printer is returned without it, so the caller uses its
         defaults rather than aborting. */
      NS_DURING
        {
          [printer parsePPDAtPath: [NSString stringWithCString: ppdFile]];
        }
      NS_HANDLER
        {
          NSLog(@"Could not read the PPD for printer %@: %@",
                name, [localException reason]);
        }
      NS_ENDHANDLER
      unlink( ppdFile );
    }
  else
    {
      NSDebugLLog(@"GSCUPS", @"Printer %@ does not have a PPD", name);
    }

  [(GSCUPSPrinter *)printer _loadIPPCapabilities];
  return AUTORELEASE(printer);
}


+ (NSArray *)printerNames
{
  NSMutableSet *set;
  int numDests;
  cups_dest_t* dests;
  int n;

  set = [[NSMutableSet alloc] init];
  AUTORELEASE(set);

  numDests = cupsGetDests(&dests);
  
  for (n = 0; n < numDests; n++)
    {
      [set addObject: [NSString stringWithCString: dests[n].name]];
    }

  cupsFreeDests(numDests, dests);

  // No printer found, return at least the dummy printer
  if ([set count] == 0)
    {
      [set addObject: GSCUPSDummyPrinterName];
    }

  return [set allObjects];
}

/* Only replace capabilities which IPP actually supplies. This keeps vendor
   PPD features and legacy defaults usable when attributes are missing. */
- (BOOL) _loadIPPCapabilities
{
#if GS_CUPS_HAS_IPP
  cups_dest_t *dest = cupsGetNamedDest(CUPS_HTTP_DEFAULT, [[self name] UTF8String], NULL);
  cups_dinfo_t *info = NULL;
  http_t *http = NULL;
  BOOL loaded = NO;

  if (dest == NULL)
    return NO;
  http = GSCUPSConnect(dest);
  if (http != NULL)
    info = cupsCopyDestInfo(http, dest);
  if (info != NULL)
    {
      NSMutableDictionary *ppd = [_tables objectForKey: @"PPD"];
      NSMutableDictionary *mappings = [NSMutableDictionary dictionary];
      NSMutableDictionary *keywords = [NSMutableDictionary dictionary];
      NSMutableArray *names = [NSMutableArray array];
      NSMutableDictionary *media = [NSMutableDictionary dictionary];
      cups_size_t size;
      ipp_attribute_t *supportedMedia = cupsFindDestSupported(http, dest, info, "media");
      NSString *defaultMedia = nil;
      int i, count;
      const char *options[] = { "sides", "print-color-mode", "printer-resolution",
                               "media-source", "multiple-document-handling" };
      NSString *keys[] = { @"Duplex", @"ColorModel", @"Resolution", @"InputSlot", @"Collate" };

      if (ppd == nil)
        {
          ppd = [NSMutableDictionary dictionary];
          [_tables setObject: ppd forKey: @"PPD"];
        }
      /* Prefer the default margins when several variants have the same size. */
      if (cupsGetDestMediaDefault(http, dest, info, 0, &size))
        {
          GSCUPSAddMedia(&size, names, ppd, media, supportedMedia);
          if ([names count] > 0)
            defaultMedia = [names objectAtIndex: 0];
        }
      count = cupsGetDestMediaCount(http, dest, info, 0);
      for (i = 0; i < count; i++)
        if (cupsGetDestMediaByIndex(http, dest, info, i, 0, &size))
          GSCUPSAddMedia(&size, names, ppd, media, supportedMedia);
      if ([names count] > 0)
        {
          [ppd setObject: names forKey: @"PageSize"];
          [ppd setObject: names forKey: @"PageRegion"];
          if (defaultMedia == nil)
            defaultMedia = [names objectAtIndex: 0];
          GSCUPSSetValue(ppd, @"DefaultPageSize", defaultMedia);
          GSCUPSSetValue(ppd, @"DefaultPageRegion", defaultMedia);
          [mappings setObject: media forKey: @"PageSize"];
          [keywords setObject: @"media" forKey: @"PageSize"];
        }
      for (i = 0; i < 5; i++)
        {
          ipp_attribute_t *supported = cupsFindDestSupported(http, dest, info, options[i]);
          ipp_attribute_t *def = cupsFindDestDefault(http, dest, info, options[i]);
          NSMutableDictionary *values = [NSMutableDictionary dictionary];
          NSMutableArray *choices = [NSMutableArray array];
          NSString *defaultChoice = nil;
          int j;

          for (j = 0; supported != NULL && j < ippGetCount(supported); j++)
            {
              NSString *value = nil, *choice = nil, *defaultValue = nil;

              if (i == 2)
                {
                  value = GSCUPSResolution(supported, j, NO);
                  choice = GSCUPSResolution(supported, j, YES);
                  defaultValue = GSCUPSResolution(def, 0, NO);
                }
              else if (ippGetValueTag(supported) == IPP_TAG_KEYWORD
                       || ippGetValueTag(supported) == IPP_TAG_NAME)
                {
                  const char *text = ippGetString(supported, j, NULL);
                  const char *defaultText = def == NULL ? NULL : ippGetString(def, 0, NULL);
                  if (text != NULL)
                    value = [NSString stringWithUTF8String: text];
                  if (defaultText != NULL)
                    defaultValue = [NSString stringWithUTF8String: defaultText];
                  choice = value;
                  if (i == 0)
                    {
                      if ([value isEqual: @"one-sided"]) choice = @"None";
                      else if ([value isEqual: @"two-sided-long-edge"]) choice = @"DuplexNoTumble";
                      else if ([value isEqual: @"two-sided-short-edge"]) choice = @"DuplexTumble";
                    }
                  else if (i == 1)
                    {
                      if ([value isEqual: @"color"]) choice = @"RGB";
                      else if ([value isEqual: @"monochrome"]) choice = @"Gray";
                    }
                  else if (i == 4)
                    {
                      if ([value isEqual: @"separate-documents-collated-copies"]) choice = @"True";
                      else if ([value isEqual: @"separate-documents-uncollated-copies"]) choice = @"False";
                      else choice = nil;
                    }
                }
              if (choice == nil || value == nil)
                continue;
              if (![choices containsObject: choice])
                [choices addObject: choice];
              [values setObject: value forKey: choice];
              if ([value isEqual: defaultValue])
                defaultChoice = choice;
            }
          if ([choices count] == 0)
            continue;
          [ppd setObject: choices forKey: keys[i]];
          GSCUPSSetValue(ppd, [@"Default" stringByAppendingString: keys[i]],
            defaultChoice == nil ? [choices objectAtIndex: 0] : defaultChoice);
          [mappings setObject: values forKey: keys[i]];
          [keywords setObject: [NSString stringWithUTF8String: options[i]] forKey: keys[i]];
          if (i == 1)
            GSCUPSSetValue(ppd, @"ColorDevice", [choices containsObject: @"RGB"] ? @"True" : @"False");
        }
      if ([keywords count] > 0)
        {
          [_tables setObject: mappings forKey: @"GSCUPSIPPValues"];
          [_tables setObject: keywords forKey: @"GSCUPSIPPKeywords"];
          loaded = YES;
        }
      cupsFreeDestInfo(info);
    }
  if (http != NULL)
    httpClose(http);
  cupsFreeDests(1, dest);
  return loaded;
#else
  return NO;
#endif
}

- (BOOL) _cupsSupportsIPPOption: (NSString *)keyword
{
  return [[_tables objectForKey: @"GSCUPSIPPKeywords"] objectForKey: keyword] != nil;
}

/* Validate immediately before submission, including combinations which CUPS
   reports as conflicting. Never silently substitute a different user choice.
   A failed refresh preserves the discovery snapshot and lets normal spooler
   error reporting handle unavailable servers. */
- (NSDictionary *) _cupsTranslateOptions: (NSDictionary *)options
                                  error: (NSString **)error
{
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  NSDictionary *keywords = [_tables objectForKey: @"GSCUPSIPPKeywords"];
  NSDictionary *mappings = [_tables objectForKey: @"GSCUPSIPPValues"];
  NSEnumerator *enumerator = [options keyEnumerator];
  NSString *key;

  if (error != NULL)
    *error = nil;
  while ((key = [enumerator nextObject]) != nil)
    {
      NSString *value = [options objectForKey: key];
      NSString *option = [keywords objectForKey: key];

      if (option != nil)
        {
          NSString *mapped = [[mappings objectForKey: key] objectForKey: value];
          if (mapped == nil)
            {
              if (error != NULL)
                *error = [NSString stringWithFormat: @"Unsupported printer option %@/%@", key, value];
              return nil;
            }
          [result setObject: mapped forKey: option];
        }
      else
        [result setObject: value forKey: key];
    }
#if GS_CUPS_HAS_IPP
  if ([keywords count] > 0)
    {
      cups_dest_t *dest = cupsGetNamedDest(CUPS_HTTP_DEFAULT, [[self name] UTF8String], NULL);
      http_t *http = dest == NULL ? NULL : GSCUPSConnect(dest);
      cups_dinfo_t *info = http == NULL ? NULL : cupsCopyDestInfo(http, dest);
      cups_option_t *selected = NULL;
      int count = 0;
      BOOL valid = YES;

      if (info != NULL)
        {
          enumerator = [result keyEnumerator];
          while ((key = [enumerator nextObject]) != nil)
            {
              const char *option = [key UTF8String];
              const char *value = [[result objectForKey: key] UTF8String];

              /* Missing attributes are not evidence that legacy/vendor
                 options are unsupported. */
              if (cupsFindDestSupported(http, dest, info, option) != NULL
                  && !cupsCheckDestSupported(http, dest, info, option, value))
                {
                  valid = NO;
                  if (error != NULL)
                    *error = [NSString stringWithFormat: @"Unsupported printer option %@=%@",
                      key, [result objectForKey: key]];
                  break;
                }
              count = cupsAddOption(option, value, count, &selected);
            }
          /* Check the complete selection. An intermediate set can conflict
             with a default that a later explicit option replaces. */
          if (valid)
            {
              int conflicts = 0;
              cups_option_t *conflicting = NULL;
              int status = cupsCopyDestConflicts(http, dest, info, count, selected,
                NULL, NULL, &conflicts, &conflicting, NULL, NULL);

              if (status != 0)
                {
                  valid = NO;
                  if (error != NULL)
                    {
                      if (conflicts > 0)
                        *error = [NSString stringWithFormat: @"Conflicting printer option %s=%s",
                          conflicting[0].name, conflicting[0].value];
                      else
                        *error = status < 0 ? @"Could not validate printer options"
                          : @"Conflicting printer options";
                    }
                }
              cupsFreeOptions(conflicts, conflicting);
            }
          cupsFreeDestInfo(info);
        }
      cupsFreeOptions(count, selected);
      if (http != NULL)
        httpClose(http);
      if (dest != NULL)
        cupsFreeDests(1, dest);
      if (!valid)
        return nil;
    }
#endif
  return result;
}

@end

