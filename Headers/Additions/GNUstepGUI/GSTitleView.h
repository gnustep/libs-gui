/** <title>GSTitleView</title>

   Copyright (C) 2003 Free Software Foundation, Inc.

   Author: Serg Stoyan <stoyan@on.com.ua>
   Date: Mar 2003
   
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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

@class NSDictionary;
@class NSButton;
@class NSImage;

@interface GSTitleView : NSView
{
  NSButton            *closeButton;
  NSButton            *miniaturizeButton;
  NSMutableDictionary *textAttributes;
  NSColor             *titleColor;

  @private
    id         _owner;
    unsigned   _ownedByMenu;
    unsigned   _hasCloseButton;
    unsigned   _hasMiniaturizeButton;
}
+ (float) height;
- (NSSize) titleSize;

// Buttons
- (NSButton *) _createButtonWithImage: (NSImage *)image
                       highlightImage: (NSImage *)imageH
                               action: (SEL)action;
- (void) addCloseButtonWithAction: (SEL)closeAction;
- (void) removeCloseButton;
- (void) addMiniaturizeButtonWithAction: (SEL)miniaturizeAction;
- (void) removeMiniaturizeButton;

- (void) setOwner: (id)owner;
- (id) owner;

@end

