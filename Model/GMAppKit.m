/*
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
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
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
#if XDPS_BACKEND_LIBRARY
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

  [archiver encodeInt:[self borderType] withName:@"borderType"];
  [archiver encodeInt:[self titlePosition] withName:@"titlePosition"];
  [archiver encodeString:[self title] withName:@"title"];
  [archiver encodeObject:[self titleFont] withName:@"titleFont"];
  [archiver encodeObject:[self contentView] withName:@"contentView"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  self = [super initWithModelUnarchiver:unarchiver];

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

  [self getPeriodicDelay:&delay interval:&interval];
  [archiver encodeInt:[self state] withName:@"state"];
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
  id theCell = [self cell];

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
  [theCell setHighlightsBy:[unarchiver decodeIntWithName:@"highlightsBy"]];
  [theCell setShowsStateBy:[unarchiver decodeIntWithName:@"showsStateBy"]];

  return self;
}

@end /* NSButton (GMArchiverMethods) */


@implementation NSCell (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [archiver encodeObject:[self font] withName:@"font"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  NSFont* font = [unarchiver decodeObjectWithName:@"font"];
  if (!font)
    font = [NSFont userFontOfSize:0];

  [self setFont:font];
  return self;
}

@end /* NSCell (GMArchiverMethods) */


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
  id target;
  SEL action;

  if ((target = [self target]))
    [archiver encodeObject:target withName:@"target"];
  if ((action = [self action]))
    [archiver encodeSelector:action withName:@"action"];

  [archiver encodeBOOL:[self isEnabled] withName:@"isEnabled"];
  [archiver encodeInt:[self alignment] withName:@"alignment"];
  [archiver encodeObject:[self font] withName:@"font"];
  [archiver encodeBOOL:[self isContinuous] withName:@"isContinuous"];
  [archiver encodeInt:[self tag] withName:@"tag"];
  [archiver encodeBOOL:[self ignoresMultiClick] withName:@"ignoresMultiClick"];

  [super encodeWithModelArchiver:archiver];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  self = [super initWithModelUnarchiver:unarchiver];

  [self setTarget:[unarchiver decodeObjectWithName:@"target"]];
  [self setAction:[unarchiver decodeSelectorWithName:@"action"]];
  [self setEnabled:[unarchiver decodeBOOLWithName:@"isEnabled"]];
  [self setAlignment:[unarchiver decodeIntWithName:@"alignment"]];
  [self setFont:[unarchiver decodeObjectWithName:@"font"]];
  [self setContinuous:[unarchiver decodeBOOLWithName:@"isContinuous"]];
  [self setTag:[unarchiver decodeIntWithName:@"tag"]];
  [self setIgnoresMultiClick:
	      [unarchiver decodeBOOLWithName:@"ignoresMultiClick"]];

  return self;
}

@end /* NSControl (GMArchiverMethods) */


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
#if XDPS_BACKEND_LIBRARY
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
#if XDPS_BACKEND_LIBRARY
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
    [self addItemWithTitle:@"dummy" action:NULL keyEquivalent:@""];

  [itemArray replaceObjectsInRange:NSMakeRange(0, count)
	     withObjectsFromArray:decodedItems];

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
#endif
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  /* Check the following: the program simply crashes if there's nothing in the
     model file */
#if 0
  int i, count;
  NSMutableArray* decodedItems
      = [unarchiver decodeObjectWithName:@"itemArray"];

  self = [super initWithModelUnarchiver:unarchiver];

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

  [self selectItemWithTitle:[unarchiver decodeStringWithName:@"selectedItem"]];
  [self synchronizeTitleAndSelectedItem];
#endif

  return self;
}

@end /* NSPopUpButton (GMArchiverMethods) */


@implementation NSResponder (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  id nextResponder;

  if ((nextResponder = [self nextResponder]))
    [archiver encodeObject:nextResponder withName:@"nextResponder"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  [self setNextResponder:[unarchiver decodeObjectWithName:@"nextResponder"]];
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
  id theCell = [self cell];
  BOOL flag;

  self = [super initWithModelUnarchiver:unarchiver];

  [self setSelectable:[unarchiver decodeBOOLWithName:@"isSelectable"]];
  [self setErrorAction:[unarchiver decodeSelectorWithName:@"errorAction"]];
  [self setTextColor:[unarchiver decodeObjectWithName:@"textColor"]];
  [self setBackgroundColor:
	    [unarchiver decodeObjectWithName:@"backgroundColor"]];
  [self setDrawsBackground:[unarchiver decodeBOOLWithName:@"drawsBackground"]];

  flag = [unarchiver decodeBOOLWithName:@"isBordered"];
  if (flag)
    [self setBordered:flag];

  flag = [unarchiver decodeBOOLWithName:@"isBezeled"];
  if (flag)
    [self setBezeled:flag];

  [self setNextText:[unarchiver decodeObjectWithName:@"nextText"]];
  [self setPreviousText:[unarchiver decodeObjectWithName:@"previousText"]];
  [self setDelegate:[unarchiver decodeObjectWithName:@"delegate"]];
  [theCell setStringValue:[unarchiver decodeStringWithName:@"stringValue"]];
  [self setEditable:[unarchiver decodeBOOLWithName:@"isEditable"]];
  [theCell setScrollable:[unarchiver decodeBOOLWithName:@"isScrollable"]];

  return self;
}

@end /* NSTextField (GMArchiverMethods) */


@implementation NSView (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [super encodeWithModelArchiver:archiver];

  [archiver encodeConditionalObject:[self superview] withName:@"superview"];
  [archiver encodeObject:[self subviews] withName:@"subviews"];
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

  [self setBounds:[unarchiver decodeRectWithName:@"bounds"]];
  [self setPostsFrameChangedNotifications:
	[unarchiver decodeBOOLWithName:@"postsFrameChangedNotifications"]];
  [self setPostsBoundsChangedNotifications:
	[unarchiver decodeBOOLWithName:@"postsBoundsChangedNotifications"]];
  [self setAutoresizesSubviews:
	[unarchiver decodeBOOLWithName:@"autoresizesSubviews"]];
  [self setAutoresizingMask:
	[unarchiver decodeUnsignedIntWithName:@"autoresizingMask"]];

  return self;
}

@end /* NSView (GMArchiverMethods) */


@implementation NSWindow (GMArchiverMethods)

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
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
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  unsigned backingType = [unarchiver decodeUnsignedIntWithName:@"backingType"];
  unsigned styleMask = [unarchiver decodeUnsignedIntWithName:@"styleMask"];
  NSRect aRect = [unarchiver decodeRectWithName:@"frame"];
  NSWindow* win = [[[NSWindow allocWithZone:[unarchiver objectZone]]
			initWithContentRect:aRect
			styleMask:styleMask backing:backingType defer:YES]
			autorelease];

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

  [self setLevel:[unarchiver decodeIntWithName:@"level"]];

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
  [[[self contentView] superview] _unconditionallyResetNeedsDisplayInAllViews];
  [[self contentView] setNeedsDisplay:YES];
#endif

  return self;
}

@end /* NSWindow (GMArchiverMethods) */

