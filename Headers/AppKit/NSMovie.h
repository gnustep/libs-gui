/** <title>NSMovie</title>

   <abstract>Encapsulate a Quicktime movie</abstract>

   Copyright <copy>(C) 2003 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: March 2003

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

#ifndef _GNUstep_H_NSMovie
#define _GNUstep_H_NSMovie

#include <Foundation/NSObject.h>

@class NSArray;
@class NSData;
@class NSURL;
@class NSPasteboard;

@interface NSMovie : NSObject <NSCopying, NSCoding> 
{
  @private
    NSData*  _movie;
    NSURL*   _url;
}

+ (NSArray*) movieUnfilteredFileTypes;
+ (NSArray*) movieUnfilteredPasteboardTypes;
+ (BOOL) canInitWithPasteboard: (NSPasteboard*)pasteboard;

- (id) initWithMovie: (void*)movie;
- (id) initWithURL: (NSURL*)url byReference: (BOOL)byRef;
- (id) initWithPasteboard: (NSPasteboard*)pasteboard;

- (void*) QTMovie;
- (NSURL*) URL;

@end

#endif /* _GNUstep_H_NSMovie */
