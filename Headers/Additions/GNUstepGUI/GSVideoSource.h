/* 
   GSVideoSource.h

   Load and read video data.

   Copyright (C) 2022 Free Software Foundation, Inc.

   Written by:  Gregory John Casamento <greg.casamento@gmail.com>
   Date: Mar 2022
   
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

#ifndef _GNUstep_H_GSVideoSource
#define _GNUstep_H_GSVideoSource

#import <Foundation/NSByteOrder.h>
#import <Foundation/NSObject.h>

@class NSArray;

@protocol GSVideoSource <NSObject>

/** Returns an array of the file types supported by the class.
 */
+ (NSArray *)videoUnfilteredFileTypes;

/** Returns an array of UTIs identifying the file types the class understands.
 */
+ (NSArray *)videoUnfilteredTypes;

/** Returns YES if the class can understand data and NO otherwise.
 */
+ (BOOL)canInitWithData: (NSData *)data;

/** <init />
 *  Initilizes the reciever for output.
 */
- (id)initWithData: (NSData *)data;

/** Reads data provided in -initWithData:.  Parameter bytes must be big enough
 *  to hold length bytes.
 */
- (NSUInteger)readBytes: (void *)bytes length: (NSUInteger)length;

/** Returns the duration, in seconds.  Equivalent to [NSMovieView-duration].
 */
- (NSTimeInterval)duration;

/** Called by [NSSound-setCurrentTime:].
 */
- (void)setCurrentTime: (NSTimeInterval)currentTime;

/** Called by [NSSound-currentTime].
 */
- (NSTimeInterval)currentTime;

@end

#endif // _GNUstep_H_GSVideoSource
