/* 
   GSFlow.h

   GSFlow class to layout views line by line dynamically (from left 
   to right and top to bottom)

   Copyright (C) 2007 Free Software Foundation, Inc.

   Author:  Quentin Mathe <qmathe@club-internet.fr>
   Date:  January 2007

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface GSFlow : NSObject
{
  IBOutlet NSView *_viewContainer;
  NSMutableArray *_layoutedViews;
  NSMutableDictionary *_layoutedViewIdentifiers;
}

- (id) initWithViews: (NSArray *)views viewContainer: (NSView *)viewContainer;

- (void) setViewContainer: (NSView *)viewContainer;
- (NSView *) viewContainer;

- (void) layout;

- (void) addView: (NSView *)view;
- (void) removeView: (NSView *)view;
- (void) removeViewAtIndex: (int)index;
- (NSView *) viewAtIndex: (int)index;

- (void) addView: (NSView *)view withIdentifier: (NSString *)identifier;
- (void) removeViewForIdentifier:(NSString *)identifier;
- (NSView *) viewForIdentifier: (NSString *)identifier;

@end
