/** <title>NSAlert</title>

   <abstract>Encapsulate an alert panel</abstract>

   Copyright <copy>(C) 2004 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: July 2004

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

#include "config.h"

#include <Foundation/NSString.h>
#include "AppKit/NSAlert.h"
#include "AppKit/NSPanel.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSImage.h"

@implementation	NSAlert

/*
 * Class methods
 */
+ (void)initialize
{
  if (self  ==  [NSAlert class])
    {
      [self setVersion: 1];
    }
}

+ (NSAlert *)alertWithMessageText:(NSString *)messageTitle
		    defaultButton:(NSString *)defaultButtonTitle
		  alternateButton:(NSString *)alternateButtonTitle
		      otherButton:(NSString *)otherButtonTitle
	informativeTextWithFormat:(NSString *)format, ...
{
  va_list ap;
  NSAlert *alert = [[self alloc] init];
  NSString *text;

  va_start(ap, format);
  if (format != nil)
    {
      text = [[NSString alloc] initWithFormat: format arguments: ap];
      [alert setInformativeText: text];
      RELEASE(text);
    }
  va_end(ap);
  [alert setMessageText: messageTitle];

  if (defaultButtonTitle != nil)
    {
	[alert addButtonWithTitle: defaultButtonTitle];
    }
  else
    {
	[alert addButtonWithTitle: _(@"OK")];
    }

  if (alternateButtonTitle != nil)
    {
	[alert addButtonWithTitle: alternateButtonTitle];
    }

  if (otherButtonTitle != nil)
    {
	[alert addButtonWithTitle: otherButtonTitle];
    }

  return AUTORELEASE(alert);
}

- (id) init
{
  _buttons = [[NSMutableArray alloc] init];
  _style = NSWarningAlertStyle;
  return self;
} 

- (void) dealloc
{
  RELEASE(_informative_text);
  RELEASE(_message_text);
  RELEASE(_icon);
  RELEASE(_buttons);
  RELEASE(_help_anchor);
  RELEASE(_window);
  [super dealloc];
}

- (void)setInformativeText:(NSString *)informativeText
{
  ASSIGN(_informative_text, informativeText);
}

- (NSString *)informativeText
{
  return _informative_text;
}

- (void)setMessageText:(NSString *)messageText
{
  ASSIGN(_message_text, messageText);
}

- (NSString *)messageText
{
  return _message_text;
}

- (void)setIcon:(NSImage *)icon
{
  ASSIGN(_icon, icon);
}

- (NSImage *)icon
{
  return _icon;
}

- (NSButton *)addButtonWithTitle:(NSString *)aTitle
{
  NSButton *button = [[NSButton alloc] init];
  int count = [_buttons count];

  [button setTitle: aTitle];
  [button setAutoresizingMask: NSViewMinXMargin | NSViewMaxYMargin];
  [button setButtonType: NSMomentaryPushButton];
  [button setTarget: self];
  [button setAction: @selector(buttonAction: )];
  [button setFont: [NSFont systemFontOfSize: 0]];
  if (count == 0)
    {
      [button setTag: NSAlertFirstButtonReturn];
      [button setKeyEquivalent: @"\r"];
    }
  else
    {
      [button setTag: NSAlertFirstButtonReturn + count];
      if ([aTitle isEqualToString: @"Cancel"])
        {
	  [button setKeyEquivalent: @"\e"];
	}
      else if ([aTitle isEqualToString: @"Don't Save"])
        {
	  [button setKeyEquivalent: @"D"];
	  [button setKeyEquivalentModifierMask: NSCommandKeyMask];
	}
    }

  [_buttons addObject: button];
  RELEASE(button);
  return button;
}

- (NSArray *)buttons
{
  return _buttons;
}

- (void)setShowsHelp:(BOOL)showsHelp
{
  _shows_help = showsHelp;
}

- (BOOL)showsHelp
{
  return _shows_help;
}

- (void)setHelpAnchor:(NSString *)anchor
{
  ASSIGN(_help_anchor, anchor);
}

- (NSString *)helpAnchor
{
  return _help_anchor;
}

- (void)setAlertStyle:(NSAlertStyle)style
{
  _style = style;
}

- (NSAlertStyle)alertStyle
{
  return _style;
}

- (void)setDelegate:(id)delegate
{
  _delegate = delegate;
}

- (id)delegate
{
  return _delegate;
}

- (int)runModal
{
  // FIXME
  return NSAlertFirstButtonReturn;
}

- (void)beginSheetModalForWindow:(NSWindow *)window
		   modalDelegate:(id)delegate
		  didEndSelector:(SEL)didEndSelector
		     contextInfo:(void *)contextInfo
{
// FIXME
}

- (id)window
{
  return _window;
}

@end
