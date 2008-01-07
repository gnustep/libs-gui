/* NSSegmentedCell.m
 *
 * Copyright (C) 2007 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2007
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 
 * USA.
 */

#include <Foundation/NSArray.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSException.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSSegmentedCell.h>

@interface NSSegmentItem : NSObject
{
  BOOL _selected;
  BOOL _enabled;
  int _tag;
  float _width;
  NSMenu *_menu;
  NSString *_label;
  NSString *_tool_tip;
  NSImage *_image;
}

- (BOOL) isSelected;
- (void) setSelected: (BOOL)flag;
- (BOOL) isSelected;
- (void) setSelected: (BOOL)flag;
- (NSMenu *) menu;
- (void) setMenu: (NSMenu *)menu;
- (NSString *) label;
- (void) setLabel: (NSString *)label;
- (NSString *) toolTip;
- (void) setToolTip: (NSString *)toolTip;
- (NSImage *) image;
- (void) setImage: (NSImage *)image;
- (int) tag;
- (void) setTag: (int)tag;
- (float) width;
- (void) setWidth: (float)width;
@end

@implementation NSSegmentItem

- (id) init
{
  self = [super init];
  
  return self;
}

- (void) dealloc
{
  TEST_RELEASE(_label);
  TEST_RELEASE(_image);
  TEST_RELEASE(_menu);
  TEST_RELEASE(_tool_tip);

  [super dealloc];
}

- (BOOL) isSelected
{
  return _selected;
}

- (void) setSelected: (BOOL)flag
{
  _selected = flag;
}

- (BOOL) isEnabled
{
  return _enabled;
}

- (void) setEnabled: (BOOL)flag
{
  _enabled = flag;
}

- (NSMenu *) menu
{
  return _menu;
}

- (void) setMenu: (NSMenu *)menu
{
  ASSIGN(_menu, menu);
}

- (NSString *) label
{
  return _label;
}

- (void) setLabel: (NSString *)label
{
  ASSIGN(_label, label);
}

- (NSString *) toolTip
{
  return _tool_tip;
}

- (void) setToolTip: (NSString *)toolTip
{
  ASSIGN(_tool_tip, toolTip);
}

- (NSImage *) image
{
  return _image;
}

- (void) setImage: (NSImage *)image
{
  ASSIGN(_image, image);
}

- (int) tag
{
  return _tag;
}

- (void) setTag: (int)tag
{
  _tag = tag;
}

- (float) width
{
  return _width;
}

- (void) setWidth: (float)width
{
  _width = width;
}

- (void) encodeWithCoder:(NSCoder *) aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
      if (_label != nil)
        [aCoder encodeObject: _label forKey: @"NSSegmentItemLabel"];
      if (_image != nil)
        [aCoder encodeObject: _image forKey: @"NSSegmentItemImage"];
      if (_menu != nil)
        [aCoder encodeObject: _menu forKey: @"NSSegmentItemMenu"];
      if (_enabled)
        [aCoder encodeBool: YES forKey: @"NSSegmentItemEnabled"];
      else
        [aCoder encodeBool: YES forKey: @"NSSegmentItemDisabled"];
      if (_selected)
        [aCoder encodeBool: YES forKey: @"NSSegmentItemSelected"];
      if (_width != 0.0)
        [aCoder encodeFloat: _width forKey: @"NSSegmentItemWidth"];
      if (_tag != 0)
        [aCoder encodeInt: _tag forKey: @"NSSegmentItemTag"];
    }
  else
    {
      // FIXME
    }
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
	if ([aDecoder allowsKeyedCoding])
    {
      if ([aDecoder containsValueForKey: @"NSSegmentItemLabel"])
        [self setLabel: [aDecoder decodeObjectForKey: @"NSSegmentItemLabel"]];
      if ([aDecoder containsValueForKey: @"NSSegmentItemImage"])
        [self setImage: [aDecoder decodeObjectForKey: @"NSSegmentItemImage"]];
      if ([aDecoder containsValueForKey: @"NSSegmentItemMenu"])
        [self setMenu: [aDecoder decodeObjectForKey: @"NSSegmentItemMenu"]];
      if ([aDecoder containsValueForKey: @"NSSegmentItemEnabled"])
          _enabled = [aDecoder decodeBoolForKey: @"NSSegmentItemEnabled"];
      else if ([aDecoder containsValueForKey: @"NSSegmentItemDisabled"])
          _enabled = ![aDecoder decodeBoolForKey: @"NSSegmentItemDisabled"];
      else
          _enabled = YES;
      if ([aDecoder containsValueForKey: @"NSSegmentItemSelected"])
        _selected = [aDecoder decodeBoolForKey: @"NSSegmentItemSelected"];
      if ([aDecoder containsValueForKey: @"NSSegmentItemWidth"])
        _width = [aDecoder decodeFloatForKey: @"NSSegmentItemWidth"];
      if ([aDecoder containsValueForKey: @"NSSegmentItemTag"])
          _tag = [aDecoder decodeIntForKey: @"NSSegmentItemTag"];
    }
  else
    {
      // FIXME
    }

  return self;
}

@end

@implementation NSSegmentedCell 

- (id) initImageCell: (NSImage*)anImage
{
  self = [super initImageCell: anImage];
  if (!self)
    return nil;

  _items = [[NSMutableArray alloc] initWithCapacity: 2];
  _selected_segment = -1;

  return self;
}

