/*
   NSPanel.m

   Panel window class and related functions

   Copyright (C) 1996 Free Software Foundation, Inc.

   NSPanel implementation
   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996

   GSAlertPanel and alert panel functions implementation
   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 1998

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

#include <Foundation/NSBundle.h>
#include <Foundation/NSCoder.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSBox.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSScreen.h>
#include <AppKit/IMLoading.h>
#include <AppKit/GMAppKit.h>

#include <AppKit/GMArchiver.h>


@implementation	NSPanel

/*
 * Class methods
 */
+ (void)initialize
{
  if (self == [NSPanel class])
    {
      [self setVersion:1];
    }
}

/*
 * Instance methods
 */
- (id) init
{
  int style = NSTitledWindowMask | NSClosableWindowMask;

  return [self initWithContentRect: NSZeroRect
			 styleMask: style
			   backing: NSBackingStoreBuffered
			     defer: NO];
}

- (void) initDefaults
{
  [super initDefaults];
  [self setReleasedWhenClosed: NO];
  [self setHidesOnDeactivate: YES];
  [self setExcludedFromWindowsMenu: YES];
}

- (BOOL) canBecomeKeyWindow
{
  if (_becomesKeyOnlyIfNeeded)
    return NO;
  return YES;
}

- (BOOL) canBecomeMainWindow
{
  return NO;
}

/*
 * If we receive an escape, close.
 */
- (void) keyDown: (NSEvent*)theEvent
{
  if ([@"\e" isEqual: [theEvent charactersIgnoringModifiers]] &&
    ([self styleMask] & NSClosableWindowMask) == NSClosableWindowMask)
    [self close];
  else
    [super keyDown: theEvent];
}

/*
 * Determining the Panel's Behavior
 */
- (BOOL) isFloatingPanel
{
  return _isFloatingPanel;
}

- (void) setFloatingPanel: (BOOL)flag
{
  _isFloatingPanel = flag;
}

- (BOOL) worksWhenModal
{
  return _worksWhenModal;
}

- (void) setWorksWhenModal: (BOOL)flag
{
  _worksWhenModal = flag;
}

- (BOOL) becomesKeyOnlyIfNeeded
{
  return _becomesKeyOnlyIfNeeded;
}

- (void) setBecomesKeyOnlyIfNeeded: (BOOL)flag
{
  _becomesKeyOnlyIfNeeded = flag;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  return self;
}

@end /* NSPanel */

#define	PANX	362.0
#define	PANY	161.0

@class	GSAlertPanel;

static GSAlertPanel	*standardAlertPanel = nil;
static GSAlertPanel	*informationalAlertPanel = nil;
static GSAlertPanel	*criticalAlertPanel = nil;
static GSAlertPanel	*gmodelAlertPanel = nil;

@interface	GSAlertPanel : NSPanel
{
  NSButton	*defButton;
  NSButton	*altButton;
  NSButton	*othButton;
  NSButton	*icoButton;
  NSTextField	*messageField;
  NSTextField	*titleField;
  int		result;
  BOOL		active;
}
- (void) buttonAction: (id) sender;
- (int) result;
- (int) runModal;
- (void) setTitle: (NSString*)title
	  message: (NSString*)message
	      def: (NSString*)defaultButton
	      alt: (NSString*)alternateButton
	    other: (NSString*)otherButton;
@end

@implementation	GSAlertPanel

/*
 * Class methods
 */
+ (void)initialize
{
  if (self == [GSAlertPanel class])
    {
      [self setVersion:1];
    }
}

+ (id) createObjectForModelUnarchiver: (GMUnarchiver*)unarchiver
{
    unsigned backingType = [unarchiver decodeUnsignedIntWithName:
			   @"backingType"];
    unsigned styleMask = [unarchiver decodeUnsignedIntWithName:@"styleMask"];
    NSRect aRect = [unarchiver decodeRectWithName:@"frame"];
    NSPanel* panel = [[[GSAlertPanel allocWithZone:[unarchiver objectZone]]
		     initWithContentRect:aRect
		     styleMask:styleMask backing:backingType defer:YES]
		    autorelease];

    return panel;
}

