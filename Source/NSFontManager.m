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

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <Foundation/NSArray.h>
#include <AppKit/NSFontManager.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>

//
// Class variables
//
static NSFontManager *sharedFontManager = nil;
static NSFontPanel *fontPanel = nil;
static Class fontManagerClass = Nil;
static Class fontPanelClass = Nil;

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
+ (void)setFontManagerFactory:(Class)class
{
  fontManagerClass = class;
}

+ (void)setFontPanelFactory:(Class)class
{
  fontPanelClass = class;
}

+ (NSFontManager *)sharedFontManager
{
  if (!sharedFontManager)
    {
      sharedFontManager = [[fontManagerClass alloc] init];
      [sharedFontManager enumerateFontsAndFamilies];
    }
  return sharedFontManager;
}

//
// Instance methods
//
- init
{
  self = [super init];

  // Allocate the font list
  fontsList = [NSMutableArray array];

  return self;
}

#if 0
/* This code needs to be reworked */

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
  j = [fontsList count];
  for (i = 0;i < j; ++i)
    {
      name = [fontsList objectAtIndex:i];
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
    {
      NSLog(@"Invalid font request\n");
      return nil;
    }
}
#endif

//
// Setting and Getting Parameters
//
- (SEL)action
{
  return action;
}

- (NSArray *)availableFonts
{
  return fontsList;
}

- (NSMenu *)fontMenu:(BOOL)create
{
  return font_menu;
}

- (NSFontPanel *)fontPanel:(BOOL)create
{
  if ((!fontPanel) && (create))
    fontPanel = [[fontPanelClass alloc] init];
  return fontPanel;
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

#if 0
- (NSFontTraitMask)traitsOfFont:(NSFont *)fontObject
{
  return [fontObject traits];
}

- (int)weightOfFont:(NSFont *)fontObject
{
  return [fontObject weight];
}
#endif

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

@implementation NSFontManager (GNUstepBackend)

- (void)enumerateFontsAndFamilies
{
}

@end
