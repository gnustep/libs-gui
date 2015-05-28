/* <title>GSXibParser</title>

   <abstract>Xib v5 (Cocoa XML) parser</abstract>

   Copyright (C) 2014 Free Software Foundation, Inc.

   Written by: Gregory Casamento <greg.casamento@gmail.com>
   Created: March 2014

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_GSXibParser
#define _GNUstep_H_GSXibParser

#import <Foundation/NSObject.h>

@class NSData;
@class NSXMLParser;
@class NSMutableDictionary;
@class GSXibElement;
@class NSMutableArray;

@interface GSXibParser : NSObject
{
  NSMutableDictionary *objects;
  GSXibElement *currentElement;
  NSMutableArray *stack;
  NSXMLParser *theParser;
}

- (id) initWithData: (NSData *)data;
- (NSDictionary *) parse;

@end

#endif
