/*
   NSBrowserCell.m

   Cell class for the NSBrowser

   Copyright (C) 1996, 1997, 1999 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996

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

#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSWindow.h>

/*
 * Class variables
 */
static NSImage	*branch_image;
static NSImage	*highlight_image;

static Class	cellClass;
static Class	colorClass;

/*
 * Private methods
 */
@interface NSBrowserCell (Private)
- (void) setBranchImageCell: aCell;
- (void) setHighlightBranchImageCell: aCell;
- (void) setTextFieldCell: aCell;
@end

@implementation NSBrowserCell (Private)

- (void) setTextFieldCell: aCell
{
  ASSIGN(_browserText, aCell);
}

- (void) setBranchImageCell: aCell
{
  ASSIGN(_branchImage, aCell);
}

- (void) setHighlightBranchImageCell: aCell
{
  ASSIGN(_highlightBranchImage, aCell);
}

@end


/*****************************************************************************
 *
 * 		NSBrowserCell
 *
 *****************************************************************************/

@implementation NSBrowserCell

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSBrowserCell class])
    {
      [self setVersion: 1];
      ASSIGN(branch_image, [NSImage imageNamed: @"common_3DArrowRight"]);
      ASSIGN(highlight_image, [NSImage imageNamed: @"common_3DArrowRightH"]);
      /*
       * Cache classes to avoid overheads of poor compiler implementation.
       */
      cellClass = [NSCell class];
      colorClass = [NSColor class];
    }
}

/*
 * Accessing Graphic Attributes
 */
+ (NSImage*) branchImage
{
  return branch_image;
}

+ (NSImage*) highlightedBranchImage
{
  return highlight_image;
}

/*
 * Instance methods
 */
- (id) init
{
  return [self initTextCell: @"aTitle"];
}

- (id) initTextCell: (NSString *)aString
{
  [super initTextCell: aString];
  // create image cells
  _branchImage = RETAIN([isa branchImage]);
  _highlightBranchImage = RETAIN([isa highlightedBranchImage]);
  // create the text cell
  _browserText = [[cellClass alloc] initTextCell: aString];
  [_browserText setEditable: NO];
  [_browserText setBordered: NO];
  [_browserText setAlignment: NSLeftTextAlignment];

  _alternateImage = nil;
  _isLeaf = NO;
  _isLoaded = NO;

  [self setEditable: NO];

  return self;
}

- (void) dealloc
{
  RELEASE(_branchImage);
  RELEASE(_highlightBranchImage);
  TEST_RELEASE(_alternateImage);
  RELEASE(_browserText);

  [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone
{
  NSBrowserCell	*c = [super copyWithZone: zone];

  c->_branchImage = RETAIN(_branchImage);
  if (_alternateImage)
    c->_alternateImage = RETAIN(_alternateImage);
  c->_highlightBranchImage = RETAIN(_highlightBranchImage);
  c->_browserText = [_browserText copyWithZone: zone];	// Copy the text cell
  c->_isLeaf = _isLeaf;
  c->_isLoaded = _isLoaded;

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

/*
 * Placing in the Browser Hierarchy
 */
- (BOOL) isLeaf
{
  return _isLeaf;
}

- (void) setLeaf: (BOOL)flag
{
  _isLeaf = flag;
}

/*
 * Determining Loaded Status
 */
- (BOOL) isLoaded
{
  return _isLoaded;
}

- (void) setLoaded: (BOOL)flag
{
  _isLoaded = flag;
}

/*
 * Setting State
 */
- (void) reset
{
  cell_highlighted = NO;
  cell_state = NO;
}

- (void) set
{
  cell_highlighted = YES;
  cell_state = YES;
}

/*
 * Setting and accessing the NSCell's Value
 */
- (double) doubleValue
{
  return [_browserText doubleValue];
}

- (float) floatValue
{
  return [_browserText floatValue];
}

- (int) intValue
{
  return [_browserText intValue];
}

- (NSString*) stringValue
{
  return [_browserText stringValue];
}

- (void) setIntValue: (int)anInt
{
  [_browserText setIntValue: anInt];
}

- (void) setDoubleValue: (double)aDouble
{
  [_browserText setDoubleValue: aDouble];
}

- (void) setFloatValue: (float)aFloat
{
  [_browserText setFloatValue: aFloat];
}

- (void) setStringValue: (NSString*)aString
{
  [_browserText setStringValue: aString];
}

/*
 * Displaying
 */
- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
  NSRect	title_rect = cellFrame;
  NSRect	image_rect = cellFrame;
  NSImage	*image = nil;
  NSColor	*backColor;

  control_view = controlView;		// remember last view cell was drawn in
  [controlView lockFocus];
  if (cell_highlighted || cell_state)		// temporary hack FAR FIX ME?
    {
      backColor = [colorClass selectedControlColor];
      [backColor set];
      if (!_isLeaf)
	{
          image = _highlightBranchImage;
	}
      else
          image_rect = NSZeroRect;
    }
  else
    {
      backColor = [[controlView window] backgroundColor];
      [backColor set];
      if (!_isLeaf)
	{
          image = _branchImage;
	}
      else
          image_rect = NSZeroRect;
    }

  image_rect.size = [image size];
													  // Right justify
  image_rect.origin.x += cellFrame.size.width - image_rect.size.width - 4.0;
  image_rect.origin.y += (cellFrame.size.height - image_rect.size.height) / 2.0;
//MAX(NSMidY(image_rect) - ([image size].height/2.),0.);

  NSRectFill(cellFrame);	// Clear the background

  title_rect.size.width -= image_rect.size.width + 8;	// draw the title cell
  [_browserText drawWithFrame: title_rect inView: controlView];

  if (image)
    {
      NSPoint position = image_rect.origin;

      [image setBackgroundColor: backColor];
      /*
       * Images are always drawn with their bottom-left corner at the origin
       * so we must adjust the position to take account of a flipped view.
       */
      if ([control_view isFlipped])
	position.y += [image size].height;
      [image compositeToPoint: position operation: NSCompositeCopy];
    }
  [controlView unlockFocus];
}

/*
 * Editing Text
 */
- (void) editWithFrame: (NSRect)aRect
		inView: (NSView *)controlView
		editor: (NSText *)textObject
	      delegate: (id)anObject
		 event: (NSEvent *)theEvent
{
  NSPoint location = [controlView convertPoint: [theEvent locationInWindow]
				      fromView: nil];

  NSDebugLog(@" NSBrowserCell: editWithFrame --- ");

  [_browserText _setCursorLocation: location];
  [_browserText _setCursorVisibility: YES];

  if ([[controlView window] makeFirstResponder: controlView])
    NSDebugLog(@" NSBrowserCell: we are now first responder --- ");

  [self drawInteriorWithFrame: aRect inView: controlView];
}

- (void) endEditing: (NSText *)textObject
{
  [_browserText _setCursorVisibility: NO];
}

- (void) _handleKeyEvent: (NSEvent*)keyEvent
{
  NSDebugLog(@" NSBrowserCell: _handleKeyEvent --- ");

  [_browserText _handleKeyEvent: keyEvent];

//  [self drawInteriorWithFrame: aRect inView: controlView];
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeObject: _browserText];
  [aCoder encodeObject: _branchImage];
  [aCoder encodeObject: _highlightBranchImage];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isLeaf];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isLoaded];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(id) at: &_browserText];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_branchImage];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_highlightBranchImage];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isLeaf];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isLoaded];

  return self;
}

@end
