/* 
   NSText.m

   The RTFD text class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: July 1998
   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
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
   59 Temple Place - Suite 330, Boston, MA 02111 - 1307, USA.
*/

// toDo: - caret blinking
//	 - formatting routine: broader than 1.5x width cause display problems
//	 - optimization: 1.deletion of single char in paragraph [opti hook 1]
//	 - optimization: 2.newline in first line
//	 - optimization: 3.paragraph made one less line due to delition 
//                         of single char [opti hook 1; diff from 1.]

#include <gnustep/gui/config.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>

#include <AppKit/NSFileWrapper.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSText.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSFontPanel.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSSpellChecker.h>
#include <AppKit/NSClipView.h>

#include <AppKit/NSDragging.h> 
#include <AppKit/NSStringDrawing.h>

#include <Foundation/NSNotification.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSScanner.h>
#include <Foundation/NSData.h>

#define HUGE 1e99

/*
 * A little utility function to determine the range of characters in a scanner
 * that are present in a specified character set.
 */
static inline NSRange
scanRange(NSScanner *scanner, NSCharacterSet* aSet)
{
  unsigned	start = [scanner scanLocation];
  unsigned	end = start;

  if ([scanner scanCharactersFromSet: aSet intoString: 0] == YES)
    {
      end = [scanner scanLocation];
    }
  return NSMakeRange(start, end - start);
}

enum {
  NSBackspaceKey      = 8,
  NSCarriageReturnKey = 13,
  NSDeleteKey         = 0x7f,
  NSBacktabKey        = 25
};

@interface _GNULineLayoutInfo: NSObject
{
  NSRange lineRange;
  NSRect	lineRect;
  float	drawingOffset;
  BOOL	dontDisplay;
  unsigned	type;
}

typedef enum
{	
  // do not use 0 in order to secure calls to nil (calls to nil return 0)!
  LineLayoutInfoType_Text = 1,
  LineLayoutInfoType_Paragraph = 2
} _GNULineLayoutInfo_t;

+ lineLayoutWithRange: (NSRange) aRange rect: (NSRect) aRect 
	drawingOffset: (float) anOffset type: (unsigned) aType;

- (NSRange) lineRange;
- (NSRect) lineRect;
- (float) drawingOffset;
- (BOOL) isDontDisplay;
- (unsigned) type;

- (void) setLineRange: (NSRange) aRange;
- (void) setLineRect: (NSRect) aRect;
- (void) setDrawingOffset: (float) anOffset;
- (void) setDontDisplay: (BOOL) flag;
- (void) setType: (unsigned) aType;
- (BOOL) isLineTerminatingParagraph;

- (NSString*) description;
@end

@implementation _GNULineLayoutInfo

+ lineLayoutWithRange: (NSRange) aRange rect: (NSRect) aRect 
	drawingOffset: (float) anOffset type: (unsigned) aType
{	
  id ret = [[[_GNULineLayoutInfo alloc] init] autorelease];
  [ret setLineRange: aRange]; 
  [ret setLineRect: aRect]; 
  [ret setDrawingOffset: anOffset]; 
  [ret setType: aType];
  return ret;
}

- (BOOL) isDontDisplay	
{
  return dontDisplay;
}

- (unsigned) type	
{
  return type;
}

- (NSRange) lineRange 
{
  return lineRange;
}

- (NSRect) lineRect 
{
  return lineRect;
}

- (float) drawingOffset 
{
  return drawingOffset;
}

- (void) setLineRange: (NSRange) aRange 
{
  lineRange = aRange;
}

- (void) setLineRect: (NSRect) aRect 
{
  //FIXME, line up textEditor with how text in text cell will be placed.
  //  aRect.origin.y += 2;

  lineRect = aRect;
}

- (void) setDrawingOffset: (float) anOffset 
{
  drawingOffset = anOffset;
}

- (void) setDontDisplay: (BOOL) flag		
{
  dontDisplay = flag;
}

- (void) setType: (unsigned) aType		
{
  type = aType;
}

- (NSString*) description
{	
  return [[NSDictionary dictionaryWithObjectsAndKeys: 	
			  NSStringFromRange(lineRange), @"LineRange",
			  NSStringFromRect(lineRect), @"LineRect",
			  nil] 
	   description];
}

- (BOOL) isLineTerminatingParagraph 
{
  // sort of hackish
  return type  == LineLayoutInfoType_Paragraph && lineRect.origin.x> 0;
}	
@end

static NSRange MakeRangeFromAbs (int a1,int a2) // not the same as NSMakeRange!
{
  if (a1 < 0)
    a1  = 0;
  if (a2 < 0)
    a2  = 0;
  if (a1 < a2)
    return NSMakeRange (a1, a2 - a1);
  else
    return NSMakeRange (a2, a1 - a2);
}

/*
static NSRange MakeRangeFromAbs(int a1,int a2)
{	if (a1< a2)	return NSMakeRange(a1,a2 - a1);	
	else		return NSMakeRange(a2,a1 - a2);
}
*/
// end: _GNULineLayoutInfo------------------------------------------------------------------------------------------

/*
@interface NSAttributedString(DrawingAddition)
- (NSSize) sizeRange: (NSRange) aRange;
- (void) drawRange: (NSRange) aRange atPoint: (NSPoint) aPoint;
- (void) drawRange: (NSRange) aRange inRect: (NSRect) aRect;
- (BOOL) areMultipleFontsInRange: (NSRange) aRange;
@end
*/

@implementation NSAttributedString(DrawingAddition)
- (NSSize) sizeRange: (NSRange) lineRange
{
  NSRect retRect = NSZeroRect;
  NSRange currRange = NSMakeRange (lineRange.location, 0);
  NSPoint currPoint = NSMakePoint (0, 0);
  NSString *string = [self string];
  
  for (; NSMaxRange (currRange) < NSMaxRange (lineRange);) // draw all "runs"
    {
      NSDictionary *attributes = [self attributesAtIndex: NSMaxRange(currRange) 
				       longestEffectiveRange: &currRange 
				       inRange: lineRange];
      NSString *substring = [string substringWithRange: currRange];
      NSRect sizeRect = NSMakeRect (currPoint.x, 0, 0, 0);
      
      sizeRect.size = [substring sizeWithAttributes: attributes];
      retRect = NSUnionRect (retRect, sizeRect);
      currPoint.x += sizeRect.size.width;
      //<!> size attachments
    } 
  return retRect.size;
}
- (void) drawRange: (NSRange) lineRange atPoint: (NSPoint) aPoint
{
  NSRange currRange = NSMakeRange (lineRange.location, 0);
  NSPoint currPoint;
  NSString *string = [self string];
  
  for (currPoint = aPoint; NSMaxRange (currRange) < NSMaxRange (lineRange);)
    {
      // draw all "runs"
      NSDictionary *attributes = [self attributesAtIndex: NSMaxRange(currRange) 
				       longestEffectiveRange: &currRange 
				       inRange: lineRange];
      NSString *substring = [string substringWithRange: currRange];
      [substring drawAtPoint: currPoint withAttributes: attributes];
      currPoint.x += [substring sizeWithAttributes: attributes].width;
      //<!> draw attachments
    }
}

- (void) drawRange: (NSRange)aRange inRect: (NSRect)aRect
{
  NSString *substring = [[self string] substringWithRange: aRange];
  
  [substring drawInRect: aRect
	     withAttributes: [NSDictionary dictionaryWithObjectsAndKeys: 
					     [NSFont systemFontOfSize: 12.0], 
					     NSFontAttributeName,
					     [NSColor blueColor], 
					     NSForegroundColorAttributeName,
					     nil]];
}

- (BOOL) areMultipleFontsInRange: (NSRange) aRange
{
  NSRange longestRange;

  [self attribute: NSFontAttributeName atIndex: aRange.location
	longestEffectiveRange: &longestRange inRange: aRange];
  
  if (NSEqualRanges (NSIntersectionRange (longestRange, aRange), aRange))
    return NO;
  else
    return YES;
}

@end

@interface _GNUSeekableArrayEnumerator: NSObject
{
  unsigned	currentIndex;
  NSArray	*array;
}
- initWithArray: (NSArray*) anArray;
- nextObject;
- previousObject;
- currentObject;
@end

@implementation _GNUSeekableArrayEnumerator

- initWithArray: (NSArray*) anArray
{
  [super init];
  array = [anArray retain];
  return self;
}
- nextObject
{	
  if (currentIndex >= [array count]) 
    return nil;
  return [array objectAtIndex: currentIndex++];
}
- previousObject
{
  if (!currentIndex) 
    return nil;
  return [array objectAtIndex:--currentIndex];
}
- currentObject
{	
  return [array objectAtIndex: currentIndex];
}

- (void) dealloc
{	
  [array release];
  [super dealloc];
}
@end
@interface NSArray(SeekableEnumerator)
- (_GNUSeekableArrayEnumerator*) seekableEnumerator;
@end
@implementation NSArray(SeekableEnumerator)
- (_GNUSeekableArrayEnumerator*) seekableEnumerator
{	
  return [[[_GNUSeekableArrayEnumerator alloc] initWithArray: self] 
	   autorelease];
}
@end



// begin: NSText------------------------------------------------------------

@implementation NSText

//
// Class methods
//
+ (void)initialize
{	
  if (self  == [NSText class])
    { 
      NSArray  *r;
      NSArray  *s;
      
      [self setVersion: 1];                     // Initial version

      r  = [NSArray arrayWithObjects: NSStringPboardType, nil];
      s  = [NSArray arrayWithObjects: NSStringPboardType, nil];
 
      [[NSApplication sharedApplication] registerServicesMenuSendTypes: s
                                                          returnTypes: r];
    }
}

//<!>
//this is sort of a botch up: rtf should be spilled out here 
// in order to be OPENSTEP - compatible
// the way to go is surely implementing 
// - (NSData *)RTFDFromRange: (NSRange)range 
// documentAttributes: (NSDictionary *)dict; and friends.
// (NeXT OPENSTEP additions to NSAttributedString)
//
// but on the other hand: since rtf is MS - technology, 
// simply let us declare the NSArchiver generated data stream output 
// being the GNU rich text format ; - )
+ (NSData*) dataForAttributedString: (NSAttributedString*) aString
{	
  return [NSArchiver archivedDataWithRootObject: aString];
}

//this is sort of a botch up: a rtf parser should come in here in order 
// to be OPENSTEP - compatible
// but on the other hand: since rtf is MS - technology, 
// simply let us declare the NSArchiver generated data stream output 
// being the GNU rich text format ; - )
// return value is guaranteed to be a NSAttributedString 
// even if data is only NSString
+ (NSAttributedString*) attributedStringForData: (NSData*) aData
{	
  id erg = [NSUnarchiver unarchiveObjectWithData: aData];
  if (![erg isKindOfClass: [NSAttributedString class]])
    return [[[NSAttributedString alloc] initWithString: erg] autorelease];
  else 
    return erg;
}

+ (NSString*) newlineString 
{
  return @"\n";
}

//
// Instance methods
//
//
// Initialization
//

- (id) init
{
  return [self initWithFrame: NSMakeRect (0, 0, 100, 100)];
}

- (id) initWithFrame: (NSRect)frameRect
{
  [super initWithFrame: frameRect];
  
  alignment = NSLeftTextAlignment;
  is_editable = YES;
  [self setRichText: NO];	// sets up the contents object
  is_selectable = YES;
  imports_graphics = NO;
  uses_font_panel = NO;
  is_horizontally_resizable = NO;
  is_vertically_resizable = YES;
  is_ruler_visible = NO;
  is_field_editor = NO;
  draws_background = YES;
  [self setBackgroundColor: [NSColor textBackgroundColor]];
  [self setTextColor: [NSColor textColor]];
  default_font = RETAIN([NSFont userFontOfSize: 12]);

  [self setSelectionWordGranularitySet:
	  [NSCharacterSet characterSetWithCharactersInString: @" "]]; //[NSCharacterSet whitespaceCharacterSet]
  [self setSelectionParagraphGranularitySet:
	  [NSCharacterSet characterSetWithCharactersInString: 
			    [[self class] newlineString]]];

  [self setMinSize: frameRect.size];
  [self setMaxSize: NSMakeSize(HUGE,HUGE)];
  
  [self setString: @"Text"];
  [self setSelectedRange: NSMakeRange (0, 0)];
  return self;
}

