/*
 *	NSTextView.h
 */

// classes needed are: NSRulerView NSTextContainer NSLayoutManager

#include <AppKit/NSTextView.h>
#include <AppKit/NSRulerView.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSSpellChecker.h>
#include <AppKit/NSFontPanel.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSTextStorage.h>

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
{	if(container) [self setTextContainer: container];
	else	// set up a new container
	{
	}
	self=[super initWithFrame:frameRect];
	return self;
}

// This variant will create the text network (textStorage, layoutManager, and a container).
- initWithFrame:(NSRect)frameRect
{       return [self initWithFrame:frameRect textContainer:nil];
}

#ifdef 0
- initWithFrame:(NSRect)frameRect
{

  textStorage = [NSTextStorage new];
//  layoutManager = [NSLayoutManager new];
//  [textStorage addLayoutManager:layoutManager];
//  [layoutManager release];

  textContainer = [[NSTextContainer alloc] 
                      initWithContainerSize:frameRect];
//  [layoutManager addTextContainer:textContainer];
  [textContainer release]; 

  return [self initWithFrame:frameRect textContainer:textContainer];
}
#endif

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
}
#endif

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
#endif
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
{}
#endif
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

/*************************** Other GNUTextView methods ***************************/

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
#endif
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

- (void) setDelegate: (id) anObject
{
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
  
  [super setDelegate: anObject];
 
#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([delegate respondsToSelector: @selector(textView##notif_name:)]) \
    [nc addObserver: delegate \
           selector: @selector(textView##notif_name:) \
               name: NSTextView##notif_name##Notification \
             object: self]
 
  SET_DELEGATE_NOTIFICATION(DidChangeSelection);
  SET_DELEGATE_NOTIFICATION(WillChangeNotifyingTextView);
}
@end
