/*
   NSTextView.m

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
   Source by Daniel Bðhringer integrated into GNUstep gui
   by Felipe A. Rodriguez <far@ix.netcom.com> 

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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <AppKit/NSTextView.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSSpellChecker.h>
#include <AppKit/NSFontPanel.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSTextStorage.h>

// classes needed are: NSRulerView NSTextContainer NSLayoutManager

@implementation NSTextView

/**************************** Initializing ****************************/

+(void) initialize
{	[super initialize];

	if([self class] == [NSTextView class]) [self registerForServices];
}


//Registers send and return types for the Services facility. This method is invoked automatically; you should never need to invoke it directly.
+(void) registerForServices
{
// do we yet have services in gnustep?
}


// container may be nil
- initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container
{	
//	self=[super initWithFrame:frameRect];
	[super initWithFrame:frameRect];

if(container) [self setTextContainer: container];
	else	// set up a new container
	{
	}
	return self;
}

// This variant will create the text network (textStorage, layoutManager, and a container).
- initWithFrame:(NSRect)frameRect
{	return [self initWithFrame:frameRect textContainer:nil];
}

/***************** Get/Set the container and other stuff *****************/

-(NSTextContainer*) textContainer
{	return textContainer;
}

// The set method should not be called directly, but you might want to override it.  Gets or sets the text container for this view.  Setting the text container marks the view as needing display.  The text container calls the set method from its setTextView: method.

-(void) setTextContainer:(NSTextContainer *)container
{	if(textContainer) [textContainer autorelease];
	textContainer=[container retain];
}

// This method should be used instead of the primitive -setTextContainer: if you need to replace a view's text container with a new one leaving the rest of the web intact.  This method deals with all the work of making sure the view doesn't get deallocated and removing the old container from the layoutManager and replacing it with the new one.

-(void) replaceTextContainer:(NSTextContainer *)newContainer
{	[self setTextContainer:newContainer];
	// now do something to retain the web
}

// The textContianerInset determines the padding that the view provides around the container.  The container's origin will be inset by this amount from the bounds point {0,0} and padding will be left to the right and below the container of the same amount.  This inset affects the view sizing in response to new layout and is used by the rectangular text containers when they track the view's frame dimensions.

-(void)setTextContainerInset:(NSSize)inset
{
}

-(NSSize) textContainerInset	{return textContainerInset;}

-(NSPoint) textContainerOrigin	{return textContainerOrigin;}

// The container's origin in the view is determined from the current usage of the container, the container inset, and the view size.  textContainerOrigin returns this point.  invalidateTextContainerOrigin is sent automatically whenever something changes that causes the origin to possibly move.  You usually do not need to call invalidate yourself. 
-(void)invalidateTextContainerOrigin
{
}

-(NSLayoutManager*) layoutManager {return layoutManager;}
-(NSTextStorage*) textStorage		{return textStorage;}

/************************* Key binding entry-point *************************/

// This method is the funnel point for text insertion after keys pass through the key binder.

#ifdef DEBUGG
-(void) insertText:(NSString*) insertString
{
[super insertText: insertString];
}
#endif /* DEBUGG */

/*************************** Sizing methods ***************************/

// Sets the frame size of the view to desiredSize constrained within min and max size.
- (void)setConstrainedFrameSize:(NSSize)desiredSize
{
}

/***************** New miscellaneous API above and beyond NSText *****************/

- (void)setAlignment:(NSTextAlignment)alignment range:(NSRange)range
{
}

-(void) pasteAsPlainText:sender
{
}
-(void) pasteAsRichText:sender
{
}

/*************************** New Font menu commands ***************************/

-(void) turnOffKerning:(id)sender
{
}
-(void) tightenKerning:(id)sender
{
}
-(void) loosenKerning:(id)sender
{
}
-(void) useStandardKerning:(id)sender
{
}
-(void) turnOffLigatures:(id)sender
{
}
-(void) useStandardLigatures:(id)sender
{
}
-(void) useAllLigatures:(id)sender
{
}
-(void) raiseBaseline:(id)sender
{
}
-(void) lowerBaseline:(id)sender
{}

/*************************** Ruler support ***************************/

-(void) rulerView:(NSRulerView *)ruler didMoveMarker:(NSRulerMarker *)marker
{
}
-(void) rulerView:(NSRulerView *)ruler didRemoveMarker:(NSRulerMarker *)marker
{
}
-(void) rulerView:(NSRulerView *)ruler didAddMarker:(NSRulerMarker *)marker
{
}
-(BOOL) rulerView:(NSRulerView *)ruler shouldMoveMarker:(NSRulerMarker *)marker
{
}
-(BOOL) rulerView:(NSRulerView *)ruler shouldAddMarker:(NSRulerMarker *)marker
{
}
-(float) rulerView:(NSRulerView *)ruler willMoveMarker:(NSRulerMarker *)marker toLocation:(float)location
{
}
-(BOOL) rulerView:(NSRulerView *)ruler shouldRemoveMarker:(NSRulerMarker *)marker
{
}
-(float) rulerView:(NSRulerView *)ruler willAddMarker:(NSRulerMarker *)marker atLocation:(float)location
{
}
-(void) rulerView:(NSRulerView *)ruler handleMouseDown:(NSEvent *)event
{
}
/*************************** Fine display control ***************************/