- (NSDictionary*) defaultTypingAttributes
{	
  return [NSDictionary dictionaryWithObjectsAndKeys: 
			 default_font, NSFontAttributeName,
		         text_color, NSForegroundColorAttributeName,
		         nil];
}

/*
 *     Handle enabling/disabling of services menu items.
 */
- (id) validRequestorForSendType: (NSString*)sendType
                     returnType: (NSString*)returnType
{
  if ((!sendType || [sendType isEqual: NSStringPboardType]) 
      && (!returnType || [returnType isEqual: NSStringPboardType]))
    {
      if ((selected_range.length || !sendType)
	  && ([self isEditable] || !returnType))
	{
	  return self;
	}
    }
  return [super validRequestorForSendType: sendType
		returnType: returnType];
      
}

- (BOOL) writeSelectionToPasteboard: (NSPasteboard*)pb
                             types: (NSArray*)sendTypes
{
  NSArray      *types;
  NSString     *string;
        
  if ([sendTypes containsObject: NSStringPboardType] == NO)
    {
      return NO;
    }
  types = [NSArray arrayWithObjects: NSStringPboardType, nil];
  [pb declareTypes: types owner: nil];
  string = [self string];
  string = [string substringWithRange: selected_range];
  return [pb setString: string forType: NSStringPboardType];
}

// <!>
// handle font pasteboard as well!
// handle ruler pasteboard as well!
- (BOOL) performPasteOperation: (NSPasteboard*)pboard
{
// color accepting
  if ([pboard availableTypeFromArray: [NSArray arrayWithObject: 
						 NSColorPboardType]])
    {
      NSColor	*color = [NSColor colorFromPasteboard: pboard];
      
      if ([self isRichText])
	{
	  [self setTextColor: color range: selected_range];
	}
      else
	[self setTextColor: color];
      return YES;
    }
  
  if ([self importsGraphics])
    {
      NSArray *types = [NSArray arrayWithObjects: NSFileContentsPboardType, 
				NSRTFDPboardType, NSRTFPboardType, 
				NSStringPboardType, NSTIFFPboardType, nil];
      if ([[pboard availableTypeFromArray: types] 
	    isEqualToString: NSRTFDPboardType])
	{	
	  [self insertText: 
		  [[self class] attributedStringForData: 
				  [pboard dataForType: NSRTFDPboardType]]];
	} 
      else if ([[pboard availableTypeFromArray: types] 
		 isEqualToString: NSRTFPboardType])
	{	
	  [self insertText: 
		  [[self class] attributedStringForData: 
				  [pboard dataForType: NSRTFPboardType]]];
	} 
      else if ([[pboard availableTypeFromArray: types] 
		 isEqualToString: NSStringPboardType])
	{
	  [self insertText: [pboard stringForType: NSStringPboardType]];
	  return YES;
	}
    } 
  else if ([self isRichText])
    {
      NSArray *types = [NSArray arrayWithObjects: NSRTFPboardType, 
				NSStringPboardType, nil];
      if ([[pboard availableTypeFromArray: types] 
	    isEqualToString: NSRTFPboardType])
	{
	  [self insertText: 
		  [[self class] attributedStringForData: 
				  [pboard dataForType: NSRTFPboardType]]];
	}
      else if ([[pboard availableTypeFromArray: types] 
		 isEqualToString: NSStringPboardType])
	{
	  [self insertText: [pboard stringForType: NSStringPboardType]];
	  return YES;
	}
    } 
  else	// plain text
    {
      NSArray *types = [NSArray arrayWithObjects: NSStringPboardType, nil];
      if ([[pboard availableTypeFromArray: types] 
	    isEqualToString: NSStringPboardType])
	{
	  [self insertText: [pboard stringForType: NSStringPboardType]];
	  return YES;
	}
    } 
  return NO;
}

- (BOOL) readSelectionFromPasteboard: (NSPasteboard*)pb
{       
  return [self performPasteOperation: pb];
}

// begin: dragging of colors and files---------------
- (unsigned int) draggingEntered: (id <NSDraggingInfo>)sender
{	
  return NSDragOperationGeneric;
}
- (unsigned int) draggingUpdated: (id <NSDraggingInfo>)sender
{	
  return NSDragOperationGeneric;
}
- (void) draggingExited: (id <NSDraggingInfo>)sender
{
}
- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>)sender
{	
  return YES;
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>)sender
{
  return [self performPasteOperation: [sender draggingPasteboard]];
}

- (void) concludeDragOperation: (id <NSDraggingInfo>)sender
{
}
// end: drag accepting---------------------------------

- (void)dealloc 
{	
  [self unregisterDraggedTypes];
  [background_color release];
  [default_font release];
  [text_color release];
  
  [plainContent release];
  [rtfContent release];
  
  [super dealloc];
}

- (NSArray*) acceptableDragTypes
{
  NSMutableArray *ret = [NSMutableArray arrayWithObjects: NSStringPboardType,
					NSColorPboardType, nil];

  if ([self isRichText])
    [ret addObject: NSRTFPboardType];
  if ([self importsGraphics])
    [ret addObject: NSRTFDPboardType];
  return ret;
}

- (void) updateDragTypeRegistration
{	
  [self registerForDraggedTypes: [self acceptableDragTypes]];
}

- (NSRange) selectionRangeForProposedRange: (NSRange)proposedCharRange 
			       granularity: (NSSelectionGranularity)granularity
{	
  NSCharacterSet *set = nil;
  unsigned lastIndex = [self textLength] - 1;
  unsigned lpos = MIN(lastIndex, proposedCharRange.location);
  // <!>better: rpos = MAX(0,(int)NSMaxRange(proposedCharRange) - 1);
  unsigned rpos = NSMaxRange(proposedCharRange);  
  NSString *string = [self string];
  BOOL rmemberstate, lmemberstate;

  if (![string length]) 
    {
      NSLog(@"We have no length, our range is 0,0\n");
      return NSMakeRange(0,0);
    }

  switch (granularity)
    {
    case NSSelectByCharacter: 
      return NSIntersectionRange (proposedCharRange, 
				  NSMakeRange (0, [self textLength] + 1));
    case NSSelectByWord: 
      set = selectionWordGranularitySet;
      break;
    case NSSelectByParagraph: 
      set = selectionParagraphGranularitySet;
      break;
    }
  // now work on set...
  lmemberstate = [set characterIsMember: [string characterAtIndex: lpos]];
  rmemberstate = [set characterIsMember: [string characterAtIndex: 
						   MIN (rpos, lastIndex)]];
  while (rpos <= lastIndex 
	 && ([set characterIsMember: [string characterAtIndex: rpos]] 
	     == rmemberstate)) 
    rpos++;
  
  while (lpos 
	 && ([set characterIsMember: [string characterAtIndex: lpos]] 
	     == lmemberstate)) 
    lpos--;
  
  if ([set characterIsMember: [string characterAtIndex: lpos]] != lmemberstate 
      && lpos < proposedCharRange.location) 
    lpos++;
  
  return MakeRangeFromAbs(lpos,rpos);
}


//
// Getting and Setting Contents 
//

// low level (no selection handling, relayout or display)
- (void) replaceRange: (NSRange)range 
 withAttributedString: (NSAttributedString*)attrString
{
  if ([self isRichText])
    {	
      return [rtfContent replaceCharactersInRange: range 
			 withAttributedString: attrString];
    } 
  else 
    return [plainContent replaceCharactersInRange: range 
			 withString: [attrString string]];
}
- (void) replaceRange: (NSRange)range withRTFD: (NSData *)rtfdData
{	
  return [self replaceRange: range 
	       withAttributedString: [[self class] attributedStringForData: 
						     rtfdData]];
}

- (void) replaceRange: (NSRange)range withRTF: (NSData*) rtfData
{
  [self replaceRange: range withRTFD: rtfData];
}

- (void) replaceRange: (NSRange)range withString: (NSString*) aString
{
  if ([self isRichText])
    {
      return [rtfContent replaceCharactersInRange: range withString: aString];
    } 
  else 
    return [plainContent replaceCharactersInRange: range withString: aString];
}

- (void) setText: (NSString*) aString range: (NSRange) aRange
{	
  [self replaceRange: (NSRange)aRange withString: aString];
}

- (NSData*) RTFDFromRange: (NSRange)range
{	
  if ([self isRichText])
    {
      return [[self class] dataForAttributedString: 
			     [rtfContent attributedSubstringFromRange: range]];
    } 
  else 
    return nil;
}

- (NSData*) RTFFromRange: (NSRange)range
{
  return [self RTFDFromRange: range];
}

- (void) setString: (NSString *)string
{	
  [plainContent release];
  plainContent = [[NSMutableString stringWithString: string] retain];
  [lineLayoutInformation autorelease]; 
  lineLayoutInformation = nil;	// force complete re - layout
  [self setRichText: NO];
  [self setSelectedRangeNoDrawing: NSMakeRange (0, 0)];
  //      [self rebuildLineLayoutInformationStartingAtLine: 0];
  //	[self setNeedsDisplay: YES];
}
- (void) setText: (NSString *)string 
{
  [self setString: string];
}

- (NSString*) string
{
  if ([self isRichText])
    return [rtfContent string];
  else	
    return plainContent;
}
- (NSString*) text		
{
  return [self string];
}

//
// Managing Global Characteristics
//
- (NSTextAlignment)alignment		
{
  return alignment; 
}
- (BOOL) drawsBackground				
{ 
  return draws_background; 
}
- (BOOL) importsGraphics				
{ 
  return imports_graphics; 
}
- (BOOL) isEditable					
{ 
  return is_editable; 
}
- (BOOL) isRichText					
{ 
  return is_rich_text; 
}
- (BOOL) isSelectable				
{ 
  return is_selectable; 
}

- (void)setAlignment: (NSTextAlignment)mode
{
  alignment = mode;
}

- (void)setDrawsBackground: (BOOL)flag
{
  draws_background = flag;
}

- (void)setEditable: (BOOL)flag
{	
  is_editable = flag;
  // If we are editable then we  are selectable
  if (flag) 
    is_selectable = YES;	
}

- (void)setImportsGraphics: (BOOL)flag
{	
  imports_graphics = flag;
  [self updateDragTypeRegistration];
}

- (void) setRichText: (BOOL)flag
{
  is_rich_text  = flag;
  if (flag)
    {
      if (!rtfContent) 
	rtfContent = [[NSMutableAttributedString 
			alloc] 
		       initWithString: 
			 plainContent? (NSString*)plainContent: 
			 @"" attributes: [self defaultTypingAttributes]];
      [lineLayoutInformation autorelease]; 
      lineLayoutInformation = nil;
      [self rebuildLineLayoutInformationStartingAtLine: 0];
    } 
  else
    {	
      if (!plainContent) 
	plainContent = [[NSMutableString 
			  alloc] 
			 initWithString: rtfContent? [rtfContent string]: @""];
      [self rebuildLineLayoutInformationStartingAtLine: 0];
      }
  
  [self updateDragTypeRegistration];
  
  [self sizeToFit];
  [self setNeedsDisplay: YES];
}

- (void)setSelectable: (BOOL)flag
{	
  is_selectable = flag;
  // If we are not selectable then we must not be editable
  if (!flag) 
    is_editable = NO;					
}

/*
 * Managing Font and Color
 */
- (NSColor*) backgroundColor
{
  return background_color;
}

- (NSFont*) font
{
  return default_font;
}

- (NSColor*) textColor
{
  return text_color;
}

- (BOOL) usesFontPanel
{
  return uses_font_panel;
}


