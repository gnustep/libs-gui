/* 
   NSFontManager.m

   Manages system and user fonts

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/NSFontManager.h>
#include <gnustep/gui/NSApplication.h>
#include <gnustep/gui/NSFontPrivate.h>

//
// Class variables
//
NSFontManager *MB_THE_FONT_MANAGER;
NSFontPanel *MB_THE_FONT_PANEL;
id MB_THE_FONT_MANAGER_FACTORY;
id MB_THE_FONT_PANEL_FACTORY;

@implementation NSFontManager

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSFontManager class])
    {
      NSDebugLog(@"Initialize NSFontManager class\n");

      // Initial version
      [self setVersion:1];

      // Set the factories
      [self setFontManagerFactory:[NSFontManager class]];
      [self setFontPanelFactory:[NSFontManager class]];
    }
}

//
// Managing the FontManager
//
+ (void)setFontManagerFactory:(Class)classId
{
  MB_THE_FONT_MANAGER_FACTORY = classId;
}

+ (void)setFontPanelFactory:(Class)classId
{
  MB_THE_FONT_PANEL_FACTORY = classId;
}

+ (NSFontManager *)sharedFontManager
{
  if (!MB_THE_FONT_MANAGER)
    MB_THE_FONT_MANAGER = [[NSFontManager alloc] init];
  [MB_THE_FONT_MANAGER enumerateFamilies];
  return MB_THE_FONT_MANAGER;
}

//
// Instance methods
//
- init
{
  [super init];

  // Allocate the font list
  font_list = [NSMutableArray array];

  return self;
}

- (void)enumerateFamilies
{
  if (!family_list)
    {
      // Allocate the family list
      family_list = [NSMutableArray array];
      family_metrics = [NSMutableArray array];

      // Enumerate the available font families
    }
}

//
// Converting Fonts
//
- (NSFont *)convertFont:(NSFont *)fontObject
{
  return fontObject;
}

- (NSFont *)convertFont:(NSFont *)fontObject
	       toFamily:(NSString *)family
{
  if ([family compare:[fontObject familyName]] == NSOrderedSame)
    {
      // If already of that family then just return it
      return fontObject;
    }
  else
    {
      // Else convert it
      NSFont *f = [fontObject mutableCopy];
      [f setFamilyName:family];
      return f;
    }
}

- (NSFont *)convertFont:(NSFont *)fontObject
		 toFace:(NSString *)typeface
{
  // +++ How to do this conversion?
  return fontObject;
}

- (NSFont *)convertFont:(NSFont *)fontObject
	    toHaveTrait:(NSFontTraitMask)trait
{
  NSFontTraitMask t = [fontObject traits];

  if (t & trait)
    {
      // If already have that trait then just return it
      return fontObject;
    }
  else
    {
      // Else convert it
      NSFont *f = [fontObject mutableCopy];
      t = t | trait;
      [f setTraits:t];
      return f;
    }
}

- (NSFont *)convertFont:(NSFont *)fontObject
	 toNotHaveTrait:(NSFontTraitMask)trait
{
  NSFontTraitMask t = [fontObject traits];

  if (!(t & trait))
    {
      // If already do not have that trait then just return it
      return fontObject;
    }
  else
    {
      // Else convert it
      NSFont *f = [fontObject mutableCopy];
      t = t ^ trait;
      [f setTraits:t];
      return f;
    }
}

- (NSFont *)convertFont:(NSFont *)fontObject
		 toSize:(float)size
{
  if ([fontObject pointSize] == size)
    {
      // If already that size then just return it
      return fontObject;
    }
  else
    {
      // Else convert it
      NSFont *f = [fontObject mutableCopy];
      [f setPointSize:size];
      return f;
    }
}

- (NSFont *)convertWeight:(BOOL)upFlag
		   ofFont:(NSFont *)fontObject
{
  int w = [fontObject weight];
  NSFont *f = [fontObject mutableCopy];

  // Weight are sort of arbitrary, so we will use
  // 0 - light, 400 - normal, 700 - bold
  if (upFlag)
    {
      if (w == 0)
	w = 400;
      else if (w == 400)
	w = 700;
    }
  else
    {
      if (w == 700)
	w = 400;
      else if (w == 400)
	w = 0;
    }

  [f setWeight: w];
  return f;
}

- (NSFont *)fontWithFamily:(NSString *)family
		    traits:(NSFontTraitMask)traits
		    weight:(int)weight
		      size:(float)size
{
  int i, j;
  BOOL found = NO;
  NSString *name;
  NSFont *f;

  // Make sure it is a legitimate family name
  j = [family_list count];
  for (i = 0;i < j; ++i)
    {
      name = [family_list objectAtIndex:i];
      if ([family compare:name] == NSOrderedSame)
	{
	  found = YES;
	  break;
	}
    }

  // Create the font
  if (found)
    {
      f = [[NSFont alloc] init];
      [f setFamilyName: family];
      [f setTraits: traits];
      [f setWeight: weight];
      [f setPointSize: size];		
      return f;
    }
  else
    return nil;
}

//
// Setting and Getting Parameters
//
- (SEL)action
{
  return action;
}

- (NSArray *)availableFonts
{
  return family_list;
}

- (NSArray *)familyMetrics;
{
  return family_metrics;
}

- (NSMenu *)fontMenu:(BOOL)create
{
  return font_menu;
}

- (NSFontPanel *)fontPanel:(BOOL)create
{
  if ((!MB_THE_FONT_PANEL) && (create))
    MB_THE_FONT_PANEL = [[NSFontPanel alloc] init];
  return MB_THE_FONT_PANEL;
}

- (BOOL)isEnabled
{
  return NO;
}

- (BOOL)isMultiple
{
  return NO;
}

- (NSFont *)selectedFont
{
  return nil;
}

- (void)setAction:(SEL)aSelector
{
  action = aSelector;
}

- (void)setEnabled:(BOOL)flag
{}

- (void)setFontMenu:(NSMenu *)newMenu
{}

- (void)setSelectedFont:(NSFont *)fontObject
	     isMultiple:(BOOL)flag
{
  selected_font = fontObject;
}

- (NSFontTraitMask)traitsOfFont:(NSFont *)fontObject
{
  return [fontObject traits];
}

- (int)weightOfFont:(NSFont *)fontObject
{
  return [fontObject weight];
}

//
// Target and Action Methods
//
- (BOOL)sendAction
{
  return NO;
}

//
// Assigning a Delegate
//
- (id)delegate
{
  return delegate;
}

- (void)setDelegate:(id)anObject
{
  delegate = anObject;
}

//
// Methods Implemented by the Delegate
//
- (BOOL)fontManager:(id)sender willIncludeFont:(NSString *)fontName
{
  if ([delegate respondsToSelector:@selector(fontManager:willIncludeFont:)])
    return [delegate fontManager:self willIncludeFont:fontName];
  else
    return YES;
}

@end
