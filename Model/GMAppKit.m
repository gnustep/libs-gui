/* -*- C++ -*-
   GMAppKit.m

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: November 1997
   
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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#include "AppKit/GMAppKit.h"

void __dummy_GMAppKit_functionForLinking() {}

@implementation NSApplication (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
#if NeXT_GUI_LIBRARY
  NSArray* windows1 = [self windows];
  NSMutableArray* windows2 = [NSMutableArray array];
  int i, count = [windows1 count];

  for (i = 0; i < count; i++) {
    NSWindow* window = [windows1 objectAtIndex:i];

    if (![window isKindOfClass:[NSMenu class]])
      [windows2 addObject:window];
  }
  [archiver encodeObject:windows2 withName:@"windows"];

#else
  [archiver encodeObject:[self windows] withName:@"windows"];
#endif
  [archiver encodeObject:[self keyWindow] withName:@"keyWindow"];
  [archiver encodeObject:[self mainWindow] withName:@"mainWindow"];
  [archiver encodeObject:[self mainMenu] withName:@"mainMenu"];
  [archiver encodeObject:[self delegate] withName:@"delegate"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  NSArray* windows;
  NSWindow* keyWindow;
  NSWindow* mainWindow;
  NSMenu* mainMenu;
  id anObject;

#if GNU_GUI_LIBRARY
  mainMenu = [unarchiver decodeObjectWithName:@"mainMenu"];
  if (mainMenu)
    [self setMainMenu:mainMenu];
#endif

  windows = [unarchiver decodeObjectWithName:@"windows"];
  keyWindow = [unarchiver decodeObjectWithName:@"keyWindow"];
  mainWindow = [unarchiver decodeObjectWithName:@"mainWindow"];

  anObject = [unarchiver decodeObjectWithName:@"delegate"];
  if (anObject)
    [self setDelegate:anObject];

#if NeXT_GUI_LIBRARY
  mainMenu = [unarchiver decodeObjectWithName:@"mainMenu"];
  if (mainMenu)
    [self setMainMenu:mainMenu];
#endif

  [keyWindow makeKeyWindow];
  [mainWindow makeMainWindow];

  return self;
}

- (void)awakeFromModel
{
  NSMenu* mainMenu = [self mainMenu];

  [mainMenu update];
#if XDPS_BACKEND_LIBRARY || XRAW_BACKEND_LIBRARY || XGPS_BACKEND_LIBRARY
  [mainMenu display];
#endif

}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  return [NSApplication sharedApplication];
}

@end /* NSApplication (GMArchiverMethods) */


