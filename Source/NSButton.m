/* 
   NSButton.m

   The button class

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

#include <AppKit/NSButton.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSApplication.h>

//
// class variables
//
id gnustep_gui_nsbutton_class = nil;

//
// NSButton implementation
//
@implementation NSButton

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSButton class])
    {
      // Initial version
      [self setVersion:1];

      // Set our cell class to NSButtonCell
      [self setCellClass:[NSButtonCell class]];
    }
}

//
// Initializing the NSButton Factory 
//
+ (Class)cellClass
{
  return gnustep_gui_nsbutton_class;
}

+ (void)setCellClass:(Class)classId
{
  gnustep_gui_nsbutton_class = classId;
}

//
// Instance methods
//
//
// Initialization
//
- init
{
  return [self initWithFrame:NSZeroRect];
}

- initWithFrame:(NSRect)frameRect
{
  [super initWithFrame:frameRect];

  // set our cell
  [self setCell:[[gnustep_gui_nsbutton_class new] autorelease]];

  return self;
}

//
// Setting the Button Type 
//
- (void)setButtonType:(NSButtonType)aType
{
  [cell setButtonType:aType];
  [self display];
}

//
// Identifying the Selected Cell 
//
- (id)selectedCell
{
  return cell;
}

//
// Setting the State 
//
- (void)setIntValue:(int)anInt
{
  [self setState:(anInt != 0)];
}

- (void)setFloatValue:(float)aFloat
{
  [self setState:(aFloat != 0)];
}

- (void)setDoubleValue:(double)aDouble
{
  [self setState:(aDouble != 0)];
}

- (void)setState:(int)value
{
  [cell setState:value];
  [self display];
}

- (int)state
{
  return [cell state];
}

//
// Setting the Repeat Interval 
//
- (void)getPeriodicDelay:(float *)delay
		interval:(float *)interval
{
  [cell getPeriodicDelay:delay interval:interval];
}

- (void)setPeriodicDelay:(float)delay
		interval:(float)interval
{
  [cell setPeriodicDelay:delay interval:interval];
}

//
// Setting the Titles 
//
- (NSString *)alternateTitle
{
  return [cell alternateTitle];
}

- (void)setAlternateTitle:(NSString *)aString
{
  [cell setAlternateTitle:aString];
  [self display];
}

- (void)setTitle:(NSString *)aString
{
  [cell setTitle:aString];
  [self display];
}

- (NSString *)title
{
  return [cell title];
}

//
// Setting the Images 
//
- (NSImage *)alternateImage
{
  return [cell alternateImage];
}

- (NSImage *)image
{
  return [cell image];
}

- (NSCellImagePosition)imagePosition
{
  return [cell imagePosition];
}

- (void)setAlternateImage:(NSImage *)anImage
{
  [cell setAlternateImage:anImage];
  [self display];
}

- (void)setImage:(NSImage *)anImage
{
  [cell setImage:anImage];
  [self display];
}

- (void)setImagePosition:(NSCellImagePosition)aPosition
{
  [cell setImagePosition:aPosition];
  [self display];
}

- (void)setAlignment:(NSTextAlignment)mode
{
  [cell setAlignment:mode];
}

- (NSTextAlignment)alignment
{
  return [cell alignment];
}

//
// Modifying Graphic Attributes 
//
- (BOOL)isBordered
{
  return [cell isBordered];
}

- (BOOL)isTransparent
{
  return [cell isTransparent];
}

- (void)setBordered:(BOOL)flag
{
  [cell setBordered:flag];
  [self display];
}

- (void)setTransparent:(BOOL)flag
{
  [cell setTransparent:flag];
  [self display];
}

//
// Displaying 
//
- (void)drawRect:(NSRect)rect
{
  [cell drawWithFrame:rect inView:self];
}

- (void)highlight:(BOOL)flag
{
  [cell highlight: flag withFrame: bounds inView: self];
}

//
// Setting the Key Equivalent 
//
- (NSString *)keyEquivalent
{
  return nil;
}

- (unsigned int)keyEquivalentModifierMask
{
  return 0;
}

- (void)setKeyEquivalent:(NSString *)aKeyEquivalent
{}

- (void)setKeyEquivalentModifierMask:(unsigned int)mask
{}

//
// Handling Events and Action Messages 
//
- (void)mouseDown:(NSEvent *)theEvent
{
  NSApplication *theApp = [NSApplication sharedApplication];
  BOOL mouseUp, done;
  NSEvent *e;
  unsigned int event_mask = NSLeftMouseDownMask | NSLeftMouseUpMask |
    NSMouseMovedMask | NSLeftMouseDraggedMask | NSRightMouseDraggedMask;
//  int oldActionMask = [cell sendActionOn:0];

  NSDebugLog(@"NSButton mouseDown\n");

  // If we are not enabled then ignore the mouse
  if (![self isEnabled])
    return;

  // capture mouse
//  [[self window] captureMouse: self];
  [self lockFocus];

  done = NO;
  e = theEvent;
  while (!done)
    {
      mouseUp = [cell trackMouse: e inRect: bounds
		      ofView:self untilMouseUp:YES];
      e = [theApp currentEvent];

      // If mouse went up then we are done
      if ((mouseUp) || ([e type] == NSLeftMouseUp))
	done = YES;
      else
	{
	  NSDebugLog(@"NSButton process another event\n");
	  e = [theApp nextEventMatchingMask:event_mask untilDate:nil
		      inMode:NSEventTrackingRunLoopMode dequeue:YES];
	}
    }

  // Release mouse
//  [[self window] releaseMouse: self];

  // If the mouse went up in the button
  if (mouseUp)
    { 
      // Unhighlight the button
      [cell highlight: NO withFrame: bounds
	    inView: self];

      [cell setState:![self state]];
      [cell drawWithFrame:bounds inView:self];
      [[self window] flushWindow];
    }
  [self unlockFocus];

  /* Restore the old action mask */
//  [cell sendActionOn:oldActionMask];

  // Have the target perform the action
//  if (mouseUp)
//    [self sendAction:[self action] to:[self target]];
}

- (void)performClick:(id)sender
{
  [cell performClick:sender];
}

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent
{
  return NO;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  return self;
}

@end
