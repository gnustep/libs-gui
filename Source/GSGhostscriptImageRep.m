/** <title>GSGhostscriptImageRep</title>

   <abstract>Ghostscript image representation.</abstract>

   Copyright (C) 2011 Free Software Foundation, Inc.
   
   Author:  Eric Wasylishen <ewasylishen@gmail.com>
   Date: June 2011
   
   This file is part of the GNUstep Application Kit Library.

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

#import <Foundation/NSArray.h>
#import <Foundation/NSAffineTransform.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSTask.h>
#import "AppKit/NSImageRep.h"
#import "AppKit/NSPasteboard.h"
#import "AppKit/NSGraphicsContext.h"
#import "GNUstepGUI/GSGhostscriptImageRep.h"

@implementation GSGhostscriptImageRep 

+ (BOOL) canInitWithData: (NSData *)data
{
  char buf[4];

  if ([data length] < 4)
    {
      return NO;
    }

  [data getBytes: buf length: 4];

  // Simple check for PostScript or EPS, Windows EPS, PDF  

  if ((buf[0] == '%' && buf[1] == '!' && buf[2] == 'P' && buf[3] == 'S') ||
      (buf[0] == '\xc5' && buf[1] == '\xd0' && buf[2] == '\xd3' && buf[3] == '\xc6') ||
      (buf[0] == '%' && buf[1] == 'P' && buf[2] == 'D' && buf[3] == 'F'))
    {
      return YES;
    }
  else
    {
      return NO;
    }
}

+ (NSArray *) imageUnfilteredFileTypes
{
  static NSArray *types = nil;

  if (types == nil)
    {
      types = [[NSArray alloc] initWithObjects: @"ps", @"eps", @"pdf", nil];
    }

  return types;
}

+ (NSArray *) imageUnfilteredPasteboardTypes
{
  static NSArray *types = nil;

  if (types == nil)
    {
      types = [[NSArray alloc] initWithObjects: NSPostScriptPboardType,
			       NSPDFPboardType,
			       nil];
    }
  
  return types;
}

- (NSData *) _pngWithGhostscriptData: (NSData *)psData atResolution: (CGFloat)res
{
  NSTask *task = [[[NSTask alloc] init] autorelease];
  NSPipe *inputPipe = [NSPipe pipe];
  NSPipe *outputPipe = [NSPipe pipe];
  NSFileHandle *inputHandle = [inputPipe fileHandleForWriting];
  NSFileHandle *outputHandle = [outputPipe fileHandleForReading];
  NSData *result;

  // FIXME: Parameterize
  [task setLaunchPath: @"/usr/bin/gs"];
  [task setArguments: [NSArray arrayWithObjects: @"-dSAFER",
			       @"-q",
			       @"-o",
			       @"-", // Write output image to stdout
			       @"-sDEVICE=pngalpha",
			       [NSString stringWithFormat: @"-r%d", (int)res],
			       @"-dTextAlphaBits=4",
			       @"-dGraphicsAlphaBits=4",
			       @"-dDOINTERPOLATE",
			       @"-", // Read input from stdin
			       nil]];
  [task setStandardInput: inputPipe];
  [task setStandardOutput: outputPipe];
  [task launch];

  [inputHandle writeData: psData];
  [inputHandle closeFile];

  result = [outputHandle readDataToEndOfFile];
  [outputHandle closeFile];

  return result;
}



// Initializing a New Instance 
+ (id) imageRepWithData: (NSData *)psData
{
  return AUTORELEASE([[self alloc] initWithData: psData]);
}

- (id) initWithData: (NSData *)psData
{
  NSData *pngData;
  
  ASSIGN(_psData, psData);

  pngData = [self _pngWithGhostscriptData: _psData atResolution: 72.0];

  if (pngData == nil)
    {
      [self release];
      return nil;
    }

 _bitmap = [NSBitmapImageRep imageRepWithData: pngData];
 
  [self setSize: [_bitmap size]];
  [self setAlpha: [_bitmap hasAlpha]];
  [self setBitsPerSample: NSImageRepMatchesDevice];
  [self setPixelsWide: NSImageRepMatchesDevice];
  [self setPixelsHigh: NSImageRepMatchesDevice];
  // FIXME: Other properties?

  return self;
}

// Drawing the Image 
- (BOOL) draw
{
  if (_bitmap != nil)
    {
      // FIXME: Re-cache at a higher resolution if needed

      return [_bitmap draw];
    }
  return NO;
}

// NSCopying protocol
- (id) copyWithZone: (NSZone *)zone
{
  GSGhostscriptImageRep *copy = [super copyWithZone: zone];

  copy->_psData = [_psData copyWithZone: zone];
  copy->_bitmap = [_bitmap copyWithZone: zone];

  return copy;
}

// NSCoding protocol
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  // FIXME:
  [super encodeWithCoder: aCoder];
  [_psData encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  // FIXME:
  NSData	*data;

  self = [super initWithCoder: aDecoder];
  data = [aDecoder decodeObject];
  return [self initWithData: data];
}

@end
