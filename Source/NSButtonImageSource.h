/* 
   NSButtonImageSource.h

   Copyright (C) 2006 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <rfm@gnu.org>
   Date: 2006
   
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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.
*/ 

#ifndef _GNUstep_H_NSImageSource
#define _GNUstep_H_NSImageSource

#include <Foundation/NSObject.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSButton.h>
#include <GNUstepGUI/GSTheme.h>

/**
 * Handle images for button cell theming.
 */
@interface NSButtonImageSource : NSObject <NSCoding, NSCopying>
{
  NSString		*imageName;
  NSMutableDictionary	*images;
}
+ (BOOL) archiveButtonImageSourceWithName: (NSString*)name
			      toDirectory: (NSString*)path;
+ (id) buttonImageSourceWithName: (NSString*)name;
- (id) copyWithZone: (NSZone*)zone;
- (void) dealloc;
- (void) encodeWithCode: (NSCoder*)aCoder;
- (id) imageForState: (struct NSButtonState)state;
- (id) initWithCoder: (NSCoder*)aCoder;
@end

@interface	NSButtonCell (NSButtonImageSource)
- (id) _buttonImageSource;
- (void) _setButtonImageSource: (id)source;
@end

#endif /* _GNUstep_H_NSImageSource */
