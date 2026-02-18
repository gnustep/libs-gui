/* NSSegmentedControl.m
 *
 * Copyright (C) 2007 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2007
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the Lesser GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * Lesser GNU General Public License for more details.
 * 
 * You should have received a copy of the Lesser GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110 
 * USA.
 */

#import "AppKit/NSControl.h"
#import "AppKit/NSEvent.h"
#import "AppKit/NSSegmentedControl.h"
#import "AppKit/NSSegmentedCell.h"
#import "AppKit/NSAccessibility.h"
#import "AppKit/NSAccessibilityProtocols.h"

static Class segmentedControlCellClass;

@implementation NSSegmentedControl 

+ (void) initialize
{
  if(self == [NSSegmentedControl class])
    {
      [self setVersion: 1];
      segmentedControlCellClass = [NSSegmentedCell class];
    }
}

+ (Class) cellClass
{
  return segmentedControlCellClass;
}

// Specifying number of segments...
- (void) setSegmentCount: (NSInteger) count
{
  [_cell setSegmentCount: count];
}

- (NSInteger) segmentCount
{
  return [_cell segmentCount];
} 

// Specifying selected segment...
- (void) setSelectedSegment: (NSInteger) segment
{
  [_cell setSelectedSegment: segment];
}

- (NSInteger) selectedSegment
{
  return [_cell selectedSegment];
}

- (void) selectSegmentWithTag: (NSInteger) tag
{
  [_cell selectSegmentWithTag: tag];
}

// Working with individual segments...
- (void) setWidth: (CGFloat)width forSegment: (NSInteger)segment
{
  [_cell setWidth: width forSegment: segment];
}

- (CGFloat) widthForSegment: (NSInteger)segment
{
  return [_cell widthForSegment: segment];
}

- (void) setImage: (NSImage *)image forSegment: (NSInteger)segment
{
  [_cell setImage: image forSegment: segment];
}

- (NSImage *) imageForSegment: (NSInteger)segment
{
  return [_cell imageForSegment: segment];
}

- (void) setLabel: (NSString *)label forSegment: (NSInteger)segment
{
  [_cell setLabel: label forSegment: segment];
}

- (NSString *) labelForSegment: (NSInteger)segment
{
  return [_cell labelForSegment: segment];
}

- (void) setMenu: (NSMenu *)menu forSegment: (NSInteger)segment
{
  [_cell setMenu: menu forSegment: segment];
}

- (NSMenu *) menuForSegment: (NSInteger)segment
{
  return [_cell menuForSegment: segment];
}

- (void) setSelected: (BOOL)flag forSegment: (NSInteger)segment
{
  [_cell setSelected: flag forSegment: segment];
}

- (BOOL) isSelectedForSegment: (NSInteger)segment
{
  return [_cell isSelectedForSegment: segment];
}

- (void) setEnabled: (BOOL)flag forSegment: (NSInteger)segment
{
  [_cell setEnabled: flag forSegment: segment];
}

- (BOOL) isEnabledForSegment: (NSInteger)segment
{
  return [_cell isEnabledForSegment: segment];
}

- (void) setSegmentStyle: (NSSegmentStyle)style
{
  [_cell setSegmentStyle: style];
}

- (NSSegmentStyle) segmentStyle
{
  return [_cell segmentStyle];
}

/*
- (void) mouseDown: (NSEvent *)event
{
  NSPoint location = [self convertPoint: [event locationInWindow] 
                           fromView: nil];

  [super mouseDown: event];
  [_cell _detectHit: location];
  NSLog(@"%@",NSStringFromPoint(location));
}
*/
@end
// MARK: - NSSegmentedControl (NSAccessibilityElement)

@implementation NSSegmentedControl (NSAccessibilityElement)

// MARK: - NSAccessibilityElement Protocol Implementation

- (NSString *) accessibilityRole
{
  return NSAccessibilityGroupRole; // Segmented control acts as a group
}

- (NSString *) accessibilitySubrole
{
  return @"AXSegmentedControl"; // Custom subrole for segmented control
}

