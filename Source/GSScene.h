/* Interface of class GSScene
   Copyright (C) 2024 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: 12-05-2024

   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#ifndef _GSScene_h_GNUSTEP_GUI_INCLUDE
#define _GSScene_h_GNUSTEP_GUI_INCLUDE

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSArray;
@class NSString;

@interface GSScene : NSObject <NSCoding, NSCopying>
{
  NSString *_sceneID;
  NSArray *_objects;
  NSPoint _canvasLocation;
}

- (NSString *) sceneID;
- (void) setSceneID: (NSString *)sceneID;

- (NSArray *) objects;
- (void) setObjects: (NSArray *)objects;

- (NSPoint) canvasLocation;
- (void) setCanvasLocation: (NSPoint)point;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* _GSScene_h_GNUSTEP_GUI_INCLUDE */
