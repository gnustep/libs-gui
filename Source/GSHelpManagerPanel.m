/** <title>GSHelpManagerPanel.m</title>

   <abstract>GSHelpManagerPanel displays a help message for an item.</abstract>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Pedro Ivo Andrade Tavares <ptavares@iname.com>
   Date: September 1999
   
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

#include "AppKit/NSApplication.h"
#include "AppKit/NSAttributedString.h"
#include "AppKit/NSTextView.h"
#include "AppKit/NSScrollView.h"
#include "AppKit/NSClipView.h"
#include "AppKit/NSColor.h"

#include "GNUstepGUI/GSHelpManagerPanel.h"

@implementation GSHelpManagerPanel

static GSHelpManagerPanel* _GSsharedGSHelpPanel;

+ (id) sharedHelpManagerPanel
{
  if(!_GSsharedGSHelpPanel)
    _GSsharedGSHelpPanel = [[GSHelpManagerPanel alloc] init];

  return _GSsharedGSHelpPanel;
}

/* This window should not be destroyed... So we don't allow it to! */
- (id) retain
{
  return self;
}

- (void) release
{
}

- (id) autorelease
{
  return self;
}

- (id) init
{
  NSScrollView	*scrollView;
  NSRect	scrollViewRect = {{0, 0}, {470, 150}};
  NSRect	winRect = {{100, 100}, {470, 150}};
  unsigned int	style = NSTitledWindowMask | NSClosableWindowMask
    | NSMiniaturizableWindowMask | NSResizableWindowMask;
  
  [self initWithContentRect: winRect
		  styleMask: style
		    backing: NSBackingStoreRetained
		      defer: NO];
  [self setFloatingPanel: YES];
  [self setRepresentedFilename: @"Help"];
  [self setTitle: @"Help"];
  [self setDocumentEdited: NO];
  
  scrollView = [[NSScrollView alloc] initWithFrame: scrollViewRect];
  [scrollView setHasHorizontalScroller: NO];
  [scrollView setHasVerticalScroller: YES]; 
  [scrollView setAutoresizingMask: NSViewHeightSizable];
  
  textView = [[NSTextView alloc] initWithFrame: 
				     [[scrollView contentView] frame]];
  [textView setEditable: NO];
  [textView setRichText: YES];
  [textView setSelectable: YES];
  // off white
  [textView setBackgroundColor: [NSColor colorWithCalibratedWhite: 0.85 
					 alpha: 1.0]];					
  [scrollView setDocumentView: textView];
  [[self contentView] addSubview: scrollView];
  RELEASE(scrollView);

  return self;
}

- (void) setHelpText: (NSAttributedString*) helpText
{
  // FIXME: The attributed text should be set, but there is 
  // no public method for this.
  [textView setText: [helpText string]];
}

- (void) close
{
  [NSApp stopModal];
  [super close];
}
@end
