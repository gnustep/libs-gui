/* 
   GSVideoSink.h

   Sink video data.

   Copyright (C) 2022 Free Software Foundation, Inc.

   Written by: Gregory John Casamento <greg.casamento@gmail.com>
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

#ifndef _GNUstep_H_GSVideoSink
#define _GNUstep_H_GSVideoSink

#import <Foundation/NSByteOrder.h>
#import <Foundation/NSObject.h>

@protocol GSVideoSink <NSObject>

/** 
 * Opens the device for output, called by [NSMovie-play].
 */
- (BOOL) open;

/** Closes the device, called by [NSMovie-stop].
 */
- (void) close;

/** 
 * Plays the data in bytes
 */
- (BOOL) playBytes: (void *)bytes length: (NSUInteger)length;

/** Called by [NSMovieView -setVolume:], and corresponds to it.  Parameter volume
 *  is between the values 0.0 and 1.0.
 */
- (void) setVolume: (float)volume;

/** Called by [NSMovieView -volume].
 */
- (CGFloat) volume;

@end

#endif // _GNUstep_H_GSVideoSink

