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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/NSButton.h>
#include <gnustep/gui/NSWindow.h>
#include <gnustep/gui/NSButtonCell.h>
#include <gnustep/gui/NSApplication.h>

//
// class variables
//
id MB_NSBUTTON_CLASS;

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
  return MB_NSBUTTON_CLASS;
}

+ (void)setCellClass:(Class)classId
{
  MB_NSBUTTON_CLASS = classId;
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
  [[self cell] release];
  [self setCell:[[MB_NSBUTTON_CLASS alloc] init]];

  return self;
}

//
// Setting the Button Type 
//
- (void)setType:(NSButtonType)aType
{
  [cell setType:aType];
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
{}

- (void)setPeriodicDelay:(float)delay
		interval:(float)interval
{}

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

  NSDebugLog(@"NSButton mouseDown\n");

  // If we are not enabled then ignore the mouse
  if (![self isEnabled])
    return;

  // capture mouse
  [[self window] captureMouse: self];

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
		      inMode:nil dequeue:YES];
	}
    }

  // Release mouse
  [[self window] releaseMouse: self];

  // If the mouse went up in the button
  if (mouseUp)
    { 
      // Unhighlight the button
      [cell highlight: NO withFrame: bounds
	    inView: self];

      //
      // Perform different state changes based upon our type
      //
      switch ([cell type])
	{
	case NSToggleButton:
	case NSMomentaryChangeButton:
	case NSMomentaryPushButton:
	  /* No state changes */
	  break;

	case NSPushOnPushOffButton:
	case NSSwitchButton:
	case NSRadioButton:
	case NSOnOffButton:
	  // Toggle our state
	  if ([self state])
	    {
	      [cell setState:0];
	      NSDebugLog(@"toggle state off\n");
	    }
	  else
	    {
	      [cell setState:1];
	      NSDebugLog(@"toggle state on\n");
	    }
	}

      // Have the target perform the action
      [self sendAction:[self action] to:[self target]];
    }
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