- (NSString *) accessibilityLabel
{
  return @"Segmented Control";
}

- (NSString *) accessibilityTitle
{
  return @"Segmented Control";
}

- (id) accessibilityValue
{
  // Return the selected segment index
  return [NSNumber numberWithInteger: [self selectedSegment]];
}

- (NSString *) accessibilityHelp
{
  NSString *toolTip = [self toolTip];
  if (toolTip && [toolTip length] > 0)
    {
      return toolTip;
    }
  
  return @"Segmented control with multiple options";
}

- (BOOL) isAccessibilityEnabled
{
  return [self isEnabled];
}

- (NSArray *) accessibilityChildren
{
  // Each segment should be represented as a child element
  NSMutableArray *children = [NSMutableArray array];
  NSInteger segmentCount = [self segmentCount];
  
  for (NSInteger i = 0; i < segmentCount; i++)
    {
      // Create a pseudo-element for each segment
      NSString *segmentLabel = [self labelForSegment: i];
      if (!segmentLabel || [segmentLabel length] == 0)
        {
          segmentLabel = [NSString stringWithFormat: @"Segment %ld", (long)i];
        }
      
      // In a full implementation, we would create actual accessibility element objects
      // For now, we'll return segment information as a dictionary
      NSDictionary *segmentInfo = @{
        @"label": segmentLabel,
        @"index": @(i),
        @"selected": @([self selectedSegment] == i),
        @"enabled": @([self isEnabledForSegment: i])
      };
      
      [children addObject: segmentInfo];
    }
  
  return children;
}

- (NSArray *) accessibilitySelectedChildren
{
  NSInteger selected = [self selectedSegment];
  if (selected >= 0)
    {
      NSArray *children = [self accessibilityChildren];
      if (selected < [children count])
        {
          return @[children[selected]];
        }
    }
  
  return nil;
}

- (NSArray *) accessibilityVisibleChildren
{
  return [self accessibilityChildren]; // All segments are visible
}

- (id) accessibilityWindow
{
  return [self window];
}

- (id) accessibilityTopLevelUIElement
{
  NSWindow *window = [self window];
  return window ? [window contentView] : nil;
}

- (NSPoint) accessibilityActivationPoint
{
  NSRect frame = [self frame];
  if ([self window] != nil)
    {
      frame = [[self superview] convertRect: frame toView: nil];
    }
  
  if (NSEqualRects(frame, NSZeroRect))
    {
      return NSZeroPoint;
    }
  
  return NSMakePoint(NSMidX(frame), NSMidY(frame));
}

- (NSString *) accessibilityURL
{
  return nil;
}

- (NSNumber *) accessibilityIndex
{
  id parent = [self superview];
  if (parent && [parent respondsToSelector: @selector(subviews)])
    {
      NSArray *siblings = [parent subviews];
      NSUInteger index = [siblings indexOfObject: self];
      if (index != NSNotFound)
        {
          return [NSNumber numberWithUnsignedInteger: index];
        }
    }
  return [NSNumber numberWithInteger: 0];
}

// MARK: - Additional Methods

- (NSArray *) accessibilityCustomRotors
{
  return nil;
}

- (BOOL) accessibilityPerformEscape
{
  return NO;
}

- (NSArray *) accessibilityCustomActions
{
  // Return nil since NSAccessibilityCustomAction may not be available
  // in all GNUstep versions. Segments can still be selected via normal interaction.
  return nil;
}

- (void) setAccessibilityElement: (BOOL) isElement
{
  // Segmented controls are always accessibility elements
}

- (void) setAccessibilityFrame: (NSRect) frame
{
  // Frame is determined by the actual view frame
}

- (void) setAccessibilityParent: (id) parent
{
  // Parent relationship is managed by the view hierarchy
}

- (void) setAccessibilityFocused: (BOOL) focused
{
  if (focused)
    {
      [[self window] makeFirstResponder: self];
    }
  else
    {
      if ([[self window] firstResponder] == self)
        {
          [[self window] makeFirstResponder: nil];
        }
    }
}

@end