- (id) initTextCell: (NSString*)aString
{
  self = [super initTextCell: aString];
  if (!self)
    return nil;

  _items = [[NSMutableArray alloc] initWithCapacity: 2];
  _selected_segment = -1;

  return self;
}

- (id) copyWithZone: (NSZone *)zone;
{
  NSSegmentedCell *c = (NSSegmentedCell *)[super copyWithZone: zone];

	if (c)
		{
      // FIXME: Need a deep copy here
      c->_items = [_items copyWithZone: zone];
    }

  return c;
}

- (void) dealloc
{
  TEST_RELEASE(_items);

  [super dealloc];
}

// Specifying number of segments...
- (void) setSegmentCount: (int)count
{
  int size;

  if ((count < 0) || (count > 2048))
    {
      [NSException raise: NSRangeException
                   format: @"Illegal segment count."];
    }

  size = [_items count];
	if (count < size)
		[_items removeObjectsInRange: NSMakeRange(count, size - count)];

	while (count-- > size)
		{
      NSSegmentItem *item = [[NSSegmentItem alloc] init];
      [_items addObject: item];
      RELEASE(item);
		}

}

- (int) segmentCount
{
  return [_items count];
}

// Specifying selected segment...
- (void) setSelectedSegment: (int)segment
{
  [self setSelected: YES forSegment: segment];
}

- (void) setSelected: (BOOL)flag forSegment: (int)seg
{
  NSSegmentItem *segment = [_items objectAtIndex: seg];

  [segment setSelected: flag];
  if (flag)
    _selected_segment = seg;
  else if (seg == _selected_segment)
    _selected_segment = -1;
}

- (int) selectedSegment
{
  return _selected_segment;
}

- (void) selectSegmentWithTag: (int)tag
{
  NSEnumerator *en = [_items objectEnumerator];
  id o = nil;
  int segment = 0;

  while ((o = [en nextObject]) != nil)
    {
      if([o tag] == tag)
        {
          break;
        }
      segment++;
    }
  
  [self setSelected: YES forSegment: segment];
}

- (void) makeNextSegmentKey
{
  int next;

  if (_selected_segment < [_items count])
    {
      next = _selected_segment + 1;
    }
  else
    {
      next = 0;
    }
  [self setSelected: NO forSegment: _selected_segment];
  [self setSelected: YES forSegment: next];
}

- (void) makePreviousSegmentKey
{
  int prev;

  if (_selected_segment > 0)
    {
      prev = _selected_segment - 1;
    }
  else
    {
      prev = 0;
    }
  [self setSelected: NO forSegment: _selected_segment];
  [self setSelected: YES forSegment: prev];
}


// Specify tracking mode...
- (void) setTrackingMode: (NSSegmentSwitchTracking)mode
{
  _segmentCellFlags._tracking_mode = mode;
}

- (NSSegmentSwitchTracking) trackingMode
{
  return _segmentCellFlags._tracking_mode;
}


// Working with individual segments...
- (void) setWidth: (float)width forSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  [segment setWidth: width];
}

- (float) widthForSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  return [segment width];
}

- (void) setImage: (NSImage *)image forSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  [segment setImage: image];
}

- (NSImage *) imageForSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  return [segment image];
}

- (void) setLabel: (NSString *)label forSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  [segment setLabel: label];
}

- (NSString *) labelForSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  return [segment label];
}

- (BOOL) isSelectedForSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  return [segment isSelected];
}

- (void) setEnabled: (BOOL)flag forSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  return [segment setEnabled: flag];
}

- (BOOL) isEnabledForSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  return [segment isEnabled];
}

- (void) setMenu: (NSMenu *)menu forSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  return [segment setMenu: menu];
}

- (NSMenu *) menuForSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  return [segment menu];
}

- (void) setToolTip: (NSString *) toolTip forSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  return [segment setToolTip: toolTip];
}

- (NSString *) toolTipForSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  return [segment toolTip];
}

- (void) setTag: (int)tag forSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  return [segment setTag: tag];
}

- (int) tagForSegment: (int)seg
{
  id segment = [_items objectAtIndex: seg];
  return [segment tag];
}

// Drawing custom content
- (void) drawSegment: (int)seg 
             inFrame: (NSRect)frame 
            withView: (NSView *)view
{
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame 
                        inView: (NSView*)controlView
{
  int i;
  unsigned int count = [_items count];
	NSRect frame = cellFrame;

	for (i = 0; i < count;i++)
		{
      frame.size.width = [[_items objectAtIndex: i] width];
      [self drawSegment: i inFrame: frame withView: controlView];
      frame.origin.x += frame.size.width;
      if (frame.origin.x >= cellFrame.size.width)
        break;
		}
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeObject: _items forKey: @"NSSegmentImages"];
      if (_selected_segment != -1)
        [aCoder encodeInt: _selected_segment forKey: @"NSSelectedSegment"];
    }
  else
    {
      // FIXME
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];
  if (!self)
    return nil;

  if ([aDecoder allowsKeyedCoding])
    {
      if ([aDecoder containsValueForKey: @"NSSegmentImages"])
        ASSIGN(_items, [aDecoder decodeObjectForKey: @"NSSegmentImages"]);
      if ([aDecoder containsValueForKey: @"NSSelectedSegment"])
        _selected_segment = [aDecoder decodeIntForKey: @"NSSelectedSegment"]; 
    }
  else
    {
      // FIXME
    }
  return self;
}

@end