// This action method changes the font of the selection for a rich text object, 
// or of all text for a plain text object. If the receiver doesn't use the Font 
// Panel, however, this method does nothing.
- (void) changeFont: sender
{	
  if ([self usesFontPanel])
    {	
      if ([self isRichText])
	{
	  NSRange searchRange = selected_range;
	  NSRange foundRange;
	  int maxSelRange;
	  
	  for (maxSelRange = NSMaxRange(selected_range); 
	       searchRange.location < maxSelRange;
	       searchRange = NSMakeRange (NSMaxRange (foundRange), 
					  maxSelRange - NSMaxRange(foundRange)))
	    {
	      NSFont *font = [rtfContent attribute: NSFontAttributeName 
					 atIndex: searchRange.location 
					 longestEffectiveRange: &foundRange 
					 inRange: searchRange];
	      if (font)
		{
		  [self setFont: [sender convertFont: font] 
			ofRange: foundRange];
		}
	    }
	} 
      else
	{	
	  [self setFont: 
		  [sender convertFont: [[self defaultTypingAttributes] 
					 objectForKey: NSFontAttributeName]]];
	}
    }
}

- (void) setSelectionWordGranularitySet: (NSCharacterSet*) aSet
{	
  ASSIGN(selectionWordGranularitySet, aSet);
}
- (void) setSelectionParagraphGranularitySet: (NSCharacterSet*) aSet
{	
  ASSIGN(selectionParagraphGranularitySet, aSet);
}


- (void) setBackgroundColor: (NSColor *)color
{
  ASSIGN(background_color, color);
}

- (void) setTypingAttributes: (NSDictionary*) dict
{	
  if (![dict isKindOfClass: [NSMutableDictionary class]])
    {	
      [typingAttributes autorelease];
      typingAttributes = [[NSMutableDictionary alloc] initWithDictionary: dict];
      // do not autorelease!
    } 
  else 
    ASSIGN(typingAttributes, (NSMutableDictionary*)dict);
}
- (NSMutableDictionary*) typingAttributes
{	
  if (typingAttributes) 
    return typingAttributes;
  else 
    return [NSMutableDictionary dictionaryWithDictionary: 
				  [self defaultTypingAttributes]];
}

- (void) setTextColor: (NSColor*)color range: (NSRange)range
{
  if ([self isRichText])
    {
      if (color)
	[rtfContent addAttribute: NSForegroundColorAttributeName
			   value: color
			   range: range];
    }
}

- (void) setColor: (NSColor*)color ofRange: (NSRange)range
{
  [self setTextColor: color range: range];
}

- (void)setFont: (NSFont*)obj
{
  ASSIGN(default_font, obj);
}

- (void)setFont: (NSFont *)font ofRange: (NSRange)range
{	
  if ([self isRichText])
    {
      if (font)
	{
	  [rtfContent addAttribute: NSFontAttributeName value: font 
		      range: range];
	  [self rebuildFromCharacterIndex: range.location];
	  NSDebugLLog (@"NSText", @"did set font");
	}
    } 
  else 
    {
    }
}

- (void) setTextColor: (NSColor *)color
{
  ASSIGN (text_color, color);
  if (![self isRichText])
    [self setNeedsDisplay: YES];
}

- (void)setUsesFontPanel: (BOOL)flag
{
  uses_font_panel = flag;
}

//
// Managing the Selection
//
- (NSRange)selectedRange			
{ 
  return selected_range; 
}

- (BOOL) shouldDrawInsertionPoint
{	
  return (selected_range.length == 0) && [self isEditable];
}

- (void) drawInsertionPointInRect: (NSRect)rect
			    color: (NSColor *)color
			 turnedOn: (BOOL)flag
{
  BOOL	didLock  = NO;

  if (!_window)
    return;

  if (_window && [[self class] focusView] != self)
    {
      [self lockFocus];
      didLock  = YES;
    }

  if (flag)
    {
      [color set]; 
      NSRectFill(rect);
    }
  else
    {
      [[self backgroundColor] set];
      NSRectFill(rect);
    }

  if (didLock)
    {
      [self unlockFocus];
      [_window flushWindow];
    }
}

- (void) drawInsertionPointAtIndex: (unsigned)index
			     color: (NSColor*)color
			  turnedOn: (BOOL)flag
{
  NSRect startRect  = [self rectForCharacterIndex: index];
  NSRect drawRect;
  
  drawRect = NSMakeRect (startRect.origin.x, startRect.origin.y,
			 1, startRect.size.height);
  [self drawInsertionPointInRect: drawRect
	color: [NSColor blackColor]
	turnedOn: flag];
}

- (void) drawSelectionAsRangeNoCaret: (NSRange) aRange
{
  if (aRange.length)
    {	
      NSRect startRect = [self rectForCharacterIndex: aRange.location];
      NSRect endRect = [self rectForCharacterIndex: NSMaxRange (aRange)];
      if (startRect.origin.y  == endRect.origin.y)  
	{	
	  // single line selection
	  NSHighlightRect (NSMakeRect (startRect.origin.x, startRect.origin.y, 
				       endRect.origin.x - startRect.origin.x, 
				       startRect.size.height));
	} 
      else if (startRect.origin.y == endRect.origin.y - endRect.size.height) 
	{	
	  // two line selection

	  // first line
	  NSHighlightRect (NSMakeRect (startRect.origin.x, startRect.origin.y, 
				       _frame.size.width - startRect.origin.x, 
				       startRect.size.height));	
	  // second line
	  NSHighlightRect (NSMakeRect (0, endRect.origin.y, endRect.origin.x, 
				       endRect.size.height));	

	} 
      else
	{
	  //   3 Rects: multiline selection

	  // first line
	  NSHighlightRect (NSMakeRect (startRect.origin.x, startRect.origin.y, 
				       _frame.size.width - startRect.origin.x, 
				       startRect.size.height));
	  // intermediate lines
	  NSHighlightRect (NSMakeRect (0, NSMaxY(startRect), 
				       _frame.size.width, 
				       endRect.origin.y - NSMaxY (startRect)));	
	  // last line
	  NSHighlightRect (NSMakeRect (0, endRect.origin.y, endRect.origin.x, 
				       endRect.size.height));	
	}
    }
}

- (void) drawSelectionAsRange: (NSRange) aRange
{
  if (aRange.length)
    {
      [self drawSelectionAsRangeNoCaret: aRange];
    }
  else
    {
      [self drawInsertionPointAtIndex: aRange.location
				color: [NSColor blackColor]
			     turnedOn: YES];
    }
}

// low level selection setting including delegation
- (void) setSelectedRangeNoDrawing: (NSRange)range
{
#if 0
	//<!> ask delegate for selection validation
#endif
	selected_range  = range;
#if 0
	[[NSNotificationCenter defaultCenter] 
	  postNotificationName: NSTextViewDidChangeSelectionNotification 
	  object: self
	  userInfo: [NSDictionary 
		      dictionaryWithObjectsAndKeys: 
			NSStringFromRange (selected_range),
		      NSOldSelectedCharacterRange, nil]];
#endif
}


- (void) setSelectedRange: (NSRange)range
{
  BOOL didLock = NO;
  
  if (!_window)
    return;

  if (_window && [[self class] focusView] != self)
    {
      [self lockFocus];
      didLock = YES;
    }

  if (selected_range.length == 0)	// remove old cursor
    {	
      [self drawInsertionPointAtIndex: selected_range.location 
	    color: nil turnedOn: NO];
    } 
  else
    {
      [self drawSelectionAsRange: selected_range];
    }

  [self setSelectedRangeNoDrawing: range];
  
  if ([self usesFontPanel])	// update fontPanel
    {	
      BOOL isMultiple = NO;
      NSFont *currentFont = nil;
      if ([self isRichText])
	{	
	  if ([rtfContent areMultipleFontsInRange: selected_range]) 
	    isMultiple = YES;
	  else 
	    currentFont = [[rtfContent attribute: NSFontAttributeName 
				       atIndex: range.location 
				       longestEffectiveRange: NULL 
				       inRange: range]
			    objectForKey: NSFontAttributeName];
	} 
      else 
	currentFont = [[self defaultTypingAttributes] 
			objectForKey: NSFontAttributeName];
      [[NSFontPanel sharedFontPanel] setPanelFont: currentFont 
				     isMultiple: isMultiple];
    }
  // display
  if (range.length)
    {	
      // <!>disable caret timed entry
    } 
  else	// no selection
    {
      if ([self isRichText])
	{
	  [self setTypingAttributes: [NSMutableDictionary 
				       dictionaryWithDictionary: 
					 [rtfContent 
					   attributesAtIndex: range.location 
					   effectiveRange: NULL]]];
	}
      // <!>enable caret timed entry
    }
  [self drawSelectionAsRange: range];
  [self scrollRangeToVisible: range];
  
  if (didLock)
    {
      [self unlockFocus];
      [_window flushWindow];
    }
}

//
// Sizing the Frame Rectangle
//
- (void) setFrame: (NSRect)frameRect
{
  [super setFrame: frameRect];
}

- (BOOL) isHorizontallyResizable		
{ 
  return is_horizontally_resizable; 
}
- (BOOL) isVerticallyResizable		
{
  return is_vertically_resizable; 
}
- (NSSize) maxSize 					
{ 
  return maxSize; 
}
- (NSSize) minSize					
{ 
  return minSize; 
}

- (void)setHorizontallyResizable: (BOOL)flag
{	
  is_horizontally_resizable = flag;
}

- (void)setMaxSize: (NSSize)newMaxSize
{	
  maxSize = newMaxSize;
}

- (void)setMinSize: (NSSize)newMinSize
{	
  minSize = newMinSize;
}

- (void) setVerticallyResizable: (BOOL)flag
{	
  is_vertically_resizable = flag;
}

- (unsigned) textLength
{
  if ([self isRichText]) 
    return [rtfContent length];
  else 
    return [plainContent length];
}

- (NSRect) boundingRectForLineRange: (NSRange)lineRange
{	
  NSArray *linesToDraw = [lineLayoutInformation subarrayWithRange: lineRange];
  NSEnumerator *lineEnum;
  _GNULineLayoutInfo *currentInfo;
  NSRect retRect = NSMakeRect (0, 0, 0, 0);
  
  for ((lineEnum = [linesToDraw objectEnumerator]); 
       (currentInfo = [lineEnum nextObject]);)
    {	
      retRect = NSUnionRect (retRect, [currentInfo lineRect]);
    } 
  return retRect;
}

- (void) disableDisplay 
{
  displayDisabled = YES;
}
- (void) reenableDisplay 
{
  displayDisabled = NO;
}

- (void) sizeToFit
{
  NSRect sizeToRect = _frame;
  
  // if we are a field editor we don't have to handle the size.
  if ([self isFieldEditor]) 
    return;

  if ([self isHorizontallyResizable]) 
    {	
      if ([lineLayoutInformation count]) 
	{	
	  sizeToRect = [self boundingRectForLineRange: 
			       NSMakeRange (0, [lineLayoutInformation count])];
	} 
      else 
	sizeToRect.size = minSize;
    } 
  else if ([self isVerticallyResizable]) 
    {
      if ([lineLayoutInformation count]) 
	{	
	  NSRect rect = NSUnionRect([[lineLayoutInformation objectAtIndex: 0]
				      lineRect],
				    [[lineLayoutInformation lastObject] 
				      lineRect]);
	  float newHeight = rect.size.height;
	  float newY;
	  NSRect tRect;

	  if (([[lineLayoutInformation lastObject] type]  
	       == LineLayoutInfoType_Paragraph) 
	      && NSMaxY (rect) <= newHeight)
	    newHeight += [[lineLayoutInformation lastObject] 
			   lineRect].size.height;
	  
	  if ([[self superview] isKindOfClass: [NSClipView class]])
	    tRect  = [(NSClipView*)[self superview] documentVisibleRect];
	  else
	    tRect  = _bounds;
	  
	  if (currentCursorY < tRect.size.height + tRect.origin.y -
	      [[lineLayoutInformation lastObject] lineRect].size.height)
	    newY  = sizeToRect.origin.y;
	  else if (currentCursorY > tRect.size.height + tRect.origin.y -
		   [[lineLayoutInformation lastObject] lineRect].size.height) 
	    {
	      newY  = currentCursorY - tRect.size.height +
		([[lineLayoutInformation lastObject] lineRect].size.height * 2);
	      [(NSClipView *)[self superview] scrollToPoint: 
			       NSMakePoint (sizeToRect.origin.x, newY)];
	    }
	  else
	    NSLog(@" ========= > Oops!\n");
	  
	  newHeight = MIN(maxSize.height,MAX(newHeight,minSize.height));
	  sizeToRect = NSMakeRect(sizeToRect.origin.x,sizeToRect.origin.y,
				  sizeToRect.size.width,newHeight);
	} 
      else 
	sizeToRect = NSMakeRect(0,0,minSize.width,minSize.height);
    }
  
  if (!NSEqualSizes(_frame.size,sizeToRect.size)) {
    [self setFrame: sizeToRect];	//[self setFrameSize: sizeToRect.size];
  }
}