@implementation NSBox (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [super encodeWithModelArchiver:archiver];

  [archiver encodeSize:[self contentViewMargins] withName:@"contentViewMargins"];
  [archiver encodeInt:[self borderType] withName:@"borderType"];
  [archiver encodeInt:[self titlePosition] withName:@"titlePosition"];
  [archiver encodeString:[self title] withName:@"title"];
  [archiver encodeObject:[self titleFont] withName:@"titleFont"];
  [archiver encodeObject:[self contentView] withName:@"contentView"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  self = [super initWithModelUnarchiver:unarchiver];

  [self setContentViewMargins:[unarchiver decodeSizeWithName:@"contentViewMargins"]];
  [self setBorderType:[unarchiver decodeIntWithName:@"borderType"]];
  [self setTitlePosition:[unarchiver decodeIntWithName:@"titlePosition"]];
  [self setTitle:[unarchiver decodeStringWithName:@"title"]];
  [self setTitleFont:[unarchiver decodeObjectWithName:@"titleFont"]];
  [self setContentView:[unarchiver decodeObjectWithName:@"contentView"]];

  return self;
}

@end /* NSBox (GMArchiverMethods) */


@implementation NSButton (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  float delay, interval;
  id theCell = [self cell];

  [archiver encodeInt:[self state] withName:@"state"];
  [self getPeriodicDelay:&delay interval:&interval];
  [archiver encodeFloat:delay withName:@"delay"];
  [archiver encodeFloat:interval withName:@"interval"];
  [archiver encodeString:[self title] withName:@"title"];
  [archiver encodeString:[self alternateTitle] withName:@"alternateTitle"];
  [archiver encodeObject:[self image] withName:@"image"];
  [archiver encodeObject:[self alternateImage] withName:@"alternateImage"];
  [archiver encodeInt:[self imagePosition] withName:@"imagePosition"];
  [archiver encodeBOOL:[self isBordered] withName:@"isBordered"];
  [archiver encodeBOOL:[self isTransparent] withName:@"isTransparent"];
  [archiver encodeString:[self keyEquivalent] withName:@"keyEquivalent"];
  [archiver encodeInt:[theCell highlightsBy] withName:@"highlightsBy"];
  [archiver encodeInt:[theCell showsStateBy] withName:@"showsStateBy"];

  [super encodeWithModelArchiver:archiver];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  float delay, interval;
  id theCell;

  self = [super initWithModelUnarchiver:unarchiver];

  [self setState:[unarchiver decodeIntWithName:@"state"]];

  delay = [unarchiver decodeFloatWithName:@"delay"];
  interval = [unarchiver decodeFloatWithName:@"interval"];
  [self setPeriodicDelay:delay interval:interval];

  [self setTitle:[unarchiver decodeStringWithName:@"title"]];
  [self setAlternateTitle:[unarchiver decodeStringWithName:@"alternateTitle"]];
  [self setImage:[unarchiver decodeObjectWithName:@"image"]];
  [self setAlternateImage:[unarchiver decodeObjectWithName:@"alternateImage"]];
  [self setImagePosition:[unarchiver decodeIntWithName:@"imagePosition"]];
  [self setBordered:[unarchiver decodeBOOLWithName:@"isBordered"]];
  [self setTransparent:[unarchiver decodeBOOLWithName:@"isTransparent"]];
  [self setKeyEquivalent:[unarchiver decodeStringWithName:@"keyEquivalent"]];

  theCell = [self cell];

  [theCell setHighlightsBy:[unarchiver decodeIntWithName:@"highlightsBy"]];
  [theCell setShowsStateBy:[unarchiver decodeIntWithName:@"showsStateBy"]];

  return self;
}

@end /* NSButton (GMArchiverMethods) */


@implementation NSCell (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
    [archiver encodeInt:[self type] withName:@"type"];
    [archiver encodeObject:[self font] withName:@"font"];
    [archiver encodeString:[self stringValue] withName:@"stringValue"];
    [archiver encodeInt:[self entryType] withName:@"entryType"];
    [archiver encodeInt:[self alignment] withName:@"alignment"];
    [archiver encodeBOOL:[self wraps] withName:@"wraps"];
    [archiver encodeObject:[self image] withName:@"image"];
    [archiver encodeInt:[self state] withName:@"state"];
    [archiver encodeBOOL:[self isEnabled] withName:@"isEnabled"];
    [archiver encodeBOOL:[self isBordered] withName:@"isBordered"];
    [archiver encodeBOOL:[self isBezeled] withName:@"isBezeled"];
    [archiver encodeBOOL:[self isEditable] withName:@"isEditable"];
    [archiver encodeBOOL:[self isSelectable] withName:@"isSelectable"];
    [archiver encodeBOOL:[self isScrollable] withName:@"isScrollable"];
    [archiver encodeBOOL:[self isContinuous] withName:@"isContinuous"];
    [archiver encodeInt:[self sendActionOn:0] withName:@"sendActionMask"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
    NSFont* font = [unarchiver decodeObjectWithName:@"font"];
    if (!font)
        font = [NSFont userFontOfSize:0];

    [self setFont:font];

    // if (model_version >= 2) {
    [self setStringValue:[unarchiver decodeStringWithName:@"stringValue"]];
    [self setEntryType:[unarchiver decodeIntWithName:@"entryType"]];
    [self setAlignment:[unarchiver decodeIntWithName:@"alignment"]];
    [self setWraps:[unarchiver decodeBOOLWithName:@"wraps"]];
    [self setImage:[unarchiver decodeObjectWithName:@"image"]];
    [self setState:[unarchiver decodeIntWithName:@"state"]];
    [self setEnabled:[unarchiver decodeBOOLWithName:@"isEnabled"]];
    [self setBordered:[unarchiver decodeBOOLWithName:@"isBordered"]];
    [self setBezeled:[unarchiver decodeBOOLWithName:@"isBezeled"]];
    [self setEditable:[unarchiver decodeBOOLWithName:@"isEditable"]];
    [self setSelectable:[unarchiver decodeBOOLWithName:@"isSelectable"]];
    [self setScrollable:[unarchiver decodeBOOLWithName:@"isScrollable"]];
    [self setContinuous:[unarchiver decodeBOOLWithName:@"isContinuous"]];
    [self sendActionOn:[unarchiver decodeIntWithName:@"sendActionMask"]];
    [self setType:[unarchiver decodeIntWithName:@"type"]];
    // }

    return self;
}

@end /* NSCell (GMArchiverMethods) */



@implementation NSActionCell (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
    [super encodeWithModelArchiver:archiver];

    [archiver encodeInt:[self tag] withName:@"tag"];
    [archiver encodeObject:[self target] withName:@"target"];
    [archiver encodeSelector:[self action] withName:@"action"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
    self = [super initWithModelUnarchiver:unarchiver];

    // if (model_version >= 2) {
    [self setTag:[unarchiver decodeIntWithName:@"tag"]];
    [self setTarget:[unarchiver decodeObjectWithName:@"target"]];
    [self setAction:[unarchiver decodeSelectorWithName:@"action"]];
    // }

    return self;
}

@end /* NSActionCell (GMArchiverMethods) */


@implementation NSButtonCell (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
    float delay, interval;

    [super encodeWithModelArchiver:archiver];

    [self getPeriodicDelay:&delay interval:&interval];
    [archiver encodeFloat:delay withName:@"delay"];
    [archiver encodeFloat:interval withName:@"interval"];
    [archiver encodeString:[self title] withName:@"title"];
    [archiver encodeString:[self alternateTitle] withName:@"alternateTitle"];
    [archiver encodeObject:[self alternateImage] withName:@"alternateImage"];
    [archiver encodeInt:[self imagePosition] withName:@"imagePosition"];
    [archiver encodeBOOL:[self isTransparent] withName:@"isTransparent"];
    [archiver encodeString:[self keyEquivalent] withName:@"keyEquivalent"];
    [archiver encodeObject:[self keyEquivalentFont] withName:@"keyEquivalentFont"];
    [archiver encodeInt:[self keyEquivalentModifierMask] withName:@"keyEquivalentModifierMask"];
    [archiver encodeInt:[self highlightsBy] withName:@"highlightsBy"];
    [archiver encodeInt:[self showsStateBy] withName:@"showsStateBy"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
    float delay, interval;
    id obj;

    self = [super initWithModelUnarchiver:unarchiver];

    // if (model_version >= 2) {
    delay = [unarchiver decodeFloatWithName:@"delay"];
    interval = [unarchiver decodeFloatWithName:@"interval"];
    [self setPeriodicDelay:delay interval:interval];

    obj = [unarchiver decodeStringWithName:@"title"];
    if (obj) [self setTitle:obj];
    obj = [unarchiver decodeStringWithName:@"alternateTitle"];
    if (obj) [self setAlternateTitle:obj];
    obj = [unarchiver decodeObjectWithName:@"alternateImage"];
    [self setAlternateImage:obj];
    [self setImagePosition:[unarchiver decodeIntWithName:@"imagePosition"]];
    [self setTransparent:[unarchiver decodeBOOLWithName:@"isTransparent"]];
    [self setKeyEquivalent:[unarchiver decodeStringWithName:@"keyEquivalent"]];
    [self setKeyEquivalentFont:[unarchiver decodeObjectWithName:@"keyEquivalentFont"]];
    [self setKeyEquivalentModifierMask:[unarchiver decodeIntWithName:@"keyEquivalentModifierMask"]];
    [self setHighlightsBy:[unarchiver decodeIntWithName:@"highlightsBy"]];
    [self setShowsStateBy:[unarchiver decodeIntWithName:@"showsStateBy"]];
    // }

    return self;
}

@end /* NSButtonCell (GMArchiverMethods) */


@implementation NSMatrix (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
    [super encodeWithModelArchiver:archiver];

    [archiver encodeInt:[self mode] withName:@"mode"];
    [archiver encodeBOOL:[self allowsEmptySelection] withName:@"allowsEmptySelection"];
    [archiver encodeBOOL:[self isSelectionByRect] withName:@"isSelectionByRect"];

    [archiver encodeBOOL:[self autosizesCells] withName:@"autosizesCells"];
    [archiver encodeBOOL:[self isAutoscroll] withName:@"isAutoscroll"];
    [archiver encodeSize:[self cellSize] withName:@"cellSize"];
    [archiver encodeSize:[self intercellSpacing] withName:@"intercellSpacing"];
    [archiver encodeObject:[self backgroundColor] withName:@"backgroundColor"];
    [archiver encodeObject:[self cellBackgroundColor] withName:@"cellBackgroundColor"];
    [archiver encodeBOOL:[self drawsBackground] withName:@"drawsBackground"];
    [archiver encodeBOOL:[self drawsCellBackground] withName:@"drawsCellBackground"];

    [archiver encodeClass:[self cellClass] withName:@"cellClass"];
    [archiver encodeObject:[self prototype] withName:@"prototype"];
    [archiver encodeInt:[self numberOfRows] withName:@"numberOfRows"];
    [archiver encodeInt:[self numberOfColumns] withName:@"numberOfColumns"];
    [archiver encodeObject:[self cells] withName:@"cells"];
    [archiver encodeObject:[self delegate] withName:@"delegate"];

    [archiver encodeObject:[self target] withName:@"target"];
    [archiver encodeSelector:[self action] withName:@"action"];
    [archiver encodeSelector:[self doubleAction] withName:@"doubleAction"];
    [archiver encodeSelector:[self errorAction] withName:@"errorAction"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
    int nr, nc;
    NSArray *cell_array;
    int i;
    
    self = [super initWithModelUnarchiver:unarchiver];

    // if (model_version >= 2) {
    [self setMode:[unarchiver decodeIntWithName:@"mode"]];
    [self setAllowsEmptySelection:[unarchiver decodeBOOLWithName:@"allowsEmptySelection"]];
    [self setSelectionByRect:[unarchiver decodeBOOLWithName:@"isSelectionByRect"]];

    [self setAutosizesCells:[unarchiver decodeBOOLWithName:@"autosizesCells"]];
    [self setAutoscroll:[unarchiver decodeBOOLWithName:@"isAutoscroll"]];
    [self setCellSize:[unarchiver decodeSizeWithName:@"cellSize"]];
    [self setIntercellSpacing:[unarchiver decodeSizeWithName:@"intercellSpacing"]];
    [self setBackgroundColor:[unarchiver decodeObjectWithName:@"backgroundColor"]];
    [self setCellBackgroundColor:[unarchiver decodeObjectWithName:@"cellBackgroundColor"]];
    [self setDrawsBackground:[unarchiver decodeBOOLWithName:@"drawsBackground"]];
    [self setDrawsCellBackground:[unarchiver decodeBOOLWithName:@"drawsCellBackground"]];

    [self setCellClass:[unarchiver decodeClassWithName:@"cellClass"]];
    [self setPrototype:[unarchiver decodeObjectWithName:@"prototype"]];
    
    nr = [unarchiver decodeIntWithName:@"numberOfRows"];
    nc = [unarchiver decodeIntWithName:@"numberOfColumns"];
    cell_array = [unarchiver decodeObjectWithName:@"cells"];
    [self renewRows:nr columns:nc];
    for (i = 0; (i < [cell_array count]) && (i < nr*nc); i++) {
        [self putCell:[cell_array objectAtIndex:i] atRow:i/nc column:i%nc];
    }
    
    [self setDelegate:[unarchiver decodeObjectWithName:@"delegate"]];
    

    [self setTarget:[unarchiver decodeObjectWithName:@"target"]];
    [self setAction:[unarchiver decodeSelectorWithName:@"action"]];
    [self setDoubleAction:[unarchiver decodeSelectorWithName:@"doubleAction"]];
    [self setErrorAction:[unarchiver decodeSelectorWithName:@"errorAction"]];
    [self sizeToCells];
    // }

    return self;
}

@end /* NSMatrix (GMArchiverMethods) */


@implementation NSScrollView (GMArchiverMethods)

// do not encode our subviews in NSView (it would encode the clipview and 
// the scroller, which are not necessary).
- (NSArray *)subviewsForModel
{
    return [NSArray array];
}

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
    [super encodeWithModelArchiver:archiver];

    [archiver encodeObject:[self backgroundColor] withName:@"backgroundColor"];
    [archiver encodeInt:[self borderType] withName:@"borderType"];
    [archiver encodeBOOL:[self hasHorizontalScroller] withName:@"hasHorizontalScroller"];
    [archiver encodeBOOL:[self hasVerticalScroller] withName:@"hasVerticalScroller"];
    [archiver encodeObject:[self documentView] withName:@"documentView"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
    self = [super initWithModelUnarchiver:unarchiver];

    [self setBackgroundColor:[unarchiver decodeObjectWithName:@"backgroundColor"]];
    [self setBorderType:[unarchiver decodeIntWithName:@"borderType"]];
    [self setHasHorizontalScroller:[unarchiver decodeBOOLWithName:@"hasHorizontalScroller"]];
    [self setHasVerticalScroller:[unarchiver decodeBOOLWithName:@"hasVerticalScroller"]];
    [self setDocumentView:[unarchiver decodeObjectWithName:@"documentView"]];

    return self;
}

@end /* NSScrollView (GMArchiverMethods) */


@implementation NSClipView (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [super encodeWithModelArchiver:archiver];

  [archiver encodeObject:[self documentView] withName:@"documentView"];
  [archiver encodeBOOL:[self copiesOnScroll] withName:@"copiesOnScroll"];
  [archiver encodeObject:[self backgroundColor] withName:@"backgroundColor"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  self = [super initWithModelUnarchiver:unarchiver];

  [self setDocumentView:[unarchiver decodeObjectWithName:@"documentView"]];
  [self setCopiesOnScroll:[unarchiver decodeBOOLWithName:@"copiesOnScroll"]];
  [self setBackgroundColor:[unarchiver decodeObjectWithName:@"backgroundColor"]];
  return self;
}

@end /* NSClipView (GMArchiverMethods) */


@implementation NSColor (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  NSString* colorSpaceName = [self colorSpaceName];

  [archiver encodeString:colorSpaceName withName:@"colorSpaceName"];

  if ([colorSpaceName isEqual:@"NSDeviceCMYKColorSpace"]) {
    [archiver encodeFloat:[self cyanComponent] withName:@"cyan"];
    [archiver encodeFloat:[self magentaComponent] withName:@"magenta"];
    [archiver encodeFloat:[self yellowComponent] withName:@"yellow"];
    [archiver encodeFloat:[self blackComponent] withName:@"black"];
    [archiver encodeFloat:[self alphaComponent] withName:@"alpha"];
  }
  else if ([colorSpaceName isEqual:@"NSDeviceWhiteColorSpace"]
	   || [colorSpaceName isEqual:@"NSCalibratedWhiteColorSpace"]) {
    [archiver encodeFloat:[self whiteComponent] withName:@"white"];
    [archiver encodeFloat:[self alphaComponent] withName:@"alpha"];
  }
  else if ([colorSpaceName isEqual:@"NSDeviceRGBColorSpace"]
	   || [colorSpaceName isEqual:@"NSCalibratedRGBColorSpace"]) {
    [archiver encodeFloat:[self redComponent] withName:@"red"];
    [archiver encodeFloat:[self greenComponent] withName:@"green"];
    [archiver encodeFloat:[self blueComponent] withName:@"blue"];
    [archiver encodeFloat:[self alphaComponent] withName:@"alpha"];
    [archiver encodeFloat:[self hueComponent] withName:@"hue"];
    [archiver encodeFloat:[self saturationComponent] withName:@"saturation"];
    [archiver encodeFloat:[self brightnessComponent] withName:@"brightness"];
  }
  else if ([colorSpaceName isEqual:@"NSNamedColorSpace"]) {
    // TODO: change it when NSColor in GNUstep will have named color lists
#if 1
    NSColor* new
	= [self colorUsingColorSpaceName:@"NSCalibratedRGBColorSpace"];
    [new encodeWithModelArchiver:archiver];
#else
    [unarchiver encodeString:[self catalogNameComponent]
		withName:@"catalogName"];
    [unarchiver encodeString:[self colorNameComponent] withName:@"colorName"];
#endif
  }
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  NSString* colorSpaceName
      = [unarchiver decodeStringWithName:@"colorSpaceName"];

  if ([colorSpaceName isEqual:@"NSDeviceCMYKColorSpace"]) {
    float cyan = [unarchiver decodeFloatWithName:@"cyan"];
    float magenta = [unarchiver decodeFloatWithName:@"magenta"];
    float yellow = [unarchiver decodeFloatWithName:@"yellow"];
    float black = [unarchiver decodeFloatWithName:@"black"];
    float alpha = [unarchiver decodeFloatWithName:@"alpha"];

    return [NSColor colorWithDeviceCyan:cyan
				magenta:magenta
				 yellow:yellow
				  black:black
				  alpha:alpha];
  }
  else if ([colorSpaceName isEqual:@"NSDeviceWhiteColorSpace"]) {
    float white = [unarchiver decodeFloatWithName:@"white"];
    float alpha = [unarchiver decodeFloatWithName:@"alpha"];

    return [NSColor colorWithDeviceWhite:white alpha:alpha];
  }
  else if ([colorSpaceName isEqual:@"NSCalibratedWhiteColorSpace"]) {
    float white = [unarchiver decodeFloatWithName:@"white"];
    float alpha = [unarchiver decodeFloatWithName:@"alpha"];

    return [NSColor colorWithCalibratedWhite:white alpha:alpha];
  }
  else if ([colorSpaceName isEqual:@"NSDeviceRGBColorSpace"]) {
    float red = [unarchiver decodeFloatWithName:@"red"];
    float green = [unarchiver decodeFloatWithName:@"green"];
    float blue = [unarchiver decodeFloatWithName:@"blue"];
    float alpha = [unarchiver decodeFloatWithName:@"alpha"];

    return [self colorWithDeviceRed:red green:green blue:blue alpha:alpha];
  }
  else if ([colorSpaceName isEqual:@"NSCalibratedRGBColorSpace"]) {
    float red = [unarchiver decodeFloatWithName:@"red"];
    float green = [unarchiver decodeFloatWithName:@"green"];
    float blue = [unarchiver decodeFloatWithName:@"blue"];
    float alpha = [unarchiver decodeFloatWithName:@"alpha"];

    return [self colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
  }
  else if ([colorSpaceName isEqual:@"NSNamedColorSpace"]) {
    NSAssert (0, @"Named color spaces not supported yet!");
  }
  return nil;
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  return self;
}

- (Class)classForModelArchiver
{
  return [NSColor class];
}

@end /* NSColor (GMArchiverMethods) */


@implementation NSControl (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
    [archiver encodeObject:[self cell] withName:@"cell"];
    [archiver encodeBOOL:[self isEnabled] withName:@"isEnabled"];
    [archiver encodeInt:[self tag] withName:@"tag"];
    [archiver encodeBOOL:[self ignoresMultiClick] withName:@"ignoresMultiClick"];

    [super encodeWithModelArchiver:archiver];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
    self = [super initWithModelUnarchiver:unarchiver];

    // if (model_version == 1) {
    //[self setTarget:[unarchiver decodeObjectWithName:@"target"]];
    //[self setAction:[unarchiver decodeSelectorWithName:@"action"]];
    //[self setEnabled:[unarchiver decodeBOOLWithName:@"isEnabled"]];
    //[self setAlignment:[unarchiver decodeIntWithName:@"alignment"]];
    //[self setFont:[unarchiver decodeObjectWithName:@"font"]];
    //[self setContinuous:[unarchiver decodeBOOLWithName:@"isContinuous"]];
    //[self setTag:[unarchiver decodeIntWithName:@"tag"]];
    //[self setIgnoresMultiClick:
    //            [unarchiver decodeBOOLWithName:@"ignoresMultiClick"]];
    // } else {
    [self setCell:[unarchiver decodeObjectWithName:@"cell"]];
    [self setEnabled:[unarchiver decodeBOOLWithName:@"isEnabled"]];
    [self setTag:[unarchiver decodeIntWithName:@"tag"]];
    [self setIgnoresMultiClick:
                [unarchiver decodeBOOLWithName:@"ignoresMultiClick"]];
    // }
    return self;
}

@end /* NSControl (GMArchiverMethods) */

#ifndef __APPLE__
@implementation NSCStringText (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [super encodeWithModelArchiver:archiver];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  return [super initWithModelUnarchiver:unarchiver];
}

@end /* NSCStringText (GMArchiverMethods) */
#endif

@implementation NSFont (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [archiver encodeString:[self fontName] withName:@"name"];
  [archiver encodeFloat:[self pointSize] withName:@"size"];
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  return [NSFont fontWithName:[unarchiver decodeStringWithName:@"name"]
		 size:[unarchiver decodeFloatWithName:@"size"]];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  return self;
}

@end /* NSFont (GMArchiverMethods) */


@implementation NSImage (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [archiver encodeString:[self name] withName:@"name"];
  [archiver encodeSize:[self size] withName:@"size"];
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  id image = [NSImage imageNamed:[unarchiver decodeStringWithName:@"name"]];

  if (!image)
    image = [NSImage imageNamed:@"NSRadioButton"];
  return image;
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  [self setSize:[unarchiver decodeSizeWithName:@"size"]];
  return self;
}

@end /* NSImage (GMArchiverMethods) */


@implementation NSMenuItem (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
#if XDPS_BACKEND_LIBRARY || XRAW_BACKEND_LIBRARY || XGPS_BACKEND_LIBRARY
  [super encodeWithModelArchiver:archiver];
#endif

  [archiver encodeObject:[self target] withName:@"target"];
  [archiver encodeSelector:[self action] withName:@"action"];
  [archiver encodeString:[self title] withName:@"title"];
  [archiver encodeInt:[self tag] withName:@"tag"];
  [archiver encodeBOOL:[self isEnabled] withName:@"isEnabled"];
  [archiver encodeString:[self keyEquivalent] withName:@"keyEquivalent"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
#if XDPS_BACKEND_LIBRARY || XRAW_BACKEND_LIBRARY || XGPS_BACKEND_LIBRARY
  self = [super initWithModelUnarchiver:unarchiver];
#endif

  [self setTarget:[unarchiver decodeObjectWithName:@"target"]];
  [self setAction:[unarchiver decodeSelectorWithName:@"action"]];
  [self setTitle:[unarchiver decodeStringWithName:@"title"]];
  [self setTag:[unarchiver decodeIntWithName:@"tag"]];
  [self setEnabled:[unarchiver decodeBOOLWithName:@"isEnabled"]];
  [self setKeyEquivalent:[unarchiver decodeStringWithName:@"keyEquivalent"]];

#if 0
  NSLog (@"menu item %@: target = %@, isEnabled = %d",
	[self title], [self target], [self isEnabled]);
#endif

  return self;
}

@end /* NSMenuItem (GMArchiverMethods) */


@implementation NSMenu (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [archiver encodeObject:[self itemArray] withName:@"itemArray"];
  [archiver encodeBOOL:[self autoenablesItems] withName:@"autoenablesItems"];
  [archiver encodeString:[self title] withName:@"title"];
}

/* Define this method here because on OPENSTEP 4.x the NSMenu is inherited from
   NSWindow and we don't want the NSWindow's method to be called. */
+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  NSString* theTitle = [unarchiver decodeStringWithName:@"title"];
  return [[[self allocWithZone:[unarchiver objectZone]] initWithTitle:theTitle]
		autorelease];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  int i, count;
  NSMutableArray* itemArray = [self itemArray];
  NSMutableArray* decodedItems
      = [unarchiver decodeObjectWithName:@"itemArray"];

  for (i = 0, count = [decodedItems count]; i < count; i++)
    [self addItem:[decodedItems objectAtIndex:i]];
//    [self addItemWithTitle:@"dummy" action:NULL keyEquivalent:@""];

//  [itemArray replaceObjectsInRange:NSMakeRange(0, count)
//	     withObjectsFromArray:decodedItems];

  for (i = 0; i < count; i++) {
    id item = [itemArray objectAtIndex:i];
    id target = [item target];

    if ([target isKindOfClass:[NSMenu class]])
      [self setSubmenu:target forItem:item];
  }

  [self setAutoenablesItems:
	  [unarchiver decodeBOOLWithName:@"autoenablesItems"]];

  [self sizeToFit];

  return self;
}

@end /* NSMenu (GMArchiverMethods) */

#if 0
@implementation NSPopUpButton (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [archiver encodeBOOL:[self pullsDown] withName:@"pullsDown"];
  
#if 0
  /* OUCH! This code crashes the translator; probably we interfere somehow with
     the way NSPopUpButton is handled by the NeXT's NIB code. Sorry, the
     popup buttons cannot be handled by the convertor! */
  [archiver encodeArray:[self itemArray] withName:@"itemArray"];
  [archiver encodeString:[self titleOfSelectedItem] withName:@"selectedItem"];
  [super encodeWithModelArchiver:archiver];
#else // need frame for workarounds to know where to place the popup
  [archiver encodeRect:[self frame] withName:@"frame"];
#endif
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  NSRect rect = [unarchiver decodeRectWithName:@"frame"];
  NSPopUpButton *popup = \
    [[[NSPopUpButton allocWithZone:[unarchiver objectZone]]
                    initWithFrame:rect
                        pullsDown:[unarchiver decodeBOOLWithName:@"pullsDown"]]
    autorelease];
  if (!popup)
    NSLog (@"cannot create the requested view!");

  return popup;
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  /* Check the following: the program simply crashes if there's nothing in the
     model file */

  int i, count;
  NSMutableArray* decodedItems
      = [unarchiver decodeObjectWithName:@"itemArray"];

  self = [super initWithModelUnarchiver:unarchiver];

  if (decodedItems) {
      for (i = 0, count = [decodedItems count]; i < count; i++) {
	  id item = [decodedItems objectAtIndex:i];
	  id myItem;
	  
	  [self addItemWithTitle:[item title]];
	  myItem = [self itemAtIndex:i];
	  [myItem setTarget:[item target]];
	  [myItem setAction:[item action]];
	  [myItem setEnabled:[item isEnabled]];
	  [myItem setTag:[item tag]];
	  [myItem setKeyEquivalent:[item keyEquivalent]];
      }
  }

  [self selectItemWithTitle:[unarchiver decodeStringWithName:@"selectedItem"]];
  [self synchronizeTitleAndSelectedItem];


  return self;
}

@end /* NSPopUpButton (GMArchiverMethods) */
#endif

@implementation NSResponder (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  id nextResponder;

  if ((nextResponder = [self nextResponder]))
    [archiver encodeObject:nextResponder withName:@"nextResponder"];
  if ([self respondsToSelector: @selector(interfaceStyle)])
    [archiver encodeUnsignedInt: [self interfaceStyle]
            withName:@"interfaceStyle"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  [self setNextResponder:[unarchiver decodeObjectWithName:@"nextResponder"]];
  if ([self respondsToSelector: @selector(setInterfaceStyle:)])
    [self setInterfaceStyle:
        [unarchiver decodeUnsignedIntWithName:@"interfaceStyle"]];

  return self;
}

@end /* NSResponder (GMArchiverMethods) */


@implementation NSTextField (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  id theCell = [self cell];

  [super encodeWithModelArchiver:archiver];

  [archiver encodeBOOL:[self isSelectable] withName:@"isSelectable"];
  [archiver encodeSelector:[self errorAction] withName:@"errorAction"];
  [archiver encodeObject:[self textColor] withName:@"textColor"];
  [archiver encodeObject:[self backgroundColor] withName:@"backgroundColor"];
  [archiver encodeBOOL:[self drawsBackground] withName:@"drawsBackground"];
  [archiver encodeBOOL:[self isBordered] withName:@"isBordered"];
  [archiver encodeBOOL:[self isBezeled] withName:@"isBezeled"];
  [archiver encodeObject:[self nextText] withName:@"nextText"];
  [archiver encodeObject:[self previousText] withName:@"previousText"];
  [archiver encodeObject:[self delegate] withName:@"delegate"];
  [archiver encodeString:[self stringValue] withName:@"stringValue"];
  [archiver encodeBOOL:[self isEditable] withName:@"isEditable"];
  [archiver encodeBOOL:[theCell isScrollable] withName:@"isScrollable"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  id theCell;

  self = [super initWithModelUnarchiver:unarchiver];

  [self setSelectable:[unarchiver decodeBOOLWithName:@"isSelectable"]];
  [self setErrorAction:[unarchiver decodeSelectorWithName:@"errorAction"]];
  [self setTextColor:[unarchiver decodeObjectWithName:@"textColor"]];
  [self setBackgroundColor:
	    [unarchiver decodeObjectWithName:@"backgroundColor"]];
  [self setDrawsBackground:[unarchiver decodeBOOLWithName:@"drawsBackground"]];

  [self setBordered:[unarchiver decodeBOOLWithName:@"isBordered"]];
  [self setBezeled:[unarchiver decodeBOOLWithName:@"isBezeled"]];

  [self setNextText:[unarchiver decodeObjectWithName:@"nextText"]];
  [self setPreviousText:[unarchiver decodeObjectWithName:@"previousText"]];
  [self setDelegate:[unarchiver decodeObjectWithName:@"delegate"]];

  theCell = [self cell];

  [theCell setStringValue:[unarchiver decodeStringWithName:@"stringValue"]];
  [self setEditable:[unarchiver decodeBOOLWithName:@"isEditable"]];
  [theCell setScrollable:[unarchiver decodeBOOLWithName:@"isScrollable"]];

  return self;
}

@end /* NSTextField (GMArchiverMethods) */


@implementation NSView (GMArchiverMethods)

// subclasses may not want to encode all subviews...
- (NSArray *)subviewsForModel
{
  return [self subviews];
}

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [super encodeWithModelArchiver:archiver];

  [archiver encodeConditionalObject:[self superview] withName:@"superview"];
  [archiver encodeObject:[self subviewsForModel] withName:@"subviews"];
  [archiver encodeRect:[self frame] withName:@"frame"];
  [archiver encodeRect:[self bounds] withName:@"bounds"];
  [archiver encodeBOOL:[self postsFrameChangedNotifications]
	    withName:@"postsFrameChangedNotifications"];
  [archiver encodeBOOL:[self postsBoundsChangedNotifications]
	    withName:@"postsBoundsChangedNotifications"];
  [archiver encodeBOOL:[self autoresizesSubviews]
	    withName:@"autoresizesSubviews"];
  [archiver encodeUnsignedInt:[self autoresizingMask]
	    withName:@"autoresizingMask"];
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  NSRect rect = [unarchiver decodeRectWithName:@"frame"];
  NSView* view = [[[self allocWithZone:[unarchiver objectZone]]
				initWithFrame:rect]
				autorelease];
  if (!view)
    NSLog (@"cannot create the requested view!");
  return view;
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  NSArray* subviews;
  int i, count;
  id superview;

  self = [super initWithModelUnarchiver:unarchiver];

  superview = [unarchiver decodeObjectWithName:@"superview"];
  [superview addSubview:self];

  subviews = [unarchiver decodeObjectWithName:@"subviews"];
  for (i = 0, count = [subviews count]; i < count; i++)
    [self addSubview:[subviews objectAtIndex:i]];

//  [self setBounds:[unarchiver decodeRectWithName:@"bounds"]];
  [self setPostsFrameChangedNotifications:
	[unarchiver decodeBOOLWithName:@"postsFrameChangedNotifications"]];
  [self setPostsBoundsChangedNotifications:
	[unarchiver decodeBOOLWithName:@"postsBoundsChangedNotifications"]];
  [self setAutoresizesSubviews:
	[unarchiver decodeBOOLWithName:@"autoresizesSubviews"]];
  [self setAutoresizingMask:
	[unarchiver decodeUnsignedIntWithName:@"autoresizingMask"]];

#ifndef NeXT_GUI_LIBRARY
  _rFlags.flipped_view = [self isFlipped];
  _rFlags.opaque_view = [self isOpaque];
  if ([sub_views count])
    _rFlags.has_subviews = 1;
#endif

  return self;
}

@end /* NSView (GMArchiverMethods) */


@implementation NSWindow (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  NSPoint wnOrigin = [self frame].origin;
  NSRect ctFrame = [[self contentView] frame];

  ctFrame.origin = wnOrigin;

  [archiver encodeRect:ctFrame withName:@"contentFrame"];
  [archiver encodeSize:[self maxSize] withName:@"maxSize"];
  [archiver encodeSize:[self minSize] withName:@"minSize"];
  [archiver encodeString:[self frameAutosaveName]
	    withName:@"frameAutosaveName"];
  [archiver encodeInt:[self level] withName:@"level"];
  [archiver encodeBOOL:[self isVisible] withName:@"isVisible"];
  [archiver encodeBOOL:[self isAutodisplay] withName:@"isAutodisplay"];
  [archiver encodeString:[self title] withName:@"title"];
  [archiver encodeString:[self representedFilename]
	    withName:@"representedFilename"];
  [archiver encodeBOOL:[self isReleasedWhenClosed]
	    withName:@"isReleasedWhenClosed"];
  [archiver encodeObject:[self contentView] withName:@"contentView"];
  [archiver encodeBOOL:[self hidesOnDeactivate]
	    withName:@"hidesOnDeactivate"];
  [archiver encodeObject:[self backgroundColor] withName:@"backgroundColor"];
  [archiver encodeUnsignedInt:[self styleMask] withName:@"styleMask"];
  [archiver encodeUnsignedInt:[self backingType] withName:@"backingType"];
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  unsigned backingType = [unarchiver decodeUnsignedIntWithName:@"backingType"];
  unsigned styleMask = [unarchiver decodeUnsignedIntWithName:@"styleMask"];
  NSRect ctRect = [unarchiver decodeRectWithName:@"contentFrame"];

  NSWindow* win = [[[NSWindow allocWithZone:[unarchiver objectZone]]
			initWithContentRect:ctRect
			styleMask:styleMask backing:backingType defer:YES]
			autorelease];
  //  printf("content: %g, %g -- frame %g, %g\n", ctRect.size.width, ctRect.size.height, [win frame].size.width, [win frame].size.height);

  return win;
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  NSString* frameAutosaveName;

  [self setContentView:[unarchiver decodeObjectWithName:@"contentView"]];
  [self setMaxSize:[unarchiver decodeSizeWithName:@"maxSize"]];
  [self setMinSize:[unarchiver decodeSizeWithName:@"minSize"]];

  frameAutosaveName = [unarchiver decodeStringWithName:@"frameAutosaveName"];
  if (frameAutosaveName)
    [self setFrameAutosaveName:frameAutosaveName];

#ifndef NeXT_GUI_LIBRARY
  window_level = [unarchiver decodeIntWithName:@"level"];
#endif

  [self setAutodisplay:[unarchiver decodeBOOLWithName:@"isAutodisplay"]];
  [self setTitle:[unarchiver decodeStringWithName:@"title"]];
  [self setRepresentedFilename:
	  [unarchiver decodeStringWithName:@"representedFilename"]];
  [self setReleasedWhenClosed:
	  [unarchiver decodeBOOLWithName:@"isReleasedWhenClosed"]];
  [self setHidesOnDeactivate:
	  [unarchiver decodeBOOLWithName:@"hidesOnDeactivate"]];
  [self setBackgroundColor:
	  [unarchiver decodeObjectWithName:@"backgroundColor"]];
  if ([unarchiver decodeBOOLWithName:@"isVisible"])
    [self orderFront:nil];

#if GNU_GUI_LIBRARY
	[[self contentView] setNeedsDisplay:YES];
#endif

  return self;
}

@end /* NSWindow (GMArchiverMethods) */

@implementation NSPanel (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
    NSPoint wnOrigin = [self frame].origin;
    NSRect ctFrame = [[self contentView] frame];

    ctFrame.origin = wnOrigin;

    [archiver encodeRect:ctFrame withName:@"contentFrame"];
    [archiver encodeSize:[self maxSize] withName:@"maxSize"];
    [archiver encodeSize:[self minSize] withName:@"minSize"];
    [archiver encodeString:[self frameAutosaveName]
	      withName:@"frameAutosaveName"];
    [archiver encodeInt:[self level] withName:@"level"];
    [archiver encodeBOOL:[self isVisible] withName:@"isVisible"];
    [archiver encodeBOOL:[self isAutodisplay] withName:@"isAutodisplay"];
    [archiver encodeString:[self title] withName:@"title"];
    [archiver encodeString:[self representedFilename]
	    withName:@"representedFilename"];
    [archiver encodeBOOL:[self isReleasedWhenClosed]
	    withName:@"isReleasedWhenClosed"];
    [archiver encodeObject:[self contentView] withName:@"contentView"];
    [archiver encodeBOOL:[self hidesOnDeactivate]
	    withName:@"hidesOnDeactivate"];
    [archiver encodeObject:[self backgroundColor] withName:@"backgroundColor"];
    [archiver encodeUnsignedInt:[self styleMask] withName:@"styleMask"];
    [archiver encodeUnsignedInt:[self backingType] withName:@"backingType"];

    [archiver encodeBOOL:[self isFloatingPanel] withName:@"isFloatingPanel"];
    [archiver encodeBOOL:[self becomesKeyOnlyIfNeeded]
            withName:@"becomesKeyOnlyIfNeeded"];
    [archiver encodeBOOL:[self worksWhenModal] withName:@"worksWhenModal"];
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
    unsigned backingType = [unarchiver decodeUnsignedIntWithName:
			   @"backingType"];
    unsigned styleMask = [unarchiver decodeUnsignedIntWithName:@"styleMask"];
    NSRect ctRect = [unarchiver decodeRectWithName:@"contentFrame"];
    NSPanel* panel = [[[NSPanel allocWithZone:[unarchiver objectZone]]
		     initWithContentRect:ctRect
		     styleMask:styleMask backing:backingType defer:YES]
		    autorelease];

    return panel;
}

-(id)initWithModelUnarchiver :(GMUnarchiver *)unarchiver
{
    NSString* frameAutosaveName;
    
    [self setContentView:[unarchiver decodeObjectWithName:@"contentView"]];
    [self setMaxSize:[unarchiver decodeSizeWithName:@"maxSize"]];
    [self setMinSize:[unarchiver decodeSizeWithName:@"minSize"]];
    
    frameAutosaveName = [unarchiver decodeStringWithName:@"frameAutosaveName"];
    if (frameAutosaveName)
	[self setFrameAutosaveName:frameAutosaveName];
    
#ifndef NeXT_GUI_LIBRARY
    window_level = [unarchiver decodeIntWithName:@"level"];
#endif
    
    [self setAutodisplay:[unarchiver decodeBOOLWithName:@"isAutodisplay"]];
    [self setTitle:[unarchiver decodeStringWithName:@"title"]];
    [self setRepresentedFilename:
        [unarchiver decodeStringWithName:@"representedFilename"]];
    [self setReleasedWhenClosed:
        [unarchiver decodeBOOLWithName:@"isReleasedWhenClosed"]];
    [self setHidesOnDeactivate:
        [unarchiver decodeBOOLWithName:@"hidesOnDeactivate"]];
    [self setBackgroundColor:
        [unarchiver decodeObjectWithName:@"backgroundColor"]];
    if ([unarchiver decodeBOOLWithName:@"isVisible"])
	[self orderFront:nil];

    [self setFloatingPanel:
        [unarchiver decodeBOOLWithName:@"isFloatingPanel"]];
    [self setBecomesKeyOnlyIfNeeded:
        [unarchiver decodeBOOLWithName:@"becomesKeyOnlyIfNeeded"]];
    [self setWorksWhenModal:
        [unarchiver decodeBOOLWithName:@"setWorksWhenModal"]];

#if GNU_GUI_LIBRARY
	[[self contentView] setNeedsDisplay:YES];
#endif
    return self;
}

@end  /* NSPanel (GMArchiverMethods) */


@implementation NSSavePanel (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
    //NSWindow specific
    [archiver encodeRect:[self frame] withName:@"frame"];
    [archiver encodeSize:[self maxSize] withName:@"maxSize"];
    [archiver encodeSize:[self minSize] withName:@"minSize"];
    [archiver encodeString:[self frameAutosaveName]
	      withName:@"frameAutosaveName"];
    [archiver encodeInt:[self level] withName:@"level"];
    [archiver encodeBOOL:[self isVisible] withName:@"isVisible"];
    [archiver encodeBOOL:[self isAutodisplay] withName:@"isAutodisplay"];
    [archiver encodeString:[self title] withName:@"title"];
    [archiver encodeString:[self representedFilename]
	    withName:@"representedFilename"];
    [archiver encodeBOOL:[self isReleasedWhenClosed]
	    withName:@"isReleasedWhenClosed"];
    [archiver encodeObject:[self contentView] withName:@"contentView"];
    [archiver encodeBOOL:[self hidesOnDeactivate]
	    withName:@"hidesOnDeactivate"];
    [archiver encodeObject:[self backgroundColor] withName:@"backgroundColor"];
    [archiver encodeUnsignedInt:[self styleMask] withName:@"styleMask"];
    [archiver encodeUnsignedInt:[self backingType] withName:@"backingType"];

    // NSPanel specific
    [archiver encodeBOOL:[self isFloatingPanel] withName:@"isFloatingPanel"];
    [archiver encodeBOOL:[self becomesKeyOnlyIfNeeded]
            withName:@"becomesKeyOnlyIfNeeded"];
    [archiver encodeBOOL:[self worksWhenModal] withName:@"worksWhenModal"];

    // NSSavePanel specific
    [archiver encodeString:[self prompt] withName:@"prompt"];
    [archiver encodeObject:[self accessoryView] withName:@"accessoryView"];
    [archiver encodeString:[self requiredFileType]
            withName:@"requiredFileType"];
    [archiver encodeBOOL:[self treatsFilePackagesAsDirectories]
            withName:@"treatsFilePackagesAsDirectories"];
    [archiver encodeString:[self directory]
            withName:@"directory"];
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
    unsigned backingType = [unarchiver decodeUnsignedIntWithName:
			   @"backingType"];
    unsigned styleMask = [unarchiver decodeUnsignedIntWithName:@"styleMask"];
    NSRect aRect = [unarchiver decodeRectWithName:@"frame"];
    // Use [self class] here instead of NSSavePanel so as to invoke
    // +allocWithZone on the correct (if any) sub-class
    NSSavePanel* panel = [[[[self class] allocWithZone:[unarchiver objectZone]]
			  initWithContentRect:aRect
			  styleMask:styleMask backing:backingType defer:YES]
			 autorelease];

#if GNU_GUI_LIBRARY
    NSDebugLLog(@"NSSavePanel", @"NSSavePanel +createObjectForModelUnarchiver");
#endif
    return panel;
}

-(id)initWithModelUnarchiver :(GMUnarchiver *)unarchiver
{
    NSString* frameAutosaveName;
    
    //NSWindow specifics
    [self setContentView:[unarchiver decodeObjectWithName:@"contentView"]];
    [self setMaxSize:[unarchiver decodeSizeWithName:@"maxSize"]];
    [self setMinSize:[unarchiver decodeSizeWithName:@"minSize"]];
    
    frameAutosaveName = [unarchiver decodeStringWithName:@"frameAutosaveName"];
    if (frameAutosaveName)
	[self setFrameAutosaveName:frameAutosaveName];
    
#ifndef NeXT_GUI_LIBRARY
    window_level = [unarchiver decodeIntWithName:@"level"];
#endif
    
    [self setAutodisplay:[unarchiver decodeBOOLWithName:@"isAutodisplay"]];
    [self setTitle:[unarchiver decodeStringWithName:@"title"]];
    [self setRepresentedFilename:
        [unarchiver decodeStringWithName:@"representedFilename"]];
    [self setReleasedWhenClosed:
        [unarchiver decodeBOOLWithName:@"isReleasedWhenClosed"]];
    [self setHidesOnDeactivate:
        [unarchiver decodeBOOLWithName:@"hidesOnDeactivate"]];
    [self setBackgroundColor:
        [unarchiver decodeObjectWithName:@"backgroundColor"]];
    if ([unarchiver decodeBOOLWithName:@"isVisible"])
	[self orderFront:nil];

    //NSPanel specifics
    [self setFloatingPanel:
        [unarchiver decodeBOOLWithName:@"isFloatingPanel"]];
    [self setBecomesKeyOnlyIfNeeded:
        [unarchiver decodeBOOLWithName:@"becomesKeyOnlyIfNeeded"]];
    [self setWorksWhenModal:
        [unarchiver decodeBOOLWithName:@"setWorksWhenModal"]];

    //NSSavePanel specifics
    [self setPrompt:[unarchiver decodeStringWithName:@"prompt"]];
    [self setAccessoryView:[unarchiver decodeObjectWithName:@"accessoryView"]];
    [self setRequiredFileType:
          [unarchiver decodeStringWithName:@"requiredFileType"]];
    [self setTreatsFilePackagesAsDirectories:
          [unarchiver decodeBOOLWithName:@"treatsFilePackagesAsDirectories"]];
    [self setDirectory:
          [unarchiver decodeStringWithName:@"directory"]];

#if GNU_GUI_LIBRARY
    [[self contentView] setNeedsDisplay:YES];
#endif
    return self;
}

@end  /* NSSavePanel (GMArchiverMethods) */


@implementation NSBrowser (GMArchiverMethods)

- (void)encodeWithModelArchiver :(GMArchiver*)archiver
{
    [super encodeWithModelArchiver:archiver];

    //NSBrowser
    [archiver encodeString:[self path] withName:@"path"];
    [archiver encodeString:[self pathSeparator] withName:@"pathSeparator"];
    [archiver encodeBOOL:[self allowsBranchSelection] 
            withName:@"allowsBranchSelection"];
    [archiver encodeBOOL:[self allowsEmptySelection]
            withName:@"allowsEmptySelection"];
    [archiver encodeBOOL:[self allowsMultipleSelection]
            withName:@"allowsMultipleSelection"];
    [archiver encodeBOOL:[self reusesColumns] withName:@"reusesColumns"];
    [archiver encodeUnsignedInt:[self maxVisibleColumns]
            withName:@"maxVisibleColumns"];
    [archiver encodeUnsignedInt:[self minColumnWidth]
            withName:@"minColumnWidth"];
    [archiver encodeBOOL:[self separatesColumns]
            withName:@"separatesColumns"];
    [archiver encodeBOOL:[self takesTitleFromPreviousColumn]
            withName:@"takesTitleFromPreviousColumn"];
    [archiver encodeBOOL:[self isTitled] withName:@"isTitled"];
    [archiver encodeBOOL:[self hasHorizontalScroller]
            withName:@"hasHorizontalScroller"];
    [archiver encodeBOOL:[self acceptsArrowKeys]
            withName:@"acceptsArrowKeys"];
    [archiver encodeBOOL:[self sendsActionOnArrowKeys]
            withName:@"sendsActionOnArrowKeys"];

    [archiver encodeObject:[self delegate] withName:@"delegate"];
    [archiver encodeSelector:[self doubleAction] withName:@"doubleAction"];
}

#if 0
+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
    unsigned backingType = [unarchiver decodeUnsignedIntWithName:
			   @"backingType"];
    unsigned styleMask = [unarchiver decodeUnsignedIntWithName:@"styleMask"];
    NSRect aRect = [unarchiver decodeRectWithName:@"frame"];
    NSBrowser* browser = [[[NSBrowser allocWithZone:[unarchiver objectZone]]
			  initWithContentRect:aRect
			  styleMask:styleMask backing:backingType defer:YES]
			 autorelease];

    return browser;
}
#endif

- (id)initWithModelUnarchiver :(GMUnarchiver *)unarchiver
{
    id delegate;


    self = [super initWithModelUnarchiver:unarchiver];
    
    [self setPath:[unarchiver decodeStringWithName:@"path"]];
    [self setPathSeparator:[unarchiver decodeStringWithName:@"pathSeparator"]];
    [self setAllowsBranchSelection:[unarchiver
		       decodeBOOLWithName:@"allowsBranchSelection"]];
    [self setAllowsEmptySelection:[unarchiver
		       decodeBOOLWithName:@"allowsEmptySelection"]];
    [self setAllowsMultipleSelection:[unarchiver
		       decodeBOOLWithName:@"allowsMultipleSelection"]];

    [self setReusesColumns:[unarchiver decodeBOOLWithName:@"reusesColumns"]];
    [self setMaxVisibleColumns:[unarchiver
		       decodeUnsignedIntWithName:@"maxVisibleColumns"]];
    [self setMinColumnWidth:[unarchiver
		       decodeUnsignedIntWithName:@"minColumnWidth"]];
    [self setSeparatesColumns:[unarchiver
		       decodeBOOLWithName:@"separatesColumns"]];
    [self setTakesTitleFromPreviousColumn:[unarchiver 
		       decodeBOOLWithName:@"takesTitleFromPreviousColumn"]];
    [self setTitled:[unarchiver 
		       decodeBOOLWithName:@"isTitled"]];
    [self setHasHorizontalScroller:[unarchiver
		       decodeBOOLWithName:@"hasHorizontalScroller"]];
    [self setAcceptsArrowKeys:[unarchiver 
                       decodeBOOLWithName:@"acceptsArrowKeys"]];
    [self setSendsActionOnArrowKeys:[unarchiver
		       decodeBOOLWithName:@"sendsActionOnArrowKeys"]];

    //avoid an exeption
    delegate = [unarchiver decodeObjectWithName:@"delegate"];
    if (delegate)
	[self setDelegate:delegate];

    [self setDoubleAction:[unarchiver decodeSelectorWithName:@"doubleAction"]];
    return self;
}

@end  /* NSBrowser (GMArchiverMethods) */

@implementation NSColorWell (GMArchiverMethods)

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  self = [super initWithModelUnarchiver:unarchiver];

  [self setColor:[unarchiver decodeObjectWithName:@"color"]];

  return self;
}

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [super encodeWithModelArchiver:archiver];

  [archiver encodeObject:[self color] withName:@"color"];
}

@end /* NSColorWell (GMArchiverMethods) */

@implementation NSImageView (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [super encodeWithModelArchiver:archiver];

  [archiver encodeInt:[self imageAlignment] withName:@"alignment"];
  [archiver encodeInt:[self imageFrameStyle] withName:@"frameStyle"];
  [archiver encodeObject:[self image] withName:@"image"];
  [archiver encodeBOOL:[self isEditable] withName:@"isEditable"];
  [archiver encodeInt:[self imageScaling] withName:@"scaling"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  self = [super initWithModelUnarchiver:unarchiver];

  [self setImageAlignment:[unarchiver decodeIntWithName:@"alignment"]];
  [self setImageFrameStyle:[unarchiver decodeIntWithName:@"frameStyle"]];
  [self setImage:[unarchiver decodeObjectWithName:@"image"]];
  [self setEditable:[unarchiver decodeBOOLWithName:@"isEditable"]];
  [self setImageScaling:[unarchiver decodeIntWithName:@"scaling"]];

  return self;
}

@end

@implementation NSTextFieldCell (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [super encodeWithModelArchiver:archiver];

  [archiver encodeObject:[self backgroundColor] withName:@"backgroundColor"];
  [archiver encodeBOOL:[self drawsBackground] withName:@"drawsBackground"];
  [archiver encodeObject:[self textColor] withName:@"textColor"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  self = [super initWithModelUnarchiver:unarchiver];

  [self setBackgroundColor:
	     [unarchiver decodeObjectWithName:@"backgroundColor"]];
  [self setDrawsBackground:
	     [unarchiver decodeBOOLWithName:@"drawsBackground"]];
  [self setTextColor:[unarchiver decodeObjectWithName:@"textColor"]];

  return self;
}

@end /* NSTextFieldCell (GMArchiverMethods) */

@implementation NSFormCell (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [super encodeWithModelArchiver:archiver];

  [archiver encodeString:[self title] withName:@"title"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  self = [super initWithModelUnarchiver:unarchiver];

  [self setTitle:[unarchiver decodeStringWithName:@"title"]];

  return self;
}

@end /* NSFormCell (GMArchiverMethods) */
