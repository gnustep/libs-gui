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
#include <Foundation/NSException.h>

#include <AppKit/NSButtonCell.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>



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

- (void) dealloc
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
  [_string release];
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

- (void) performClick: (id)sender
{
  NSView	*cv = [self controlView];

  [self highlight: YES withFrame: [cv frame] inView: cv];
  if (action && target)
    {
      NS_DURING
	{
	  [(NSControl*)cv sendAction: action to: target];
	}
      NS_HANDLER
	{
	  [self highlight: NO withFrame: [cv frame] inView: cv];
          [localException raise];
	}
      NS_ENDHANDLER
    }
  [self highlight: NO withFrame: [cv frame] inView: cv];
}

//
// Setting the Key Equivalent
//
- (NSString*) keyEquivalent
{
  return keyEquivalent;
}

- (NSFont*) keyEquivalentFont
{
  return keyEquivalentFont;
}

- (unsigned int) keyEquivalentModifierMask
{
  return keyEquivalentModifierMask;
}

- (void) setKeyEquivalent: (NSString*)key
{
  if (keyEquivalent != key)
    {
      [keyEquivalent release];
      keyEquivalent = [key copy];
    }
}

- (void) setKeyEquivalentModifierMask: (unsigned int)mask
{
  keyEquivalentModifierMask = mask;
}

- (void) setKeyEquivalentFont: (NSFont*)fontObj
{
  ASSIGN(keyEquivalentFont, fontObj);
}

