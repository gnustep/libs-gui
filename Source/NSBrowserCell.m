/** <title>NSBrowserCell</title>

   <abstract>Cell class for the NSBrowser</abstract>

   Copyright (C) 1996, 1997, 1999 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: December 1999

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

#include "gnustep/gui/config.h"

#include <Foundation/NSUserDefaults.h>

#include "AppKit/NSBrowserCell.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSWindow.h"

/*
 * Class variables
 */
static NSImage	*_branch_image;
static NSImage	*_highlight_image;

static Class	_colorClass;

// GNUstep user default to have NSBrowserCell in bold if non leaf
static BOOL _gsFontifyCells = NO;
static NSFont *_nonLeafFont;
static NSFont *_leafFont;

@implementation NSBrowserCell

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSBrowserCell class])
    {
      [self setVersion: 1];
      ASSIGN(_branch_image, [NSImage imageNamed: @"common_3DArrowRight"]);
      ASSIGN(_highlight_image, [NSImage imageNamed: @"common_3DArrowRightH"]);

      /*
       * Cache classes to avoid overheads of poor compiler implementation.
       */
      _colorClass = [NSColor class];
      
      // A GNUstep experimental feature
      if ([[NSUserDefaults standardUserDefaults] 
	    boolForKey: @"GSBrowserCellFontify"])
	{
	  _gsFontifyCells = YES;
	  _nonLeafFont = RETAIN ([NSFont boldSystemFontOfSize: 0]);
	  _leafFont = RETAIN ([NSFont systemFontOfSize: 0]);
	}
    }
}

/*
 * Accessing Graphic Attributes
 */
+ (NSImage*) branchImage
{
  return _branch_image;
}

+ (NSImage*) highlightedBranchImage
{
  return _highlight_image;
}

/*
 * Instance methods
 */
- (id) initTextCell: (NSString *)aString
{
  [super initTextCell: aString];
  //_alternateImage = nil;
  //_browsercell_is_leaf = NO; 
  //_browsercell_is_loaded = NO;

  if (_gsFontifyCells)
    [self setFont: _nonLeafFont];

  return self;
}

- (id) initImageCell: (NSImage *)anImage
{
  [super initImageCell: anImage];
  //_alternateImage = nil;
  //_browsercell_is_leaf = NO; 
  //_browsercell_is_loaded = NO;

  if (_gsFontifyCells)
    [self setFont: _nonLeafFont];
  
  return self;
}


- (void) dealloc
{
  TEST_RELEASE (_alternateImage);

  [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone
{
  NSBrowserCell	*c = [super copyWithZone: zone];

  TEST_RETAIN (_alternateImage);
  //c->_browsercell_is_leaf = _browsercell_is_leaf;
  //c->_browsercell_is_loaded = _browsercell_is_loaded;

  return c;
}

/*
 * Accessing Graphic Attributes
 */
- (NSImage*) alternateImage
{
  return _alternateImage;
}

- (void) setAlternateImage: (NSImage *)anImage
{
  ASSIGN(_alternateImage, anImage);
}

- (NSColor *)highlightColorInView: (NSView *)controlView
{
  return [_colorClass selectedControlColor];
}

/*
 * Placing in the Browser Hierarchy
 */
- (BOOL) isLeaf
{
  return _browsercell_is_leaf;
}

- (void) setLeaf: (BOOL)flag
{
  if (_browsercell_is_leaf == flag)
    return;

  _browsercell_is_leaf = flag;
  
  if (_gsFontifyCells)
    {
      if (_browsercell_is_leaf)
	{
	  [self setFont: _leafFont];
	}
      else 
	{
	  [self setFont: _nonLeafFont];
	}
    }
}

/*
 * Determining Loaded Status
 */
- (BOOL) isLoaded
{
  return _browsercell_is_loaded;
}

- (void) setLoaded: (BOOL)flag
{
  _browsercell_is_loaded = flag;
}

/*
 * Setting State
 */
- (void) reset
{
  _cell.is_highlighted = NO;
  _cell.state = NO;
}

- (void) set
{
  _cell.is_highlighted = YES;
  _cell.state = YES;
}

/*
 * Displaying
 */
- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
  NSRect	title_rect = cellFrame;
  NSImage	*image = nil;
  NSColor	*backColor;
  NSWindow      *cvWin = [controlView window];
  BOOL          showsFirstResponder;

  if (!cvWin)
    return;

  if (_cell.is_highlighted || _cell.state)
    {
      backColor = [self highlightColorInView: controlView];
      [backColor set];
      if (!_browsercell_is_leaf)
	image = [isa highlightedBranchImage];
    }
  else
    {
      backColor = [cvWin backgroundColor];
      [backColor set];
      if (!_browsercell_is_leaf)
	image = [isa branchImage];
    }
  
  // Clear the background
  NSRectFill(cellFrame);	

  showsFirstResponder = _cell.shows_first_responder;

  // Draw the branch image if there is one
  if (image) 
    {
      NSRect image_rect;

      image_rect.origin = cellFrame.origin;
      image_rect.size = [image size];
      image_rect.origin.x += cellFrame.size.width - image_rect.size.width - 4.0;
      image_rect.origin.y
	+= (cellFrame.size.height - image_rect.size.height) / 2.0;
      [image setBackgroundColor: backColor];
      /*
       * Images are always drawn with their bottom-left corner at the origin
       * so we must adjust the position to take account of a flipped view.
       */
      if ([controlView isFlipped])
	image_rect.origin.y += image_rect.size.height;
      [image compositeToPoint: image_rect.origin 
	     operation: NSCompositeSourceOver];

      title_rect.size.width -= image_rect.size.width + 8;	
    }

  // Skip 2 points from the left border
  title_rect.origin.x += 2;
  title_rect.size.width -= 2;
  
  // Draw the body of the cell
  if ((_cell.type == NSImageCellType)
      && (_cell.is_highlighted || _cell.state)
      && _alternateImage)
    {
      // Draw the alternateImage 
      NSSize size;
      NSPoint position;
      
      size = [_alternateImage size];
      position.x = MAX(NSMidX(title_rect) - (size.width/2.),0.);
      position.y = MAX(NSMidY(title_rect) - (size.height/2.),0.);
      if ([controlView isFlipped])
	position.y += size.height;
      [_alternateImage compositeToPoint: position 
		       operation: NSCompositeSourceOver];
    }
  else
    {
      // Draw image, or text
      _cell.shows_first_responder = NO;

      [super drawInteriorWithFrame: title_rect inView: controlView];
    }

  if (showsFirstResponder == YES)
    NSDottedFrameRect(cellFrame);

  _cell.shows_first_responder = showsFirstResponder;
}

- (BOOL) isOpaque
{
  return YES;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  BOOL tmp;
  [super encodeWithCoder: aCoder];
  
  tmp = _browsercell_is_leaf;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &tmp];
  tmp = _browsercell_is_loaded;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &tmp];
  [aCoder encodeObject: _alternateImage];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  BOOL tmp;
  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &tmp];
  [self setLeaf: tmp];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &tmp];
  [self setLoaded: tmp];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_alternateImage];

  return self;
}

@end
