/* 
   NSFontPanel.m

   System generic panel for selecting and previewing fonts

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Modified:  Fred Kiefer <FredKiefer@gmx.de>
   Date: Febuary 2000
   Almost complete rewrite.
   
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
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSBox.h>


float sizes[] = {4.0, 6.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 
		 14.0, 16.0, 18.0, 24.0, 36.0, 48.0, 64.0};

@interface NSFontPanel (Private)
- (NSFont *) _fontForSelection: (NSFont *) fontObject;

// Some action methods
- (void) cancel: (id) sender;
- (void) _togglePreview: (id) sender;
- (void) ok: (id) sender;

- (id)_initWithoutGModel;
@end

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

+ (BOOL)sharedFontPanelExists
{
  NSFontManager *fm = [NSFontManager sharedFontManager];

  return ([fm fontPanel: NO] != nil);
}

//
// Instance methods
//
-(id) init
{
  //  if (![GMModel loadIMFile: @"FontPanel" owner: self]);
  [self _initWithoutGModel];

  ASSIGN(_familyList, [[NSFontManager sharedFontManager] 
			availableFontFamilies]);
  ASSIGN(_faceList, [NSArray array]);
  _face = -1;
  _family = -1;

  return self;
}

- (void) dealloc
{
  RELEASE(_panelFont);
  RELEASE(_familyList);
  TEST_RELEASE(_faceList);
  TEST_RELEASE(_setButton);
  TEST_RELEASE(_previewArea);
  TEST_RELEASE(_familyBrowser);
  TEST_RELEASE(_faceBrowser);
  TEST_RELEASE(_sizeBrowser);
  TEST_RELEASE(_sizeField);
  TEST_RELEASE(_accessoryView);

  [super dealloc];
}

//
// Enabling
//
- (BOOL)isEnabled
{
  return [_setButton isEnabled];
}

- (void)setEnabled: (BOOL)flag
{
  [_setButton setEnabled: flag];
}

//
// Setting the Font 
//
- (void)setPanelFont: (NSFont *)fontObject
	  isMultiple: (BOOL)flag
{
  ASSIGN(_panelFont, fontObject);
  _multiple = flag;
  
  if (fontObject == nil)
    return;

  [_previewArea setFont: fontObject];
  
  if (flag)
    {
      // TODO: Unselect all items and show a message
      [_previewArea setStringValue: @"Multiple fonts selected"];
    }
  else
    {
      NSFontManager *fm = [NSFontManager sharedFontManager];
      NSString *family = [fontObject familyName];
      NSString *fontName = [fontObject fontName];
      float size = [fontObject pointSize];
      NSString *face = @"";
      //NSFontTraitMask traits = [fm traitsOfFont: fontObject];
      //int weight = [fm weightOfFont: fontObject];
      int i;
      
      // Select the row for the font family
      for (i = 0; i < [_familyList count]; i++)
	{
	  if ([[_familyList objectAtIndex: i] isEqualToString: family])
	    break;
	}
      if (i < [_familyList count])
	[_familyBrowser selectRow: i inColumn: 1];

      ASSIGN(_faceList, [fm availableMembersOfFontFamily: family]);
      // Select the row for the font family
      for (i = 0; i < [_faceList count]; i++)
	{
	  if ([[[_faceList objectAtIndex: i] objectAtIndex: 0] 
		isEqualToString: fontName])
	    break;
	}
      if (i < [_faceList count])
	{
	  [_faceBrowser selectRow: i inColumn: 1];
	  face = [[_faceList objectAtIndex: i] objectAtIndex: 1];
	}
      // show point size and select the row if there is one
      [_sizeField setFloatValue: size];
      for (i = 0; i < sizeof(sizes)/sizeof(float); i++)
	{
	  if (size == sizes[i])
	    [_sizeBrowser selectRow: i inColumn: 1];
	}
      
      [_previewArea setStringValue: [NSString stringWithFormat: @"%@ %@ %d PT",
					      family, face, (int)size]];
    }
}

//
// Converting
//
- (NSFont *)panelConvertFont: (NSFont *)fontObject
{
  NSFont *newFont;

  if (_multiple)
    {
      //TODO: We go over every item in the panel and check if a 
      // value is selected. If so we send it on to the manager
      //  newFont = [fm convertFont: fontObject toHaveTrait: NSItalicFontMask];
    }
  else 
    {
      newFont = [self _fontForSelection: fontObject];
    }

  return newFont;
}

//
// Works in modal loops
//
- (BOOL)worksWhenModal
{
  return YES;
}

//
// Configuring the NSFontPanel 
//
- (NSView *)accessoryView
{
  return _accessoryView;
}

- (void)setAccessoryView: (NSView *)aView
{
  // FIXME: We have to resize
  // Perhaps we could copy the code from NSSavePanel over to here
  if (_accessoryView != nil)
    [_accessoryView removeFromSuperview];

  ASSIGN(_accessoryView, aView);
  [[self contentView] addSubview: aView];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeObject: _panelFont];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_multiple];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_preview];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  _panelFont = RETAIN([aDecoder decodeObject]);
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_multiple];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_preview];

  return self;
}

@end

@implementation NSFontPanel (Privat)

- (id)_initWithoutGModel
{
  NSRect pf = {{100,100}, {300,300}};
  NSRect ta = {{0,50}, {300,250}};
  NSRect sv = {{0,5}, {300,245}};
  NSRect ts = {{0,200}, {297,40}};
  NSRect pa = {{6,0}, {285,50}};
  NSRect bs = {{0,0}, {297,188}};
  NSRect s1 = {{6,5}, {110,183}};
  NSRect s2 = {{122,5}, {110,183}};
  NSRect s3 = {{237,5}, {56,135}};
  NSRect sl = {{237,142}, {56,21}};
  NSRect l3 = {{237,166}, {56,22}};
  NSRect ba = {{0,0}, {300,50}};
  NSRect sb = {{0,45}, {300,2}};
  NSRect rb = {{56,8}, {72,24}};
  NSRect pb = {{137,8}, {72,24}};
  NSRect db = {{217,8}, {72,24}};
  NSView *v;
  NSView *topArea;
  NSView *bottomArea;
  NSView *topSplit;
  NSView *bottomSplit;
  NSSplitView *splitView;
  NSTextField *label;
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

  // preview and selection
  topArea = [[NSView alloc] initWithFrame: ta];
  [topArea setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

  splitView = [[NSSplitView alloc] initWithFrame: sv];
  [splitView setVertical: NO]; 
  [splitView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];

  topSplit = [[NSView alloc] initWithFrame: ts];
  [topSplit setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];  

  // Display for the font example
  _previewArea = [[NSTextField alloc] initWithFrame: pa];
  [_previewArea setBackgroundColor: [NSColor textBackgroundColor]];
  [_previewArea setDrawsBackground: YES];
  [_previewArea setEditable: NO];
  [_previewArea setSelectable: NO];
  //[_previewArea setUsesFontPanel: NO];
  [_previewArea setAlignment: NSCenterTextAlignment];
  [_previewArea setStringValue: @"Font preview"];
  [_previewArea setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];  
  [topSplit addSubview: _previewArea];

  bottomSplit = [[NSView alloc] initWithFrame: bs];

  // Selection of the font family
  // We use a browser with one column to get a selection list
  _familyBrowser = [[NSBrowser alloc] initWithFrame: s1];
  [_familyBrowser setDelegate: self];
  [_familyBrowser setMaxVisibleColumns: 1];
  [_familyBrowser setAllowsMultipleSelection: NO];
  [_familyBrowser setAllowsEmptySelection: YES];
  [_familyBrowser setHasHorizontalScroller: NO];
  [_familyBrowser setTitled: YES];
  [_familyBrowser setTakesTitleFromPreviousColumn: NO];
  [_familyBrowser setTarget: self];
  [_familyBrowser setDoubleAction: @selector(familySelected:)];
  [_familyBrowser setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [bottomSplit addSubview: _familyBrowser];

  // selection of type face
  // We use a browser with one column to get a selection list
  _faceBrowser = [[NSBrowser alloc] initWithFrame: s2];
  [_faceBrowser setDelegate: self];
  [_faceBrowser setMaxVisibleColumns: 1];
  [_faceBrowser setAllowsMultipleSelection: NO];
  [_faceBrowser setAllowsEmptySelection: YES];
  [_faceBrowser setHasHorizontalScroller: NO];
  [_faceBrowser setTitled: YES];
  [_faceBrowser setTakesTitleFromPreviousColumn: NO];
  [_faceBrowser setTarget: self];
  [_faceBrowser setDoubleAction: @selector(faceSelected:)];
  [_faceBrowser setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [bottomSplit addSubview: _faceBrowser];

  // label for selection of size
  label = [[NSTextField alloc] initWithFrame: l3];
  [label setFont: [NSFont boldSystemFontOfSize: 12]];
  [label setAlignment: NSCenterTextAlignment];
  [label setDrawsBackground: YES];
  [label setEditable: NO];
  [label setTextColor: [NSColor windowFrameTextColor]];
  [label setBackgroundColor: [NSColor controlShadowColor]];
  [label setStringValue: @"Size"];
  [label setAutoresizingMask: (NSViewWidthSizable | NSViewMinYMargin)];
  [bottomSplit addSubview: label];
  RELEASE(label);

  // this is the size input field
  _sizeField = [[NSTextField alloc] initWithFrame: sl];
  [_sizeField setDrawsBackground: YES];
  [_sizeField setEditable: YES];
  //[_sizeField setAllowsEditingTextAttributes: NO];
  [_sizeField setAlignment: NSCenterTextAlignment];
  [_sizeField setBackgroundColor: [NSColor windowFrameTextColor]];
  [_sizeField setAutoresizingMask: (NSViewWidthSizable | NSViewMinYMargin)];
  [bottomSplit addSubview: _sizeField];

  _sizeBrowser = [[NSBrowser alloc] initWithFrame: s3];
  [_sizeBrowser setDelegate: self];
  [_sizeBrowser setMaxVisibleColumns: 1];
  [_sizeBrowser setAllowsMultipleSelection: NO];
  [_sizeBrowser setAllowsEmptySelection: YES];
  [_sizeBrowser setHasHorizontalScroller: NO];
  [_sizeBrowser setTitled: NO];
  [_sizeBrowser setTakesTitleFromPreviousColumn: NO];
  [_sizeBrowser setTarget: self];
  [_sizeBrowser setDoubleAction: @selector(sizeSelected:)];
  [_sizeBrowser setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [bottomSplit addSubview: _sizeBrowser];

  [splitView addSubview: topSplit];
  // reset the size
  [topSplit setFrame: ts];
  RELEASE(topSplit);
  [splitView addSubview: bottomSplit];
  RELEASE(bottomSplit);
  [topArea addSubview: splitView];
  RELEASE(splitView);

  // action buttons
  bottomArea = [[NSView alloc] initWithFrame: ba];

  slash = [[NSBox alloc] initWithFrame: sb];
  [slash setBorderType: NSGrooveBorder];
  [slash setTitlePosition: NSNoTitle];
  [bottomArea addSubview: slash];
  RELEASE(slash);

  // cancle button
  revertButton = [[NSButton alloc] initWithFrame: rb];
  [revertButton setStringValue: @"Revert"];
  [revertButton setAction: @selector(cancel:)];
  [revertButton setTarget: self];
  [bottomArea addSubview: revertButton];
  RELEASE(revertButton);

  // toggle button for preview
  previewButton = [[NSButton alloc] initWithFrame: pb];
  [previewButton setStringValue: @"Preview"];
  [previewButton setButtonType: NSOnOffButton];
  [previewButton setAction: @selector(_togglePreview:)];
  [previewButton setTarget: self];
  [bottomArea addSubview: previewButton];
  RELEASE(previewButton);

  // button to set the font
  _setButton = [[NSButton alloc] initWithFrame: db];
  [_setButton setStringValue: @"Set"];
  [_setButton setAction: @selector(ok:)];
  [_setButton setTarget: self];
  [bottomArea addSubview: _setButton];
  // make it the default button
  //[self setDefaultButtonCell: [_setButton cell]];

  [v addSubview: topArea];
  RELEASE(topArea);

  // Add the accessory view, if there is one
  if (_accessoryView != nil)
    [v addSubview: _accessoryView];
    
  [v addSubview: bottomArea];
  RELEASE(bottomArea);

  return self;
}


- (void) _togglePreview: (id) sender
{
  _preview = [sender state];
  if (_preview)
    {

    }    
}

- (void) ok: (id) sender
{
  // The set button has been pushed
  NSFontManager *fm = [NSFontManager sharedFontManager];

  [fm modifyFontViaPanel: self];
  [self close];  
}

- (void) cancel: (id) sender
{
  // The cancel button has been pushed
  // we should reset the items in the panel 
  // and close the window
  [self setPanelFont: _panelFont
	isMultiple: _multiple];
  [self close];
}

- (NSFont *) _fontForSelection: (NSFont *) fontObject
{
  float size;
  NSString *fontName;

  size = [_sizeField floatValue];
  if (size == 0.0)
    size = [fontObject pointSize];
  if (_face == -1)
    // FIXME: This uses the first face of the font family
    fontName = [[_faceList objectAtIndex: 0] objectAtIndex: 0];
  else
    fontName = [[_faceList objectAtIndex: _face] objectAtIndex: 0];
  
  // FIXME: We should check if the font is correct
  return [NSFont fontWithName: fontName size: size];
}
 
@end


@implementation NSFontPanel (NSBrowserDelegate)

- (BOOL)browser:(NSBrowser *)sender 
      selectRow: (int)row
       inColumn:(int)column
{
  if (sender == _familyBrowser)
    {
      NSFontManager *fm = [NSFontManager sharedFontManager];

      ASSIGN(_faceList, [fm availableMembersOfFontFamily: 
			      [_familyList objectAtIndex: row]]);

      _family = row;
      [_faceBrowser validateVisibleColumns];
      _face = -1;
    }
  else if (sender == _faceBrowser)
    _face = row;
  else if (sender == _sizeBrowser)
    {
      float size = sizes[row];
      [_sizeField setFloatValue: size];
    }

  if (_preview)
    {
      float size = [_sizeField floatValue];
      NSString *faceName;
      NSString *familyName;
      
      if (_family == -1)
	familyName = @"";
      else
	familyName = [_familyList objectAtIndex: _family];

      if (_face == -1)
	faceName = @"";
      else
	faceName = [[_faceList objectAtIndex: _face] objectAtIndex: 1];

      // build up a font and use it in the preview area
      [_previewArea setFont: [self _fontForSelection: _panelFont]];
      [_previewArea setStringValue: [NSString stringWithFormat: @"%@ %@ %d PT",
					      familyName, faceName, (int)size]];
    }

  return YES;
}

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column
{
  if (sender == _familyBrowser)
    return [_familyList count];
  else if (sender == _faceBrowser)
    return [_faceList count];
  else if (sender == _sizeBrowser)
    return sizeof(sizes)/sizeof(float);

  return 0;
}

- (NSString *)browser:(NSBrowser *)sender titleOfColumn:(int)column
{
  if (sender == _familyBrowser)
    return @"Family";
  else if (sender == _faceBrowser)
    return @"Typeface";

  return @"";
}

- (void)browser:(NSBrowser *)sender 
willDisplayCell:(id)cell 
	  atRow:(int)row 
	 column:(int)column
{
  NSString *value = nil;
  
  if (sender == _familyBrowser)
    {
      if ([_familyList count] > row)
	{
	  value = [_familyList objectAtIndex: row];
	}
    }
  else if (sender == _faceBrowser)
    {
      if ([_faceList count] > row)
	{
	  value = [[_faceList objectAtIndex: row] objectAtIndex: 1];
	} 
    }
  else if (sender == _sizeBrowser)
    {
      value = [NSString stringWithFormat: @"%d", (int) sizes[row]];
    }
  
  [cell setStringValue: value];
  [cell setLeaf: YES];
}

- (BOOL) browser: (NSBrowser *)sender 
   isColumnValid: (int)column;
{
  return NO;
}

@end