- (void) sizeToFit: sender {[self sizeToFit];}

//
// Responding to Editing Commands
//
- (void) alignCenter: sender
{
}

- (void) alignLeft: sender
{
}

- (void) alignRight: sender
{
}

- (void) selectAll: sender
{	
  [self setSelectedRange: NSMakeRange(0,[self textLength])];
}

- (void) subscript: sender
{
}

- (void) superscript: sender
{
}

- (void) underline: sender
{	
  if ([self isRichText])
    {
      BOOL doUnderline = YES;
      if ([[rtfContent attribute: NSUnderlineStyleAttributeName 
		       atIndex: selected_range.location 
		       effectiveRange: NULL] intValue])	
	doUnderline = NO;
      
      if (selected_range.length)
	{
	  [rtfContent addAttribute: NSUnderlineStyleAttributeName 
		      value: [NSNumber numberWithInt: doUnderline] 
		      range: selected_range];
	  [self rebuildFromCharacterIndex: selected_range.location];
	} 
      else  // no redraw necess.
	[[self typingAttributes] 
	  setObject: [NSNumber numberWithInt: doUnderline] 
	  forKey: NSUnderlineStyleAttributeName];
    }
}

- (void) unscript: sender
{
  if ([self isRichText])
    {
      if (selected_range.length)
	{
	  [rtfContent removeAttribute: NSUnderlineStyleAttributeName 
		      range: selected_range];
	  [self rebuildFromCharacterIndex: selected_range.location];
	} 
      else // no redraw necess.
	[[self typingAttributes] 
	  removeObjectForKey: NSUnderlineStyleAttributeName];	
    }
}

//
// Managing the Ruler
//
- (BOOL) isRulerVisible				
{ 
  return NO; 
}

- (void) toggleRuler: sender
{
}


//
// Scrolling
//

- (void) scrollRangeToVisible: (NSRange)range
{
  [self scrollRectToVisible: 
	  NSUnionRect ([self rectForCharacterIndex: 
			       selected_range.location],
		       [self rectForCharacterIndex: 
			       NSMaxRange (selected_range)])];
}

//
// Reading and Writing RTFD Files
//
- (BOOL) readRTFDFromFile: (NSString *)path
{
  NSData *data = [NSData dataWithContentsOfFile: path];
  id peek;

  if (data && (peek = [[self class] attributedStringForData: data]))
    {	
      is_rich_text = YES; // not [self setRichText: YES] for efficiancy reasons
      [self updateDragTypeRegistration];
      [self replaceRange: NSMakeRange (0, [self textLength]) 
	    withAttributedString: peek];
      [self rebuildLineLayoutInformationStartingAtLine: 0];
      [self setNeedsDisplay: YES];
      return YES;
    }
  return NO;
}

- (BOOL) writeRTFDToFile: (NSString *)path atomically: (BOOL)flag
{	
  if ([self isRichText])
    {
      NSFileWrapper *wrapper = [[[NSFileWrapper alloc] 
				  initRegularFileWithContents: 
				    [[self class] dataForAttributedString: 
						    rtfContent]] autorelease];
      return [wrapper writeToFile: path atomically: flag updateFilenames: YES];
    } 
  return NO;
}

//
// Managing the Field Editor
//
- (BOOL) isFieldEditor 
{ 
  return is_field_editor; 
}

- (void) setFieldEditor: (BOOL)flag
{	
  is_field_editor = flag;
}

- (int) lineLayoutIndexForCharacterIndex: (unsigned) anIndex
{
  NSEnumerator		*lineEnum;
  _GNULineLayoutInfo	*currentInfo;
  
  if ([lineLayoutInformation count] 
      && anIndex >= NSMaxRange ([[lineLayoutInformation lastObject] lineRange]))
    return [lineLayoutInformation count] - 1;
  
  for ((lineEnum = [lineLayoutInformation objectEnumerator]); 
       (currentInfo = [lineEnum nextObject]);)
    {	
      NSRange lineRange = [currentInfo lineRange];
      if (lineRange.location<= anIndex 
	  && (anIndex <= NSMaxRange (lineRange) 
	      - ([currentInfo type] == LineLayoutInfoType_Paragraph? 1: 0)))
	return [lineLayoutInformation indexOfObject: currentInfo];
    }

  if ([lineLayoutInformation count]) 
    NSLog(@"NSText's lineLayoutIndexForCharacterIndex: index out of bounds!");

  return 0;
}

//<!> choose granularity according to keyboard modifier flags

- (void) moveCursorUp: sender
{
  unsigned cursorIndex;
  NSPoint cursorPoint;

  /* Do nothing if we are at beginning of text */
  if (selected_range.location == 0)
    return;

  if (selected_range.length) 
    {
      currentCursorX = [self rectForCharacterIndex: 
			       selected_range.location].origin.x;
      currentCursorY = [self rectForCharacterIndex: 
			       selected_range.location].origin.y;
    }
  cursorIndex = selected_range.location;
  cursorPoint = [self rectForCharacterIndex: cursorIndex].origin;
  cursorIndex = [self characterIndexForPoint: 
			NSMakePoint (currentCursorX + 0.001, 
				     MAX (0, cursorPoint.y - 0.001))];
  [self setSelectedRange: [self selectionRangeForProposedRange: 
				  NSMakeRange (cursorIndex, 0) 
				granularity: NSSelectByCharacter]];

  // FIXME: Terrible hack.
  [self insertText: @""];
}
- (void) moveCursorDown: sender
{
  unsigned cursorIndex;
  NSRect cursorRect;

  /* Do nothing if we are at end of text */
  if (selected_range.location == [self textLength])
    return;

  if (selected_range.length) 
    {
      currentCursorX = [self rectForCharacterIndex: 
			       NSMaxRange (selected_range)].origin.x;
      currentCursorY = [self rectForCharacterIndex: 
			       NSMaxRange (selected_range)].origin.y;
    }
  cursorIndex = selected_range.location;
  cursorRect = [self rectForCharacterIndex: cursorIndex];
  cursorIndex = [self characterIndexForPoint: 
			NSMakePoint (currentCursorX + 0.001, 
				     NSMaxY (cursorRect) + 0.001)];
  [self setSelectedRange: [self selectionRangeForProposedRange: 
				  NSMakeRange (cursorIndex, 0) 
				granularity: NSSelectByCharacter]];
  // FIXME: Terrible hack.
  [self insertText: @""];
}
- (void) moveCursorLeft: sender
{	
  /* Do nothing if we are at beginning of text */
  if (selected_range.location == 0)
    return;

  [self setSelectedRange: 
	  [self selectionRangeForProposedRange: 
		  NSMakeRange (selected_range.location - 1, 0) 
		granularity: NSSelectByCharacter]];
  currentCursorX = [self rectForCharacterIndex: 
			   selected_range.location].origin.x;
}
- (void) moveCursorRight: sender
{
  /* Do nothing if we are at end of text */
  if (selected_range.location == [self textLength])
    return;

  [self setSelectedRange: 
	  [self selectionRangeForProposedRange: 
		  NSMakeRange (MIN (NSMaxRange (selected_range) + 1, 
				    [self textLength]), 0)
		granularity: NSSelectByCharacter]];
  currentCursorX = [self rectForCharacterIndex: 
			   selected_range.location].origin.x;
}

//
// Handling Events 
//
- (void) mouseDown: (NSEvent *)theEvent
{
  NSSelectionGranularity granularity = NSSelectByCharacter;
  NSRange chosenRange, prevChosenRange, proposedRange;
  NSPoint point, startPoint;
  NSEvent *currentEvent;
  unsigned startIndex;
  BOOL didDragging = NO;

  // If not selectable then don't recognize the mouse down  
  if (!is_selectable) 
    return;

  [_window makeFirstResponder: self];
  
  switch ([theEvent clickCount])
    {
    case 1: granularity = NSSelectByCharacter;
      break;
    case 2: granularity = NSSelectByWord;
      break;
    case 3: granularity = NSSelectByParagraph;
      break;
    }
  
  startPoint = [self convertPoint: [theEvent locationInWindow] fromView: nil];
  startIndex = [self characterIndexForPoint: startPoint];
  
  proposedRange = NSMakeRange (startIndex, 0);
  chosenRange = prevChosenRange = [self selectionRangeForProposedRange: 
					  proposedRange 
					granularity: granularity];
  
  [self lockFocus];
  
  // clean up before doing the dragging
  if (selected_range.length == 0)	// remove old cursor
    {
      [self drawInsertionPointAtIndex: selected_range.location 
	    color: nil turnedOn: NO];
    } 
  else 
    [self drawSelectionAsRangeNoCaret: selected_range];
  
  //<!> make this non - blocking (or make use of timed entries)
  for (currentEvent = [_window 
			nextEventMatchingMask: 
			  (NSLeftMouseDraggedMask|NSLeftMouseUpMask)];
       [currentEvent type] != NSLeftMouseUp;
       (currentEvent = [_window 
			 nextEventMatchingMask: 
			   (NSLeftMouseDraggedMask|NSLeftMouseUpMask)]), 
	 prevChosenRange = chosenRange)	// run modal loop
    {
      BOOL didScroll = [self autoscroll: currentEvent];
      point = [self convertPoint: [currentEvent locationInWindow] 
		    fromView: nil];
      proposedRange = MakeRangeFromAbs ([self characterIndexForPoint: point], 
					startIndex);
      chosenRange = [self selectionRangeForProposedRange: proposedRange 
			  granularity: granularity];
      
      if (NSEqualRanges (prevChosenRange, chosenRange))
	{	
	  if (!didDragging)
	    {
	      [self drawSelectionAsRangeNoCaret: chosenRange];
	      [_window flushWindow];
	    }
	  else 
	    continue;
	}
      // this changes the selection without needing instance drawing 
      // (carefully thought out ; - ) 
      if (!didScroll)
	{
	  [self drawSelectionAsRangeNoCaret: 
		  MakeRangeFromAbs (MIN (chosenRange.location, 
					 prevChosenRange.location),
				    MAX (chosenRange.location, 
					 prevChosenRange.location))];
	  [self drawSelectionAsRangeNoCaret: 
		  MakeRangeFromAbs (MIN (NSMaxRange (chosenRange), 
					 NSMaxRange (prevChosenRange)),
				    MAX (NSMaxRange (chosenRange),
					 NSMaxRange (prevChosenRange)))];
	  [_window flushWindow];
	}
      else
	{
	  [self drawRectNoSelection: [self visibleRect]];
	  [self drawSelectionAsRangeNoCaret: chosenRange];
	  [_window flushWindow];
	}
      
      didDragging = YES;
    }
  
  NSDebugLog(@"chosenRange. location  = % d, length  = %d\n",
	     (int)chosenRange.location, (int)chosenRange.length);
  
  [self setSelectedRangeNoDrawing: chosenRange];
  if (!didDragging) 
    [self drawSelectionAsRange: chosenRange];
  else if (chosenRange.length  == 0) 
    [self drawInsertionPointAtIndex: chosenRange.location 
	  color: [NSColor blackColor] turnedOn: YES];
  
  // remember for column stable cursor up/down
  currentCursorX = [self rectForCharacterIndex: chosenRange.location].origin.x;	
  // remember for column stable cursor up/down
  currentCursorY = [self rectForCharacterIndex: chosenRange.location].origin.y;	
  [self unlockFocus];
  [_window flushWindow];
}


