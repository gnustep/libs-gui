/* 
   NSNibLoading.h

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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/ 

#ifndef _GNUstep_H_NSNibLoading
#define _GNUstep_H_NSNibLoading

#include <Foundation/NSObject.h>
#include <Foundation/NSBundle.h>

@class	NSString;
@class	NSDictionary;
@class	NSMutableDictionary;

@interface NSObject (NSNibAwaking)

/*
 * Notification of Loading
 */
- (void) awakeFromNib;

@end


@interface NSBundle (NSNibLoading)

+ (BOOL) loadNibFile: (NSString *)fileName
   externalNameTable: (NSDictionary *)context
	    withZone: (NSZone *)zone;

+ (BOOL) loadNibNamed: (NSString *)aNibName
	        owner: (id)owner;

- (BOOL) loadNibFile: (NSString *)fileName
   externalNameTable: (NSDictionary *)context
	    withZone: (NSZone *)zone;

@end

#ifndef	NO_GNUSTEP

/*
 * This is the class that holds objects within a nib.
 */
@interface GSNibContainer : NSObject <NSCoding>
{
  NSMutableDictionary	*nameTable;
  NSMutableArray	*connections;
  BOOL			_isAwake;
}
- (void) awakeWithContext: (NSDictionary*)context;
- (NSMutableDictionary*) nameTable;
- (NSMutableArray*) connections;
@end

@interface GSNibItem : NSObject <NSCoding>
{
  NSString		*theClass;
  NSRect		theFrame;
}
@end

#endif	/* NO_GNUSTEP */

#endif /* _GNUstep_H_NSNibLoading */

