/* 
   NSFontManager.h

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

#ifndef _GNUstep_H_NSFontManager
#define _GNUstep_H_NSFontManager

#include <AppKit/stdappkit.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSFontPanel.h>
#include <AppKit/NSMenu.h>

@interface NSFontManager : NSObject

{
  // Attributes
  id delegate;
  SEL action;
  NSMutableArray *family_list;
  NSMutableArray *family_metrics;
  NSFont *selected_font;
  NSMutableArray *font_list;
  NSMenu *font_menu;
}

//
// Managing the FontManager
//
+ (void)setFontManagerFactory:(Class)classId;
+ (void)setFontPanelFactory:(Class)classId;
+ (NSFontManager *)sharedFontManager;

//
// Initialization
//
- (void)enumerateFamilies;

//
// Converting Fonts
//
- (NSFont *)convertFont:(NSFont *)fontObject;
- (NSFont *)convertFont:(NSFont *)fontObject
	       toFamily:(NSString *)family;
- (NSFont *)convertFont:(NSFont *)fontObject
		 toFace:(NSString *)typeface;
- (NSFont *)convertFont:(NSFont *)fontObject
	    toHaveTrait:(NSFontTraitMask)trait;
- (NSFont *)convertFont:(NSFont *)fontObject
	 toNotHaveTrait:(NSFontTraitMask)trait;
- (NSFont *)convertFont:(NSFont *)fontObject
		 toSize:(float)size;
- (NSFont *)convertWeight:(BOOL)upFlag
		   ofFont:(NSFont *)fontObject;
- (NSFont *)fontWithFamily:(NSString *)family
		    traits:(NSFontTraitMask)traits
		    weight:(int)weight
		      size:(float)size;

//
// Setting and Getting Parameters
//
- (SEL)action;
- (NSArray *)availableFonts;
- (NSArray *)familyMetrics;
- (NSMenu *)fontMenu:(BOOL)create;
- (NSFontPanel *)fontPanel:(BOOL)create;
- (BOOL)isEnabled;
- (BOOL)isMultiple;
- (NSFont *)selectedFont;
- (void)setAction:(SEL)aSelector;
- (void)setEnabled:(BOOL)flag;
- (void)setFontMenu:(NSMenu *)newMenu;
- (void)setSelectedFont:(NSFont *)fontObject
	     isMultiple:(BOOL)flag;
- (NSFontTraitMask)traitsOfFont:(NSFont *)fontObject;
- (int)weightOfFont:(NSFont *)fontObject;

//
// Target and Action Methods
//
- (BOOL)sendAction;

//
// Assigning a Delegate
//
- (id)delegate;
- (void)setDelegate:(id)anObject;

//
// Methods Implemented by the Delegate
//
- (BOOL)fontManager:(id)sender willIncludeFont:(NSString *)fontName;

@end

#endif // _GNUstep_H_NSFontManager