- (void) redisplayForLineRange: (NSRange) redrawLineRange
{
  BOOL	didLock = NO;
  
  if (_window && [[self class] focusView] != self)
    {
      [self lockFocus]; 
      didLock = YES;
    }
  
  if ([lineLayoutInformation count] 
      && redrawLineRange.location < [lineLayoutInformation count] 
      && redrawLineRange.length)
    {
      _GNULineLayoutInfo *firstInfo 
	= [lineLayoutInformation objectAtIndex: redrawLineRange.location];
      NSRect displayRect, firstRect = [firstInfo lineRect];
      
      if ([firstInfo type]  == LineLayoutInfoType_Paragraph 
	  && firstRect.origin.x >0 && redrawLineRange.location)
      {	
	redrawLineRange.location--;
	redrawLineRange.length++;
      }
      displayRect 
	= NSUnionRect ([[lineLayoutInformation 
			  objectAtIndex: redrawLineRange.location] 
			 lineRect],
		       [[lineLayoutInformation 
			  objectAtIndex: 
			    MAX (0, (int)NSMaxRange (redrawLineRange) - 1)] 
			 lineRect]);
      
      displayRect.size.width = _frame.size.width - displayRect.origin.x;
      [[self backgroundColor] set]; 
      NSRectFill (displayRect);
       
      if ([self isRichText])
	{	
	  [self drawRichLinesInLineRange: redrawLineRange];
	} 
      else
	{
	  [self drawPlainLinesInLineRange: redrawLineRange];
	}
      [self drawSelectionAsRange: selected_range];
    }
  
  if ([self drawsBackground])	// clean up the remaining area under text of us
    {
      float lowestY = 0;
      NSRect myFrame = _frame;
      
      if ([lineLayoutInformation count]) 
	lowestY = NSMaxY ([[lineLayoutInformation lastObject] lineRect]);
      
      if (![lineLayoutInformation count] 
	  || (lowestY < NSMaxY(myFrame) 
	      && myFrame.size.height <= [self minSize].height))
	{	
	  [[self backgroundColor] set];
	  NSRectFill (NSMakeRect (0, lowestY, myFrame.size.width, 
				  NSMaxY (myFrame) - lowestY));
	  if (![lineLayoutInformation count] 
	      || [[lineLayoutInformation lastObject] 
		   type] == LineLayoutInfoType_Paragraph)
	    [self drawSelectionAsRange: selected_range];
	}
    } 
  
  if (didLock)
    {
      [self unlockFocus];
      [_window flushWindow];
    }
}

- (void) rebuildFromCharacterIndex: (int) anIndex
{
  NSRange redrawLineRange;
  int start;
  int count = [self rebuildLineLayoutInformationStartingAtLine: 
		      start = [self lineLayoutIndexForCharacterIndex: anIndex]];
  redrawLineRange = NSMakeRange (MAX (0, start - 1), count + 1);
  redrawLineRange = NSIntersectionRange (redrawLineRange, 
					 [self lineRangeForRect: 
						 [self visibleRect]]);
  [self redisplayForLineRange: redrawLineRange];
  
  NSLog (NSStringFromRange (redrawLineRange));
}

// central text inserting method (takes care 
// of optimized redraw/ cursor positioning)

- (void) insertText: insertObjc
{
  NSRange selectedRange = selected_range;
  int lineIndex = [self lineLayoutIndexForCharacterIndex: 
			  selectedRange.location]; 
  int origLineIndex = lineIndex;
  int caretLineIndex = lineIndex;
  NSRange redrawLineRange;
  NSString *insertString = nil;
  
  if ([insertObjc isKindOfClass: [NSString class]]) 
    insertString = insertObjc;
  else	
    insertString = [insertObjc string];
  
  // in case e.g a space is inserted and a word actually shortened: 
  //redraw previous line to give it the chance to move up 
  if ([lineLayoutInformation count] 
      && [[lineLayoutInformation objectAtIndex: origLineIndex] 
	   type] != LineLayoutInfoType_Paragraph 
      && origLineIndex 
      && [[lineLayoutInformation objectAtIndex: origLineIndex - 1] 
	   type] != LineLayoutInfoType_Paragraph)
    origLineIndex--;
  
  redrawLineRange = MakeRangeFromAbs (origLineIndex, 
				      [lineLayoutInformation count]);
  
  if ([self isRichText])
    {
      [self replaceRange: selected_range
	    withAttributedString: [insertObjc isKindOfClass: 
						[NSAttributedString class]]? 
	    insertObjc: 
	      [[[NSAttributedString alloc] 
		 initWithString: insertString 
		 attributes: [self typingAttributes]]
		autorelease]];
    } 
  else
    {
      [self replaceRange: selected_range withString: insertString];
    }
  redrawLineRange.length = [self rebuildLineLayoutInformationStartingAtLine: 
				   redrawLineRange.location
				 delta: 
				   [insertString length] - selectedRange.length
				 actualLine: caretLineIndex];
  
  // ScrollView interaction
  [self sizeToFit];
  
  // move cursor <!> [self selectionRangeForProposedRange: ]
  [self 
    setSelectedRange: 
      NSMakeRange (selected_range.location + [insertString length], 0)];

  // remember x for row - stable cursor movements
  currentCursorX = [self rectForCharacterIndex: 
			   selected_range.location].origin.x;

  // remember x for row - stable cursor movements
  currentCursorY = [self rectForCharacterIndex: 
			   selected_range.location].origin.y;
  
  redrawLineRange = NSIntersectionRange (redrawLineRange, 
					 [self lineRangeForRect: 
						 [self visibleRect]]);
  [self redisplayForLineRange: redrawLineRange];
  // broadcast notification
  [[NSNotificationCenter defaultCenter] 
    postNotificationName: NSTextDidChangeNotification 
    object: self];
}

// central text deletion/backspace method 
// (takes care of optimized redraw/ cursor positioning)
- (void) deleteRange: (NSRange) aRange backspace: (BOOL) flag
{	
  int redrawLineIndex, caretLineIndex, firstLineIndex; 
  int lastLineIndex, linePosition;
  NSRange redrawLineRange;
  NSRange deleteRange;
  
  if (!aRange.length && !flag) 
    return;

  if (!aRange.location && ! aRange.length) 
    return;
  
  if (aRange.length) 
    {
      deleteRange = aRange;
      linePosition = deleteRange.location;
    }
  else
    {	
      deleteRange = NSMakeRange (MAX (0, aRange.location - 1), 1);
      linePosition = NSMaxRange (deleteRange); 
    }

  firstLineIndex = caretLineIndex 
    = [self lineLayoutIndexForCharacterIndex: linePosition];

  lastLineIndex 
    = [self lineLayoutIndexForCharacterIndex: NSMaxRange (deleteRange)];

  // since first word may move upward
  redrawLineIndex = MAX (0, firstLineIndex - 1);
  
  if (firstLineIndex 
      && [[lineLayoutInformation objectAtIndex: firstLineIndex - 1] 
	   type]  == LineLayoutInfoType_Paragraph)
    {	
      _GNULineLayoutInfo *upperInfo 
	= [lineLayoutInformation objectAtIndex: firstLineIndex];
      _GNULineLayoutInfo *prevInfo 
	= [lineLayoutInformation objectAtIndex: firstLineIndex - 1];

      if (linePosition > [upperInfo lineRange].location)
	redrawLineIndex++; // no danger of word moving up
      else if ([prevInfo lineRect].origin.x > 0)
	redrawLineIndex--; // remove newline: skip paragraph - terminating infoObject
      redrawLineIndex = MAX (0, redrawLineIndex);
    }

  redrawLineIndex = MIN (redrawLineIndex, [lineLayoutInformation count] - 1);
  redrawLineRange = MakeRangeFromAbs (redrawLineIndex, 
				      [lineLayoutInformation count]);
  
  if ([self isRichText])
    [rtfContent   deleteCharactersInRange: deleteRange];
  else
    [plainContent deleteCharactersInRange: deleteRange];
  
  redrawLineRange.length 
    = [self rebuildLineLayoutInformationStartingAtLine: redrawLineRange.location
	    delta: - deleteRange.length
	    actualLine: caretLineIndex];
  
  // ScrollView interaction
  [self sizeToFit];

  // move cursor <!> [self selectionRangeForProposedRange: ]
  [self setSelectedRange: NSMakeRange (deleteRange.location, 0)];
  
  // remember x for row - stable cursor movements
  currentCursorX = [self rectForCharacterIndex: 
			   selected_range.location].origin.x;		
  
  // remember x for row - stable cursor movements
  currentCursorY = [self rectForCharacterIndex: 
			   selected_range.location].origin.y;		

  redrawLineRange 
    = NSIntersectionRange (redrawLineRange, 
			   [self lineRangeForRect: [self visibleRect]]);
  [self redisplayForLineRange: redrawLineRange];
  
  // broadcast notification
  [[NSNotificationCenter defaultCenter] 
    postNotificationName: NSTextDidChangeNotification 
    object: self];
}


- (void) keyDown: (NSEvent *)theEvent
{	
  unsigned short keyCode;
  
  // If not editable then don't recognize the key down
  if (!is_editable) 
    {
      [super keyDown: theEvent];
      return;
    }					
  
  keyCode = [theEvent keyCode];

  // Some keys are extremely special if we are field editor 
  if ([self isFieldEditor]) 
    {
      int notNumber = NSIllegalTextMovement;
      
      switch (keyCode)
	{	
	case NSUpArrowFunctionKey:
	  notNumber = NSUpTextMovement;
	  break;
	case NSDownArrowFunctionKey:
	  notNumber = NSDownTextMovement;
	  break;
	case NSLeftArrowFunctionKey:
	  //notNumber = NSLeftTextMovement;
	  break;
	case NSRightArrowFunctionKey:
	  //notNumber = NSRightTextMovement;
	  break;
	case NSCarriageReturnKey: 
	  notNumber = NSReturnTextMovement;
	  break;
	case 0x09: 
	  if ([theEvent modifierFlags] & NSShiftKeyMask)
	    notNumber = NSBacktabTextMovement;
	  else 
	    notNumber = NSTabTextMovement;
	  break;
	}
      if (notNumber != NSIllegalTextMovement)
	{
	  // This is similar to [self resignFirstResponder],
	  // with the difference that in the notification we need
	  // to put the NSTextMovement, which resignFirstResponder
	  // does not.  Also, if we are ending editing, we are going 
	  // to be removed, so it's useless to update any drawing.
	  NSNumber *number;
	  NSDictionary *uiDictionary;
	  
	  if (([self isEditable]) 
	      && ([delegate respondsToSelector: 
			      @selector(textShouldEndEditing:)])
	      && ([delegate textShouldEndEditing: self] == NO))
	    return;
	  
	  // Add any clean-up stuff here
	  
	  number = [NSNumber numberWithInt: notNumber];
	  uiDictionary = [NSDictionary dictionaryWithObject: number
				       forKey: @"NSTextMovement"];
	  [[NSNotificationCenter defaultCenter] 
	    postNotificationName: NSTextDidEndEditingNotification 
	    object: self
	    userInfo: uiDictionary]; 
	  return;
	}
    }

  // Special Characters for generic NSText
  switch (keyCode)
    {	
    case NSUpArrowFunctionKey: 
      [self moveCursorUp: self];
      return;
    case NSDownArrowFunctionKey:
      [self moveCursorDown: self];
      return;
    case NSLeftArrowFunctionKey:
      [self moveCursorLeft: self];
      return;
    case NSRightArrowFunctionKey:
      [self moveCursorRight: self];
      return;
    case NSDeleteFunctionKey:
      if (selected_range.location != [self textLength])
	{
	  /* Not at the end of text -- delete following character */
	  [self deleteRange: 
		  [self selectionRangeForProposedRange: 
			  NSMakeRange (selected_range.location, 1)
			granularity: NSSelectByCharacter]
		backspace: NO];
	  return;
	}
      /* end of text: behave the same way as NSBackspaceKey */
    case NSBackspaceKey: 
      [self deleteRange: selected_range backspace: YES];
      return;
#if 1
    case 0x6d: 	// end - key: debugging: enforce complete re - layout
      [lineLayoutInformation autorelease]; 
      lineLayoutInformation = nil;
      [self rebuildLineLayoutInformationStartingAtLine: 0];
      [self setNeedsDisplay: YES];
      return;
#endif
#if 1
      // TODO: Choose another key
    case 0x45: 	// num - lock: debugging
      NSLog ([lineLayoutInformation description]);
      return;
#endif
    case NSCarriageReturnKey:
      NSLog (@"\bCarriage return.\b\n");
      [self insertText: [[self class] newlineString]];
      return;
    }
  
  // If the character(s) was not a special one, simply insert it.
  [self insertText: [theEvent characters]];
}

