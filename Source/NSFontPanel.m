/* 
   NSFontPanel.m

   System generic panel for selecting and previewing fonts

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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
#include <AppKit/NSFontPanel.h>
#include <AppKit/NSFontManager.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSSplitView.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSButton.h>

@implementation NSFontPanel

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSFontPanel class])
    {
      NSDebugLog(@"Initialize NSFontPanel class\n");

      // Initial version
      [self setVersion:1];
    }
}

//
// Creating an NSFontPanel 
//
+ (NSFontPanel *)sharedFontPanel
{
  NSFontManager *fm = [NSFontManager sharedFontManager];

  return [fm fontPanel:YES];
}

//
// Instance methods
//

//
// Creating an NSFontPanel 
//
- (id)init
{
  NSRect pf = {{100,100}, {300,300}};
  NSRect ts = {{0,0}, {300,50}};
  NSRect bs = {{0,0}, {300,182}};
  NSRect pa = {{7,0}, {286,50}};
  NSRect l = {{7,162}, {110,20}};
  NSRect ss = {{7,0}, {110,160}};
  NSRect b = {{60,5}, {75,25}};
  NSView *v;
  NSView *topArea;
  NSView *bottomArea;
  NSView *topSplit;
  NSView *bottomSplit;
  NSSplitView *splitView;
  NSTextField *previewArea;
  NSTextField *label;
  NSScrollView *familyScroll;
  NSScrollView *typeScroll;
  NSScrollView *sizeScroll;
  NSButton *setButton;
  NSButton *revertButton;
  NSButton *previewButton;

  unsigned int  style = NSTitledWindowMask;

  self = [super initWithContentRect:pf 
		styleMask:style
		backing:NSBackingStoreRetained
		defer:NO
		screen:nil];
  [self setTitle:@"Font Panel"];

  v = [self contentView];

  topArea = [[NSView alloc] initWithFrame:NSMakeRect(0,50,300,240)];

  splitView = [[NSSplitView alloc] initWithFrame:NSMakeRect(0,0,300,240)];  
  [splitView setVertical:NO]; 
  [topArea addSubview:splitView];

  topSplit = [[NSView alloc] initWithFrame:ts];

  previewArea = [[NSTextField alloc] initWithFrame:pa];
  [previewArea setBackgroundColor:[NSColor whiteColor]];
  [previewArea setDrawsBackground:YES];
  [topSplit addSubview:previewArea];

  bottomSplit = [[NSView alloc] initWithFrame:bs];

  label = [[NSTextField alloc] initWithFrame:l];
  [label setAlignment: NSCenterTextAlignment];
  [label setFont:[NSFont boldSystemFontOfSize:12]];
  [label setStringValue:@"Family"];
  [label setDrawsBackground:YES];
  [label setTextColor:[NSColor whiteColor]];
  [label setBackgroundColor:[NSColor darkGrayColor]];
  [bottomSplit addSubview:label];
  [label release];

  familyScroll = [[NSScrollView alloc] initWithFrame:ss];
  [familyScroll setHasVerticalScroller:YES];
  [bottomSplit addSubview:familyScroll];

  l.origin.x = 120;

  label = [[NSTextField alloc] initWithFrame:l];
  [label setFont:[NSFont boldSystemFontOfSize:12]];
  [label setAlignment: NSCenterTextAlignment];
  [label setDrawsBackground:YES];
  [label setTextColor:[NSColor whiteColor]];
  [label setBackgroundColor:[NSColor darkGrayColor]];
  [label setStringValue:@"Typeface"];
  [bottomSplit addSubview:label];
  [label release];

  ss.origin.x = 120;

  typeScroll = [[NSScrollView alloc] initWithFrame:ss];
  [typeScroll setHasVerticalScroller:YES];
  [bottomSplit addSubview:typeScroll];

  l.origin.x = 233;
  l.size.width = 60;

  label = [[NSTextField alloc] initWithFrame:l];
  [label setFont:[NSFont boldSystemFontOfSize:12]];
  [label setAlignment: NSCenterTextAlignment];
  [label setDrawsBackground:YES];
  [label setTextColor:[NSColor whiteColor]];
  [label setBackgroundColor:[NSColor darkGrayColor]];
  [label setStringValue:@"Size"];
  [bottomSplit addSubview:label];
  [label release];

  // last label, this is the size input. We don't release this one.

  l.origin.x = 233;
  l.origin.y = 140;
  l.size.height = 20;
  l.size.width = 60;

  label = [[NSTextField alloc] initWithFrame:l];
  [label setDrawsBackground:YES];
  [label setBackgroundColor:[NSColor whiteColor]];
  [bottomSplit addSubview:label];

  ss.origin.x = 233;
  ss.size.height = 135;
  ss.size.width = 60;

  sizeScroll = [[NSScrollView alloc] initWithFrame:ss];
  [sizeScroll setHasVerticalScroller:YES];
  [bottomSplit addSubview:sizeScroll];

  bottomArea = [[NSView alloc] initWithFrame:NSMakeRect(0,0,300,100)];

  revertButton = [[NSButton alloc] initWithFrame:b];
  [revertButton setStringValue:@"Revert"];
  [bottomArea addSubview:revertButton];

  b.origin.x = 140;

  previewButton = [[NSButton alloc] initWithFrame:b];
  [previewButton setStringValue:@"Preview"];
  [bottomArea addSubview:previewButton];

  b.origin.x = 220;

  setButton = [[NSButton alloc] initWithFrame:b];
  [setButton setStringValue:@"Set"];
  [bottomArea addSubview:setButton];

  [splitView addSubview:bottomSplit];
  [splitView addSubview:topSplit];

  [v addSubview:topArea];
  [v addSubview:bottomArea];

  return self;
}

- (NSFont *)panelConvertFont:(NSFont *)fontObject
{
  return panel_font;
}

//
// Setting the Font 
//
- (void)setPanelFont:(NSFont *)fontObject
	  isMultiple:(BOOL)flag
{
  panel_font = fontObject;
}

//
// Configuring the NSFontPanel 
//
- (NSView *)accessoryView
{
  return nil;
}

- (BOOL)isEnabled
{
  return NO;
}

- (void)setAccessoryView:(NSView *)aView
{}

- (void)setEnabled:(BOOL)flag
{}

- (BOOL)worksWhenModal
{
  return NO;
}

//
// Displaying the NSFontPanel 
//
- (void)orderWindow:(NSWindowOrderingMode)place	 
	 relativeTo:(int)otherWindows
{}

- (void)display
{
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeObject: panel_font];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  panel_font = [aDecoder decodeObject];

  return self;
}

@end
