/* Definition of class NSStoryboard
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory Casamento
   Date: Mon Jan 20 15:57:37 EST 2020

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#ifndef _NSStoryboard_h_GNUSTEP_GUI_INCLUDE
#define _NSStoryboard_h_GNUSTEP_GUI_INCLUDE

#import <Foundation/NSObject.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSString, NSBundle, NSMutableDictionary;
  
typedef NSString *NSStoryboardName;
typedef NSString *NSStoryboardSceneIdentifier;

DEFINE_BLOCK_TYPE(NSStoryboardControllerCreator, NSCoder*, id);

@interface NSStoryboard : NSObject
{
  NSMutableDictionary *_scenesMap;
  NSString *_initialViewControllerId;
  NSString *_applicationSceneId;
}
  
+ (NSStoryboard *) mainStoryboard; // 10.13
  
+ (instancetype) storyboardWithName: (NSStoryboardName)name
                             bundle: (NSBundle *)bundle;

- (id) instantiateInitialController;

- (id) instantiateInitialControllerWithCreator: (NSStoryboardControllerCreator)block; // 10.15

- (id) instantiateControllerWithIdentifier: (NSStoryboardSceneIdentifier)identifier;

- (id) instantiateControllerWithIdentifier: (NSStoryboardSceneIdentifier)identifier
                                   creator: (NSStoryboardControllerCreator)block;  // 10.15
@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSStoryboard_h_GNUSTEP_GUI_INCLUDE */

