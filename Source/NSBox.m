/** <title>NSBox</title>

   <abstract>Simple box view that can display a border and title</abstract>

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
#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>
#include <Foundation/NSString.h>

#include <AppKit/NSBox.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSTextFieldCell.h>

#include <math.h>

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
	
  _cell = [[NSTextFieldCell alloc] initTextCell: @"Title"];
  [_cell setAlignment: NSCenterTextAlignment];
  [_cell setBordered: NO];
  [_cell setEditable: NO];
  [_cell setDrawsBackground: YES];
  //[_cell setBackgroundColor: [NSColor controlColor]];
  _offsets.width = 5;
  _offsets.height = 5;
  _border_rect = _bounds;
  _border_type = NSGrooveBorder;
  _title_position = NSAtTop;
  _title_rect = NSZeroRect;
  [self setAutoresizesSubviews: NO];
  _content_view = [NSView new];
  [super addSubview: _content_view];
  [_content_view setFrame: [self calcSizesAllowingNegative: NO]];
  RELEASE(_content_view);

  return self;
}

- (void) dealloc
{
  TEST_RELEASE(_cell);
  [super dealloc];
}

//
// Getting and Modifying the Border and Title 
//
- (NSRect) borderRect
{
  return _border_rect;
}

- (NSBorderType) borderType
{
  return _border_type;
}

- (void) setBorderType: (NSBorderType)aType
{
  if (_border_type != aType)
    {
      _border_type = aType;
      [_content_view setFrame: [self calcSizesAllowingNegative: NO]];
      [self setNeedsDisplay: YES];
    }
}

// TODO: implement the macosx behaviour for setTitle:
- (void) setTitle: (NSString *)aString
{
  [_cell setStringValue: aString];
  [_content_view setFrame: [self calcSizesAllowingNegative: NO]];
  [self setNeedsDisplay: YES];
}

- (void) setTitleWithMnemonic: (NSString *)aString
{
  [_cell setTitleWithMnemonic: aString];
  [_content_view setFrame: [self calcSizesAllowingNegative: NO]];
  [self setNeedsDisplay: YES];
}

- (void) setTitleFont: (NSFont *)fontObj
{
  [_cell setFont: fontObj];
  [_content_view setFrame: [self calcSizesAllowingNegative: NO]];
  [self setNeedsDisplay: YES];
}

- (void) setTitlePosition: (NSTitlePosition)aPosition
{
  if (_title_position != aPosition)
    {
      _title_position = aPosition;
      [_content_view setFrame: [self calcSizesAllowingNegative: NO]];
      [self setNeedsDisplay: YES];
    }
}

- (NSString*) title
{
  return [_cell stringValue];
}

- (id) titleCell
{
  return _cell;
}

- (NSFont*) titleFont
{
  return [_cell font];
}

- (NSTitlePosition) titlePosition
{
  return _title_position;
}

- (NSRect) titleRect
{
  return _title_rect;
}

//
// Setting and Placing the Content View 
//
- (id) contentView
{
  return _content_view;
}

- (NSSize) contentViewMargins
{
  return _offsets;
}

- (void) setContentView: (NSView*)aView
{
  if (aView)
    {
      [super replaceSubview: _content_view with: aView];
      _content_view = aView;
      [_content_view setFrame: [self calcSizesAllowingNegative: NO]];
    }
}

- (void) setContentViewMargins: (NSSize)offsetSize
{
  NSAssert(offsetSize.width >= 0 && offsetSize.height >= 0,
	@"illegal margins supplied");

  _offsets = offsetSize;
  [_content_view setFrame: [self calcSizesAllowingNegative: NO]];
  [self setNeedsDisplay: YES];

}

//
// Resizing the Box 
//
- (void) setFrame: (NSRect)frameRect
{
  [super setFrame: frameRect];
  [_content_view setFrame: [self calcSizesAllowingNegative: NO]];
}
- (void) setFrameSize: (NSSize)newSize
{
  [super setFrameSize: newSize];
  [_content_view setFrame: [self calcSizesAllowingNegative: NO]];
}
- (void) setFrameFromContentFrame: (NSRect)contentFrame
{
  // First calc the sizes to see how much we are off by
  NSRect r = [self calcSizesAllowingNegative: YES];
  NSRect f = _frame;

  NSAssert(contentFrame.size.width >= 0 && contentFrame.size.height >= 0,
	@"illegal content frame supplied");

  if (_super_view)
    r = [_super_view convertRect: r fromView: self];
  
  // Add the difference to the frame
  f.size.width = f.size.width + (contentFrame.size.width - r.size.width);
  f.size.height = f.size.height + (contentFrame.size.height - r.size.height);
  f.origin.x = f.origin.x + (contentFrame.origin.x - r.origin.x);
  f.origin.y = f.origin.y + (contentFrame.origin.y - r.origin.y);

  [self setFrame: f];
  [_content_view setFrame: [self calcSizesAllowingNegative: NO]];  
}

-(NSSize) minimumSize
{
  NSRect r;
  NSSize borderSize = _sizeForBorderType (_border_type);

  if ([_content_view respondsToSelector: @selector(minimumSize)])
    {
      r.size = [_content_view minimumSize];
    }
  else
    {   
      NSArray *subviewArray = [_content_view subviews];
      if ([subviewArray count])
	{
	  id o, e = [subviewArray objectEnumerator];
	  r = [[e nextObject] frame];
	  // Loop through subviews and calculate rect to encompass all
	  while ((o = [e nextObject]))
	    {
	      r = NSUnionRect(r, [o frame]);
	    }
	}
      else // _content_view has no subviews
	{
	  r = NSZeroRect;
	}
    }

  r.size = [self convertSize: r.size fromView: _content_view];
  r.size.width += (2 * _offsets.width) + (2 * borderSize.width);
  r.size.height += (2 * _offsets.height) + (2 * borderSize.height);
  return r.size;
}

- (void) sizeToFit
{
  NSRect f;

  if ([_content_view respondsToSelector: @selector(sizeToFit)])
    {
      [_content_view sizeToFit];
    }
  else // _content_view !respondsToSelector: sizeToFit
    {   
      NSArray *subviewArray = [_content_view subviews];
      if ([subviewArray count])
	{
	  id o, e = [subviewArray objectEnumerator];
	  NSRect r = [[e nextObject] frame];
	  // Loop through subviews and calculate rect to encompass all
	  while ((o = [e nextObject]))
	    {
	      r = NSUnionRect(r, [o frame]);
	    }
	  [_content_view setBoundsOrigin: r.origin];
	  r.size = [self convertSize: r.size fromView: _content_view];
	  [_content_view setAutoresizesSubviews: NO];
	  [_content_view setFrameSize: r.size];
	  [_content_view setAutoresizesSubviews: YES];
	}
      else // _content_view has no subviews
	{
  	  [_content_view setFrame: [self calcSizesAllowingNegative: NO]];
	}
    }

  f = [_content_view frame];

  // The box width should be enough to display the title
  if (_title_position != NSNoTitle)
    {
      NSSize titleSize = [_cell cellSize];
      titleSize.width += 6;
      if (f.size.width < titleSize.width)
	f.size.width = titleSize.width;
    }
  
  if (_super_view != nil)
    [self setFrameFromContentFrame: [self convertRect: f toView: _super_view]];
  else // _super_view == nil
    [self setFrameFromContentFrame: f]; 
}

- (void) resizeWithOldSuperviewSize: (NSSize)oldSize
{
  [super resizeWithOldSuperviewSize: oldSize];
  [_content_view setFrame: [self calcSizesAllowingNegative: NO]];
}

//
// Managing the NSView Hierarchy 
//
- (void) addSubview: (NSView*)aView
{
  [_content_view addSubview: aView];
}

- (void) addSubview: (NSView*)aView
         positioned: (NSWindowOrderingMode)place
         relativeTo: (NSView*)otherView
{
  [_content_view addSubview: aView positioned: place relativeTo: otherView];
}

- (void) replaceSubview: (NSView *)aView with: (NSView*) newView
{
  [_content_view replaceSubview: aView with: newView];
}

//
// Displaying
//
- (void) drawRect: (NSRect)rect
{
  NSColor *color = [_window backgroundColor];
  rect = NSIntersectionRect(_bounds, rect);
  // Fill inside
  [color set];
  NSRectFill(rect);

  // Draw border
  switch (_border_type)
    {
    case NSNoBorder: 
      break;
    case NSLineBorder: 
      [[NSColor controlDarkShadowColor] set];
      NSFrameRect(_border_rect);
      break;
    case NSBezelBorder: 
      NSDrawGrayBezel(_border_rect, rect);
      break;
    case NSGrooveBorder: 
      NSDrawGroove(_border_rect, rect);
      break;
    }

  // Draw title
  if (_title_position != NSNoTitle)
    {
      [_cell setBackgroundColor: color];
      [_cell drawWithFrame: _title_rect inView: self];
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

  [aCoder encodeObject: _cell];
  [aCoder encodeSize: _offsets];
  [aCoder encodeValueOfObjCType: @encode(NSBorderType) at: &_border_type];
  [aCoder encodeValueOfObjCType: @encode(NSTitlePosition) at: &_title_position];
  // NB: the content view is our (only) subview, so it is already 
  // encoded by NSView.
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(id) at: &_cell];
  _offsets = [aDecoder decodeSize];
  [aDecoder decodeValueOfObjCType: @encode(NSBorderType)
			       at: &_border_type];
  [aDecoder decodeValueOfObjCType: @encode(NSTitlePosition) 
			       at: &_title_position];

  // The content view is our only sub_view
  if ([_sub_views count] == 0)
    {
  
      NSDebugLLog(@"NSBox", @"NSBox: decoding without content view\n");
      // No content view
      _content_view = nil;
      [self calcSizesAllowingNegative: NO];
    }
  else 
    {
      if ([_sub_views count] != 1)
	{
	  NSLog (@"Warning: Encoded NSBox with more than one content view!");
	}
      _content_view = [_sub_views objectAtIndex: 0];
      // The following also computes _title_rect and _border_rect.
      [_content_view setFrame: [self calcSizesAllowingNegative: NO]];
    }
  return self;
}

@end

@implementation NSBox (Private)

- (NSRect) calcSizesAllowingNegative: (BOOL)aFlag
{
  NSRect r = NSZeroRect;

  switch (_title_position)
    {
    case NSNoTitle: 
      {
	NSSize borderSize = _sizeForBorderType (_border_type);
	_border_rect = _bounds;
	_title_rect = NSZeroRect;

	// Add the offsets to the border rect
	r.origin.x = _offsets.width + borderSize.width;
	r.origin.y = _offsets.height + borderSize.height;
	r.size.width = _border_rect.size.width - (2 * _offsets.width)
	  - (2 * borderSize.width);
	r.size.height = _border_rect.size.height - (2 * _offsets.height)
	  - (2 * borderSize.height);

	break;
      }
    case NSAboveTop: 
      {
	NSSize titleSize = [_cell cellSize];
	NSSize borderSize = _sizeForBorderType (_border_type);
	float c;

	// Add spacer around title
	titleSize.width += 6;
	titleSize.height += 2;

	// Adjust border rect by title cell
	_border_rect = _bounds;
	_border_rect.size.height -= titleSize.height + borderSize.height;

	// Add the offsets to the border rect
	r.origin.x = _border_rect.origin.x + _offsets.width + borderSize.width;
	r.origin.y = _border_rect.origin.y + _offsets.height + borderSize.height;
	r.size.width = _border_rect.size.width - (2 * _offsets.width)
	  - (2 * borderSize.width);
	r.size.height = _border_rect.size.height - (2 * _offsets.height)
	  - (2 * borderSize.height);

	// center the title cell
	c = (_bounds.size.width - titleSize.width) / 2;
	if (c < 0) c = 0;
	_title_rect.origin.x = _bounds.origin.x + c;
	_title_rect.origin.y = _bounds.origin.y + _border_rect.size.height
	  + borderSize.height;
	_title_rect.size = titleSize;

	break;
      }
    case NSBelowTop: 
      {
	NSSize titleSize = [_cell cellSize];
	NSSize borderSize = _sizeForBorderType (_border_type);
	float c;

	// Add spacer around title
	titleSize.width += 6;
	titleSize.height += 2;

	// Adjust border rect by title cell
	_border_rect = _bounds;

	// Add the offsets to the border rect
	r.origin.x = _border_rect.origin.x + _offsets.width + borderSize.width;
	r.origin.y = _border_rect.origin.y + _offsets.height + borderSize.height;
	r.size.width = _border_rect.size.width - (2 * _offsets.width)
	  - (2 * borderSize.width);
	r.size.height = _border_rect.size.height - (2 * _offsets.height)
	  - (2 * borderSize.height);

	// Adjust by the title size
	r.size.height -= titleSize.height + borderSize.height;

	// center the title cell
	c = (_border_rect.size.width - titleSize.width) / 2;
	if (c < 0) c = 0;
	_title_rect.origin.x = _border_rect.origin.x + c;
	_title_rect.origin.y = _border_rect.origin.y + _border_rect.size.height
	  - titleSize.height - borderSize.height;
	_title_rect.size = titleSize;

	break;
      }
    case NSAtTop: 
      {
	NSSize titleSize = [_cell cellSize];
	NSSize borderSize = _sizeForBorderType (_border_type);
	float c;
	float topMargin;
	float topOffset;

	// Add spacer around title
	titleSize.width += 6;
	titleSize.height += 2;

	_border_rect = _bounds;

	topMargin = ceil(titleSize.height / 2);
	topOffset = titleSize.height - topMargin;
	
	// Adjust by the title size
	_border_rect.size.height -= topMargin;
	
	// Add the offsets to the border rect
	r.origin.x = _border_rect.origin.x + _offsets.width + borderSize.width;
	r.size.width = _border_rect.size.width - (2 * _offsets.width)
	  - (2 * borderSize.width);
	
	if (topOffset > _offsets.height)
	  {
	    r.origin.y = _border_rect.origin.y + _offsets.height + borderSize.height;
	    r.size.height = _border_rect.size.height - _offsets.height
	      - (2 * borderSize.height) - topOffset;
	  }
	else
	  {
	    r.origin.y = _border_rect.origin.y + _offsets.height + borderSize.height;
	    r.size.height = _border_rect.size.height - (2 * _offsets.height)
	      - (2 * borderSize.height);
	  }

	// Adjust by the title size
	//	r.size.height -= titleSize.height + borderSize.height;

	// center the title cell
	c = (_border_rect.size.width - titleSize.width) / 2;
	if (c < 0) c = 0;
	_title_rect.origin.x = _border_rect.origin.x + c;
	_title_rect.origin.y = _border_rect.origin.y + _border_rect.size.height
	  - topMargin;
	_title_rect.size = titleSize;

	break;
      }
    case NSAtBottom: 
      {
	NSSize titleSize = [_cell cellSize];
	NSSize borderSize = _sizeForBorderType (_border_type);
	float c;
	float bottomMargin;
	float bottomOffset;

	// Add spacer around title
	titleSize.width += 6;
	titleSize.height += 2;

	_border_rect = _bounds;

	bottomMargin = ceil(titleSize.height / 2);
	bottomOffset = titleSize.height - bottomMargin;

	// Adjust by the title size
	_border_rect.origin.y += bottomMargin;
	_border_rect.size.height -= bottomMargin;

	// Add the offsets to the border rect
	r.origin.x = _border_rect.origin.x + _offsets.width + borderSize.width;
	r.size.width = _border_rect.size.width - (2 * _offsets.width)
	  - (2 * borderSize.width);

	if (bottomOffset > _offsets.height)
	  {
	    r.origin.y = _border_rect.origin.y + bottomOffset + borderSize.height;
	    r.size.height = _border_rect.size.height - _offsets.height
	      - bottomOffset
	      - (2 * borderSize.height);
	  }
	else
	  {
	    r.origin.y = _border_rect.origin.y + _offsets.height + borderSize.height;
	    r.size.height = _border_rect.size.height - (2 * _offsets.height)
	      - (2 * borderSize.height);
	  }

	// Adjust by the title size
	/*
	r.origin.y += (titleSize.height / 2) + borderSize.height;
	r.size.height -= (titleSize.height / 2) + borderSize.height;
	*/
	// center the title cell
	c = (_border_rect.size.width - titleSize.width) / 2;
	if (c < 0) c = 0;
	_title_rect.origin.x = c;
	_title_rect.origin.y = 0;
	_title_rect.size = titleSize;

	break;
      }
    case NSBelowBottom: 
      {
	NSSize titleSize = [_cell cellSize];
	NSSize borderSize = _sizeForBorderType (_border_type);
	float c;

	// Add spacer around title
	titleSize.width += 6;
	titleSize.height += 2;

	// Adjust by the title
	_border_rect = _bounds;
	_border_rect.origin.y += titleSize.height + borderSize.height;
	_border_rect.size.height -= titleSize.height + borderSize.height;

	// Add the offsets to the border rect
	r.origin.x = _border_rect.origin.x + _offsets.width + borderSize.width;
	r.origin.y = _border_rect.origin.y + _offsets.height + borderSize.height;
	r.size.width = _border_rect.size.width - (2 * _offsets.width)
	  - (2 * borderSize.width);
	r.size.height = _border_rect.size.height - (2 * _offsets.height)
	  - (2 * borderSize.height);

	// center the title cell
	c = (_border_rect.size.width - titleSize.width) / 2;
	if (c < 0) c = 0;
	_title_rect.origin.x = c;
	_title_rect.origin.y = 0;
	_title_rect.size = titleSize;

	break;
      }
    case NSAboveBottom: 
      {
	NSSize titleSize = [_cell cellSize];
	NSSize borderSize = _sizeForBorderType (_border_type);
	float c;

	// Add spacer around title
	titleSize.width += 6;
	titleSize.height += 2;

	_border_rect = _bounds;

	// Add the offsets to the border rect
	r.origin.x = _border_rect.origin.x + _offsets.width + borderSize.width;
	r.origin.y = _border_rect.origin.y + _offsets.height + borderSize.height;
	r.size.width = _border_rect.size.width - (2 * _offsets.width)
	  - (2 * borderSize.width);
	r.size.height = _border_rect.size.height - (2 * _offsets.height)
	  - (2 * borderSize.height);

	// Adjust by the title size
	r.origin.y += titleSize.height + borderSize.height;
	r.size.height -= titleSize.height + borderSize.height;

	// center the title cell
	c = (_border_rect.size.width - titleSize.width) / 2;
	if (c < 0) c = 0;
	_title_rect.origin.x = _border_rect.origin.x + c;
	_title_rect.origin.y = _border_rect.origin.y + borderSize.height;
	_title_rect.size = titleSize;

	break;
      }
    }

  if (!aFlag)
    {
      if (r.size.width < 0)
	{
	  r.size.width = 0;
	}
      if (r.size.height < 0)
	{
	  r.size.height = 0;
	}
    }
  
  return r;
}

@end
