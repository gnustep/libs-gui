/* A value binding made with NSContinuouslyUpdatesValue pushes the text to the
   bound object while the field editor is still editing, rather than waiting
   for editing to end.  Typing is simulated by setting the field editor's text
   and telling it that it changed, which is what an inserted character ends up
   doing.  A window and a field editor are needed, so the set keeps the usual
   backend skip guard. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSKeyValueBinding.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSWindow.h>

@interface Recorder : NSObject
{
@public
  NSString *text;
}
- (NSString *) text;
- (void) setText: (NSString *)aString;
@end

@implementation Recorder
- (NSString *) text
{
  return text;
}
- (void) setText: (NSString *)aString
{
  ASSIGN(text, aString);
}
- (void) dealloc
{
  RELEASE(text);
  [super dealloc];
}
@end

int
main(int argc, const char **argv)
{
  Recorder *model;
  NSWindow *win;
  NSTextField *field;
  NSText *editor;

  START_SET("NSControl continuous value binding")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      model = AUTORELEASE([[Recorder alloc] init]);
      [model setText: @"start"];

      win = AUTORELEASE([[NSWindow alloc]
	initWithContentRect: NSMakeRect(0, 0, 200, 60)
		  styleMask: NSTitledWindowMask
		    backing: NSBackingStoreBuffered
		      defer: NO]);
      field = AUTORELEASE([[NSTextField alloc]
	initWithFrame: NSMakeRect(10, 10, 180, 22)]);
      [[win contentView] addSubview: field];

      [field bind: NSValueBinding
	 toObject: model
      withKeyPath: @"text"
	  options: [NSDictionary dictionaryWithObject:
	    [NSNumber numberWithBool: YES]
	    forKey: NSContinuouslyUpdatesValueBindingOption]];

      PASS([[field stringValue] isEqualToString: @"start"],
	"binding a value fills the field from the bound object");

      [win makeKeyAndOrderFront: nil];
      [win makeFirstResponder: field];
      editor = [field currentEditor];
      if (editor == nil)
	{
	  SKIP("the text field did not get a field editor")
	}

      [editor setString: @"typed"];
      [(NSTextView *)editor didChangeText];

      PASS([[model text] isEqualToString: @"typed"],
	"a continuous binding updates the bound object while editing");

      [win makeFirstResponder: nil];
      PASS([[model text] isEqualToString: @"typed"],
	"the value is still there once editing ends");

      [field unbind: NSValueBinding];

      /* Without the option the bound object keeps its value until the field
         editor gives up first responder. */
      [model setText: @"start"];
      field = AUTORELEASE([[NSTextField alloc]
	initWithFrame: NSMakeRect(10, 10, 180, 22)]);
      [[win contentView] addSubview: field];
      [field bind: NSValueBinding
	 toObject: model
      withKeyPath: @"text"
	  options: nil];

      [win makeFirstResponder: field];
      editor = [field currentEditor];
      if (editor == nil)
	{
	  SKIP("the text field did not get a field editor")
	}

      [editor setString: @"typed again"];
      [(NSTextView *)editor didChangeText];

      PASS([[model text] isEqualToString: @"start"],
	"a plain binding leaves the bound object alone while editing");

      /* What a plain binding does once editing ends is deliberately not
         asserted here.  The value reaches the bound object from
         -sendAction:to:, and driving the field editor directly rather than
         typing into it does not get that far. */

      [win makeFirstResponder: nil];
      [field unbind: NSValueBinding];
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSControl continuous value binding")


  return 0;
}