- (BOOL) acceptsFirstResponder
{	
  if ([self isSelectable]) 
    return YES;
  else 
    return NO;
}

- (BOOL) resignFirstResponder
{	
  if (([self isEditable]) 
      && ([delegate respondsToSelector: @selector(textShouldEndEditing:)])
      && ([delegate textShouldEndEditing: self] == NO))
    return NO;
  
  // Add any clean-up stuff here

  if ([self shouldDrawInsertionPoint])
    {
      [self drawInsertionPointAtIndex: selected_range.location 
	    color: nil turnedOn: NO];
      
      //<!> stop timed entry
    }

  [[NSNotificationCenter defaultCenter] 
    postNotificationName: NSTextDidEndEditingNotification 
    object: self];
  return YES;
}

- (BOOL) becomeFirstResponder
{
  if ([self isSelectable] == NO) 
    return NO;
  
  if (([delegate respondsToSelector: @selector(textShouldBeginEditing:)])
      && ([delegate textShouldBeginEditing: self] == NO))
    return NO;
  
  // Add any initialization stuff here.
  
  //if ([self shouldDrawInsertionPoint])
  //  {
  //   [self lockFocus];
  //   [self drawInsertionPointAtIndex: selected_range.location 
  //      color: [NSColor blackColor] turnedOn: YES];
  //   [self unlockFocus];
  //   //<!> restart timed entry
  //  }
  [[NSNotificationCenter defaultCenter] 
    postNotificationName: NSTextDidBeginEditingNotification 
    object: self];
  return YES;
}

/*
 * Managing the Delegate
 */
- (id) delegate
{
  return delegate;
}

