/* 
   NSFontManager.m

   Manages system and user fonts

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Modified:  Fred Kiefer <FredKiefer@gmx.de>
   Date: January 2000
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
#include <Foundation/NSArray.h>
#include <Foundation/NSSet.h>
#include <AppKit/NSFontManager.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSFontPanel.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/GSFontInfo.h>


/*
 * Class variables
 */
static NSFontManager	*sharedFontManager = nil;
static NSFontPanel	*fontPanel = nil;
static Class		fontManagerClass = Nil;
static Class		fontPanelClass = Nil;

@implementation NSFontManager

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSFontManager class])
    {
      NSDebugLog(@"Initialize NSFontManager class\n");

      // Initial version
      [self setVersion: 1];

      // Set the factories
      [self setFontManagerFactory: [NSFontManager class]];
      [self setFontPanelFactory: [NSFontPanel class]];
    }
}

/*
 * Managing the FontManager
 */
+ (void) setFontManagerFactory: (Class)class
{
  fontManagerClass = class;
}

+ (void) setFontPanelFactory: (Class)class
{
  fontPanelClass = class;
}

+ (NSFontManager*) sharedFontManager
{
  if (!sharedFontManager)
    {
      NSDebugLog(@"Initializing NSFontManager fonts\n");
      sharedFontManager = [[fontManagerClass alloc] init];
    }
  return sharedFontManager;
}

/*
 * Instance methods
 */
- (id) init
{
  if (sharedFontManager && self != sharedFontManager)
    {
      RELEASE(self);
      return sharedFontManager;
    }
  self = [super init];

  _action = @selector(changeFont:);
  _storedTag = NSNoFontChangeAction;
  _fontEnumerator = RETAIN([GSFontEnumerator  
			     sharedEnumeratorWithFontManager: self]);

  return self;
}

- (void) dealloc
{
  TEST_RELEASE(_selectedFont);
  TEST_RELEASE(_fontMenu);
  TEST_RELEASE(_fontEnumerator);
  [super dealloc];
}

/*
 * information on available fonts
 */
- (NSArray*) availableFonts
{
  return [_fontEnumerator availableFonts];
}

- (NSArray*) availableFontFamilies
{
  return [_fontEnumerator availableFontFamilies];
}

- (NSArray*) availableFontNamesWithTraits: (NSFontTraitMask)fontTraitMask
{
  int i, j;
  NSArray *fontFamilies = [self availableFontFamilies];
  NSMutableArray *fontNames = [NSMutableArray array];
  NSFontTraitMask traits;

  for (i = 0; i < [fontFamilies count]; i++)
    {
      NSArray *fontDefs = [self availableMembersOfFontFamily: 
				  [fontFamilies objectAtIndex: i]];
      
      for (j = 0; j < [fontDefs count]; j++)
	{
	  NSArray	*fontDef = [fontDefs objectAtIndex: j];

	  traits = [[fontDef objectAtIndex: 3] unsignedIntValue];
	  // Check if the font has exactly the given mask
	  if (traits == fontTraitMask)
	    {
	      NSString *name = [fontDef objectAtIndex: 0];
	
	      if ([self _includeFont: name])
		[fontNames addObject: name];
	    }
	}
    }

  return fontNames;
}

/*
 * This are somewhat strange methods, as they are not in the list,
 * but their implementation is defined.
 */
- (NSArray*) availableMembersOfFontFamily: (NSString*)family
{
  return [_fontEnumerator availableMembersOfFontFamily: family];
}

- (NSString*) localizedNameForFamily: (NSString*)family 
				face: (NSString*)face
{
  // TODO
  return [NSString stringWithFormat: @"%@-%@", family, face];
}

//
// Selecting fonts
//

