/* 
   NSFontPanel.m

   System generic panel for selecting and previewing fonts

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
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
- (NSFont*) _fontForSelection: (NSFont*) fontObject;

// Some action methods
- (void) cancel: (id) sender;
- (void) _togglePreview: (id) sender;
- (void) ok: (id) sender;

- (id)_initWithoutGModel;
@end

@implementation NSFontPanel

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSFontPanel class])
    {
      NSDebugLog(@"Initialize NSFontPanel class\n");

      // Initial version
      [self setVersion: 1];
    }
}

/*
 * Creating an NSFontPanel 
 */
+ (NSFontPanel*) sharedFontPanel
{
  NSFontManager	*fm = [NSFontManager sharedFontManager];

  return [fm fontPanel: YES];
}

+ (BOOL) sharedFontPanelExists
{
  NSFontManager	*fm = [NSFontManager sharedFontManager];

  return ([fm fontPanel: NO] != nil);
}

/*
 * Instance methods
 */
- (id) init
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

  TEST_RELEASE(_accessoryView);

  [super dealloc];
}

/*
 * Enabling
 */
- (BOOL) isEnabled
{
  NSButton *setButton = [[self contentView] viewWithTag: NSFPSetButton];

  return [setButton isEnabled];
}

- (void) setEnabled: (BOOL)flag
{
  NSButton *setButton = [[self contentView] viewWithTag: NSFPSetButton];

  [setButton setEnabled: flag];
}

/*
 * Setting the Font 
 */
- (void) setPanelFont: (NSFont*)fontObject
	   isMultiple: (BOOL)flag
{
  NSTextField *previewArea = [[self contentView] viewWithTag: NSFPPreviewField];

  ASSIGN(_panelFont, fontObject);
  _multiple = flag;
  
  if (fontObject == nil)
    return;

  [previewArea setFont: fontObject];
  
  if (flag)
    {
      // TODO: Unselect all items and show a message
      [previewArea setStringValue: @"Multiple fonts selected"];
    }
  else
    {
      NSFontManager *fm = [NSFontManager sharedFontManager];
      NSString *family = [fontObject familyName];
      NSString *fontName = [fontObject fontName];
      float size = [fontObject pointSize];
      NSTextField *sizeField = [[self contentView] viewWithTag: NSFPSizeField];
      NSBrowser *sizeBrowser = [[self contentView] viewWithTag: NSFPSizeBrowser];
      NSBrowser *familyBrowser = [[self contentView] viewWithTag: NSFPFamilyBrowser];
      NSBrowser *faceBrowser = [[self contentView] viewWithTag: NSFPFaceBrowser];
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
	{
	  [familyBrowser selectRow: i inColumn: 0];
	  _family = i;
	  ASSIGN(_faceList, [fm availableMembersOfFontFamily: family]);
	  [faceBrowser validateVisibleColumns];
	  _face = -1;
	}

      // Select the row for the font face
      for (i = 0; i < [_faceList count]; i++)
	{
	  if ([[[_faceList objectAtIndex: i] objectAtIndex: 0] 
		isEqualToString: fontName])
	    break;
	}
      if (i < [_faceList count])
	{
	  [faceBrowser selectRow: i inColumn: 0];
	  _face = i;
	  face = [[_faceList objectAtIndex: i] objectAtIndex: 1];
	}
      // show point size and select the row if there is one
      [sizeField setFloatValue: size];
      for (i = 0; i < sizeof(sizes)/sizeof(float); i++)
	{
	  if (size == sizes[i])
	    [sizeBrowser selectRow: i inColumn: 0];
	}
      
      [previewArea setStringValue: [NSString stringWithFormat: @"%@ %@ %d PT",
					     family, face, (int)size]];
    }
}

/*
 * Converting
 */
- (NSFont*) panelConvertFont: (NSFont*)fontObject
{
  NSFont	*newFont;

  if (_multiple)
    {
      //TODO: We go over every item in the panel and check if a 
      // value is selected. If so we send it on to the manager
      //  newFont = [fm convertFont: fontObject toHaveTrait: NSItalicFontMask];
      NSLog(@"Multiple font conversion not implemented in NSFontPanel");
      newFont = [self _fontForSelection: fontObject];
    }
  else 
    {
      newFont = [self _fontForSelection: fontObject];
    }

  if (newFont == nil)
    newFont = fontObject;

  return newFont;
}

