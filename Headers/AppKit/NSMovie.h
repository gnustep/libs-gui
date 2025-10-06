/**
   <title>NSMovie</title>

   <abstract>Encapsulate a movie</abstract>

   Copyright <copy>(C) 2003 Free Software Foundation, Inc.</copy>

   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: May 2025
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: March 2003

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
#import <Foundation/NSObject.h>
#import "AppKit/AppKitDefines.h"

/**
 * NSMovie
 *
 * Encapsulates a QuickTime movie object, providing methods to initialize and
 * retrieve movie data from various sources, such as NSData, NSURL, or NSPasteboard.
 *
 * Instance Variables:
 *   _movie:
 *     The raw NSData representing the contents of the QuickTime movie.
 *
 *   _url:
 *     The URL from which the movie was loaded. May be nil if not URL-based.
 *
 *   _tmp:
 *     A boolean indicating whether the movie data is temporary (not persisted).
 */

@class NSArray;
@class NSData;
@class NSURL;
@class NSPasteboard;

APPKIT_EXPORT_CLASS
@interface NSMovie : NSObject <NSCopying, NSCoding> 
{
  @private
    NSData*   _movie;
    NSURL*    _url;
    BOOL      _tmp;
}

/**
 * An array of all of the types NSMovie can support.
 */
+ (NSArray*) movieUnfilteredFileTypes;

/**
 * An array of all of the pasteboard types NSMovie can support.
 */
+ (NSArray*) movieUnfilteredPasteboardTypes;

/**
 * Returns YES, if the object can be initialized with the given pasteboard.
 */
+ (BOOL) canInitWithPasteboard: (NSPasteboard*)pasteboard;

/**
 * Returns an NSMovie with the raw data pointed to by movie.
 */
- (instancetype) initWithMovie: (void*)movie;

/**
 * Returns an NSMovie with the given URL. byRef should be YES if it is by reference.
 */
- (instancetype) initWithURL: (NSURL*)url byReference: (BOOL)byRef;

/**
 * Returns an NSMovie initialized with the pasteboard passed in.
 */
- (instancetype) initWithPasteboard: (NSPasteboard*)pasteboard;

/**
 * Returns the raw data for the movie.
 */
- (void*) QTMovie;

/**
 * Returns the URL of the movie to be played.
 */
- (NSURL*) URL;

@end

#endif /* _GNUstep_H_NSMovie */