- (void) buttonAction: (id)sender
{
  if (active == NO)
    {
      NSLog(@"alert panel buttonAction: when not in modal loop\n");
      return;
    }
  else if (sender == defButton)
    {
      result = NSAlertDefaultReturn;
    }
  else if (sender == altButton)
    {
      result = NSAlertAlternateReturn;
    }
  else if (sender == othButton)
    {
      result = NSAlertOtherReturn;
    }
  else
    {
      NSLog(@"alert panel buttonAction: from unknown sender - x%x\n",
		(unsigned)sender);
    }
  active = NO;
  [[NSApplication sharedApplication] stopModal];
}

- (void) dealloc
{
  if (self == standardAlertPanel)
    standardAlertPanel = nil;
  if (self == informationalAlertPanel)
    informationalAlertPanel = nil;
  if (self == criticalAlertPanel)
    criticalAlertPanel = nil;
  [defButton release];
  [altButton release];
  [othButton release];
  [icoButton release];
  [messageField release];
  [titleField release];
  [super dealloc];
}

- (void) encodeWithModelArchiver: (GMArchiver *)archiver
{
  [super encodeWithModelArchiver: archiver];
  [archiver encodeObject: defButton withName: @"DefaultButton"];
  [archiver encodeObject: altButton withName: @"AlternateButton"];
  [archiver encodeObject: othButton withName: @"OtherButton"];
  [archiver encodeObject: icoButton withName: @"IconButton"];
  [archiver encodeObject: messageField withName: @"MessageField"];
  [archiver encodeObject: titleField withName: @"TitleField"];
}

