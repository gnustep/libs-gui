/* <title>GSXibLoading</title>

   <abstract>Xib (Cocoa XML) model loader</abstract>

   Copyright (C) 2010 Free Software Foundation, Inc.

   Written by: Fred Kiefer <FredKiefer@gmx.de>
   Created: March 2010
   Refactored slightly by: Gregory Casamento <greg.casamento@gmail.com>
   Created: May 2010

   This file is part of the GNUstep Base Library.

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

#ifndef _GNUstep_H_GSXibElement
#define _GNUstep_H_GSXibElement

#import <Foundation/NSObject.h>

@class NSString, NSDictionary, NSMutableDictionary, NSMutableArray;

@interface GSXibElement: NSObject
{
  NSString *type;
  NSDictionary *attributes;
  NSString *value;
  NSMutableDictionary *elements;
  NSMutableArray *values;
}

- (GSXibElement*) initWithType: (NSString*)typeName 
                 andAttributes: (NSDictionary*)attribs;
- (NSString*) type;
- (NSString*) value;
- (NSDictionary*) elements;
- (NSArray*) values;
- (void) addElement: (GSXibElement*)element;
- (void) setElement: (GSXibElement*)element forKey: (NSString*)key;
- (void) setValue: (NSString*)text;
- (NSString*) attributeForKey: (NSString*)key;
- (GSXibElement*) elementForKey: (NSString*)key;
- (NSDictionary *) attributes;
@end

#endif