/*
 * Works in modal loops
 */
- (BOOL) worksWhenModal
{
  return YES;
}

/*
 * Configuring the NSFontPanel 
 */
- (NSView*) accessoryView
{
  return _accessoryView;
}

- (void) setAccessoryView: (NSView*)aView
{
  // FIXME: We have to resize
  // Perhaps we could copy the code from NSSavePanel over to here
  if (_accessoryView != nil)
    [_accessoryView removeFromSuperview];

  ASSIGN(_accessoryView, aView);
  [[self contentView] addSubview: aView];
}

/*
 * NSCoding protocol
 */
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

- (id) _initWithoutGModel
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
  NSTextField *previewArea;
  NSBrowser *sizeBrowser;
  NSBrowser *familyBrowser;
  NSBrowser *faceBrowser;
  NSTextField *label;
  NSTextField *sizeField;
  NSButton *revertButton;
  NSButton *previewButton;
  NSButton *setButton;
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
  previewArea = [[NSTextField alloc] initWithFrame: pa];
  [previewArea setBackgroundColor: [NSColor textBackgroundColor]];
  [previewArea setDrawsBackground: YES];
  [previewArea setEditable: NO];
  [previewArea setSelectable: NO];
  //[previewArea setUsesFontPanel: NO];
  [previewArea setAlignment: NSCenterTextAlignment];
  [previewArea setStringValue: @"Font preview"];
  [previewArea setAutoresizingMask: (NSViewWidthSizable|NSViewHeightSizable)];  
  [previewArea setTag: NSFPPreviewField];
  [topSplit addSubview: previewArea];
  RELEASE(previewArea);

  bottomSplit = [[NSView alloc] initWithFrame: bs];

  // Selection of the font family
  // We use a browser with one column to get a selection list
  familyBrowser = [[NSBrowser alloc] initWithFrame: s1];
  [familyBrowser setDelegate: self];
  [familyBrowser setMaxVisibleColumns: 1];
  [familyBrowser setAllowsMultipleSelection: NO];
  [familyBrowser setAllowsEmptySelection: YES];
  [familyBrowser setHasHorizontalScroller: NO];
  [familyBrowser setTitled: YES];
  [familyBrowser setTakesTitleFromPreviousColumn: NO];
  [familyBrowser setTarget: self];
  [familyBrowser setDoubleAction: @selector(familySelected:)];
  [familyBrowser setAutoresizingMask: (NSViewWidthSizable|NSViewHeightSizable)];
  [familyBrowser setTag: NSFPFamilyBrowser];
  [bottomSplit addSubview: familyBrowser];
  RELEASE(familyBrowser);

  // selection of type face
  // We use a browser with one column to get a selection list
  faceBrowser = [[NSBrowser alloc] initWithFrame: s2];
  [faceBrowser setDelegate: self];
  [faceBrowser setMaxVisibleColumns: 1];
  [faceBrowser setAllowsMultipleSelection: NO];
  [faceBrowser setAllowsEmptySelection: YES];
  [faceBrowser setHasHorizontalScroller: NO];
  [faceBrowser setTitled: YES];
  [faceBrowser setTakesTitleFromPreviousColumn: NO];
  [faceBrowser setTarget: self];
  [faceBrowser setDoubleAction: @selector(faceSelected:)];
  [faceBrowser setAutoresizingMask: (NSViewWidthSizable|NSViewHeightSizable)];
  [faceBrowser setTag: NSFPFaceBrowser];
  [bottomSplit addSubview: faceBrowser];
  RELEASE(faceBrowser);

  // label for selection of size
  label = [[NSTextField alloc] initWithFrame: l3];
  [label setFont: [NSFont boldSystemFontOfSize: 0]];
  [label setAlignment: NSCenterTextAlignment];
  [label setDrawsBackground: YES];
  [label setEditable: NO];
  [label setTextColor: [NSColor windowFrameTextColor]];
  [label setBackgroundColor: [NSColor controlShadowColor]];
  [label setStringValue: @"Size"];
  [label setAutoresizingMask: (NSViewWidthSizable | NSViewMinYMargin)];
  [label setTag: NSFPSizeTitle];
  [bottomSplit addSubview: label];
  RELEASE(label);

  // this is the size input field
  sizeField = [[NSTextField alloc] initWithFrame: sl];
  [sizeField setDrawsBackground: YES];
  [sizeField setEditable: YES];
  //[sizeField setAllowsEditingTextAttributes: NO];
  [sizeField setAlignment: NSCenterTextAlignment];
  [sizeField setBackgroundColor: [NSColor windowFrameTextColor]];
  [sizeField setAutoresizingMask: (NSViewWidthSizable|NSViewMinYMargin)];
  [sizeField setTag: NSFPSizeField];
  [bottomSplit addSubview: sizeField];
  RELEASE(sizeField);

  sizeBrowser = [[NSBrowser alloc] initWithFrame: s3];
  [sizeBrowser setDelegate: self];
  [sizeBrowser setMaxVisibleColumns: 1];
  [sizeBrowser setAllowsMultipleSelection: NO];
  [sizeBrowser setAllowsEmptySelection: YES];
  [sizeBrowser setHasHorizontalScroller: NO];
  [sizeBrowser setTitled: NO];
  [sizeBrowser setTakesTitleFromPreviousColumn: NO];
  [sizeBrowser setTarget: self];
  [sizeBrowser setDoubleAction: @selector(sizeSelected:)];
  [sizeBrowser setAutoresizingMask: (NSViewWidthSizable|NSViewHeightSizable)];
  [sizeBrowser setTag: NSFPSizeBrowser];
  [bottomSplit addSubview: sizeBrowser];
  RELEASE(sizeBrowser);

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
  [revertButton setTag: NSFPRevertButton];
  [bottomArea addSubview: revertButton];
  RELEASE(revertButton);

  // toggle button for preview
  previewButton = [[NSButton alloc] initWithFrame: pb];
  [previewButton setStringValue: @"Preview"];
  [previewButton setButtonType: NSOnOffButton];
  [previewButton setAction: @selector(_togglePreview:)];
  [previewButton setTarget: self];
  [previewButton setTag: NSFPPreviewButton];
  [bottomArea addSubview: previewButton];
  RELEASE(previewButton);

  // button to set the font
  setButton = [[NSButton alloc] initWithFrame: db];
  [setButton setStringValue: @"Set"];
  [setButton setAction: @selector(ok:)];
  [setButton setTarget: self];
  [setButton setTag: NSFPSetButton];
  [bottomArea addSubview: setButton];
  // make it the default button
  //[self setDefaultButtonCell: [setButton cell]];
  RELEASE(setButton);

  [v addSubview: topArea];
  RELEASE(topArea);

  // Add the accessory view, if there is one
  if (_accessoryView != nil)
    [v addSubview: _accessoryView];
    
  [v addSubview: bottomArea];
  RELEASE(bottomArea);

  return self;
}