- (void) setSelectedFont: (NSFont*)fontObject
	      isMultiple: (BOOL)flag
{
  if (_selectedFont == fontObject)
    {
      if (flag != _multiple)
	{
	  _multiple = flag;
	  // The panel should also know if multiple changed
	  if (fontPanel != nil)
	    [fontPanel setPanelFont: fontObject isMultiple: flag];
	}
      return;
    }

  _multiple = flag;
  ASSIGN(_selectedFont, fontObject);

  if (fontPanel != nil)
    [fontPanel setPanelFont: fontObject isMultiple: flag];
  
  if (_fontMenu != nil)
    {
      NSMenuItem *menuItem;
      NSFontTraitMask trait = [self traitsOfFont: fontObject];

      /*
       * FIXME: We should check if that trait is available
       * We keep the tag, to mark the item
       */
      if (trait & NSItalicFontMask)
	{
	  menuItem = [_fontMenu itemWithTag: NSItalicFontMask];
	  if (menuItem != nil)
	    {
	      [menuItem setTitle: @"Unitalic"];
	      [menuItem setAction: @selector(removeFontTrait:)];
	    }
	}
      else
	{
	  menuItem = [_fontMenu itemWithTag: NSItalicFontMask];
	  if (menuItem != nil)
	    {
	      [menuItem setTitle: @"Italic"];
	      [menuItem setAction: @selector(addFontTrait:)];
	    }
	}

      if (trait & NSBoldFontMask)
	{
	  menuItem = [_fontMenu itemWithTag: NSBoldFontMask];
	  if (menuItem != nil)
	    {
	      [menuItem setTitle: @"Unbold"];
	      [menuItem setAction: @selector(removeFontTrait:)];
	    }
	}
      else
	{
	  menuItem = [_fontMenu itemWithTag: NSBoldFontMask];
	  if (menuItem != nil)
	    {
	      [menuItem setTitle: @"Bold"];
	      [menuItem setAction: @selector(addFontTrait:)];
	    }
	}

      // TODO Update the rest of the font menu to reflect this font
    }
}

- (NSFont*) selectedFont
{
  return _selectedFont;
}

- (BOOL) isMultiple
{
  return _multiple;
}

/*
 * Action methods
 */
- (void) addFontTrait: (id)sender
{
  _storedTag = NSAddTraitFontAction;
  _trait = [sender tag];
  [self sendAction];

  // We update our own selected font
  if (_selectedFont != nil)
    {
      NSFont	*newFont = [self convertFont: _selectedFont];

      if (newFont != nil)
	{
	  [self setSelectedFont: newFont isMultiple: _multiple];
	}
    }
}

- (void) removeFontTrait: (id)sender
{
  _storedTag = NSRemoveTraitFontAction;
  _trait = [sender tag];
  [self sendAction];

  // We update our own selected font
  if (_selectedFont != nil)
    {
      NSFont	*newFont = [self convertFont: _selectedFont];

      if (newFont != nil)
	{
	  [self setSelectedFont: newFont isMultiple: _multiple];
	}
    }
}

- (void) modifyFont: (id)sender
{
  _storedTag = [sender tag];
  [self sendAction];

  // We update our own selected font
  if (_selectedFont != nil)
    {
      NSFont	*newFont = [self convertFont: _selectedFont];

      if (newFont != nil)
	{
	  [self setSelectedFont: newFont isMultiple: _multiple];
	}
    }
}

- (void) modifyFontViaPanel: (id)sender
{
  _storedTag = NSViaPanelFontAction;
  [self sendAction];

  // We update our own selected font
  if (_selectedFont != nil)
    {
      NSFont	*newFont = [self convertFont: _selectedFont];

      if (newFont != nil)
	{
	  [self setSelectedFont: newFont isMultiple: _multiple];
	}
    }
}

/*
 * Automatic font conversion
 */
- (NSFont*) convertFont: (NSFont*)fontObject
{
  NSFont *newFont = fontObject;
  int i;
  float size;
  float sizes[] = {4.0, 6.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 
		   14.0, 16.0, 18.0, 24.0, 36.0, 48.0, 64.0};

  if (fontObject == nil)
    return nil;

  switch (_storedTag)
    {
      case NSNoFontChangeAction: 
	break;
      case NSViaPanelFontAction: 
	if (fontPanel != nil)
	  {
	    newFont = [fontPanel panelConvertFont: fontObject];
	  }
	break;
      case NSAddTraitFontAction: 
	newFont = [self convertFont: fontObject toHaveTrait: _trait];
	break;
      case NSRemoveTraitFontAction: 
	 newFont = [self convertFont: fontObject toNotHaveTrait: _trait];
	break;
      case NSSizeUpFontAction: 
	size = [fontObject pointSize];
	for (i = 0; i < sizeof(sizes)/sizeof(float); i++)
	  {
	    if (sizes[i] > size)
	      {
		size = sizes[i];
		break;
	      }
	  }
	newFont = [self convertFont: fontObject 
			toSize: size];
	break;
      case NSSizeDownFontAction: 
	size = [fontObject pointSize];
	for (i = sizeof(sizes)/sizeof(float) -1; i >= 0; i--)
	  {
	    if (sizes[i] < size)
	      {
		size = sizes[i];
		break;
	      }
	  }
	newFont = [self convertFont: fontObject 
			toSize: size];
	break;
      case NSHeavierFontAction: 
	newFont = [self convertWeight: YES ofFont: fontObject]; 
	break;
      case NSLighterFontAction: 
	newFont = [self convertWeight: NO ofFont: fontObject]; 
	break;
    }

  return newFont;
}


