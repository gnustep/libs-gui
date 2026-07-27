/* Implementation of class NSDraggingImageComponent

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

#import "config.h"
#import <Foundation/NSString.h>
#import "AppKit/NSDraggingItem.h"

@implementation NSDraggingImageComponent

+ (instancetype) draggingImageComponentWithKey: (NSDraggingImageComponentKey)key
{
  return AUTORELEASE([[self alloc] initWithKey: key]);
}

- (instancetype) initWithKey: (NSDraggingImageComponentKey)key
{
  self = [super init];
  if (self != nil)
    {
      ASSIGNCOPY(_key, key);
    }
  return self;
}

- (void) dealloc
{
  DESTROY(_key);
  DESTROY(_contents);
  [super dealloc];
}

- (NSDraggingImageComponentKey) key
{
  return _key;
}

- (void) setKey: (NSDraggingImageComponentKey)key
{
  ASSIGNCOPY(_key, key);
}

- (id) contents
{
  return _contents;
}

- (void) setContents: (id)contents
{
  ASSIGN(_contents, contents);
}

- (NSRect) frame
{
  return _frame;
}

- (void) setFrame: (NSRect)frame
{
  _frame = frame;
}

@end