- (void) _togglePreview: (id)sender
{
  _preview = (sender == nil) ? YES : [sender state];
  if (_preview)
    {
      NSFont	*font = [self _fontForSelection: _panelFont];
      NSTextField *sizeField = [[self contentView] viewWithTag: NSFPSizeField];
      float	size = [sizeField floatValue];
      NSString	*faceName;
      NSString	*familyName;
      NSTextField *previewArea = [[self contentView] viewWithTag: NSFPPreviewField];
      
      if (size == 0 && font != nil)
	{
	  size = [font pointSize];
	}
      if (_family == -1)
	{
	  familyName = @"NoFamily";
	}
      else
	{
	  familyName = [_familyList objectAtIndex: _family];
	}
      if (_face == -1)
	{
	  faceName = @"NoFace";
	}
      else
	{
	  faceName = [[_faceList objectAtIndex: _face] objectAtIndex: 1];
	}
      // build up a font and use it in the preview area
      if (font != nil)
	{
	  [previewArea setFont: font];
	}
      [previewArea setStringValue: [NSString stringWithFormat: @"%@ %@ %d PT",
					     familyName, faceName, (int)size]];
    }    
}

- (void) ok: (id)sender
{
  // The set button has been pushed
  NSFontManager *fm = [NSFontManager sharedFontManager];

  [fm modifyFontViaPanel: self];
}