/*
 * Converting Fonts
 */

- (NSFont*) convertFont: (NSFont*)fontObject
	       toFamily: (NSString*)family
{
  if ([family isEqualToString: [fontObject familyName]])
    {
      // If already of that family then just return it
      return fontObject;
    }
  else
    {
      // Else convert it
      NSFont *newFont;
      NSFontTraitMask trait = [self traitsOfFont: fontObject];
      int weight = [self weightOfFont: fontObject];
      float size = [fontObject pointSize];

      newFont = [self fontWithFamily: family 
			      traits: trait
			      weight: weight
				size: size];
      if (newFont == nil)
	return fontObject;
      else 
	return newFont;
    }
}

- (NSFont*) convertFont: (NSFont*)fontObject
		 toFace: (NSString*)typeface
{
  NSFont *newFont;

  // This conversion just retains the point size
  if ([[fontObject fontName] isEqualToString: typeface])
    {
      return fontObject;
    }

  newFont = [NSFont fontWithName: typeface size: [fontObject pointSize]];
  if (newFont == nil)
    return fontObject;
  else 
    return newFont;
}

- (NSFont*) convertFont: (NSFont*)fontObject
	    toHaveTrait: (NSFontTraitMask)trait
{
  NSFontTraitMask t = [self traitsOfFont: fontObject];

  if (t & trait)
    {
      // If already have that trait then just return it
      return fontObject;
    }
  else
    {
      // Else convert it
      NSFont *newFont;

      int weight = [self weightOfFont: fontObject];
      float size = [fontObject pointSize];
      NSString *family = [fontObject familyName];

      // We cannot reuse the weight in a bold
      if (trait == NSBoldFontMask)
	weight = 9;

      t = t | trait;
      newFont = [self fontWithFamily: family 
			      traits: t
			      weight: weight
				size: size];

      if (newFont == nil)
	return fontObject;
      else 
	return newFont;
    }
}

- (NSFont*) convertFont: (NSFont*)fontObject
	 toNotHaveTrait: (NSFontTraitMask)trait
{
  NSFontTraitMask t = [self traitsOfFont: fontObject];

  if (!(t & trait))
    {
      // If already do not have that trait then just return it
      return fontObject;
    }
  else
    {
      // Else convert it
      NSFont *newFont;

      int weight = [self weightOfFont: fontObject];
      float size = [fontObject pointSize];
      NSString *family = [fontObject familyName];

      // We cannot reuse the weight in an unbold
      if (trait == NSBoldFontMask)
	weight = 5;

      t = t ^ trait;
      newFont = [self fontWithFamily: family 
			      traits: t
			      weight: weight
				size: size];
      if (newFont == nil)
	return fontObject;
      else 
	return newFont;
    }
}

- (NSFont*) convertFont: (NSFont*)fontObject
		 toSize: (float)size
{
  if ([fontObject pointSize] == size)
    {
      // If already that size then just return it
      return fontObject;
    }
  else
    {
      // Else convert it
      NSFont *newFont;

      newFont = [NSFont fontWithName: [fontObject fontName] 
			size: size];
      if (newFont == nil)
	return fontObject;
      else 
	return newFont;
    }
}