- (id) initWithContentRect: (NSRect)r
		 styleMask: (unsigned)m
		   backing: (NSBackingStoreType)b
		     defer: (BOOL)d
		    screen: (NSScreen*)s
{
  self = [super initWithContentRect: r
			  styleMask: m
			    backing: b
			      defer: d
			     screen: s];
  if (self)
    {
      NSView	*content;
      NSImage	*image;
      unsigned	bs = 10.0;		/* Inter-button space	*/
      unsigned	bh = 24.0;		/* Button height.	*/
      unsigned	bw = 72.0;		/* Button width.	*/
      NSRect	rect;
      NSBox	*box;

      [self setMaxSize: r.size];
      [self setMinSize: r.size];
      [self setTitle: @" "];

      content = [self contentView];

      rect.size.height = 2.0;
      rect.size.width = 362.0;
      rect.origin.y = 95.0;
      rect.origin.x = 0.0;
      box = [[NSBox alloc] initWithFrame: rect];
      [box setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
      [box setTitlePosition: NSNoTitle];
      [box setBorderType: NSGrooveBorder];
      [content addSubview: box];
      [box release];

      rect.size.height = bh;
      rect.size.width = bw;
      rect.origin.y = bs;
      rect.origin.x = 280.0;
      defButton = [[NSButton alloc] initWithFrame: rect];
      [defButton setAutoresizingMask: NSViewMinXMargin | NSViewMaxYMargin];
      [defButton setButtonType: NSMomentaryPushButton];
      [defButton setTitle: @"Default"];
      [defButton setTarget: self];
      [defButton setAction: @selector(buttonAction:)];
      [defButton setFont: [NSFont systemFontOfSize: 12.0]];
      [defButton setKeyEquivalent: @"\r"];
      [defButton setImagePosition: NSImageRight];
      [defButton setImage: [NSImage imageNamed: @"common_ret"]];

      rect.origin.x = 199.0;
      altButton = [[NSButton alloc] initWithFrame: rect];
      [altButton setAutoresizingMask: NSViewMinXMargin | NSViewMaxYMargin];
      [altButton setButtonType: NSMomentaryPushButton];
      [altButton setTitle: @"Alternative"];
      [altButton setTarget: self];
      [altButton setAction: @selector(buttonAction:)];
      [altButton setFont: [NSFont systemFontOfSize: 12.0]];

      rect.origin.x = 120.0;
      othButton = [[NSButton alloc] initWithFrame: rect];
      [othButton setAutoresizingMask: NSViewMinXMargin | NSViewMaxYMargin];
      [othButton setButtonType: NSMomentaryPushButton];
      [othButton setTitle: @"Other"];
      [othButton setTarget: self];
      [othButton setAction: @selector(buttonAction:)];
      [othButton setFont: [NSFont systemFontOfSize: 12.0]];

      rect.size.height = 48.0;
      rect.size.width = 48.0;
      rect.origin.y = 105.0;
      rect.origin.x = 8.0;
      icoButton = [[NSButton alloc] initWithFrame: rect];
      [icoButton setAutoresizingMask: NSViewMaxXMargin | NSViewMinYMargin];
      [icoButton setBordered: NO];
      [icoButton setEnabled: NO];
      [icoButton setImagePosition: NSImageOnly];
      image = [[NSApplication sharedApplication] applicationIconImage];
      [icoButton setImage: image];

      rect.size.height = 36.0;
      rect.size.width = 344.0;
      rect.origin.y = 46.0;
      rect.origin.x = 8.0;
      messageField = [[NSTextField alloc] initWithFrame: rect];
      [messageField setAutoresizingMask:
		NSViewWidthSizable | NSViewHeightSizable | NSViewMaxYMargin];
      [messageField setEditable: NO];
      [messageField setSelectable: NO];
      [messageField setBezeled: NO];
      [messageField setDrawsBackground: NO];
      [messageField setAlignment: NSCenterTextAlignment];
      [messageField setStringValue: @""];
      [messageField setFont: [NSFont systemFontOfSize: 14.0]];

      rect.size.height = 21.0;
      rect.size.width = 289.0;
      rect.origin.y = 121.0;
      rect.origin.x = 64.0;
      titleField = [[NSTextField alloc] initWithFrame: rect];
      [titleField setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
      [titleField setEditable: NO];
      [titleField setSelectable: NO];
      [titleField setBezeled: NO];
      [titleField setDrawsBackground: NO];
      [titleField setStringValue: @""];
      [titleField setFont: [NSFont systemFontOfSize: 18.0]];

    }
  return self;
}

- (id) initWithModelUnarchiver: (GMUnarchiver*)unarchiver
{
  self = [super initWithModelUnarchiver: unarchiver];
  defButton = [[unarchiver decodeObjectWithName: @"DefaultButton"] retain];
  altButton = [[unarchiver decodeObjectWithName: @"AlternateButton"] retain];
  othButton = [[unarchiver decodeObjectWithName: @"OtherButton"] retain];
  icoButton = [[unarchiver decodeObjectWithName: @"IconButton"] retain];
  messageField = [[unarchiver decodeObjectWithName: @"MessageField"] retain];
  titleField = [[unarchiver decodeObjectWithName: @"TitleField"] retain];
  gmodelAlertPanel = self;
  return gmodelAlertPanel;
}

- (int) result
{
  return result;
}

- (int) runModal
{
  active = YES;
  [NSApp runModalForWindow: self];
  [self orderOut: self];
  return result;
}

- (void) setTitle: (NSString*)title
	  message: (NSString*)message
	      def: (NSString*)defaultButton
	      alt: (NSString*)alternateButton
	    other: (NSString*)otherButton
{
  NSView	*content = [self contentView];

  if (defaultButton)
    {
      [defButton setTitle: defaultButton];
      if ([defButton superview] == nil)
	[content addSubview: defButton];
      [self makeFirstResponder: defButton];
    }
  else
    {
      if ([defButton superview] != nil)
	[defButton removeFromSuperview];
    }

  if (alternateButton)
    {
      [altButton setTitle: alternateButton];
      if ([altButton superview] == nil)
	[content addSubview: altButton];
    }
  else
    {
      if ([altButton superview] != nil)
	[altButton removeFromSuperview];
    }

  if (otherButton)
    {
      [othButton setTitle: otherButton];
      if ([othButton superview] == nil)
	[content addSubview: othButton];
    }
  else
    {
      if ([othButton superview] != nil)
	[othButton removeFromSuperview];
    }

  if (message)
    {
      [messageField setStringValue: message];
      if ([messageField superview] == nil)
	[content addSubview: messageField];
    }
  else
    {
      if ([messageField superview] != nil)
	[messageField removeFromSuperview];
    }

  if (title)
    {
      [titleField setStringValue: title];
      if ([titleField superview] == nil)
	[content addSubview: titleField];
    }
  else
    {
      if ([titleField superview] != nil)
	[titleField removeFromSuperview];
    }

  result = NSAlertErrorReturn;	/* If no button was pressed	*/
  [content display];
}

@end /* GSAlertPanel */

id
NSGetAlertPanel(NSString *title,
		NSString *msg,
		NSString *defaultButton,
		NSString *alternateButton,
		NSString *otherButton, ...)
{
  va_list	ap;
  NSString	*message;
  GSAlertPanel	*panel;

  va_start (ap, otherButton);
  message = [NSString stringWithFormat: msg arguments: ap];
  va_end (ap);

  if (title == nil)
    title = @"Alert";

  if (standardAlertPanel == nil)
    {
#if 0
      if (![GMModel loadIMFile: @"AlertPanel" owner: [GSAlertPanel alloc]])
	{
	  NSLog(@"cannot open alert panel model file\n");
	  return nil;
        }
#else

      panel = [GSAlertPanel alloc];
      panel = [panel initWithContentRect: NSMakeRect(0, 0, PANX, PANY)
			       styleMask: NSTitledWindowMask
				 backing: NSBackingStoreRetained
				   defer: YES
				  screen: nil];

#endif
    }
  else
    {
      panel = standardAlertPanel;
      standardAlertPanel = nil;
    }
  [panel setTitle: title
	  message: message
	      def: defaultButton
	      alt: alternateButton
	    other: otherButton];

  return panel;
}

id
NSGetCriticalAlertPanel(NSString *title,
			NSString *msg,
			NSString *defaultButton,
			NSString *alternateButton,
			NSString *otherButton, ...)
{
  va_list	ap;
  NSString	*message;
  GSAlertPanel	*panel;

  if (title == nil)
    title = @"Warning";
  va_start (ap, otherButton);
  message = [NSString stringWithFormat: msg arguments: ap];
  va_end (ap);

  if (criticalAlertPanel == nil)
    {
      panel = NSGetAlertPanel(title, msg, defaultButton,
			alternateButton, otherButton, ap);
      criticalAlertPanel = panel;
    }
  else
    panel = criticalAlertPanel;

  [panel setTitle: @"Critical"];
  [panel setTitle: title
	  message: message
	      def: defaultButton
	      alt: alternateButton
	    other: otherButton];
  return panel;
}

id
NSGetInformationalAlertPanel(NSString *title,
			     NSString *msg,
			     NSString *defaultButton,
			     NSString *alternateButton,
			     NSString *otherButton, ...)
{
  va_list	ap;
  NSString	*message;
  GSAlertPanel	*panel;

  if (title == nil)
    title = @"Information";
  va_start (ap, otherButton);
  message = [NSString stringWithFormat: msg arguments: ap];
  va_end (ap);

  if (informationalAlertPanel == nil)
    {
      panel = NSGetAlertPanel(title, msg, defaultButton,
			alternateButton, otherButton, ap);
      informationalAlertPanel = panel;
    }
  else
    panel = informationalAlertPanel;

  [panel setTitle: @"Information"];
  [panel setTitle: title
	  message: message
	      def: defaultButton
	      alt: alternateButton
	    other: otherButton];
  return panel;
}

void
NSReleaseAlertPanel(id alertPanel)
{
  if (alertPanel != standardAlertPanel
    && alertPanel != informationalAlertPanel
    && alertPanel != criticalAlertPanel)
    [alertPanel release];
}

int
NSRunAlertPanel(NSString *title,
		NSString *msg,
		NSString *defaultButton,
		NSString *alternateButton,
		NSString *otherButton, ...)
{
  va_list	ap;
  GSAlertPanel	*panel;
  NSString	*message;
  int		result;

  if (title == nil)
    title = @"Alert";
  if (defaultButton == nil)
    defaultButton = @"OK";

  va_start (ap, otherButton);
  message = [NSString stringWithFormat: msg arguments: ap];
  va_end (ap);

  if (standardAlertPanel)
    {
      panel = standardAlertPanel;
      [panel setTitle: title
	      message: message
		  def: defaultButton
		  alt: alternateButton
		other: otherButton];
    }
  else
    {
      panel = NSGetAlertPanel(title, message, defaultButton,
			alternateButton, otherButton, ap);
      standardAlertPanel = panel;
    }

  result = [panel runModal];
  NSReleaseAlertPanel(panel);
  return result;
}

int
NSRunCriticalAlertPanel(NSString *title,
			NSString *msg,
			NSString *defaultButton,
			NSString *alternateButton,
			NSString *otherButton, ...)
{
  va_list	ap;
  GSAlertPanel	*panel;
  int		result;

  va_start (ap, otherButton);
  panel = NSGetCriticalAlertPanel(title, msg,
    defaultButton, alternateButton, otherButton, ap);
  va_end (ap);

  result = [panel runModal];
  NSReleaseAlertPanel(panel);
  return result;
}

int
NSRunInformationalAlertPanel(NSString *title,
			     NSString *msg,
			     NSString *defaultButton,
			     NSString *alternateButton,
			     NSString *otherButton, ...)
{
  va_list	ap;
  GSAlertPanel	*panel;
  int		result;

  va_start (ap, otherButton);
  panel = NSGetInformationalAlertPanel(title, msg,
    defaultButton, alternateButton, otherButton, ap);
  va_end (ap);

  result = [panel runModal];
  NSReleaseAlertPanel(panel);
  return result;
}

int
NSRunLocalizedAlertPanel(NSString *table,
			 NSString *title,
			 NSString *msg,
			 NSString *defaultButton, 
			 NSString *alternateButton, 
			 NSString *otherButton, ...)
{
  va_list	ap;
  GSAlertPanel	*panel;
  NSString	*message;
  int		result;
  NSBundle	*bundle = [NSBundle mainBundle];

  if (title == nil)
    title = @"Alert";

  title = [bundle localizedStringForKey: title
				  value: title
				  table: table];
  if (defaultButton)
    defaultButton = [bundle localizedStringForKey: defaultButton
					    value: defaultButton
					    table: table];
  if (alternateButton)
    alternateButton = [bundle localizedStringForKey: alternateButton
					      value: alternateButton
					      table: table];
  if (otherButton)
    otherButton = [bundle localizedStringForKey: otherButton
					  value: otherButton
					  table: table];
  if (msg)
    msg = [bundle localizedStringForKey: msg
				  value: msg
				  table: table];

  va_start (ap, otherButton);
  message = [NSString stringWithFormat: msg arguments: ap];
  va_end (ap);

  if (standardAlertPanel)
    {
      panel = standardAlertPanel;
      [panel setTitle: title
	      message: message
		  def: defaultButton
		  alt: alternateButton
		other: otherButton];
    }
  else
    {
      panel = NSGetAlertPanel(title, message, defaultButton,
	alternateButton, otherButton, ap);
      standardAlertPanel = panel;
    }

  result = [panel runModal];
  NSReleaseAlertPanel(panel);
  return result;
}