- (void) setDelegate: (id)anObject
{
  NSNotificationCenter *nc  = [NSNotificationCenter defaultCenter];

  if (delegate)
    [nc removeObserver: delegate name: nil object: self];
  ASSIGN(delegate, anObject);

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([delegate respondsToSelector: @selector(text##notif_name:)]) \
    [nc addObserver: delegate \
          selector: @selector(text##notif_name:) \
              name: NSText##notif_name##Notification \
            object: self]  
  
  SET_DELEGATE_NOTIFICATION(DidBeginEditing);
  SET_DELEGATE_NOTIFICATION(DidChange);
  SET_DELEGATE_NOTIFICATION(DidEndEditing);
}

- (NSRange) characterRangeForBoundingRect: (NSRect)boundsRect
{
  NSRange lineRange = [self lineRangeForRect: boundsRect];

  if (lineRange.length) 
    return MakeRangeFromAbs ([[lineLayoutInformation 
				objectAtIndex: lineRange.location] 
			       lineRange].location,
			     NSMaxRange ([[lineLayoutInformation 
					    objectAtIndex: 
					      NSMaxRange (lineRange)] 
					   lineRange]));
  else 
    return NSMakeRange (0, 0);
}


- (unsigned) characterIndexForPoint: (NSPoint)point
{
  int i;
  NSEnumerator *lineEnum;
  _GNULineLayoutInfo *currentInfo;
  NSDictionary *attributes = [self defaultTypingAttributes];

  if (point.y >= NSMaxY([[lineLayoutInformation lastObject] lineRect])) 
    return [self textLength];
  
  point.x = MAX(0,point.x); point.y = MAX(0,point.y);
  
  for (i = 0, (lineEnum = [lineLayoutInformation objectEnumerator]);
       (currentInfo = [lineEnum nextObject]);
       i++)
    {	
      NSRect rect = [currentInfo lineRect];

      if (NSMaxY(rect)>= point.y 
	  && rect.origin.y<point.y 
	  && rect.origin.x< point.x 
	  && point.x >= NSMaxX(rect)) 
	return NSMaxRange ([currentInfo lineRange]);

      // this loop holds some optimization potential (linear search)
      if (NSPointInRect (point, rect))
	{	
	  int retPos = 0;
	  NSRange range = [currentInfo lineRange];
	  
	  for (retPos = range.location; retPos<= NSMaxRange(range); retPos++)
	    // this loop holds some optimization potential (linear search)
	    {
	      NSString *evalString = nil;
	      
	      if ([self isRichText])
		{
		  if ([rtfContent 
			sizeRange: 
			  NSMakeRange (range.location, 
				       retPos - range.location)].width 
		      >= point.x) 
		    return MAX (0, retPos - 1);
		} 
	      else
		{
		  evalString = [plainContent 
				 substringWithRange: 
				   NSMakeRange (range.location, 
						retPos - range.location)];
		  if ([evalString sizeWithAttributes: attributes].width 
		      >= point.x) 
		    return MAX (0, retPos - 1);
		}
	    } 
	  return range.location;
	}
    } 
  NSLog (@"NSText's characterIndexForPoint: index not found!");
  return 0;
}

// rect to the end of line
- (NSRect) rectForCharacterIndex: (unsigned) index
{
  int i;
  NSEnumerator *lineEnum;
  _GNULineLayoutInfo *currentInfo;
  NSDictionary *attributes = [self defaultTypingAttributes];

  if (![lineLayoutInformation count]) 
    return NSMakeRect (0, 0, _frame.size.width, 
		       [[[self class] newlineString] 
			 sizeWithAttributes: attributes].height);
  
  if (index >= NSMaxRange([[lineLayoutInformation lastObject] lineRange]))
    {	
      NSRect rect = [[lineLayoutInformation lastObject] lineRect];
      if (NSMaxX (rect) >= _frame.size.width)
	{	
	  return NSMakeRect (0, NSMaxY(rect), 
			     _frame.size.width, rect.size.height);
	}
      return NSMakeRect (NSMaxX (rect), rect.origin.y, 
			 _frame.size.width - NSMaxX (rect),
			 rect.size.height);
    }
  
  for (i = 0, (lineEnum = [lineLayoutInformation objectEnumerator]);
       (currentInfo = [lineEnum nextObject]); i++)
    {	
      NSRange	range = [currentInfo lineRange];
      if (NSLocationInRange (index, range))
	{	
	  NSRect rect = [currentInfo lineRect];
	  if ([self isRichText])
	    {
	      NSSize stringSize 
		= [rtfContent sizeRange: 
				MakeRangeFromAbs (range.location, index)];
	      float x = rect.origin.x + stringSize.width;
	      
	      return NSMakeRect (x, rect.origin.y, NSMaxX (rect) - x, 
				 rect.size.height);
	    } 
	  else
	    {
	      NSString *evalString 
		= [plainContent substringWithRange: 
				  MakeRangeFromAbs (range.location, index)];
	      NSSize stringSize = [evalString sizeWithAttributes: attributes];
	      float x = rect.origin.x + stringSize.width;

	      return NSMakeRect (x, rect.origin.y, NSMaxX (rect) - x,
				 rect.size.height);
	    }
	}
    }
  NSLog (@"NSText's rectForCharacterIndex: rect not found!");
  return NSZeroRect;
}

- (unsigned) lineLayoutIndexForPoint: (NSPoint)point
{	
  int i;
  NSEnumerator *lineEnum;
  _GNULineLayoutInfo *currentInfo;
  NSDictionary *attributes = [self defaultTypingAttributes];
  
  if  (point.y >= NSMaxY ([[lineLayoutInformation lastObject] lineRect])) 
    return [lineLayoutInformation count] - 1;
  
  point.x = MAX (0, point.x); 
  point.y = MAX (0, point.y);
  
  for (i = 0, (lineEnum = [lineLayoutInformation objectEnumerator]); 
       (currentInfo = [lineEnum nextObject]); i++)
    {
      NSRect rect = [currentInfo lineRect];
      if (NSMaxY(rect) > point.y 
	  && rect.origin.y <= point.y 
	  && rect.origin.x < point.x 
	  && point.x >= NSMaxX (rect))
	return [lineLayoutInformation indexOfObject: currentInfo];
      if (NSPointInRect (point, rect))	
	{
	  // this loop holds some optimization potential (linear search)
	  int retPos = 0;
	  NSRange range = [currentInfo lineRange];
	  
	  // this loop holds some optimization potential (linear search)
	  for (retPos = range.location; retPos<= NSMaxRange (range); retPos++)
	    {
	      NSString *evalString = nil;
	      
	      if ([self isRichText])
		{	
		  if ([rtfContent 
			sizeRange: 
			  NSMakeRange (range.location, 
				       retPos - range.location)].width 
		      >= point.x)
		    return [lineLayoutInformation indexOfObject: currentInfo];
		} 
	      else
		{
		  evalString 
		    = [plainContent substringWithRange: 
				      NSMakeRange (range.location, 
						   retPos - range.location)];
		  if ([evalString sizeWithAttributes: attributes].width 
		      >= point.x) 
		    return [lineLayoutInformation indexOfObject: currentInfo];
		}
	    } 
	  return [lineLayoutInformation indexOfObject: currentInfo];
	}
    } 
  return 0;
}

// internal method <!> range is currently not passed as absolute
- (void) addNewlines: (NSRange) aRange 
     intoLayoutArray: (NSMutableArray*) anArray 
	  attributes: (NSDictionary*) attributes 
	     atPoint: (NSPoint*) aPointP
	       width: (float) width 
      characterIndex: (unsigned) startingLineCharIndex 
     ghostEnumerator: (_GNUSeekableArrayEnumerator*) prevArrayEnum
	    didShift: (BOOL*) didShift 
verticalDisplacement: (float*) verticalDisplacement
{	
  NSSize advanceSize = [[[self class] newlineString] 
			 sizeWithAttributes: attributes];
  int count = aRange.length,charIndex;
  _GNULineLayoutInfo *thisInfo,*ghostInfo = nil;
  BOOL isRich = [self isRichText];
  
  (*didShift) = NO;
  
  for (charIndex = aRange.location; --count >= 0; charIndex++)
    {
      NSRect currentLineRect;
      
      if (0 && isRich)
	{
	  advanceSize = [rtfContent sizeRange: 
				      NSMakeRange (startingLineCharIndex, 1)];
	}
      currentLineRect = NSMakeRect (aPointP ->x, aPointP ->y, 
				    width - aPointP ->x, advanceSize.height);
      [anArray addObject: 
		 thisInfo = [_GNULineLayoutInfo 
			      lineLayoutWithRange: 
				NSMakeRange (startingLineCharIndex, 1) 
			      rect: currentLineRect 
			      drawingOffset: 0 
			      type: LineLayoutInfoType_Paragraph]];
      
      startingLineCharIndex++; 
      aPointP ->x = 0; 
      aPointP ->y += advanceSize.height;
      
      if (prevArrayEnum && !(ghostInfo = [prevArrayEnum nextObject])) 
	prevArrayEnum = nil;
      
      if (ghostInfo && ([thisInfo type] != [ghostInfo type]))
	{
	  _GNULineLayoutInfo *prevInfo = [prevArrayEnum previousObject];
	  prevArrayEnum = nil;
	  (*didShift) = YES;
	  (*verticalDisplacement) += aPointP ->y - [prevInfo lineRect].origin.y;
	}
    }
}

// private helper function
static unsigned 
_relocLayoutArray (NSMutableArray *lineLayoutInformation,
		   NSArray *ghostArray, 
		   int aLine,
		   int relocOffset,
		   int rebuildLineDrift,
		   float yReloc)
{	
  // lines actually updated (optimized drawing)
  unsigned ret = [lineLayoutInformation count] - aLine;	
  NSArray *relocArray 
    = [ghostArray subarrayWithRange: 
		    MakeRangeFromAbs (MAX (0, ret + rebuildLineDrift), 
				      [ghostArray count])];
  NSEnumerator *relocEnum;
  _GNULineLayoutInfo *currReloc;
  
  if (![relocArray count]) 
    return ret;
  
  for ((relocEnum = [relocArray objectEnumerator]); 
       (currReloc = [relocEnum nextObject]);)
    {
      NSRange range = [currReloc lineRange];
      [currReloc setLineRange: NSMakeRange (range.location + relocOffset, 
					    range.length)];
      if (yReloc)
	{
	  NSRect rect = [currReloc lineRect];
	  [currReloc setLineRect: NSMakeRect (rect.origin.x, 
					      rect.origin.y + yReloc, 
					      rect.size.width, 
					      rect.size.height)];
	}
    }
  [lineLayoutInformation addObjectsFromArray: relocArray];
  return ret;
}


// begin: central line formatting method---------------------------------------
// returns count of lines actually updated
// <!> detachNewThreadSelector: selector toTarget: target withObject: argument;

- (int) rebuildLineLayoutInformationStartingAtLine: (int) aLine 
					     delta: (int) insertionDelta 
					actualLine: (int) insertionLineIndex
{
  NSDictionary		*attributes = [self defaultTypingAttributes];
  NSPoint		drawingPoint = NSZeroPoint;
  NSScanner		*pScanner;
  float			width = _frame.size.width;
  unsigned		startingIndex = 0,currentLineIndex;
  _GNULineLayoutInfo	*lastValidLineInfo = nil;
  NSArray		*ghostArray = nil;	// for optimization detection
  _GNUSeekableArrayEnumerator *prevArrayEnum = nil;
  NSCharacterSet *invSelectionWordGranularitySet 
    = [selectionWordGranularitySet invertedSet];
  NSCharacterSet *invSelectionParagraphGranularitySet 
    = [selectionParagraphGranularitySet invertedSet];
  NSString *parsedString;
  BOOL isHorizontallyResizable = [self isHorizontallyResizable];
  int lineDriftOffset = 0, rebuildLineDrift = 0;
  BOOL frameshiftCorrection = NO, nlDidShift = NO, enforceOpti = NO;
  float	yDisplacement = 0;
  BOOL isRich = [self isRichText];

  if (!lineLayoutInformation) 
    lineLayoutInformation = [[NSMutableArray alloc] init];
  else
    {
      // remember old array for optimization purposes
      ghostArray 
	= [lineLayoutInformation 
	    subarrayWithRange: 
	      NSMakeRange (aLine, [lineLayoutInformation count] - aLine)];
      // every time an object is added to lineLayoutInformation 
      // a nextObject has to be performed on prevArrayEnum!
      prevArrayEnum = [ghostArray seekableEnumerator];	
    }
  
  if (aLine)
    {
      lastValidLineInfo = [lineLayoutInformation objectAtIndex: aLine - 1];
      drawingPoint = [lastValidLineInfo lineRect].origin;
      drawingPoint.y += [lastValidLineInfo lineRect].size.height;
      startingIndex = NSMaxRange([lastValidLineInfo lineRange]);
    }
  if ([lastValidLineInfo type] == LineLayoutInfoType_Paragraph)
    {
      drawingPoint.x = 0;
    } 
  // keep paragraph - terminating space on same line as paragraph
  if ((((int)[lineLayoutInformation count]) - 1) >= aLine)	
    {
      _GNULineLayoutInfo *anchorLine 
	= [lineLayoutInformation objectAtIndex: aLine];
      NSRect anchorRect = [anchorLine lineRect];

      if (anchorRect.origin.x > drawingPoint.x 
	  && [lastValidLineInfo lineRect].origin.y == anchorRect.origin.y)
	{
	  drawingPoint = anchorRect.origin;
	}
    }
  
  [lineLayoutInformation 
    removeObjectsInRange: 
      NSMakeRange (aLine, [lineLayoutInformation count] - aLine)];

  currentLineIndex = aLine;
  
// each paragraph

  parsedString = [[self string] substringFromIndex: startingIndex];
  pScanner = [NSScanner scannerWithString: parsedString];
  [pScanner setCharactersToBeSkipped: nil];
  while ([pScanner isAtEnd] == NO)
    {
      NSScanner	*lScanner;
      NSString	*paragraph;
      NSRange	paragraphRange, leadingNlRange, trailingNlRange;
      unsigned	currentLoc = [pScanner scanLocation];
      unsigned	startingParagraphIndex = currentLoc + startingIndex; 
      unsigned	startingLineCharIndex = startingParagraphIndex;
      BOOL	isBuckled = NO, inBuckling = NO;

      leadingNlRange
	= scanRange(pScanner, selectionParagraphGranularitySet);
      paragraphRange
	= scanRange(pScanner, invSelectionParagraphGranularitySet);
      trailingNlRange
	= scanRange(pScanner, selectionParagraphGranularitySet);

      if (leadingNlRange.length > 0)
	{
	  [self addNewlines: leadingNlRange
	    intoLayoutArray: lineLayoutInformation 
		 attributes: attributes 
		    atPoint: &drawingPoint 
		      width: width
	     characterIndex: startingLineCharIndex 
	    ghostEnumerator: prevArrayEnum
		   didShift: &nlDidShift 
       verticalDisplacement: &yDisplacement];

	  if (nlDidShift)
	    {
	      if (insertionDelta  == 1)
		{
		  frameshiftCorrection = YES;
		  rebuildLineDrift--;
		}
	      else if (insertionDelta  == - 1)
		{
		  frameshiftCorrection = YES;
		  rebuildLineDrift++;
		}
	      else nlDidShift = NO;
	    }
	  
	  startingLineCharIndex += leadingNlRange.length; 
	  currentLineIndex += leadingNlRange.length;
	}

      
      // each line
      paragraph = [parsedString substringWithRange: paragraphRange];
      lScanner = [NSScanner scannerWithString: paragraph];
      [lScanner setCharactersToBeSkipped: nil];
      while ([lScanner isAtEnd] == NO)
	{
	  NSRect	currentLineRect = NSMakeRect (0, drawingPoint.y, 0, 0);
	  // starts with zero, do not confuse with startingLineCharIndex
	  unsigned	localLineStartIndex = [lScanner scanLocation];
	  NSSize	advanceSize = NSZeroSize;
	  
	  // scan the individual words to the end of the line
	  for (; ![lScanner isAtEnd]; drawingPoint.x += advanceSize.width)
	    {
	      NSRange	currentStringRange, trailingSpacesRange; 
	      NSRange	leadingSpacesRange;
	      unsigned	scannerPosition = [lScanner scanLocation];
	      
	      // snack next word
	      
	      // leading spaces: only first time
	      leadingSpacesRange
		= scanRange(lScanner, selectionWordGranularitySet);
	      currentStringRange
		= scanRange(lScanner, invSelectionWordGranularitySet);
	      trailingSpacesRange
		= scanRange(lScanner, selectionWordGranularitySet);

	      if (leadingSpacesRange.length) 
		currentStringRange = NSUnionRange(leadingSpacesRange, 
						   currentStringRange);
	      if (trailingSpacesRange.length) 
		currentStringRange = NSUnionRange(trailingSpacesRange, 
						   currentStringRange);
	      
	      // evaluate size of current word and line so far
	      if (isRich)	
		advanceSize 
		  = [rtfContent 
		      sizeRange: 
			NSMakeRange (currentStringRange.location + paragraphRange.location + startingIndex, 
				     currentStringRange.length)];
	      else		
		advanceSize = [[paragraph substringWithRange: 
					    currentStringRange] 
				sizeWithAttributes: attributes];

	      currentLineRect = NSUnionRect (currentLineRect, 
					     NSMakeRect (drawingPoint.x, 
							 drawingPoint.y, 
							 advanceSize.width, 
							 advanceSize.height));
	      
	      // handle case where single word is broader than width 
	      // (buckle word) <!> unfinished and untested 
	      // for richText (absolute position see above)
	      if (!isHorizontallyResizable && advanceSize.width >= width)
		{	
		  if (isBuckled)
		    {
		      NSSize currentSize = NSMakeSize (HUGE, 0);
		      unsigned lastVisibleCharIndex;
		      
		      for (lastVisibleCharIndex 
			     = startingLineCharIndex + currentStringRange.length;
			   currentSize.width>= width 
			     && lastVisibleCharIndex> startingLineCharIndex;
			   lastVisibleCharIndex--)
			{
			  if (isRich)
			    {
			      currentSize 
				= [rtfContent 
				    sizeRange: 
				      MakeRangeFromAbs (startingLineCharIndex, 
							lastVisibleCharIndex)];
			    } 
			  else
			    {
			      NSString *evalString 
				= [plainContent 
				    substringWithRange: 
				      MakeRangeFromAbs (startingLineCharIndex, 
							lastVisibleCharIndex)];
			      currentSize 
				= [evalString sizeWithAttributes: attributes];
			    }
			}
		      isBuckled = NO; 
		      inBuckling = YES;
		      scannerPosition 
			= localLineStartIndex 
			+ (lastVisibleCharIndex - startingLineCharIndex);
		      currentLineRect.size.width = advanceSize.width = width;
		    }
		  else	
		    {
		      // undo layout of extralarge word 
		      // (will be done the next line [see above])
		      isBuckled = YES;
		      currentLineRect.size.width -= advanceSize.width;
		    }
		}
	      
	      // end of line -> word wrap
	      
	      // >= : wichtig för abknicken (isBuckled)
	      if (!isHorizontallyResizable 
		  && (currentLineRect.size.width >= width || isBuckled))				{
		_GNULineLayoutInfo *ghostInfo = nil, *thisInfo;
		
		// undo layout of last word
		[lScanner setScanLocation: scannerPosition];	
		  
		currentLineRect.origin.x = 0; 
		currentLineRect.origin.y = drawingPoint.y;
		drawingPoint.y += currentLineRect.size.height; 
		drawingPoint.x = 0;
		  
		[lineLayoutInformation 
		  addObject: (thisInfo 
			      = [_GNULineLayoutInfo 
				  lineLayoutWithRange: 
				    NSMakeRange (startingLineCharIndex, 
						 scannerPosition - localLineStartIndex)
				  rect: currentLineRect 
				  drawingOffset: 0 
				  type: LineLayoutInfoType_Text])];
		
		currentLineIndex++;
		startingLineCharIndex = NSMaxRange([thisInfo lineRange]);
		
		if (prevArrayEnum 
		    && !(ghostInfo = [prevArrayEnum nextObject])) 
		  prevArrayEnum = nil;
		
		// optimization stuff 
		// (do relayout only as much lines as necessary 
		// and patch the rest)---------
		if (ghostInfo)
		  {	
		    if ([ghostInfo type] != [thisInfo type])	
		      {
			// frameshift correction
			frameshiftCorrection = YES;
			if (insertionDelta  == - 1)
			  {
			    // deletition of newline
			    _GNULineLayoutInfo *nextObject;
			    if (!(nextObject = [prevArrayEnum nextObject])) 
			      prevArrayEnum = nil;
			    else
			      {
				if (nlDidShift && frameshiftCorrection)
				  {
				    //	frameshiftCorrection = NO;
#if 0
				    NSLog(@"opti hook 1 (preferred)");
#endif
				  } 
				else
				  {
				    lineDriftOffset 
				      += ([thisInfo lineRange].length 
					  - [ghostInfo lineRange].length 
					  - [nextObject lineRange].length);
				    yDisplacement 
				      += [thisInfo lineRect].origin.y 
				      - [nextObject lineRect].origin.y;
				    rebuildLineDrift++;
				  }
			      }
			  }
		      }
		    else 
		      lineDriftOffset += ([thisInfo lineRange].length 
					  - [ghostInfo lineRange].length);
		    
		    // is it possible to simply patch layout changes 
		    // into layout array instead of doing a time 
		    // consuming re - layout of the whole doc?
		    if ((currentLineIndex - 1 > insertionLineIndex 
			 && !inBuckling && !isBuckled) 
			&& (!(lineDriftOffset - insertionDelta) 
			    || (nlDidShift && !lineDriftOffset) 
			    || enforceOpti))
		      {
			unsigned erg = _relocLayoutArray (lineLayoutInformation,
							  ghostArray,
							  aLine,
							  insertionDelta, 
							  rebuildLineDrift,
							  yDisplacement);
			
			// y displacement: redisplay all remaining lines
			if (frameshiftCorrection) 
			  erg = [lineLayoutInformation count] - aLine;	
			else if (currentLineIndex - 1  == insertionLineIndex 
				 && ABS(insertionDelta) == 1)
			  {	
			    // return 2: redisplay only this and previous line
			    erg = 2;
			  }
#if 0
			NSLog(@"opti for: %d",erg);
#endif
			return erg;
		      }
		  }
		// end: optimization stuff--------------------------
		// -----------------------------------------------
		break;
		
		// newline - induced premature lineending: flush
	      } 
	      else if ([lScanner isAtEnd])
		{
		  _GNULineLayoutInfo *thisInfo;
		  scannerPosition = [lScanner scanLocation];
		  [lineLayoutInformation 
		    addObject: (thisInfo 
				= [_GNULineLayoutInfo 
				    lineLayoutWithRange: 
				      NSMakeRange (startingLineCharIndex, 
						   scannerPosition - localLineStartIndex)
				    rect: currentLineRect 
				    drawingOffset: 0 
				    type: LineLayoutInfoType_Text])];
		  currentLineIndex++;
		  startingLineCharIndex = NSMaxRange ([thisInfo lineRange]);
		  
		  // check for optimization (lines after paragraph 
		  // are unchanged and do not need redisplay/relayout)------
		  if (prevArrayEnum)
		    {
		      _GNULineLayoutInfo *ghostInfo = nil;
		      
		      ghostInfo = [prevArrayEnum nextObject];
		      
		      if (ghostInfo)
			{
			  if ([ghostInfo type] != [thisInfo type])	
			    {
			      // frameshift correction for inserted newline
			      frameshiftCorrection = YES;
			      
			      if (insertionDelta  == 1)
				{
				  [prevArrayEnum previousObject];
				  lineDriftOffset 
				    += ([thisInfo lineRange].length 
					- [ghostInfo lineRange].length) + insertionDelta;
				  rebuildLineDrift--;
				  yDisplacement 
				    += [thisInfo lineRect].origin.y 
				    - [ghostInfo lineRect].origin.y;
				} 
			      else if (insertionDelta  == - 1)
				{	
				  if (nlDidShift && frameshiftCorrection)
				    {
				      //	frameshiftCorrection = NO;
#if 0
				      NSLog(@"opti hook 2");
#endif
				    }
				}
			    }
			  else 
			    lineDriftOffset 
			      += ([thisInfo lineRange].length 
				  - [ghostInfo lineRange].length);
			} 
		      else 
			{
			  // new array obviously longer than the previous one
			  prevArrayEnum = nil;
			}	
		      // end: optimization stuff------------------------------
		      // -------------------------------------------
		    }
		}
	    }
	}
      // add the trailing newlines of current paragraph if any
      if (trailingNlRange.length)
	{	
	  [self addNewlines: trailingNlRange 
		intoLayoutArray: lineLayoutInformation 
		attributes: attributes 
		atPoint: &drawingPoint 
		width: width
		characterIndex: startingLineCharIndex 
		ghostEnumerator: prevArrayEnum
		didShift: &nlDidShift 
		verticalDisplacement: &yDisplacement];
	  if (nlDidShift)
	    {
	      if (insertionDelta == 1)
		{
		  frameshiftCorrection = YES;
		  rebuildLineDrift--;
		}
	      else if (insertionDelta == - 1)
		{
		  frameshiftCorrection = YES;
		  rebuildLineDrift++;
		}
	      else nlDidShift = NO;
	    }
	  currentLineIndex += trailingNlRange.length;
	}
    }
  
  // lines actually updated (optimized drawing)
  return [lineLayoutInformation count] - aLine;	
}
// end: central line formatting method------------------------------------

- (int) rebuildLineLayoutInformationStartingAtLine: (int) aLine
{
  return [self rebuildLineLayoutInformationStartingAtLine: aLine 
	       delta: 0 actualLine: 0];
}

// relies on lineLayoutInformation
- (void) drawPlainLinesInLineRange: (NSRange) aRange
{	
  if (NSMaxRange (aRange) > MAX (0, [lineLayoutInformation count] - 1))	
    {
      // lay out lines before drawing them
      [self rebuildLineLayoutInformationStartingAtLine: 
	      MAX (0, [lineLayoutInformation count] - 1)];
    }

  {	
    NSArray *linesToDraw = [lineLayoutInformation subarrayWithRange: aRange];
    NSEnumerator *lineEnum;
    _GNULineLayoutInfo *currentInfo;
    NSDictionary *attributes = [self defaultTypingAttributes];
    
    for ((lineEnum = [linesToDraw objectEnumerator]);
	 (currentInfo = [lineEnum nextObject]);)
      {	
	if ([currentInfo isDontDisplay] 
	    || [currentInfo type] == LineLayoutInfoType_Paragraph) 
	  continue;	// e.g. for nl
	
	[[plainContent substringWithRange: [currentInfo lineRange]] 
	  drawAtPoint: [currentInfo lineRect].origin 
	  withAttributes: attributes];
	// <!> make this use drawInRect: withAttributes: in the future 
	// (for proper adoption of layout information [e.g. centering])
      }
  }
}

- (void) drawRichLinesInLineRange: (NSRange) aRange
{	
  if (NSMaxRange(aRange) > [lineLayoutInformation count] - 1)
    // lay out lines before drawing them
    {
      [self rebuildLineLayoutInformationStartingAtLine: 
	      [lineLayoutInformation count] - 1];
    }

  {
    NSArray *linesToDraw = [lineLayoutInformation subarrayWithRange: aRange];
    NSEnumerator *lineEnum;
    _GNULineLayoutInfo	*currentInfo;
    
    for ((lineEnum = [linesToDraw objectEnumerator]);
	 (currentInfo = [lineEnum nextObject]);)
      {
	if ([currentInfo isDontDisplay] 
	    || [currentInfo type]  == LineLayoutInfoType_Paragraph) 
	  continue;	// e.g. for nl

	[rtfContent drawRange: [currentInfo lineRange] 
		    atPoint: [currentInfo lineRect].origin];
	// <!> make this use drawRange: inRect: in the future 
	// (for proper adoption of layout information [e.g. centering])
      }
  }
}

- (NSRange) lineRangeForRect: (NSRect) rect
{
  NSPoint upperLeftPoint = rect.origin; 
  NSPoint lowerRightPoint = NSMakePoint (NSMaxX (rect), NSMaxY (rect));
  NSRange myTest;
  unsigned startLine, endLine;

  startLine = [self lineLayoutIndexForPoint: upperLeftPoint];
  endLine = [self lineLayoutIndexForPoint: lowerRightPoint];
  //FIXME 	return MakeRangeFromAbs (startLine, endLine + 1);
  if ([plainContent length] != 0) 
    {
      myTest  = MakeRangeFromAbs (startLine, endLine + 1);
      NSDebugLog(@"myTest: length  = %d, location  = %d\n",
		 (int)myTest.length,
		 (int)myTest.location);
      return myTest;
  } 
  else 
    {
      myTest  = MakeRangeFromAbs (startLine, endLine);
      NSDebugLog (@"myTest: length  = %d, location  = %d\n",
		  (int)myTest.length,
		  (int)myTest.location);
      return myTest;
    }
}

- (void) drawRectNoSelection: (NSRect)rect
{	
  NSRange		redrawLineRange;
  
  // bootstrap layout information 
  // for [self lineLayoutIndexForCharacterIndex: anIndex] to work initially
  if (![lineLayoutInformation count])	
    {
      [self rebuildLineLayoutInformationStartingAtLine: 0];
    }
  
  redrawLineRange = [self lineRangeForRect: rect];
  
  if ([self drawsBackground])	
    {
      // clear area under text
      [[self backgroundColor] set]; 
      NSRectFill(rect);
    }
  
  if ([self isRichText])
    {
      [self drawRichLinesInLineRange: redrawLineRange];
    }
  else
    {
      [self drawPlainLinesInLineRange: redrawLineRange];
    }

}

- (void) drawRect: (NSRect)rect
{	
  if (displayDisabled) 
    return;
  
  [self drawRectNoSelection: rect];
  [self drawSelectionAsRange: selected_range];
}

// text lays out from top to bottom
- (BOOL) isFlipped 
{
  return YES;
}

- (BOOL) isOpaque
{ 
  if (draws_background == NO 
      || background_color == nil 
      || [background_color alphaComponent] < 1.0)
    return NO;
  else
    return YES; 
}

//
// Copy and paste
//
- (void) copy: sender
{	
  NSMutableArray *types = [NSMutableArray arrayWithObjects: 
					    NSStringPboardType, nil];
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];
  
  if ([self isRichText])			
    [types addObject: NSRTFPboardType];
  
  if ([self importsGraphics])		
    [types addObject: NSRTFDPboardType];
  
  [pboard declareTypes: types owner: self];

  [pboard setString: [[self string] substringWithRange: selected_range] 
	  forType: NSStringPboardType];

  if ([self isRichText])
    [pboard setData: [self RTFFromRange: selected_range] 
	    forType: NSRTFPboardType];

  if ([self importsGraphics])
    [pboard setData: [self RTFDFromRange: selected_range] 
	    forType: NSRTFDPboardType];
}

// <!>
- (void) copyFont: sender
{
}

// <!>
- (void) copyRuler: sender
{
}

- (void) delete: sender
{	
  [self deleteRange: selected_range backspace: NO];
}
- (void) cut: sender
{	
  if (selected_range.length)
    {
      [self copy: self];
      [self delete: self];
    }
}


- (void) paste: sender
{
  [self performPasteOperation: [NSPasteboard generalPasteboard]];
}

- (void) pasteFont: sender
{
  [self performPasteOperation: [NSPasteboard pasteboardWithName: NSFontPboard]];
}

- (void) pasteRuler: sender
{
  [self performPasteOperation:
	  [NSPasteboard pasteboardWithName: NSRulerPboard]];
}




//
// NSCoding protocol
//
- (void)encodeWithCoder: aCoder
{	
  [super encodeWithCoder: aCoder];
  
  [aCoder encodeConditionalObject: delegate];
  
  [aCoder encodeObject: plainContent];
  [aCoder encodeObject: rtfContent];
  
  [aCoder encodeValueOfObjCType: "I" at: &alignment];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_editable];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_rich_text];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_selectable];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &imports_graphics];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &uses_font_panel];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_horizontally_resizable];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_vertically_resizable];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_ruler_visible];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &is_field_editor];
  [aCoder encodeObject: background_color];
  [aCoder encodeObject: text_color];
  [aCoder encodeObject: default_font];
  [aCoder encodeValueOfObjCType: @encode(NSRange) at: &selected_range];
}