- (NSFont*) convertWeight: (BOOL)upFlag
		   ofFont: (NSFont*)fontObject
{
  NSFont *newFont;
  NSString *fontName = nil;
  NSFontTraitMask trait = [self traitsOfFont: fontObject];
  float size = [fontObject pointSize];
  NSString *family = [fontObject familyName];
  int w = [self weightOfFont: fontObject];
  // We check what weights we have for this family. We must
  // also check to see if that font has the correct traits!
  NSArray *fontDefs = [self availableMembersOfFontFamily: family];

  if (upFlag)
    {
      int i;
      // The documentation is a bit unclear about the range of weights
      // sometimes it says 0 to 9 and sometimes 0 to 15
      int next_w = 15;

      // Correct the trait
      if (w == 8)
	trait |= NSBoldFontMask;

      for (i = 0; i < [fontDefs count]; i++)
	{
	  NSArray *fontDef = [fontDefs objectAtIndex: i];
	  int w1 = [[fontDef objectAtIndex: 2] intValue];

	  if (w1 > w && w1 < next_w && 
	      [[fontDef objectAtIndex: 3] unsignedIntValue] == trait)
	    {
	      next_w = w1;
	      fontName = [fontDef objectAtIndex: 0];
	    }
	}

      w = next_w;
    }
  else
    {
      int i;
      int next_w = 0;

      // Correct the trait
      if (w == 9)
	trait &= ~NSBoldFontMask;

      for (i = 0; i < [fontDefs count]; i++)
	{
	  NSArray *fontDef = [fontDefs objectAtIndex: i];
	  int w1 = [[fontDef objectAtIndex: 2] intValue];

	  if (w1 < w && w1 > next_w && 
	      [[fontDef objectAtIndex: 3] unsignedIntValue] == trait)
	    {
	      next_w = w1;
	      fontName = [fontDef objectAtIndex: 0];
	    }
	}

      w = next_w;
    }

  if (fontName != nil)
    newFont = [NSFont fontWithName: fontName
		      size: size];
  else 
    newFont = [self fontWithFamily: family 
		    traits: trait
		    weight: w
		    size: size];
  
  if (newFont == nil)
    return fontObject;
  else 
    return newFont;
}

/*
 * Getting a font
 */
- (NSFont*) fontWithFamily: (NSString*)family
		    traits: (NSFontTraitMask)traits
		    weight: (int)weight
		      size: (float)size
{
  NSArray *fontDefs = [self availableMembersOfFontFamily: family];
  int i;

  //NSLog(@"Searching font %@: %i: %i", family, weight, traits);  
  for (i = 0; i < [fontDefs count]; i++)
    {
      NSArray *fontDef = [fontDefs objectAtIndex: i];

      //NSLog(@"Testing font %@: %i: %i", [fontDef objectAtIndex: 0], 
      //	    [[fontDef objectAtIndex: 2] intValue], 
      //	    [[fontDef objectAtIndex: 3] unsignedIntValue]);  
      if (([[fontDef objectAtIndex: 2] intValue] == weight) &&
	  ([[fontDef objectAtIndex: 3] unsignedIntValue] == traits))
	{
	  //NSLog(@"Found font");
	  return [NSFont fontWithName: [fontDef objectAtIndex: 0] 
			 size: size];
	}
    }

  //NSLog(@"Didnt find font");  
  return nil;
}

//
// Examining a font
//
- (NSFontTraitMask) traitsOfFont: (NSFont*)fontObject
{
  GSFontInfo       *info;
  NSFontTraitMask  mask = 0;

  info = [GSFontInfo fontInfoForFontName: [fontObject fontName]
		                  matrix: [fontObject matrix]];

  if (info)
    mask = [info traits];
  return mask;
}

- (int) weightOfFont: (NSFont*)fontObject
{
  GSFontInfo       *info;

  info = [GSFontInfo fontInfoForFontName: [fontObject fontName]
		                  matrix: [fontObject matrix]];

  return [info weight];
}

- (BOOL) fontNamed: (NSString*)typeface 
         hasTraits: (NSFontTraitMask)fontTraitMask;
{
  // TODO: THis method is implemented very slow, but I dont 
  // see any use for it, so why change it?
  int i, j;
  NSArray *fontFamilies = [self availableFontFamilies];
  NSFontTraitMask traits;
  
  for (i = 0; i < [fontFamilies count]; i++)
    {
      NSArray *fontDefs = [self availableMembersOfFontFamily: 
				  [fontFamilies objectAtIndex: i]];
      
      for (j = 0; j < [fontDefs count]; j++)
	{
	  NSArray *fontDef = [fontDefs objectAtIndex: j];
	  
	  if ([[fontDef objectAtIndex: 3] isEqualToString: typeface])
	    {
	      traits = [[fontDef objectAtIndex: 3] unsignedIntValue];
	      // FIXME: This is not exactly the right condition
	      if ((traits & fontTraitMask) == fontTraitMask)
		{
		  return YES;
		}
	      else
		return NO;
	    }
	}
    }
  
  return NO;
}