- (void) setKeyEquivalentFont: (NSString*)fontName size: (float)fontSize
{
  ASSIGN(keyEquivalentFont, [NSFont fontWithName: fontName size: fontSize]);
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

  switch (buttonType)
	{
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
- (NSColor *)textColor
{
  if (([self state] && ([self showsStateBy] & NSChangeGrayCellMask))
      || ([self isHighlighted] && ([self highlightsBy] & NSChangeGrayCellMask)))
    return [NSColor lightGrayColor];
  return [NSColor blackColor];
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  // Save last view drawn to
  [self setControlView: controlView];

  // do nothing if cell's frame rect is zero
  if (NSIsEmptyRect(cellFrame))
    return;

  // draw the border if needed
  if ([self isBordered])
    {
      if ([self isHighlighted] && ([self highlightsBy] & NSPushInCellMask))
        {
          NSDrawGrayBezel(cellFrame, cellFrame);
        }
      else
        {
          NSDrawButton(cellFrame, cellFrame);
        }
    }

  [self drawInteriorWithFrame: cellFrame inView: controlView];
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  BOOL		showAlternate = NO;
  unsigned	mask;
  NSImage	*imageToDisplay;
  NSString	*titleToDisplay;
  NSSize	imageSize = {0, 0};
  NSRect	rect;
  float		backgroundGray = NSLightGray;

  cellFrame = NSInsetRect(cellFrame, xDist, yDist);

  // determine the background color
  if ([self state])
    {
      if ( [self showsStateBy]
           & (NSChangeGrayCellMask | NSChangeBackgroundCellMask) )
        backgroundGray = NSWhite;
    }

  if ([self isHighlighted])
    {
      if ( [self highlightsBy]
           & (NSChangeGrayCellMask | NSChangeBackgroundCellMask) )
        backgroundGray = NSWhite;
    }

  // set cell's background color
  [[NSColor colorWithCalibratedWhite:backgroundGray alpha:1.0] set];
  NSRectFill(cellFrame);

  // Determine the image and the title that will be
  // displayed. If the NSContentsCellMask is set the
  // image and title are swapped only if state is 1 or
  // if highlighting is set (when a button is pushed it's
  // content is changed to the face of reversed state).
  if ([self isHighlighted])
    mask = [self highlightsBy];
  else
    mask = [self showsStateBy];
  if (mask & NSContentsCellMask)
    showAlternate = [self state];

  if (showAlternate || [self isHighlighted])
    {
      imageToDisplay = [self alternateImage];
      if (!imageToDisplay)
	imageToDisplay = [self image];
      titleToDisplay = [self alternateTitle];
      if (!titleToDisplay)
        titleToDisplay = [self title];
    }
  else
    {
      imageToDisplay = [self image];
      titleToDisplay = [self title];
    }

  if (imageToDisplay)
    imageSize = [imageToDisplay size];

  rect = NSMakeRect (cellFrame.origin.x, cellFrame.origin.y,
                     imageSize.width, imageSize.height);

  switch ([self imagePosition])
    {
      case NSNoImage:
	 // draw title only
	 [self _drawText: titleToDisplay inFrame: cellFrame];
	 break;

      case NSImageOnly:
	 // draw image only
	 [self _drawImage: imageToDisplay inFrame: cellFrame];
	 break;

      case NSImageLeft:
	 // draw image to the left of the title
	 rect.origin = cellFrame.origin;
	 rect.size.width = imageSize.width;
	 rect.size.height = cellFrame.size.height;
	 [self _drawImage: imageToDisplay inFrame: rect];

	 // draw title
	 rect.origin.x += imageSize.width + xDist;
	 rect.size.width = cellFrame.size.width - imageSize.width - xDist;
	 [self _drawText: titleToDisplay inFrame: rect];
	 break;

      case NSImageRight:
	 // draw image to the right of the title
	 rect.origin.x = NSMaxX (cellFrame) - imageSize.width;
	 rect.origin.y = cellFrame.origin.y;
	 rect.size.width = imageSize.width;
	 rect.size.height = cellFrame.size.height;
	 [self _drawImage:imageToDisplay inFrame:rect];

	 // draw title
	 rect.origin = cellFrame.origin;
	 rect.size.width = cellFrame.size.width - imageSize.width - xDist;
	 rect.size.height = cellFrame.size.height;
	 [self _drawText: titleToDisplay inFrame: rect];
	 break;

      case NSImageBelow:
	 // draw image below title
	 cellFrame.size.height /= 2;
	 [self _drawImage: imageToDisplay inFrame: cellFrame];
	 cellFrame.origin.y += cellFrame.size.height;
	 [self _drawText: titleToDisplay inFrame: cellFrame];
	 break;

      case NSImageAbove:
	 // draw image above title
	 cellFrame.size.height /= 2;
	 [self _drawText: titleToDisplay inFrame: cellFrame];
	 cellFrame.origin.y += cellFrame.size.height;
	 [self _drawImage: imageToDisplay inFrame: cellFrame];
	 break;

      case NSImageOverlaps:
	 // draw title over the image
	 [self _drawImage: imageToDisplay inFrame: cellFrame];
	 [self _drawText: titleToDisplay inFrame: cellFrame];
	 break;
    }
}


- (id) copyWithZone: (NSZone*)zone
{
  NSButtonCell	*c = [super copyWithZone: zone];

  c->altContents = [altContents copyWithZone: zone];
  if (altImage)
    c->altImage = [altImage retain];
  c->keyEquivalent = [keyEquivalent copyWithZone: zone];
  if (keyEquivalentFont)
    c->keyEquivalentFont = [keyEquivalentFont retain];
  c->keyEquivalentModifierMask = keyEquivalentModifierMask;
  c->transparent = transparent;
  c->highlightsByMask = highlightsByMask;
  c->showAltStateMask = showAltStateMask;

  return c;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];

  NSDebugLog(@"NSButtonCell: start encoding\n");
  [aCoder encodeObject: keyEquivalent];
  [aCoder encodeObject: keyEquivalentFont];
  [aCoder encodeObject: altContents];
  [aCoder encodeObject: altImage];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &transparent];
  NSDebugLog(@"NSButtonCell: finish encoding\n");
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  NSDebugLog(@"NSButtonCell: start decoding\n");
  [aDecoder decodeValueOfObjCType: @encode(id) at: &keyEquivalent];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &keyEquivalentFont];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &altContents];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &altImage];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &transparent];
  NSDebugLog(@"NSButtonCell: finish decoding\n");

  return self;
}

@end
