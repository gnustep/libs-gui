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
#include <AppKit/NSFont.h>
#include <AppKit/NSFontPanel.h>
#include <AppKit/NSFontManager.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSSplitView.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSBox.h>

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
      [self setVersion: 1];
    }
}

//
// Creating an NSFontPanel 
//
+ (NSFontPanel *)sharedFontPanel
{
  NSFontManager *fm = [NSFontManager sharedFontManager];

  return [fm fontPanel: YES];
}

//
// Instance methods
//

//
// Creating an NSFontPanel 
//
- (id)init
{
  NSRect pf = {{100,100}, {297,298}};
  NSRect ts = {{0,0}, {297,48}};
  NSRect bs = {{0,0}, {297,184}};
  NSRect pa = {{8,0}, {281,48}};
  NSRect l = {{8,162}, {109,21}};
  NSRect ss = {{8,0}, {109,161}};
  NSRect b = {{56,8}, {72,24}};
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
  NSBox *slash;

  unsigned int style = NSTitledWindowMask | NSClosableWindowMask
                     | NSMiniaturizableWindowMask | NSResizableWindowMask;

  self = [super initWithContentRect: pf 
		styleMask: style
		backing: NSBackingStoreRetained
		defer: NO
		screen: nil];
  [self setTitle: @"Font Panel"];

  v = [self contentView];

  topArea = [[NSView alloc] initWithFrame: NSMakeRect(0,50,300,250)];

  splitView = [[NSSplitView alloc] initWithFrame: NSMakeRect(0,0,300,240)];  
  [splitView setVertical: NO]; 
  [topArea addSubview: splitView];

  topSplit = [[NSView alloc] initWithFrame: ts];

  previewArea = [[NSTextField alloc] initWithFrame: pa];
  [previewArea setBackgroundColor: [NSColor textBackgroundColor]];
  [previewArea setDrawsBackground: YES];
  [topSplit addSubview: previewArea];

  bottomSplit = [[NSView alloc] initWithFrame: bs];

  l.size.width = 110;

  label = [[NSTextField alloc] initWithFrame: l];
  [label setAlignment: NSCenterTextAlignment];
  [label setFont: [NSFont boldSystemFontOfSize: 12]];
  [label setStringValue: @"Family"];
  [label setEditable: NO];
  [label setDrawsBackground: YES];
  [label setTextColor: [NSColor windowFrameTextColor]];
  [label setBackgroundColor: [NSColor controlShadowColor]];
  [bottomSplit addSubview: label];
  [label release];

  ss.size.width = 110;

  familyScroll = [[NSScrollView alloc] initWithFrame: ss];
  [familyScroll setHasVerticalScroller: YES];
  [bottomSplit addSubview: familyScroll];

  l.size.width = 109;
  l.origin.x = 120;

  label = [[NSTextField alloc] initWithFrame: l];
  [label setFont: [NSFont boldSystemFontOfSize: 12]];
  [label setEditable: NO];
  [label setAlignment: NSCenterTextAlignment];
  [label setDrawsBackground: YES];
  [label setTextColor: [NSColor windowFrameTextColor]];
  [label setBackgroundColor: [NSColor controlShadowColor]];
  [label setStringValue: @"Typeface"];
  [bottomSplit addSubview: label];
  [label release];

  ss.size.width = 109;
  ss.origin.x = 120;

  typeScroll = [[NSScrollView alloc] initWithFrame: ss];
  [typeScroll setHasVerticalScroller: YES];
  [bottomSplit addSubview: typeScroll];

  l.origin.x = 231;
  l.size.width = 58;

  label = [[NSTextField alloc] initWithFrame: l];
  [label setFont: [NSFont boldSystemFontOfSize: 12]];
  [label setAlignment: NSCenterTextAlignment];
  [label setDrawsBackground: YES];
  [label setEditable: NO];
  [label setTextColor: [NSColor windowFrameTextColor]];
  [label setBackgroundColor: [NSColor controlShadowColor]];
  [label setStringValue: @"Size"];
  [bottomSplit addSubview: label];
  [label release];

  // last label, this is the size input. We don't release this one.

  l.origin.x = 231;
  l.origin.y = 140;

  label = [[NSTextField alloc] initWithFrame: l];
  [label setDrawsBackground: YES];
  [label setBackgroundColor: [NSColor windowFrameTextColor]];
  [bottomSplit addSubview: label];

  ss.origin.x = 231;
  ss.size.height = 138;
  ss.size.width = 58;

  sizeScroll = [[NSScrollView alloc] initWithFrame: ss];
  [sizeScroll setHasVerticalScroller: YES];
  [bottomSplit addSubview: sizeScroll];

  bottomArea = [[NSView alloc] initWithFrame: NSMakeRect(0,0,300,50)];
 
  slash = [[NSBox alloc] initWithFrame: NSMakeRect(0,40,300,2)];
  [slash setBorderType: NSGrooveBorder];
  [slash setTitlePosition: NSNoTitle];
  [bottomArea addSubview: slash];
  [slash release];

  revertButton = [[NSButton alloc] initWithFrame: b];
  [revertButton setStringValue: @"Revert"];
  [bottomArea addSubview: revertButton];

  b.origin.x = 137;

  previewButton = [[NSButton alloc] initWithFrame: b];
  [previewButton setStringValue: @"Preview"];
  [previewButton setButtonType: NSOnOffButton];
  [bottomArea addSubview: previewButton];

  b.origin.x = 217;

  setButton = [[NSButton alloc] initWithFrame: b];
  [setButton setStringValue: @"Set"];
  [bottomArea addSubview: setButton];

  [splitView addSubview: bottomSplit];
  [splitView addSubview: topSplit];

  [v addSubview: topArea];
  [v addSubview: bottomArea];

  return self;
}

- (NSFont *)panelConvertFont: (NSFont *)fontObject
{
  return panel_font;
}

//
// Setting the Font 
//
- (void)setPanelFont: (NSFont *)fontObject
	  isMultiple: (BOOL)flag
{
  ASSIGN(panel_font, fontObject);
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

- (void)setAccessoryView: (NSView *)aView
{}

- (void)setEnabled: (BOOL)flag
{}

- (BOOL)worksWhenModal
{
  return NO;
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

  panel_font = RETAIN([aDecoder decodeObject]);

  return self;
}

@end
