/* 
   NSButtonCell.m

   The button cell class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
	        Ovidiu Predescu <ovidiu@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   
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
#include <Foundation/NSLock.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>

#include <AppKit/NSButtonCell.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSImage.h>



@implementation NSButtonCell

//
// Class methods
//
+ (void)initialize
{
	if (self == [NSButtonCell class])
		[self setVersion:1];								// Initial version
}

//
// Instance methods
//
- _init
{
	cell_enabled = YES;
	transparent = NO;
	cell_bordered = YES;
	showAltStateMask = NSNoCellMask;	// configure as a NSMomentaryPushButton
	highlightsByMask = NSPushInCellMask | NSChangeGrayCellMask;
	delayInterval = 0.4;
	repeatInterval = 0.075;
	altContents = nil;
	
	return self;
}

- init
{
	[self initTextCell:@"Button"];
	
	return self;
}

- initImageCell:(NSImage *)anImage
{
	[super initImageCell:anImage];
	
	contents = nil;
	
	return [self _init];
}

- initTextCell:(NSString *)aString
{
	[super initTextCell:aString];
	
	return [self _init];
}

- (void)dealloc
{
	[altContents release];
	[altImage release];
	[keyEquivalent release];
	[keyEquivalentFont release];
	
	[super dealloc];
}

//
// Setting the Titles 
//
- (NSString *)title								{ return [self stringValue]; }
- (NSString *)alternateTitle					{ return altContents; }
- (void)setFont:(NSFont *)fontObject			{ [super setFont:fontObject]; }

- (void)setTitle:(NSString *)aString
{
	[self setStringValue:aString];
	[self setState:[self state]];						// update our state
}

- (void)setAlternateTitle:(NSString *)aString
{
NSString* _string = [aString copy];

	ASSIGN(altContents, _string);
	[self setState:[self state]];						// update our state
}

//
// Setting the Images 
//
- (NSImage *)alternateImage						{ return altImage; }
- (NSCellImagePosition)imagePosition			{ return image_position; }
- (void)setAlternateImage:(NSImage *)anImage	{ ASSIGN(altImage, anImage); }

- (void)setImagePosition:(NSCellImagePosition)aPosition
{
	image_position = aPosition;
}

//
// Setting the Repeat Interval 
//
- (void)getPeriodicDelay:(float *)delay interval:(float *)interval
{
	*delay = delayInterval;
	*interval = repeatInterval;
}

- (void)setPeriodicDelay:(float)delay interval:(float)interval
{
	delayInterval = delay;
	repeatInterval = interval;
	[self setContinuous:YES];
}

//
// Setting the Key Equivalent 
//
- (NSString *)keyEquivalent				{ return keyEquivalent; }
- (NSFont *)keyEquivalentFont			{ return keyEquivalentFont; }

- (unsigned int)keyEquivalentModifierMask 
{ 
	return keyEquivalentModifierMask;
}

- (void)setKeyEquivalent:(NSString *)key	
{ 
	ASSIGN(keyEquivalent, [key copy]);
}

- (void)setKeyEquivalentModifierMask:(unsigned int)mask
{
	keyEquivalentModifierMask = mask;
}

- (void)setKeyEquivalentFont:(NSFont *)fontObj
{
	ASSIGN(keyEquivalentFont, fontObj);
}

- (void)setKeyEquivalentFont:(NSString *)fontName size:(float)fontSize
{
	ASSIGN(keyEquivalentFont, [NSFont fontWithName:fontName size:fontSize]);
}

//
// Modifying Graphic Attributes 
//
- (BOOL)isTransparent					{ return transparent; }
- (void)setTransparent:(BOOL)flag		{ transparent = flag; }

- (BOOL)isOpaque				
{ 
	return !transparent && [self isBordered]; 
}

//
// Modifying Graphic Attributes 
//
- (int)highlightsBy						{ return highlightsByMask; }
- (void)setHighlightsBy:(int)mask		{ highlightsByMask = mask; }
- (void)setShowsStateBy:(int)mask		{ showAltStateMask = mask; }


- (void)setButtonType:(NSButtonType)buttonType
{
  [super setType:buttonType];

  switch (buttonType) {
    case NSMomentaryLight:
      [self setHighlightsBy:NSChangeBackgroundCellMask];
      [self setShowsStateBy:NSNoCellMask];
      break;
    case NSMomentaryPushButton:
      [self setHighlightsBy:NSPushInCellMask | NSChangeGrayCellMask];
      [self setShowsStateBy:NSNoCellMask];
      break;
    case NSMomentaryChangeButton:
      [self setHighlightsBy:NSContentsCellMask];
      [self setShowsStateBy:NSNoCellMask];
      break;
    case NSPushOnPushOffButton:
      [self setHighlightsBy:NSPushInCellMask | NSChangeGrayCellMask];
      [self setShowsStateBy:NSChangeBackgroundCellMask];
      break;
    case NSOnOffButton:
      [self setHighlightsBy:NSChangeBackgroundCellMask];
      [self setShowsStateBy:NSChangeBackgroundCellMask];
      break;
    case NSToggleButton:
      [self setHighlightsBy:NSPushInCellMask | NSContentsCellMask];
      [self setShowsStateBy:NSContentsCellMask];
      break;
    case NSSwitchButton:
      [self setHighlightsBy:NSContentsCellMask];
      [self setShowsStateBy:NSContentsCellMask];
      [self setImage:[NSImage imageNamed:@"common_SwitchOff"]];
      [self setAlternateImage:[NSImage imageNamed:@"common_SwitchOn"]];
      [self setImagePosition:NSImageLeft];
      [self setAlignment:NSLeftTextAlignment];
      break;
    case NSRadioButton:
      [self setHighlightsBy:NSContentsCellMask];
      [self setShowsStateBy:NSContentsCellMask];
      [self setImage:[NSImage imageNamed:@"common_RadioOff"]];
      [self setAlternateImage:[NSImage imageNamed:@"common_RadioOn"]];
      [self setImagePosition:NSImageLeft];
      [self setAlignment:NSLeftTextAlignment];
      break;
  }

  // update our state
  [self setState:[self state]];
}

- (int)showsStateBy						{ return showAltStateMask; }
- (void)setIntValue:(int)anInt			{ [self setState:(anInt != 0)]; }
- (void)setFloatValue:(float)aFloat		{ [self setState:(aFloat != 0)]; }
- (void)setDoubleValue:(double)aDouble	{ [self setState:(aDouble != 0)]; }
- (int)intValue							{ return [self state]; }
- (float)floatValue						{ return [self state]; }
- (double)doubleValue					{ return [self state]; }

//
// Displaying
//
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	control_view = controlView;				// Save last view cell was drawn to
}

//
// Simulating a Click 
//
- (void)performClick:(id)sender
{
}

- (id)copyWithZone:(NSZone*)zone
{
  NSButtonCell* c = [super copyWithZone:zone];

  c->altContents = [[altContents copy] retain];
  ASSIGN(c->altImage, altImage);
  c->keyEquivalent = [[keyEquivalent copy] retain];
  ASSIGN(c->keyEquivalentFont, keyEquivalentFont);
  c->keyEquivalentModifierMask = keyEquivalentModifierMask;
  c->transparent = transparent;
  c->highlightsByMask = highlightsByMask;
  c->showAltStateMask = showAltStateMask;

  return c;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  NSDebugLog(@"NSButtonCell: start encoding\n");
  [aCoder encodeObject: altContents];
  [aCoder encodeObject: altImage];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &transparent];
  NSDebugLog(@"NSButtonCell: finish encoding\n");
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  NSDebugLog(@"NSButtonCell: start decoding\n");
  altContents = [aDecoder decodeObject];
  altImage = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &transparent];
  NSDebugLog(@"NSButtonCell: finish decoding\n");

  return self;
}

@end
