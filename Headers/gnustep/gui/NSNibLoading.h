/* 
   NSNibLoading.h

   Something to do with loading Nibs?

   Copyright (C) 1997, 1999 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: 1997
   Author:  Richard Frith-Macdonald <richard@branstorm.co.uk>
   Date: 1999
   
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

#ifndef _GNUstep_H_NSNibLoading
#define _GNUstep_H_NSNibLoading

#include <Foundation/NSObject.h>
#include <Foundation/NSBundle.h>

@class	NSString;
@class	NSDictionary;
@class	NSMutableDictionary;

@interface NSObject (NSNibAwaking)

//
// Notification of Loading
//
- (void) awakeFromNib;

@end


@interface NSBundle (NSNibLoading)

+ (BOOL) loadNibFile: (NSString *)fileName
   externalNameTable: (NSDictionary *)context
	    withZone: (NSZone *)zone;

+ (BOOL) loadNibNamed: (NSString *)aNibName
	        owner: (id)owner;

@end

#ifndef	NO_GNUSTEP

/*
 *	This is the class that manages objects within a nib - when a nib is
 *	loaded, the [-setAllOutlets] method is used to set up the objects
 *	and the GSNibContainer object is released.
 */
@interface GSNibContainer : NSObject
{
  NSMutableDictionary	*nameTable;
  NSMutableDictionary	*outletMap;
}
- (NSMutableDictionary*) nameTable;
- (NSMutableDictionary*) outletsFrom: (NSString*)instanceName;
- (void) setAllOutlets;
- (BOOL) setOutlet: (NSString*)outletName from: (id)source to: (id)target;
- (BOOL) setOutlet: (NSString*)outletName
	  fromName: (NSString*)sourceName
	    toName: (NSString*)targetName;
@end

@interface GSNibItem : NSObject
{
  NSString		*theClass;
  NSRect		frame;
  BOOL			hasFrame;
  NSMutableArray	*settings;
}
@end

#endif	/* NO_GNUSTEP */

#endif // _GNUstep_H_NSNibLoading
