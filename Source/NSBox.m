/* 
   NSBox.m

   Simple box view that can display a border and title

   Copyright (C) 1996 Free Software Foundation, Inc.

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
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSString.h>

#include <AppKit/NSBox.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSTextFieldCell.h>

@interface NSBox (Private)
- (NSRect) calcSizesAllowingNegative: (BOOL)aFlag;
@end

@implementation NSBox

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSBox class])
    {
      // Initial version
      [self setVersion: 1];
    }
}

//
// Instance methods
//
- (id) initWithFrame: (NSRect)frameRect
{
  [super initWithFrame: frameRect];
	
  cell = [[NSTextFieldCell alloc] initTextCell: @"Title"];
  [cell setAlignment: NSCenterTextAlignment];
  [cell setBordered: NO];
  [cell setEditable: NO];
  [cell setDrawsBackground: YES];
  [cell setBackgroundColor: [window backgroundColor]];
  offsets.width = 5;
  offsets.height = 5;
  border_rect = bounds;
  border_type = NSGrooveBorder;
  title_position = NSAtTop;
  title_rect = NSZeroRect;
  [self setAutoresizesSubviews: NO];
  content_view = [NSView new];
  [super addSubview: content_view];
  [content_view setFrame: [self calcSizesAllowingNegative: NO]];
  [content_view release];

  return self;
}

- (void) dealloc
{
  if (cell) 
    [cell release];

  [super dealloc];
}

//
// Getting and Modifying the Border and Title 
//
- (NSRect) borderRect
{
  return border_rect;
}

- (NSBorderType) borderType
{
  return border_type;
}

- (void) setBorderType: (NSBorderType)aType
{
  if (border_type != aType)
    {
      border_type = aType;
      [content_view setFrame: [self calcSizesAllowingNegative: NO]];
      [self setNeedsDisplay: YES];
    }
}

// TODO: implement the macosx behaviour for setTitle:
- (void) setTitle: (NSString *)aString
{
  [cell setStringValue: aString];
  [content_view setFrame: [self calcSizesAllowingNegative: NO]];
  [self setNeedsDisplay: YES];
}

// TODO: - (void) setTitleWithMnemonic: (NSString *)aString

- (void) setTitleFont: (NSFont *)fontObj
{
  [cell setFont: fontObj];
  [content_view setFrame: [self calcSizesAllowingNegative: NO]];
  [self setNeedsDisplay: YES];
}

- (void) setTitlePosition: (NSTitlePosition)aPosition
{
  if (title_position != aPosition)
    {
      title_position = aPosition;
      [content_view setFrame: [self calcSizesAllowingNegative: NO]];
      [self setNeedsDisplay: YES];
    }
}

- (NSString*) title
{
  return [cell stringValue];
}

- (id) titleCell
{
  return cell;
}

- (NSFont*) titleFont
{
  return [cell font];
}

- (NSTitlePosition) titlePosition
{
  return title_position;
}

- (NSRect) titleRect
{
  return title_rect;
}

//
// Setting and Placing the Content View 
//
- (id) contentView
{
  return content_view;
}

- (NSSize) contentViewMargins
{
  return offsets;
}

- (void) setContentView: (NSView*)aView
{
  if (aView)
    {
      [super replaceSubview: content_view with: aView];
      content_view = aView;
      [content_view setFrame: [self calcSizesAllowingNegative: NO]];
    }
}

- (void) setContentViewMargins: (NSSize)offsetSize
{
  NSAssert(offsetSize.width >= 0 && offsetSize.height >= 0,
	@"illegal margins supplied");

  offsets = offsetSize;
  [content_view setFrame: [self calcSizesAllowingNegative: NO]];
  [self setNeedsDisplay: YES];

}

//
// Resizing the Box 
//
- (void) setFrame: (NSRect)frameRect
{
  [super setFrame: frameRect];
  [content_view setFrame: [self calcSizesAllowingNegative: NO]];
}
- (void) setFrameSize: (NSSize)newSize
{
  [super setFrameSize: newSize];
  [content_view setFrame: [self calcSizesAllowingNegative: NO]];
}
- (void) setFrameFromContentFrame: (NSRect)contentFrame
{
  // First calc the sizes to see how much we are off by
  NSRect r = [self calcSizesAllowingNegative: YES];
  NSRect f = frame;

  NSAssert(contentFrame.size.width >= 0 && contentFrame.size.height >= 0,
	@"illegal content frame supplied");

  if ([self superview])
    r = [[self superview] convertRect: r fromView: self];
  
  // Add the difference to the frame
  f.size.width = f.size.width + (contentFrame.size.width - r.size.width);
  f.size.height = f.size.height + (contentFrame.size.height - r.size.height);
  f.origin.x = f.origin.x + (contentFrame.origin.x - r.origin.x);
  f.origin.y = f.origin.y + (contentFrame.origin.y - r.origin.y);

  [self setFrame: f];
  [content_view setFrame: [self calcSizesAllowingNegative: NO]];  
}

- (void) sizeToFit
{
  NSRect f;

  if ([content_view respondsToSelector: @selector(sizeToFit)])
    [content_view sizeToFit];
  else // content_view !respondsToSelector: sizeToFit
    {   
      NSArray *subviewArray = [content_view subviews];
      if ([subviewArray count])
	{
	  id o, e = [subviewArray objectEnumerator];
	  NSRect r = [[e nextObject] frame];
	  // Loop through subviews and calculate rect to encompass all
	  while ((o = [e nextObject]))
	    {
	      f = [o frame];
	      if (f.origin.x < r.origin.x)
		r.origin.x = f.origin.x;
	      if (f.origin.y < f.origin.y)
		r.origin.y = f.origin.y;
	      if ((f.origin.x + f.size.width) > (r.origin.x + r.size.width))
		r.size.width = (f.origin.x + f.size.width) - r.origin.x;
	      if ((f.origin.y + f.size.height) > (r.origin.y + r.size.height))
		r.size.height = (f.origin.y + f.size.height) - r.origin.y;
	    }
	  [content_view setBoundsOrigin: r.origin];
	  r.size = [self convertSize: r.size fromView: content_view];
	  [content_view setAutoresizesSubviews: NO];
	  [content_view setFrameSize: r.size];
	  [content_view setAutoresizesSubviews: YES];
	}
      else // content_view has no subviews
	{
	  [content_view setFrame: NSZeroRect];
	}
    }

  f = [content_view frame];

  // The box width should be enough to display the title
  if (title_position != NSNoTitle)
    {
      NSSize titleSize = [cell cellSize];
      titleSize.width += 1;
      if (f.size.width < titleSize.width)
	f.size.width = titleSize.width;
    }
  
  if ([self superview])
    [self setFrameFromContentFrame: [self convertRect: f toView: [self superview]]];
  else // ![self superview]
    [self setFrameFromContentFrame: f]; 
}

- (void) resizeWithOldSuperviewSize: (NSSize)oldSize
{
  [super resizeWithOldSuperviewSize: oldSize];
  [content_view setFrame: [self calcSizesAllowingNegative: NO]];
}

//
// Managing the NSView Hierarchy 
//
- (void) addSubview: (NSView*)aView
{
  [content_view addSubview: aView];
}

- (void) addSubview: (NSView*)aView
         positioned: (NSWindowOrderingMode)place
         relativeTo: (NSView*)otherView
{
  [content_view addSubview: aView positioned: place relativeTo: otherView];
}

- (void) replaceSubview: (NSView *)aView with: (NSView*) newView
{
  [content_view replaceSubview: aView with: newView];
}

//
// Displaying
//
- (void) drawRect: (NSRect)rect
{
  rect = NSIntersectionRect(bounds, rect);
  // Fill inside
  [[window backgroundColor] set];
  NSRectFill(rect);

  // Draw border
  switch (border_type)
    {
    case NSNoBorder: 
      break;
    case NSLineBorder: 
      [[NSColor controlDarkShadowColor] set];
      NSFrameRect(border_rect);
      break;
    case NSBezelBorder: 
      NSDrawGrayBezel(border_rect, rect);
      break;
    case NSGrooveBorder: 
      NSDrawGroove(border_rect, rect);
      break;
    }

  // Draw title
  switch (title_position)
    {
    case NSNoTitle: 
      // Nothing to do
      break;
    case NSAboveTop: 
    case NSAtTop: 
    case NSBelowTop: 
    case NSAboveBottom: 
    case NSAtBottom: 
    case NSBelowBottom: 
      [cell setBackgroundColor: [window backgroundColor]];
      [cell drawWithFrame: title_rect inView: self];
    }
}

- (BOOL) isOpaque
{
  return YES;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeObject: cell];
  [aCoder encodeObject: content_view];
  [aCoder encodeSize: offsets];
  [aCoder encodeRect: border_rect];
  [aCoder encodeRect: title_rect];
  [aCoder encodeValueOfObjCType: @encode(NSBorderType) at: &border_type];
  [aCoder encodeValueOfObjCType: @encode(NSTitlePosition) at: &title_position];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  id aview;
  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(id) at: &cell];
  aview = [aDecoder decodeObject];
  [self setContentView: aview];
  offsets = [aDecoder decodeSize];
  border_rect = [aDecoder decodeRect];
  title_rect = [aDecoder decodeRect];
  [aDecoder decodeValueOfObjCType: @encode(NSBorderType)
			       at: &border_type];
  [aDecoder decodeValueOfObjCType: @encode(NSTitlePosition) 
			       at: &title_position];

  return self;
}

@end

@implementation NSBox (Private)

- (NSRect) calcSizesAllowingNegative: (BOOL)aFlag
{
  NSRect r = NSZeroRect;

  switch (title_position)
    {
    case NSNoTitle: 
      {
	NSSize borderSize = [NSCell sizeForBorderType: border_type];
	border_rect = bounds;
	title_rect = NSZeroRect;

	// Add the offsets to the border rect
	r.origin.x = offsets.width + borderSize.width;
	r.origin.y = offsets.height + borderSize.height;
	r.size.width = border_rect.size.width - (2 * offsets.width)
	  - (2 * borderSize.width);
	r.size.height = border_rect.size.height - (2 * offsets.height)
	  - (2 * borderSize.height);

	break;
      }
    case NSAboveTop: 
      {
	NSSize titleSize = [cell cellSize];
	NSSize borderSize = [NSCell sizeForBorderType: border_type];
	float c;

	// Add spacer around title
	titleSize.width += 1;
	titleSize.height += 1;

	// Adjust border rect by title cell
	border_rect = bounds;
	border_rect.size.height -= titleSize.height + borderSize.height;

	// Add the offsets to the border rect
	r.origin.x = border_rect.origin.x + offsets.width + borderSize.width;
	r.origin.y = border_rect.origin.y + offsets.height + borderSize.height;
	r.size.width = border_rect.size.width - (2 * offsets.width)
	  - (2 * borderSize.width);
	r.size.height = border_rect.size.height - (2 * offsets.height)
	  - (2 * borderSize.height);

	// center the title cell
	c = (bounds.size.width - titleSize.width) / 2;
	if (c < 0) c = 0;
	title_rect.origin.x = bounds.origin.x + c;
	title_rect.origin.y = bounds.origin.y + border_rect.size.height
	  + borderSize.height;
	title_rect.size = titleSize;

	break;
      }
    case NSBelowTop: 
      {
	NSSize titleSize = [cell cellSize];
	NSSize borderSize = [NSCell sizeForBorderType: border_type];
	float c;

	// Add spacer around title
	titleSize.width += 1;
	titleSize.height += 1;

	// Adjust border rect by title cell
	border_rect = bounds;

	// Add the offsets to the border rect
	r.origin.x = border_rect.origin.x + offsets.width + borderSize.width;
	r.origin.y = border_rect.origin.y + offsets.height + borderSize.height;
	r.size.width = border_rect.size.width - (2 * offsets.width)
	  - (2 * borderSize.width);
	r.size.height = border_rect.size.height - (2 * offsets.height)
	  - (2 * borderSize.height);

	// Adjust by the title size
	r.size.height -= titleSize.height + borderSize.height;

	// center the title cell
	c = (border_rect.size.width - titleSize.width) / 2;
	if (c < 0) c = 0;
	title_rect.origin.x = border_rect.origin.x + c;
	title_rect.origin.y = border_rect.origin.y + border_rect.size.height
	  - titleSize.height - borderSize.height;
	title_rect.size = titleSize;

	break;
      }
    case NSAtTop: 
      {
	NSSize titleSize = [cell cellSize];
	NSSize borderSize = [NSCell sizeForBorderType: border_type];
	float c;

	// Add spacer around title
	titleSize.width += 1;
	titleSize.height += 1;

	border_rect = bounds;

	// Adjust by the title size
	border_rect.size.height -= titleSize.height / 2;

	// Add the offsets to the border rect
	r.origin.x = border_rect.origin.x + offsets.width + borderSize.width;
	r.origin.y = border_rect.origin.y + offsets.height + borderSize.height;
	r.size.width = border_rect.size.width - (2 * offsets.width)
	  - (2 * borderSize.width);
	r.size.height = border_rect.size.height - (2 * offsets.height)
	  - (2 * borderSize.height);

	// Adjust by the title size
	r.size.height -= (titleSize.height / 2) + borderSize.height;

	// center the title cell
	c = (border_rect.size.width - titleSize.width) / 2;
	if (c < 0) c = 0;
	title_rect.origin.x = border_rect.origin.x + c;
	title_rect.origin.y = border_rect.origin.y + border_rect.size.height
	  - (titleSize.height / 2);
	title_rect.size = titleSize;

	break;
      }
    case NSAtBottom: 
      {
	NSSize titleSize = [cell cellSize];
	NSSize borderSize = [NSCell sizeForBorderType: border_type];
	float c;

	// Add spacer around title
	titleSize.width += 1;
	titleSize.height += 1;

	border_rect = bounds;

	// Adjust by the title size
	border_rect.origin.y += titleSize.height / 2;
	border_rect.size.height -= titleSize.height / 2;

	// Add the offsets to the border rect
	r.origin.x = border_rect.origin.x + offsets.width + borderSize.width;
	r.origin.y = border_rect.origin.y + offsets.height + borderSize.height;
	r.size.width = border_rect.size.width - (2 * offsets.width)
	  - (2 * borderSize.width);
	r.size.height = border_rect.size.height - (2 * offsets.height)
	  - (2 * borderSize.height);

	// Adjust by the title size
	r.origin.y += (titleSize.height / 2) + borderSize.height;
	r.size.height -= (titleSize.height / 2) + borderSize.height;

	// center the title cell
	c = (border_rect.size.width - titleSize.width) / 2;
	if (c < 0) c = 0;
	title_rect.origin.x = c;
	title_rect.origin.y = 0;
	title_rect.size = titleSize;

	break;
      }
    case NSBelowBottom: 
      {
	NSSize titleSize = [cell cellSize];
	NSSize borderSize = [NSCell sizeForBorderType: border_type];
	float c;

	// Add spacer around title
	titleSize.width += 1;
	titleSize.height += 1;

	// Adjust by the title
	border_rect = bounds;
	border_rect.origin.y += titleSize.height + borderSize.height;
	border_rect.size.height -= titleSize.height + borderSize.height;

	// Add the offsets to the border rect
	r.origin.x = border_rect.origin.x + offsets.width + borderSize.width;
	r.origin.y = border_rect.origin.y + offsets.height + borderSize.height;
	r.size.width = border_rect.size.width - (2 * offsets.width)
	  - (2 * borderSize.width);
	r.size.height = border_rect.size.height - (2 * offsets.height)
	  - (2 * borderSize.height);

	// center the title cell
	c = (border_rect.size.width - titleSize.width) / 2;
	if (c < 0) c = 0;
	title_rect.origin.x = c;
	title_rect.origin.y = 0;
	title_rect.size = titleSize;

	break;
      }
    case NSAboveBottom: 
      {
	NSSize titleSize = [cell cellSize];
	NSSize borderSize = [NSCell sizeForBorderType: border_type];
	float c;

	// Add spacer around title
	titleSize.width += 1;
	titleSize.height += 1;

	border_rect = bounds;

	// Add the offsets to the border rect
	r.origin.x = border_rect.origin.x + offsets.width + borderSize.width;
	r.origin.y = border_rect.origin.y + offsets.height + borderSize.height;
	r.size.width = border_rect.size.width - (2 * offsets.width)
	  - (2 * borderSize.width);
	r.size.height = border_rect.size.height - (2 * offsets.height)
	  - (2 * borderSize.height);

	// Adjust by the title size
	r.origin.y += titleSize.height + borderSize.height;
	r.size.height -= titleSize.height + borderSize.height;

	// center the title cell
	c = (border_rect.size.width - titleSize.width) / 2;
	if (c < 0) c = 0;
	title_rect.origin.x = border_rect.origin.x + c;
	title_rect.origin.y = border_rect.origin.y + borderSize.height;
	title_rect.size = titleSize;

	break;
      }
    }

  if (!aFlag)
    {
      if (r.size.width < 0)
	r.size.width = 0;
      if (r.size.height < 0)
	r.size.height = 0;
    }
  
  return r;
}

@end