//
// Enabling
//
- (BOOL) isEnabled
{
  if (fontPanel != nil)
    {
      return [fontPanel isEnabled];
    }
  else
    return NO;
}

- (void) setEnabled: (BOOL)flag
{
  int i;

  if (_fontMenu != nil)
    {
      for (i = 0; i < [_fontMenu numberOfItems]; i++)
	{
	  [[_fontMenu itemAtIndex: i] setEnabled: flag];
	}
    }

  if (fontPanel != nil)
    [fontPanel setEnabled: flag];
}

//
// Font menu
//
- (NSMenu*) fontMenu: (BOOL)create
{
  if (create && _fontMenu == nil)
    {
      NSMenuItem *menuItem;
      
      // As the font menu is stored in a instance variable we 
      // dont autorelease it
      _fontMenu = [NSMenu new];
      [_fontMenu setTitle: @"Font Menu"];

      // First an entry to start the font panel
      menuItem = [_fontMenu addItemWithTitle: @"Font Panel"
			    action: @selector(orderFrontFontPanel:)
			    keyEquivalent: @"f"];
      [menuItem setTarget: self];

      // Entry for italic
      menuItem = [_fontMenu addItemWithTitle: @"Italic"
			    action: @selector(addFontTrait:)
			    keyEquivalent: @"i"];
      [menuItem setTag: NSItalicFontMask];
      [menuItem setTarget: self];

      // Entry for bold
      menuItem = [_fontMenu addItemWithTitle: @"Bold"
			    action: @selector(addFontTrait:)
			    keyEquivalent: @"b"];
      [menuItem setTag: NSBoldFontMask];
      [menuItem setTarget: self];

      // Entry to increase weight
      menuItem = [_fontMenu addItemWithTitle: @"Heavier"
			    action: @selector(modifyFont:)
			    keyEquivalent: @"h"];
      [menuItem setTag: NSHeavierFontAction];
      [menuItem setTarget: self];
 
      // Entry to decrease weight
      menuItem = [_fontMenu addItemWithTitle: @"Lighter"
			    action: @selector(modifyFont:)
			    keyEquivalent: @"g"];
      [menuItem setTag: NSLighterFontAction];
      [menuItem setTarget: self];
 
      // Entry to increase size
      menuItem = [_fontMenu addItemWithTitle: @"Larger"
			    action: @selector(modifyFont:)
			    keyEquivalent: @"l"];
      [menuItem setTag: NSSizeUpFontAction];
      [menuItem setTarget: self];

      // Entry to decrease size
      menuItem = [_fontMenu addItemWithTitle: @"Smaller"
			    action: @selector(modifyFont:)
			    keyEquivalent: @"s"];
      [menuItem setTag: NSSizeDownFontAction];
      [menuItem setTarget: self];
    }
  return _fontMenu;
}

- (void) setFontMenu: (NSMenu*)newMenu
{
  ASSIGN(_fontMenu, newMenu); 
}

// Font panel

- (NSFontPanel*) fontPanel: (BOOL)create
{
  if ((fontPanel == nil) && (create))
    {
      fontPanel = [[fontPanelClass alloc] init];
    }
  return fontPanel;
}

- (void) orderFrontFontPanel: (id)sender
{
  if (fontPanel == nil)
    fontPanel = [self fontPanel: YES];
  [fontPanel orderFront: sender];
  [fontPanel setPanelFont: _selectedFont isMultiple: _multiple];
}

/*
 * Assigning a Delegate
 */
- (id) delegate
{
  return _delegate;
}

- (void) setDelegate: (id)anObject
{
  _delegate = anObject;
}

/*
 * Setting and Getting Parameters
 */
- (SEL) action
{
  return _action;
}

- (void) setAction: (SEL)aSelector
{
  _action = aSelector;
}

- (BOOL) sendAction
{
  NSApplication *theApp = [NSApplication sharedApplication];

  if (_action)
    return [theApp sendAction: _action to: nil from: self];
  else
    return NO;
}

@end

@implementation NSFontManager (GNUstepBackend)

/*
 * Ask delegate if to include a font
 */
- (BOOL) _includeFont: (NSString*)fontName
{
  if ((_delegate != nil)
    && [_delegate respondsToSelector: @selector(fontManager: willIncludeFont:)])
    return [_delegate fontManager: self willIncludeFont: fontName];
  else
    return YES;
}

@end
