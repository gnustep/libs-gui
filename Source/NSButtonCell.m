/*
   NSButtonCell.m

   The button cell class

   Copyright (C) 1996-1999 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
	        Ovidiu Predescu <ovidiu@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998

   Modified: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   
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
#include <AppKit/PSOperators.h>



@implementation NSButtonCell

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSButtonCell class])
    [self setVersion: 1];
}

//
// Instance methods
//
- (id) _init
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

- (id) init
{
  [self initTextCell: @"Button"];

  return self;
}

- (id) initImageCell: (NSImage *)anImage
{
  [super initImageCell: anImage];

  contents = nil;

  return [self _init];
}

- (id) initTextCell: (NSString *)aString
{
  [super initTextCell: aString];

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
- (NSString *) title								
{
  return [self stringValue];
}

- (NSString *) alternateTitle					
{
  return altContents;
}

- (void) setFont: (NSFont *)fontObject		
{
  [super setFont: fontObject];
}

- (void) setTitle: (NSString *)aString
{
  [self setStringValue: aString];
  [self setState: [self state]];
}

- (void) setAlternateTitle: (NSString *)aString
{
  NSString* _string = [aString copy];

  ASSIGN(altContents, _string);
  [_string release];
  [self setState: [self state]];
}

//
// Setting the Images
//
- (NSImage *) alternateImage						
{
  return altImage;
}

- (NSCellImagePosition) imagePosition			
{
  return image_position;
}

- (void) setAlternateImage: (NSImage *)anImage
{
  ASSIGN(altImage, anImage);
}

- (void) setImagePosition: (NSCellImagePosition)aPosition
{
  image_position = aPosition;
}

//
// Setting the Repeat Interval
//
- (void) getPeriodicDelay: (float *)delay interval: (float *)interval
{
  *delay = delayInterval;
  *interval = repeatInterval;
}

- (void) setPeriodicDelay: (float)delay interval: (float)interval
{
  delayInterval = delay;
  repeatInterval = interval;
  [self setContinuous: YES];
}

- (void) performClick: (id)sender
{
  NSView	*cv;

  if (control_view)
    cv = control_view;
  else 
    cv = [NSView focusView];

  [self highlight: YES withFrame: [cv frame] inView: cv];
  if (action)
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
- (BOOL) isTransparent					
{
  return transparent;
}

- (void) setTransparent: (BOOL)flag	
{
  transparent = flag;
}

- (BOOL) isOpaque
{
	return !transparent && [self isBordered];
}

//
// Modifying Graphic Attributes
//
- (int) highlightsBy						
{
  return highlightsByMask;
}

- (void) setHighlightsBy: (int)mask	
{
  highlightsByMask = mask;
}

- (void) setShowsStateBy: (int)mask	
{
  showAltStateMask = mask;
}

- (void) setButtonType: (NSButtonType)buttonType
{
  [super setType: buttonType];

  switch (buttonType)
    {
      case NSMomentaryLight: 
	[self setHighlightsBy: NSChangeBackgroundCellMask];
	[self setShowsStateBy: NSNoCellMask];
	break;
      case NSMomentaryPushButton: 
	[self setHighlightsBy: NSPushInCellMask | NSChangeGrayCellMask];
	[self setShowsStateBy: NSNoCellMask];
	break;
      case NSMomentaryChangeButton: 
	[self setHighlightsBy: NSContentsCellMask];
	[self setShowsStateBy: NSNoCellMask];
	break;
      case NSPushOnPushOffButton: 
	[self setHighlightsBy: NSPushInCellMask | NSChangeGrayCellMask];
	[self setShowsStateBy: NSChangeBackgroundCellMask];
	break;
      case NSOnOffButton: 
	[self setHighlightsBy: NSChangeBackgroundCellMask];
	[self setShowsStateBy: NSChangeBackgroundCellMask];
	break;
      case NSToggleButton: 
	[self setHighlightsBy: NSPushInCellMask | NSContentsCellMask];
	[self setShowsStateBy: NSContentsCellMask];
	break;
      case NSSwitchButton: 
	[self setHighlightsBy: NSContentsCellMask];
	[self setShowsStateBy: NSContentsCellMask];
	[self setImage: [NSImage imageNamed: @"common_SwitchOff"]];
	[self setAlternateImage: [NSImage imageNamed: @"common_SwitchOn"]];
	[self setImagePosition: NSImageLeft];
	[self setAlignment: NSLeftTextAlignment];
	break;
      case NSRadioButton: 
	[self setHighlightsBy: NSContentsCellMask];
	[self setShowsStateBy: NSContentsCellMask];
	[self setImage: [NSImage imageNamed: @"common_RadioOff"]];
	[self setAlternateImage: [NSImage imageNamed: @"common_RadioOn"]];
	[self setImagePosition: NSImageLeft];
	[self setAlignment: NSLeftTextAlignment];
	break;
    }

  [self setState: [self state]];
}

- (int) showsStateBy						
{
  return showAltStateMask;
}

- (void) setIntValue: (int)anInt		
{
  [self setState: (anInt != 0)];
}

- (void) setFloatValue: (float)aFloat	
{
  [self setState: (aFloat != 0)];
}

- (void) setDoubleValue: (double)aDouble
{
  [self setState: (aDouble != 0)];
}

- (int) intValue							
{
  return [self state];
}

- (float) floatValue						
{
  return [self state];
}

- (double) doubleValue					
{
  return [self state];
}

//
// Displaying
//
- (NSColor *) textColor
{
  if ([self isEnabled] == NO)
    return [NSColor disabledControlTextColor];
  if (([self state] && ([self showsStateBy] & NSChangeGrayCellMask))
      || ([self isHighlighted] && ([self highlightsBy] & NSChangeGrayCellMask)))
    return [NSColor selectedControlTextColor];
  return [NSColor controlTextColor];
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  // Save last view drawn to
  [self setControlView: controlView];

  // transparent buttons never draw
  if ([self isTransparent])
    return;

  // do nothing if cell's frame rect is zero
  if (NSIsEmptyRect(cellFrame))
    return;

  // draw the border if needed
  if ([self isBordered])
    {
      [controlView lockFocus];
      if ([self isHighlighted] && ([self highlightsBy] & NSPushInCellMask))
        {
          NSDrawGrayBezel(cellFrame, NSZeroRect);
        }
      else
        {
          NSDrawButton(cellFrame, NSZeroRect);
        }
        [controlView unlockFocus];
    }

  [self drawInteriorWithFrame: cellFrame inView: controlView];
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  BOOL		showAlternate = NO;
  unsigned	mask;
  NSImage	*imageToDisplay;
  NSRect	imageRect;
  NSString	*titleToDisplay;
  NSRect	titleRect;
  NSSize	imageSize = {0, 0};
  NSColor	*backgroundColor = nil;

  // transparent buttons never draw
  if ([self isTransparent])
    return;

  cellFrame = [self drawingRectForBounds: cellFrame];
  [controlView lockFocus];

  // pushed in buttons contents are displaced to the bottom right 1px
  if ([self isBordered] && [self isHighlighted]
      && ([self highlightsBy] & NSPushInCellMask))
    cellFrame = NSOffsetRect (cellFrame,
			      1., [control_view isFlipped] ? 1. : -1.);

  // determine the background color
  if ([self state])
    {
      if ( [self showsStateBy]
	& (NSChangeGrayCellMask | NSChangeBackgroundCellMask) )
	backgroundColor = [NSColor selectedControlColor];
    }

  if ([self isHighlighted])
    {
      if ( [self highlightsBy]
	& (NSChangeGrayCellMask | NSChangeBackgroundCellMask) )
	backgroundColor = [NSColor selectedControlColor];
    }

  if (backgroundColor == nil)
    backgroundColor = [NSColor controlBackgroundColor];

  // set cell's background color
  [backgroundColor set];
  NSRectFill(cellFrame);

  /*
   * Determine the image and the title that will be
   * displayed. If the NSContentsCellMask is set the
   * image and title are swapped only if state is 1 or
   * if highlighting is set (when a button is pushed it's
   * content is changed to the face of reversed state).
   */
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
      if (titleToDisplay == nil || [titleToDisplay isEqual: @""])
        titleToDisplay = [self title];
    }
  else
    {
      imageToDisplay = [self image];
      titleToDisplay = [self title];
    }

  if (imageToDisplay)
    {
      imageSize = [imageToDisplay size];
      [imageToDisplay setBackgroundColor: backgroundColor];
    }

  switch ([self imagePosition])
    {
      case NSNoImage: 
	imageToDisplay = nil;
	titleRect = cellFrame;
	break;

      case NSImageOnly: 
	titleToDisplay = nil;
	imageRect = cellFrame;
	break;

      case NSImageLeft: 
	imageRect.origin = cellFrame.origin;
	imageRect.size.width = imageSize.width;
	imageRect.size.height = cellFrame.size.height;

	titleRect = imageRect;
	titleRect.origin.x += imageSize.width + xDist;
	titleRect.size.width = cellFrame.size.width - imageSize.width - xDist;
	break;

      case NSImageRight: 
	imageRect.origin.x = NSMaxX(cellFrame) - imageSize.width;
	imageRect.origin.y = cellFrame.origin.y;
	imageRect.size.width = imageSize.width;
	imageRect.size.height = cellFrame.size.height;

	titleRect.origin = cellFrame.origin;
	titleRect.size.width = cellFrame.size.width - imageSize.width - xDist;
	titleRect.size.height = cellFrame.size.height;
	break;

      case NSImageBelow: 
	imageRect = cellFrame;
	imageRect.size.height /= 2;
	titleRect = imageRect;
        titleRect.origin.y += titleRect.size.height;
	break;

      case NSImageAbove: 
	titleRect = cellFrame;
	titleRect.size.height /= 2;
	imageRect = titleRect;
        imageRect.origin.y += imageRect.size.height;
	break;

      case NSImageOverlaps: 
	titleRect = cellFrame;
	imageRect = cellFrame;
	break;
    }
  if (imageToDisplay != nil)
    {
      NSSize size;
      NSPoint position;

      size = [imageToDisplay size];
      position.x = MAX(NSMidX(imageRect) - (size.width/2.),0.);
      position.y = MAX(NSMidY(imageRect) - (size.height/2.),0.);
      /*
       * Images are always drawn with their bottom-left corner at the origin
       * so we must adjust the position to take account of a flipped view.
       */
      if ([control_view isFlipped])
	position.y += size.height;
      [imageToDisplay compositeToPoint: position operation: NSCompositeCopy];
    }
  if (titleToDisplay != nil)
    {
      [self _drawText: titleToDisplay inFrame: titleRect];
    }
  [controlView unlockFocus];
}

