/* 
   NSMenuItemCell.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Michael Hanni <mhanni@sprintmail.com>
   Date: 1999
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <gnustep/gui/config.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSString.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSColor.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuItemCell.h>

#include <AppKit/PSOperators.h>
 
static BOOL usesUserKeyEquivalents = YES;

@implementation NSMenuItemCell
+ (void)initialize
{
  if (self == [NSMenuItemCell class])
    {
      // Initial version
      [self setVersion:2];
    }
}

- (id)init
{
  mcell_has_submenu = NO;
  [super init];
  [super setTarget:nil];
  return self;
}

// NSMenuitem protocol
- (void)setTarget:(id)anObject
{
  BOOL  hadSubmenu = mcell_has_submenu;
  mcell_has_submenu = anObject && [anObject isKindOfClass:[NSMenu class]];
  if (mcell_has_submenu)
    [anObject retain];
  if (hadSubmenu)
    [target release];
  [super setTarget:anObject];
}

- (BOOL)hasSubmenu
{
  return mcell_has_submenu;
}

- (void)setTitle:(NSString*)aString
{
  [super setStringValue:aString];
}
 
- (NSString*)title
{
  return [super stringValue];
}

- (NSString*)keyEquivalent
{
  if (usesUserKeyEquivalents)
    return [self userKeyEquivalent];   
  else
    return [super keyEquivalent];
}

- (NSString*)userKeyEquivalent
{
  NSString* userKeyEquivalent = [[[[NSUserDefaults standardUserDefaults]
      persistentDomainForName:NSGlobalDomain]
      objectForKey:@"NSCommandKeys"]
      objectForKey:[self stringValue]];
 
  if (!userKeyEquivalent)
    userKeyEquivalent = [super keyEquivalent];

  return userKeyEquivalent;
}
    
- (void)setRepresentedObject:(id)anObject
{
  ASSIGN(representedObject, anObject);
}

- (id)representedObject
{
  return representedObject;
}

// NSMenuItemCell methods as defined by MacOSX API.

- (void)setHighlighted:(BOOL)flag
{
  mcell_highlighted = flag;
}

- (BOOL)isHighlighted
{
  return mcell_highlighted;
}

- (void)setMenuItem:(NSMenuItem *)item
{
  ASSIGN(mcell_item, item);
}

- (NSMenuItem *)menuItem
{
  return mcell_item;
}

- (void)calcSize
{
  //calc sizes of images, title, and cache.

  // At the end we set sizing to NO.
  mcell_needs_sizing = NO;
}

- (void)setNeedsSizing:(BOOL)flag
{
  mcell_needs_sizing = flag;
}

- (BOOL)needsSizing
{
  return mcell_needs_sizing;
}

- (float)imageWidth
{
  if (mcell_needs_sizing)
    [self calcSize];

  return mcell_imageWidth;
}

- (float)titleWidth
{
  if (mcell_needs_sizing)
    [self calcSize];

//  return mcell_titleWidth;
  return [[NSFont systemFontOfSize:12] widthOfString:[self title]];
}

- (float)keyEquivalentWidth
{
  if (mcell_needs_sizing)
    [self calcSize];

  return mcell_keyEqWidth;
}

- (float)stateImageWidth
{
  if (mcell_needs_sizing)
    [self calcSize];

  return mcell_stateImgWidth;
}

// Drawing.

- (NSRect)imageRectForBounds:(NSRect)cellFrame
{
  return NSZeroRect;
}

- (NSRect)keyEquivalentRectForBounds:(NSRect)cellFrame
{
  return NSZeroRect;
}

- (NSRect)stateImageRectForBounds:(NSRect)cellFrame
{
  return NSZeroRect;
}

- (NSRect)titleRectForBounds:(NSRect)cellFrame
{
  return NSZeroRect;
}

// Real drawing,

- (void)drawBorderAndBackgroundWithFrame:(NSRect)cellFrame
				  inView:(NSView *)controlView
{
}

- (void)drawImageWithFrame:(NSRect)cellFrame
		    inView:(NSView *)controlView
{
}

- (void)drawKeyEquivalentWithFrame:(NSRect)cellFrame
			    inView:(NSView *)controlView
{
}

- (void)drawSeparatorItemWithFrame:(NSRect)cellFrame
			    inView:(NSView *)controlView
{
}

- (void)drawStateImageWithFrame:(NSRect)cellFrame
			 inView:(NSView *)controlView
{
}

- (void)drawTitleWithFrame:(NSRect)cellFrame
		    inView:(NSView *)controlView
{
}

- (void)drawWithFrame:(NSRect)cellFrame
	       inView:(NSView *)controlView
{
  NSGraphicsContext     *ctxt = GSCurrentContext();
  NSRect floodRect = cellFrame;
  NSString *keyQ = nil;

  NSDrawButton(cellFrame, cellFrame);

  floodRect.origin.x += 1;
  floodRect.origin.y += 2;
  floodRect.size.height -= 3;
  floodRect.size.width -= 2;

  if (cell_highlighted) {
    [[NSColor whiteColor] set];
    NSRectFill(floodRect);
  } else {
    [[NSColor lightGrayColor] set];
    NSRectFill(floodRect);
  }

  if ([self isEnabled])
    [[NSColor blackColor] set];
  else
    [[NSColor grayColor] set];

  [[NSFont systemFontOfSize:12] set];
  DPSmoveto(ctxt, cellFrame.origin.x + 5, cellFrame.origin.y + 6);
  DPSshow(ctxt, [[self title] cString]);

  if (mcell_has_submenu) {
    floodRect.origin.x = cellFrame.size.width - 12;
    floodRect.origin.y += 5;
    floodRect.size.height = 7;
    floodRect.size.width = 7;

    [self _drawImage:[NSImage imageNamed:@"common_3DArrowRight"] inFrame:floodRect];  
  } else if (keyQ = [self keyEquivalent]) {
    floodRect.origin.x = cellFrame.size.width - 12;
    floodRect.origin.y += 5;
    floodRect.size.height = 7;
    floodRect.size.width = 7;

    [self _drawText:keyQ inFrame:floodRect];
  }
}
@end
