/* 
   NSControl.m

   The abstract control class

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

#include <AppKit/NSControl.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSCell.h>

//
// Class variables
//
static id MB_NSCONTROL_CELL_CLASS = nil;

// NSControl notifications
NSString *NSControlTextDidBeginEditingNotification = @"NSControlTextDidBeginEditingNotification";
NSString *NSControlTextDidEndEditingNotification = @"NSControlTextDidEndEditingNotification";
NSString *NSControlTextDidChangeNotification = @"NSControlTextDidChangeNotification";

@implementation NSControl

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSControl class])
    {
      NSDebugLog(@"Initialize NSControl class\n");

      // Initial version
      [self setVersion:1];

      // Set cell class
      [self setCellClass:[NSCell class]];
    }
}

//
// Setting the Control's Cell 
//
+ (Class)cellClass
{
  return MB_NSCONTROL_CELL_CLASS;
}

+ (void)setCellClass:(Class)factoryId
{
  MB_NSCONTROL_CELL_CLASS = factoryId;
}

//
// Instance methods
//
//
// Initializing an NSControl Object
//
- (id)initWithFrame:(NSRect)frameRect
{
  [super initWithFrame:frameRect];

  // create our cell
  [self setCell:[[MB_NSCONTROL_CELL_CLASS new] autorelease]];

  tag = 0;

  return self;
}

- (void)dealloc
{
    // release our cell
    [cell release];

    [super dealloc];
}

//
// Creating copies
//
- copyWithZone:(NSZone *)zone
{
  id c;
  c = NSAllocateObject (isa, 0, zone);

  NSLog(@"NSControl: copyWithZone\n");

  // make sure the new copy also has a new copy of the cell
  [c setCell: [[cell copy] autorelease]];
  return c;
}

//
// Setting the Control's Cell 
//
- (id)cell
{
  return cell;
}

- (void)setCell:(NSCell *)aCell
{
  // Not a cell class --then forget it
  if (![aCell isKindOfClass:[NSCell class]])
    return;

  [aCell retain];
  [cell release];
  cell = aCell;
}

//
// Enabling and Disabling the Control 
//
- (BOOL)isEnabled
{
  return [[self selectedCell] isEnabled];
}

- (void)setEnabled:(BOOL)flag
{
  [[self selectedCell] setEnabled:flag];
}

//
// Identifying the Selected Cell 
//
- (id)selectedCell
{
  if ([cell state])
    return cell;
  else
    return nil;
}

- (int)selectedTag
{
  return [[self selectedCell] tag];
}

//
// Setting the Control's Value 
//
- (double)doubleValue
{
  return [[self selectedCell] doubleValue];
}

- (float)floatValue
{
  return [[self selectedCell] floatValue];
}

- (int)intValue
{
  return [[self selectedCell] intValue];
}

- (void)setDoubleValue:(double)aDouble
{
  [[self selectedCell] setDoubleValue:aDouble];
}

- (void)setFloatValue:(float)aFloat
{
  [[self selectedCell] setFloatValue:aFloat];
}

- (void)setIntValue:(int)anInt
{
  [[self selectedCell] setIntValue:anInt];
}

- (void)setNeedsDisplay
{
  [super setNeedsDisplay:YES];
}

- (void)setStringValue:(NSString *)aString
{
  [[self selectedCell] setStringValue:aString];
}

- (NSString *)stringValue
{
  return [[self selectedCell] stringValue];
}

//
// Interacting with Other Controls 
//
- (void)takeDoubleValueFrom:(id)sender
{
  [[self selectedCell] takeDoubleValueFrom:sender];
}

- (void)takeFloatValueFrom:(id)sender
{
  [[self selectedCell] takeFloatValueFrom:sender];
}

- (void)takeIntValueFrom:(id)sender
{
  [[self selectedCell] takeIntValueFrom:sender];
}

- (void)takeStringValueFrom:(id)sender
{
  [[self selectedCell] takeStringValueFrom:sender];
}

//
// Formatting Text 
//
- (NSTextAlignment)alignment
{
  if (cell)
    return [cell alignment];
  else
    return NSLeftTextAlignment;
}

- (NSFont *)font
{
  if (cell)
    return [cell font];
  else
    return nil;
}

- (void)setAlignment:(NSTextAlignment)mode
{
  if (cell) [cell setAlignment:mode];
}

- (void)setFont:(NSFont *)fontObject
{
  if (cell) [cell setFont:fontObject];
}

- (void)setFloatingPointFormat:(BOOL)autoRange
			  left:(unsigned)leftDigits
right:(unsigned)rightDigits
{}

//
// Managing the Field Editor 
//
- (BOOL)abortEditing
{
  return NO;
}

- (NSText *)currentEditor
{
  return nil;
}

- (void)validateEditing
{}

//
// Resizing the Control 
//
- (void)calcSize
{}

- (void)sizeToFit
{}

//
// Displaying the Control and Cell 
//
- (void)drawCell:(NSCell *)aCell
{
  if (cell == aCell) [cell drawWithFrame:bounds inView:self];
}

- (void)drawCellInside:(NSCell *)aCell
{
  if (cell == aCell) [cell drawInteriorWithFrame:bounds inView:self];
}

- (void)selectCell:(NSCell *)aCell
{
  if (cell == aCell) [cell setState:1];
}

- (void)updateCell:(NSCell *)aCell
{
  [self setNeedsDisplay:YES];
//  [self drawCell:aCell];
}

- (void)updateCellInside:(NSCell *)aCell
{
  [self setNeedsDisplay:YES];
//  [self drawCellInside:aCell];
}

//
// Target and Action 
//
- (SEL)action
{
  return [cell action];
}

- (BOOL)isContinuous
{
  return [cell isContinuous];
}

- (BOOL)sendAction:(SEL)theAction
		to:(id)theTarget
{
  NSApplication *theApp = [NSApplication sharedApplication];

  return [theApp sendAction:theAction to:theTarget from:self];
}

- (int)sendActionOn:(int)mask
{
  return 0;
}

- (void)setAction:(SEL)aSelector
{
  [cell setAction:aSelector];
}

- (void)setContinuous:(BOOL)flag
{
  [cell setContinuous:flag];
}

- (void)setTarget:(id)anObject
{
  [cell setTarget:anObject];
}

- (id)target
{
  return [cell target];
}

//
// Assigning a Tag 
//
- (void)setTag:(int)anInt
{
  tag = anInt;
}

- (int)tag
{
  return tag;
}

//
// Tracking the Mouse 
//
- (void)mouseDown:(NSEvent *)theEvent
{
  //NSRect f;

  //f = MBConvertRectToWindow(bounds);
  //[cell trackMouse:theEvent inRect:f ofView:self untilMouseUp:YES];
}

- (BOOL)ignoresMultiClick
{
  return NO;
}

- (void)setIgnoresMultiClick:(BOOL)flag
{}

//
// Methods Implemented by the Delegate
//
- (BOOL)control:(NSControl *)control
textShouldBeginEditing:(NSText *)fieldEditor
{
  return NO;
}

- (BOOL)control:(NSControl *)control
textShouldEndEditing:(NSText *)fieldEditor
{
  return NO;
}

- (void)controlTextDidBeginEditing:(NSNotification *)aNotification
{}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{}

- (void)controlTextDidChange:(NSNotification *)aNotification
{}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeValueOfObjCType: "i" at: &tag];
  [aCoder encodeObject: cell];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  [aDecoder decodeValueOfObjCType: "i" at: &tag];
  cell = [aDecoder decodeObject];

  return self;
}

@end
