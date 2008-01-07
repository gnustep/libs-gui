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


#include <AppKit/NSSegmentedCell.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSImage.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSEnumerator.h>

@interface NSSegmentItem : NSObject
{
  BOOL _selected;
  BOOL _enabled;
  BOOL _is_key;
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
- (BOOL) isKey;
- (void) setKey: (BOOL)flag;
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

- (BOOL) isKey
{
  return _is_key;
}

- (void) setKey: (BOOL)flag
{
  _is_key = flag;
}

- (NSMenu *) menu
{
  return _menu;
}

- (void) setMenu: (NSMenu *)menu
{
  _menu = menu;
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
@end

@implementation NSSegmentedCell 

// Specifying number of segments...
- (void) setSegmentCount: (int) count
{
}

- (int) segmentCount
{
  return [_items count];
}

// Specifying selected segment...
- (void) setSelectedSegment: (int) segment
{
  _selected_segment = segment;
}

- (void) setSelected: (BOOL)flag forSegment: (int)seg
{
  NSSegmentItem *segment = [_items objectAtIndex: seg];
  [segment setSelected: flag];
}

- (int) selectedSegment
{
  return _selected_segment;
}

- (void) selectSegmentWithTag: (int) tag
{
  NSEnumerator *en = [_items objectEnumerator];
  id o = nil;
  int segment = 0;

  while((o = [en nextObject]) != nil)
    {
      if([o tag] == tag)
	{
	  break;
	}
      segment++;
    }
  
  [o setSelected: YES];
  _selected_segment = segment;
}

- (void) makeNextSegmentKey
{
  if(_selected_segment < [_items count])
    {
      _selected_segment++;
    }
}

- (void) makePreviousSegmentKey
{
  if(_selected_segment > 0)
    {
      _selected_segment--;
    }
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
@end
