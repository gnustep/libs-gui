/* 
   GNUAlertPanel.m

   GNUAlertPanel window class

   Copyright (C) 1998 Free Software Foundation, Inc.

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
#include <AppKit/NSApplication.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSPanel.h>


@interface	GNUAlertPanel : NSPanel
{
  NSPanel	*panel;
  NSButton	*defButton;
  NSButton	*altButton;
  NSButton	*othButton;
  int		result;
  int		state;
}
- (int) result;
- (void) setTitle: (NSString*)title
	  message: (NSString*)message
	      def: (NSString*)defaultButton
	      alt: (NSString*)alternateButton
	    other: (NSString*)otherButton;
@end

@implementation	GNUAlertPanel
- (id) copyWithZone: (NSZone*)zone
{
  [self notImplemented: _cmd];
  return nil;
}

- (int) result
{
  return result;
}

- (void) setTitle: (NSString*)title
	  message: (NSString*)message
	      def: (NSString*)defaultButton
	      alt: (NSString*)alternateButton
	    other: (NSString*)otherButton
{
  [self notImplemented: _cmd];
}
@end

static GNUAlertPanel	*standardAlertPanel = nil;
static GNUAlertPanel	*reusableAlertPanel = nil;

id
NSGetAlertPanel(NSString *title,
		NSString *msg,
		NSString *defaultButton,
		NSString *alternateButton,
		NSString *otherButton, ...)
{
  va_list	ap;
  NSString	*message;
  GNUAlertPanel	*panel;

  va_start (ap, otherButton);
  message = [NSString stringWithFormat: msg arguments: ap];
  va_end (ap);

  if (title == nil)
    title = @"Alert";

  if (standardAlertPanel == nil)
    panel = nil; /* Should load our standard panel from a gmodel */

  panel = [standardAlertPanel copy];
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
  NSPanel	*panel;

  if (title == nil)
    title = @"Warning";
  va_start (ap, otherButton);
  panel = NSGetAlertPanel(title, msg, defaultButton,
			alternateButton, otherButton, ap);
  va_end (ap);

  return [panel retain];
}

id
NSGetInformationalAlertPanel(NSString *title,
			     NSString *msg,
			     NSString *defaultButton,
			     NSString *alternateButton,
			     NSString *otherButton, ...)
{
  va_list	ap;
  NSPanel	*panel;

  if (title == nil)
    title = @"Information";
  va_start (ap, otherButton);
  panel = NSGetAlertPanel(title, msg, defaultButton,
			alternateButton, otherButton, ap);
  va_end (ap);

  return [panel retain];
}

void
NSReleaseAlertPanel(id alertPanel)
{
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
  NSApplication	*app;
  GNUAlertPanel	*panel;
  NSString	*message;
  int		result;

  if (title == nil)
    title = @"Alert";
  if (defaultButton == nil)
    defaultButton = @"OK";

  va_start (ap, otherButton);
  message = [NSString stringWithFormat: msg arguments: ap];
  va_end (ap);

  if (reusableAlertPanel)
    {
      panel = reusableAlertPanel;
      reusableAlertPanel = nil;
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
    }

  app = [NSApplication sharedApplication];
  [app runModalForWindow: panel];
  result = [panel result];
  if (reusableAlertPanel == nil)
    reusableAlertPanel = panel;
  else
    NSReleaseAlertPanel(panel);

  return result;
}

