/* 
   NSMenuItemCell.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Michael Hanni <mhanni@sprintmail.com>
   Date: June 1999
   
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

#ifndef _GNUstep_H_NSMenuItemCell
#define _GNUstep_H_NSMenuItemCell

#include <AppKit/NSActionCell.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSMenuItem.h>

@interface NSMenuItemCell : NSButtonCell <NSMenuItem>
{
  id representedObject;
  BOOL mcell_highlighted;
  BOOL mcell_has_submenu;

  // Not used is GS.
  NSMenuItem *mcell_item;

  BOOL mcell_needs_sizing;
  float mcell_imageWidth;
  float mcell_titleWidth;
  float mcell_keyEqWidth;
  float mcell_stateImgWidth;
}

// NSMenuItem Protocol demands these:
- (void)setTarget:(id)anObject;

- (void)setTitle:(NSString*)aString;
- (NSString*)title;

- (NSString*)keyEquivalent;

- (NSString*)userKeyEquivalent;

- (void)setRepresentedObject:(id)anObject;
- (id)representedObject;

// NSMenuItemCell from MacOSX API.

- (void)setHighlighted:(BOOL)flag;
- (BOOL)isHighlighted;

// These NSMenuItem calls are deprecated in GS. You should not use them
// under any circumstance (i.e. they don't do anything.)

- (void)setMenuItem:(NSMenuItem *)item;
- (NSMenuItem *)menuItem;

- (void)calcSize;
- (void)setNeedsSizing:(BOOL)flag;
- (BOOL)needsSizing;

- (float)imageWidth;
- (float)titleWidth;
- (float)keyEquivalentWidth;
- (float)stateImageWidth;

- (NSRect)imageRectForBounds:(NSRect)cellFrame;
- (NSRect)keyEquivalentRectForBounds:(NSRect)cellFrame;
- (NSRect)stateImageRectForBounds:(NSRect)cellFrame;
- (NSRect)titleRectForBounds:(NSRect)cellFrame;

- (void)drawBorderAndBackgroundWithFrame:(NSRect)cellFrame
                                  inView:(NSView *)controlView;
- (void)drawImageWithFrame:(NSRect)cellFrame
                    inView:(NSView *)controlView;
- (void)drawKeyEquivalentWithFrame:(NSRect)cellFrame
                            inView:(NSView *)controlView;
- (void)drawSeparatorItemWithFrame:(NSRect)cellFrame
                            inView:(NSView *)controlView;
- (void)drawStateImageWithFrame:(NSRect)cellFrame   
                         inView:(NSView *)controlView;
- (void)drawTitleWithFrame:(NSRect)cellFrame
                    inView:(NSView *)controlView;
@end

#endif