- initWithCoder: aDecoder
{	
  [super initWithCoder: aDecoder];
  
  delegate  = [aDecoder decodeObject];
  
  plainContent = [aDecoder decodeObject];
  rtfContent = [aDecoder decodeObject];
  
  [aDecoder decodeValueOfObjCType: "I" at: &alignment];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_editable];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_rich_text];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_selectable];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &imports_graphics];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &uses_font_panel];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) 
	    at: &is_horizontally_resizable];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_vertically_resizable];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_ruler_visible];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &is_field_editor];
  background_color  = [aDecoder decodeObject];
  text_color  = RETAIN([aDecoder decodeObject]);
  default_font  = RETAIN([aDecoder decodeObject]);
  [aDecoder decodeValueOfObjCType: @encode(NSRange) at: &selected_range];
  
  return self;
}

//
// Spelling
//

- (void) checkSpelling: sender
{	
  NSRange errorRange 
    = [[NSSpellChecker sharedSpellChecker] 
	checkSpellingOfString: [self string] 
	startingAt: NSMaxRange (selected_range)];

  if (errorRange.length) 
    [self setSelectedRange: errorRange];
  else 
    NSBeep();
}

- (void) showGuessPanel: sender
{	[[[NSSpellChecker sharedSpellChecker] spellingPanel] orderFront: self];
}

//
// NSChangeSpelling protocol
//

- (void) changeSpelling: sender
{	
  [self insertText: [[(NSControl*)sender selectedCell] stringValue]];
}

- (int) spellCheckerDocumentTag
{
  if (!spellCheckerDocumentTag) 
    spellCheckerDocumentTag = [NSSpellChecker uniqueSpellDocumentTag];
  
  return spellCheckerDocumentTag;
}

//
// NSIgnoreMisspelledWords protocol
//
- (void) ignoreSpelling: sender
{
  [[NSSpellChecker sharedSpellChecker] 
    ignoreWord: [[(NSControl*)sender selectedCell] stringValue] 
    inSpellDocumentWithTag: [self spellCheckerDocumentTag]];
}

@end