- (void) cancel: (id)sender
{
  /*
   * The cancel button has been pushed
   * we should reset the items in the panel 
   */
  [self setPanelFont: _panelFont
	  isMultiple: _multiple];
}

- (NSFont*) _fontForSelection: (NSFont*)fontObject
{
  float		size;
  NSString	*fontName;
  NSTextField *sizeField = [[self contentView] viewWithTag: NSFPSizeField];

  size = [sizeField floatValue];
  if (size == 0.0)
    {
      if (fontObject == nil)
	{
	  size = 12.0;
	}
      else
	{
	  size = [fontObject pointSize];
	}
    }
  if (_face < 0)
    {
      unsigned	i = [_faceList count];

      if (i == 0)
	{
	  return nil;	/* Nothing available	*/
	}
      // FIXME - just uses first face
      fontName = [[_faceList objectAtIndex: 0] objectAtIndex: 0];
    }
  else
    {
      fontName = [[_faceList objectAtIndex: _face] objectAtIndex: 0];
    }
  
  // FIXME: We should check if the font is correct
  return [NSFont fontWithName: fontName size: size];
}
 
@end


@implementation NSFontPanel (NSBrowserDelegate)

- (BOOL) browser: (NSBrowser*)sender 
       selectRow: (int)row
	inColumn: (int)column
{
  if ([sender tag] == NSFPFamilyBrowser)
    {
      NSFontManager *fm = [NSFontManager sharedFontManager];
      NSBrowser *faceBrowser = [[self contentView] viewWithTag: NSFPFaceBrowser];

      ASSIGN(_faceList, [fm availableMembersOfFontFamily: 
			      [_familyList objectAtIndex: row]]);

      _family = row;
      [faceBrowser validateVisibleColumns];
      _face = -1;
    }
  else if ([sender tag] == NSFPFaceBrowser)
    {
      _face = row;
    }
  else if ([sender tag] == NSFPSizeBrowser)
    {
      float size = sizes[row];
      NSTextField *sizeField = [[self contentView] viewWithTag: NSFPSizeField];

      [sizeField setFloatValue: size];
    }

  if (_preview)
    {
      [self _togglePreview: nil];
    }

  return YES;
}

- (int) browser: (NSBrowser*)sender numberOfRowsInColumn: (int)column
{
  if ([sender tag] == NSFPFamilyBrowser)
    return [_familyList count];
  else if ([sender tag] == NSFPFaceBrowser)
    return [_faceList count];
  else if ([sender tag] == NSFPSizeBrowser)
    return sizeof(sizes)/sizeof(float);

  return 0;
}

- (NSString*) browser: (NSBrowser*)sender titleOfColumn: (int)column
{
  if ([sender tag] == NSFPFamilyBrowser)
    return @"Family";
  else if ([sender tag] == NSFPFaceBrowser)
    return @"Typeface";

  return @"";
}

- (void) browser: (NSBrowser*)sender 
 willDisplayCell: (id)cell 
	   atRow: (int)row 
	  column: (int)column
{
  NSString *value = nil;
  
  if ([sender tag] == NSFPFamilyBrowser)
    {
      if ([_familyList count] > row)
	{
	  value = [_familyList objectAtIndex: row];
	}
    }
  else if ([sender tag] == NSFPFaceBrowser)
    {
      if ([_faceList count] > row)
	{
	  value = [[_faceList objectAtIndex: row] objectAtIndex: 1];
	} 
    }
  else if ([sender tag] == NSFPSizeBrowser)
    {
      value = [NSString stringWithFormat: @"%d", (int) sizes[row]];
    }
  
  [cell setStringValue: value];
  [cell setLeaf: YES];
}

- (BOOL) browser: (NSBrowser*)sender 
   isColumnValid: (int)column;
{
  return NO;
}

@end
