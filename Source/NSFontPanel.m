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
  NSRect ts = {{0,250}, {300,50}};
  NSRect bs = {{0,0}, {300,300}};
  NSRect pa = {{5,5}, {290,40}};
  NSRect l = {{5,215}, {110, 20}};
  NSRect ss = {{5,50}, {110, 160}};
  NSRect b = {{60,5}, {75,25}};
  NSView *v;
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

//  v = [self contentView];

  splitView = [NSSplitView new];  
  [splitView setVertical:NO]; 
  [self setContentView:splitView];

  topSplit = [[NSView alloc] initWithFrame:ts];

  previewArea = [[NSTextField alloc] initWithFrame:pa];
  [previewArea setBackgroundColor:[NSColor whiteColor]];
  [previewArea setDrawsBackground:YES];
  [topSplit addSubview:previewArea];

  bottomSplit = [[NSView alloc] initWithFrame:bs];

  label = [[NSTextField alloc] initWithFrame:l];
  [label setAlignment: NSCenterTextAlignment];
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

  l.origin.x = 235;
  l.size.width = 60;

  label = [[NSTextField alloc] initWithFrame:l];
  [label setAlignment: NSCenterTextAlignment];
  [label setDrawsBackground:YES];
  [label setTextColor:[NSColor whiteColor]];
  [label setBackgroundColor:[NSColor darkGrayColor]];
  [label setStringValue:@"Size"];
  [bottomSplit addSubview:label];
  [label release];

  // last label, this is the size input. We don't release this one.

  l.origin.x = 235;
  l.origin.y = 190;
  l.size.height = 20;
  l.size.width = 60;

  label = [[NSTextField alloc] initWithFrame:l];
  [label setDrawsBackground:YES];
  [label setBackgroundColor:[NSColor whiteColor]];
  [bottomSplit addSubview:label];

  ss.origin.x = 235;
  ss.origin.y = 50;
  ss.size.height = 135;
  ss.size.width = 60;

  sizeScroll = [[NSScrollView alloc] initWithFrame:ss];
  [sizeScroll setHasVerticalScroller:YES];
  [bottomSplit addSubview:sizeScroll];

  revertButton = [[NSButton alloc] initWithFrame:b];
  [revertButton setStringValue:@"Revert"];
  [bottomSplit addSubview:revertButton];

  b.origin.x = 140;

  previewButton = [[NSButton alloc] initWithFrame:b];
  [previewButton setStringValue:@"Preview"];
  [bottomSplit addSubview:previewButton];

  b.origin.x = 220;

  setButton = [[NSButton alloc] initWithFrame:b];
  [setButton setStringValue:@"Set"];
  [bottomSplit addSubview:setButton];

  [splitView addSubview:bottomSplit];
  [splitView addSubview:topSplit];

  return self;
}

/*
- initWithFrame:(NSRect)aFrame
{
  [super initWithFrame:aFrame];
}
*/
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
