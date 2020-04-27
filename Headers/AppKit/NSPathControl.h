/* Definition of class NSPathControl
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Wed Apr 22 18:19:40 EDT 2020

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

#ifndef _NSPathControl_h_GNUSTEP_GUI_INCLUDE
#define _NSPathControl_h_GNUSTEP_GUI_INCLUDE

#import <AppKit/NSControl.h>
#import <AppKit/NSDragging.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

enum {
  NSPathStyleStandard,
  NSPathStyleNavigationBar,  // deprecated
  NSPathStylePopUp
};
typedef NSUInteger NSPathStyle;

@protocol NSPathControlDelegate;

@class NSColor, NSPathComponentCell, NSArray, NSURL, NSAttributedString, NSString,
  NSMenu, NSPasteboard, NSOpenPanel, NSPathControlItem;
  
@interface NSPathControl : NSControl
{
  NSPathStyle _pathStyle;
  NSColor *_backgroundColor;
  NSArray *_pathItems;
  NSString *_placeholderString;
  NSAttributedString *_placeholderAttributedString;
  NSArray *_allowedTypes;
  id<NSPathControlDelegate> _delegate;
  NSURL *_url;
  SEL _doubleAction;
  NSArray *_pathComponentCells;
}

- (void) setPathStyle: (NSPathStyle)style;
- (NSPathStyle) pathStyle;

- (NSPathComponentCell *) clickedPathComponentCell;
- (NSArray *) pathComponentCells;
- (void) setPathComponentCells: (NSArray *)cells;

- (SEL) doubleAction;
- (void) setDoubleAction: (SEL)doubleAction;

- (NSURL *) URL;
- (void) setURL: (NSURL *)url;

- (id<NSPathControlDelegate>) delegate;
- (void) setDelegate: (id<NSPathControlDelegate>) delegate;

- (void) setDraggingSourceOperationMask: (NSDragOperation)mask 
                               forLocal: (BOOL)local;

- (NSMenu *) menu;
- (void) setMenu: (NSMenu *)menu;

- (NSArray *) allowedTypes;
- (void) setAllowedTypes: (NSArray *)allowedTypes;

- (NSPathControlItem *) clickedPathItem;

- (NSArray *) pathItems;
- (void) setPathItems: (NSArray *)items;

- (NSAttributedString *) placeholderAttributedString;
- (void) setPlaceholderAttributedString: (NSAttributedString *)string;

- (NSString *) placeholderString;
- (void) setPlaceholderString: (NSString *)string;
 
@end

@protocol NSPathControlDelegate

- (BOOL)pathControl:(NSPathControl *)pathControl 
  shouldDragPathComponentCell:(NSPathComponentCell *)pathComponentCell 
               withPasteboard:(NSPasteboard *)pasteboard;

- (NSDragOperation)pathControl:(NSPathControl *)pathControl 
                  validateDrop:(id<NSDraggingInfo>)info;

- (BOOL)pathControl:(NSPathControl *)pathControl 
         acceptDrop:(id<NSDraggingInfo>)info;

- (void)pathControl:(NSPathControl *)pathControl 
  willDisplayOpenPanel:(NSOpenPanel *)openPanel;

- (void)pathControl:(NSPathControl *)pathControl 
      willPopUpMenu:(NSMenu *)menu;

- (BOOL)pathControl:(NSPathControl *)pathControl 
     shouldDragItem:(NSPathControlItem *)pathItem 
     withPasteboard:(NSPasteboard *)pasteboard;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSPathControl_h_GNUSTEP_GUI_INCLUDE */

