/* 
   NSTrackingArea.h

   Create a rectangle to track mouse movements.

   Copyright (C) 2013 Free Software Foundation, Inc.

   Written by: Gregory Casamento <greg.casamento@gmail.com>
   Date: September 2013
   
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

#ifndef _GNUstep_H_NSTrackingArea
#define _GNUstep_H_NSTrackingArea
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSCoder.h>

/*
 * Options pulled from Cocoa documentation.
 */ 
enum {
    NSTrackingMouseEnteredAndExited = 0x01,
    NSTrackingMouseMoved = 0x02,
    NSTrackingCursorUpdate = 0x04,
    NSTrackingActiveWhenFirstResponder = 0x10,
    NSTrackingActiveInKeyWindow = 0x20,
    NSTrackingActiveInActiveApp = 0x40,
    NSTrackingActiveAlways = 0x80,
    NSTrackingAssumeInside = 0x100,
    NSTrackingInVisibleRect = 0x200,
    NSTrackingEnabledDuringMouseDrag = 0x400
};
typedef NSUInteger NSTrackingAreaOptions;

@class NSDictionary;
@class GSTrackingRect;

APPKIT_EXPORT_CLASS
@interface NSTrackingArea : NSObject <NSCoding, NSCopying>
{
    NSDictionary *_userInfo;
    GSTrackingRect *_trackingRect;
    NSTrackingAreaOptions _options;
}

- (id)initWithRect: (NSRect)rect
           options: (NSTrackingAreaOptions)options
             owner: (id)owner
          userInfo: (NSDictionary *)userInfo;

- (NSTrackingAreaOptions) options;
- (id) owner;
- (NSRect) rect;
- (NSDictionary *) userInfo;

@end

#endif // _GNUstep_H_NSTrackingArea

