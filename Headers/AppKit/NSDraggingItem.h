/* -*-objc-*-
   NSDraggingItem.h

   Copyright (C) 2026 Free Software Foundation, Inc.

   Author: Todd White <todd.white@thalion.global>
   Date: July 2026

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

#ifndef _GNUstep_H_NSDraggingItem
#define _GNUstep_H_NSDraggingItem
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_7, GS_API_LATEST)

#if defined(__cplusplus)
extern "C" {
#endif

@class NSString;

typedef NSString * NSDraggingImageComponentKey;

/* Keys identifying the standard drag image components. */
APPKIT_EXPORT NSDraggingImageComponentKey const NSDraggingImageComponentIconKey;
APPKIT_EXPORT NSDraggingImageComponentKey const NSDraggingImageComponentLabelKey;

APPKIT_EXPORT_CLASS
@interface NSDraggingImageComponent : NSObject
{
  NSDraggingImageComponentKey _key;
  id _contents;
  NSRect _frame;
}

+ (instancetype) draggingImageComponentWithKey: (NSDraggingImageComponentKey)key;

- (instancetype) initWithKey: (NSDraggingImageComponentKey)key;

- (NSDraggingImageComponentKey) key;
- (void) setKey: (NSDraggingImageComponentKey)key;

- (id) contents;
- (void) setContents: (id)contents;

- (NSRect) frame;
- (void) setFrame: (NSRect)frame;

@end

#if defined(__cplusplus)
}
#endif

#endif /* MAC_OS_X_VERSION_10_7 */

#endif /* _GNUstep_H_NSDraggingItem */
