/* 
   NSColorList.h

   Manage named lists of NSColors.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: 2000
   
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

#ifndef _GNUstep_H_NSColorList
#define _GNUstep_H_NSColorList

#include <Foundation/NSCoder.h>
#include <AppKit/AppKitDefines.h>

@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableDictionary;

@class NSColor;

@interface NSColorList : NSObject <NSCoding>

{
  NSString* _name;
  NSString* _fullFileName;
  BOOL _is_editable;

  // Color Lists are required to be a sort of ordered dictionary
  // For now it is implemented as follows (Scott Christley, 1996):

  // This object contains couples (keys (=color names), values (=colors))
  NSMutableDictionary* _colorDictionary;

  // This object contains the keys (=color names) in order
  NSMutableArray* _orderedColorKeys;
}

//
// Initializing an NSColorList
//
/**
 * Initializes a new, empty color list registered under given name.
 */
- (id)initWithName:(NSString *)name;

/**
 * <p>Initializes a new color list registered under given name, taking
 * contents from the file specified in path.  (Path should include the
 * filename with extension (usually ".clr"), and by convention name should be
 * the same as filename <em>without</em> the extension.)</p>
 *  
 * <p>The format of the file can be either an archive of an NSColorList
 * or an ASCII format.  ASCII files follow this format:</p>
 *
 * <p>first line  =  [#/colors] <br/>
 * each subsequent line describes a color as [int float+ string] <br/>
 * the first int describes the method (RGBA, etc.), the floats
 * provide its arguments (e.g., r, g, b, alpha), and string is name.</p>
 *
 * <p>The <em>method</em> corresponds to one of the [NSColor] initializers.
 * We are looking for documentation of the exact correspondence on OpenStep;
 * for now the only supported method is "0", which is an RGBA format with
 * the arguments in order R,G,B, A.</p>
 */
- (id)initWithName:(NSString *)name
	  fromFile:(NSString *)path;

//
// Getting All Color Lists
//
+ (NSArray *)availableColorLists;

//
// Getting a Color List by Name
//
+ (NSColorList *)colorListNamed:(NSString *)name;
- (NSString *)name;

//
// Managing Colors by Key
//
- (NSArray *)allKeys;
- (NSColor *)colorWithKey:(NSString *)key;
- (void)insertColor:(NSColor *)color
		key:(NSString *)key
	    atIndex:(unsigned)location;
- (void)removeColorWithKey:(NSString *)key;
- (void)setColor:(NSColor *)aColor
	  forKey:(NSString *)key;

//
// Editing
//
- (BOOL)isEditable;

//
// Writing and Removing Files
//
- (BOOL)writeToFile:(NSString *)path;
- (void)removeFile;

//
// NSCoding protocol
//
- (void)encodeWithCoder: (NSCoder *)aCoder;
- initWithCoder: (NSCoder *)aDecoder;

@end

/* Notifications */
APPKIT_EXPORT NSString *NSColorListChangedNotification;

#endif // _GNUstep_H_NSColorList
