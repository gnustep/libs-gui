/** <title>NSMovie</title>

   <abstract>Encapsulate a Quicktime movie</abstract>

   Copyright <copy>(C) 2003 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: March 2003

   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: March 2022

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

#ifndef _GNUstep_H_NSMovie
#define _GNUstep_H_NSMovie

#import <GNUstepBase/GSVersionMacros.h>
#import <GNUstepGUI/GSVideoSource.h>
#import <GNUstepGUI/GSVideoSink.h>

#import <Foundation/NSObject.h>

@class NSArray;
@class NSData;
@class NSURL;
@class NSPasteboard;

@interface NSMovie : NSObject <NSCopying, NSCoding> 
{
  @private
    NSData             *_movieData;
    NSURL              *_url;
    void               *_movie;
    id< GSVideoSource > _source;
    id< GSVideoSink >   _sink;
}

/**
 * Returns the array of file types/extensions that NSMovie can handle
 */
+ (NSArray *) movieUnfilteredFileTypes;

/**
 * Returns the array of pasteboard types that NSMovie can handle
 */
+ (NSArray *) movieUnfilteredPasteboardTypes;

/**
 * Returns YES, if NSMovie can initialize with the data on the pasteboard
 */
+ (BOOL) canInitWithPasteboard: (NSPasteboard *)pasteboard;

/**
 * Accepts a Carbon movie and uses it to init NSMovie (non-functional on GNUstep).
 */
- (id) initWithMovie: (void *)movie;

/**
 * Retrieves the data from url and initializes with it, does so by references depending
 * on byRef
 */
- (id) initWithURL: (NSURL *)url byReference: (BOOL)byRef;

/**
 * Pulls the data from the pasteboard and initializes NSMovie.
 */
- (id) initWithPasteboard: (NSPasteboard *)pasteboard;

/**
 * Return QTMovie
 */ 
- (void *) QTMovie;

/**
 * The URL used to initialize NSMovie
 */
- (NSURL *) URL;

@end

#endif /* _GNUstep_H_NSMovie */
