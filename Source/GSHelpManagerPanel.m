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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/ 

#include "AppKit/NSApplication.h"
#include "AppKit/NSAttributedString.h"
#include "AppKit/NSTextView.h"
#include "AppKit/NSTextContainer.h"
#include "AppKit/NSScrollView.h"
#include "AppKit/NSClipView.h"
#include "AppKit/NSColor.h"

#include "GNUstepGUI/GSHelpManagerPanel.h"

@implementation GSHelpManagerPanel

static GSHelpManagerPanel* _GSsharedGSHelpPanel;

+ (id) sharedHelpManagerPanel
{
  if (!_GSsharedGSHelpPanel)
    _GSsharedGSHelpPanel = [[GSHelpManagerPanel alloc] init];

  return _GSsharedGSHelpPanel;
}

- (id)init
{
  NSRect	winRect = {{100, 100}, {470, 150}};
  unsigned int style = NSTitledWindowMask | NSClosableWindowMask
                  | NSMiniaturizableWindowMask | NSResizableWindowMask;

  self = [super initWithContentRect: winRect
		                      styleMask: style
		                        backing: NSBackingStoreRetained
		                          defer: NO];
  
  if (self) {
    NSRect scrollViewRect = {{0, 0}, {470, 150}};
    NSRect r;
    NSScrollView *scrollView;
  
    [self setReleasedWhenClosed: NO]; 
    [self setFloatingPanel: YES];
 //   [self setTitle: NSLocalizedString(@"Help", @"")];
    [self setTitle: @"Help"];

    scrollView = [[NSScrollView alloc] initWithFrame: scrollViewRect];
    [scrollView setHasHorizontalScroller: NO];
    [scrollView setHasVerticalScroller: YES]; 
    [scrollView setAutoresizingMask: NSViewHeightSizable];

    r = [[scrollView contentView] frame];
    textView = [[NSTextView alloc] initWithFrame: r];
    [textView setRichText: YES];
    [textView setEditable: NO];
    [textView setSelectable: NO];
    [textView setHorizontallyResizable: NO];
    [textView setVerticallyResizable: YES];
    [textView setMinSize: NSMakeSize (0, 0)];
    [textView setMaxSize: NSMakeSize (1E7, 1E7)];
    [textView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
    [[textView textContainer] setContainerSize: NSMakeSize(r.size.width, 1e7)];
    [[textView textContainer] setWidthTracksTextView: YES];
    [textView setUsesRuler: NO];
 //   [textView setBackgroundColor: [NSColor colorWithCalibratedWhite: 0.85 alpha: 1.0]];					
    
    [scrollView setDocumentView: textView];
    RELEASE(textView);
    
    [[self contentView] addSubview: scrollView];
    RELEASE(scrollView);
  }

  return self;
}

- (void)setHelpText:(NSAttributedString *)helpText
{
  [[textView textStorage] setAttributedString: helpText];
}

- (void) close
{
  if ([self isVisible])
    {
      [NSApp stopModal];
    }
  [super close];
}

@end