-(void) setNeedsDisplayInRect:(NSRect)rect avoidAdditionalLayout:(BOOL)fla
{
}

#ifdef DEBUGG
-(BOOL)shouldDrawInsertionPoint
{
}
-(void) drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color turnedOn:(BOOL)flag
{
}
#endif /* DEBUGG */

/*************************** Especially for subclassers ***************************/

-(void) updateRuler
{
}
-(void) updateFontPanel
{
}

-(NSArray*)acceptableDragTypes
{	NSMutableArray *ret=[NSMutableArray arrayWithObject:NSStringPboardType];

	if([self isRichText])			[ret addObject:NSRTFPboardType];
	if([self importsGraphics])		[ret addObject:NSRTFDPboardType];
	return ret;
}

#ifdef DEBUGG
- (void)updateDragTypeRegistration
{
}

- (NSRange)selectionRangeForProposedRange:(NSRange)proposedCharRange granularity:(NSSelectionGranularity)granularity
{
}
#endif /* DEBUGG */

@end

@implementation NSTextView (NSSharing)

// The methods in this category deal with settings that need to be shared by all the NSTextViews of a single NSLayoutManager.  Many of these methods are overrides of NSText or NSResponder methods.

/*************************** Selected/Marked range ***************************/

-(void) setSelectedRange:(NSRange)charRange affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)stillSelectingFlag
{
}
-(NSSelectionAffinity) selectionAffinity 		{return selectionAffinity;}
-(NSSelectionGranularity) selectionGranularity	{return selectionGranularity;}
-(void) setSelectionGranularity:(NSSelectionGranularity)granularity
{	selectionGranularity= granularity;
}

-(void) setSelectedTextAttributes:(NSDictionary *)attributeDictionary
{
}
-(NSDictionary*) selectedTextAttributes
{
}

-(void) setInsertionPointColor:(NSColor *)color
{	if(insertionPointColor) [insertionPointColor autorelease];
	insertionPointColor=[color retain];
}
- (NSColor *)insertionPointColor	{return insertionPointColor;}

-(void) updateInsertionPointStateAndRestartTimer:(BOOL)restartFlag
{
}

-(NSRange)markedRange
{
}

-(void) setMarkedTextAttributes:(NSDictionary*)attributeDictionary
{
}
-(NSDictionary*) markedTextAttributes
{
}

/*************************** Other NSTextView methods ***************************/

-(void) setRulerVisible:(BOOL)flag
{
}
-(BOOL) usesRuler
{
}

-(void) setUsesRuler:(BOOL)flag
{
}

-(int) spellCheckerDocumentTag
{
}

-(NSDictionary*) typingAttributes
{
}
-(void) setTypingAttributes:(NSDictionary *)attrs
{
}

//Initiates a series of delegate messages (and general notifications) to determine whether modifications can be made to the receiver's text. If characters in the text string are being changed, replacementString contains the characters that will replace the characters in affectedCharRange. If only text attributes are being changed, replacementString is nil. This method checks with the delegate as needed using textShouldBeginEditing: and textView:shouldChangeTextInRange:replacementString:, returning YES to allow the change, and NO to prohibit it.

//This method must be invoked at the start of any sequence of user-initiated editing changes. If your subclass of NSTextView implements new methods that modify the text, make sure to invoke this method to determine whether the change should be made. If the change is allowed, complete the change by invoking the didChangeText method. See ªNotifying About Changes to the Textº in the class description for more information. If you can't determine the affected range or replacement string before beginning changes, pass (NSNotFound, 0) and nil for these values.

-(BOOL) shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
}
-(void)didChangeText
{}

-(NSRange)rangeForUserTextChange
{
}
-(NSRange) rangeForUserCharacterAttributeChange
{
}
-(NSRange) rangeForUserParagraphAttributeChange
{
}


/*************************** NSResponder methods ***************************/

#ifdef DEBUGG
-(BOOL) resignFirstResponder
{	return YES;
}
-(BOOL) becomeFirstResponder
{	return YES;
}
#endif /* DEBUGG */

/*************************** Smart copy/paste/delete support ***************************/

-(BOOL)smartInsertDeleteEnabled		{return smartInsertDeleteEnabled;}
-(void) setSmartInsertDeleteEnabled:(BOOL)flag
{
}
-(NSRange) smartDeleteRangeForProposedRange:(NSRange)proposedCharRange
{
}
-(void) smartInsertForString:(NSString *)pasteString replacingRange:(NSRange)charRangeToReplace beforeString:(NSString **)beforeString afterString:(NSString **)afterString
{
}

@end
