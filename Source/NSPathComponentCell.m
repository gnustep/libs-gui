/* Implementation of class NSPathComponentCell
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Wed Apr 22 18:19:21 EDT 2020

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/NSURL.h>
#import <Foundation/NSGeometry.h>

#import "AppKit/NSPathComponentCell.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSStringDrawing.h"

@implementation NSPathComponentCell

- (NSImage *) image
{
  return _image;
}

- (void) setImage: (NSImage *)image
{
  ASSIGNCOPY(_image, image);
}

- (NSURL *) URL
{
  return _url;
}

- (void) setURL: (NSURL *)url
{
  ASSIGNCOPY(_url, url);
}

- (void) drawInteriorWithFrame: (NSRect)f
                        inView: (NSView *)v
{
  NSString *string = [[_url path] lastPathComponent];
  NSRect textFrame = f;
  NSRect imgFrame = f;
  NSRect arrowFrame = f;
  NSImage *arrowImage = [NSImage imageNamed: @"NSMenuArrow"];

  [super drawInteriorWithFrame: f inView: v];
  
  // Modify positions...
  textFrame.origin.x += 25.0; // the width of the image plus a few pixels.
  textFrame.origin.y += 3.0; // center with the image...
  imgFrame.size.width = 20.0;
  imgFrame.size.height = 20.0;
  arrowFrame.origin.x += f.size.width - 20.0; 
  arrowFrame.size.width = 8.0;
  arrowFrame.size.height = 8.0;
  arrowFrame.origin.y += 5.0;
  
  // Draw the image...
  [_image drawInRect: imgFrame];

  // Draw the text...
  [[NSColor textColor] set]; 
  [string drawAtPoint: textFrame.origin
       withAttributes: nil];

  // Draw the arrow...
  if (_lastComponent == NO)
    {
      [arrowImage drawInRect: arrowFrame];
    }
}

@end