- (NSSize) cellSize 
{
  NSSize s;
  NSSize borderSize;
  BOOL		showAlternate = NO;
  unsigned	mask;
  NSImage	*imageToDisplay;
  NSString	*titleToDisplay;
  NSSize	imageSize;
  NSSize	titleSize;
  
  // 
  // The following code must be kept in sync with -drawInteriorWithFrame
  //
  
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
      if (titleToDisplay == nil || [titleToDisplay isEqual: @""])
	titleToDisplay = [self title];
    }
  else
    {
      imageToDisplay = [self image];
      titleToDisplay = [self title];
    }
  
  if (imageToDisplay)
    imageSize = [imageToDisplay size];
  else 
    imageSize = NSZeroSize;
  
  if (titleToDisplay)
    titleSize = NSMakeSize ([cell_font widthOfString: titleToDisplay], 
			    [cell_font pointSize]);
  else 
    titleSize = NSZeroSize;
  
  switch ([self imagePosition])
    {
    case NSNoImage: 
      s = titleSize;
      break;
      
    case NSImageOnly: 
      s = imageSize;
      break;
      
    case NSImageLeft: 
    case NSImageRight: 
      s.width = imageSize.width + titleSize.width + xDist;
      if (imageSize.height > titleSize.height)
	s.height = imageSize.height;
      else 
	s.height = titleSize.height;
      break;
      
    case NSImageBelow: 
    case NSImageAbove: 
      if (imageSize.width > titleSize.width)
	s.height = imageSize.width;
      else 
	s.width = titleSize.width;
      s.height = imageSize.height + titleSize.height; // + yDist ??
      break;
      
    case NSImageOverlaps: 
      if (imageSize.width > titleSize.width)
	s.width = imageSize.width;
      else
	s.width = titleSize.width;
      
      if (imageSize.height > titleSize.height)
	s.height = imageSize.height;
      else
	s.height = titleSize.height;

      break;
    }
  
  // Add some spacing between text/image and border
  // if there is text in the button
  if (titleToDisplay) {
    s.width += 2 * xDist;
    s.height += 2 * yDist;
  }
 
  // Get border size
  if ([self isBordered])
    // Buttons only have three paths for border (NeXT looks)
    borderSize = NSMakeSize (1.5, 1.5);
  else
    borderSize = [NSCell sizeForBorderType: NSNoBorder];
  
  // Add border size
  s.width += 2 * borderSize.width;
  s.height += 2 * borderSize.height;
  
  return s;
}

- (NSRect) drawingRectForBounds: (NSRect)theRect
{
  if (cell_bordered)
    {
      // Special case:  Buttons have only three different paths for border.
      // One white path at the top left corner, one black path at the
      // bottom right and another in dark gray at the inner bottom right.
      float yDelta = [control_view isFlipped] ? 1. : 2.;
      return NSMakeRect (theRect.origin.x + 1.,
			 theRect.origin.y + yDelta,
			 theRect.size.width - 3.,
			 theRect.size.height - 3.);
    }
  else
    {
      // Get border size
      NSSize borderSize = [NSCell sizeForBorderType: NSNoBorder];
      return NSInsetRect (theRect, borderSize.width, borderSize.height);
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
  [super encodeWithCoder: aCoder];

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
