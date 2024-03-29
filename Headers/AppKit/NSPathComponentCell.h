/* Definition of class NSPathComponentCell
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Wed Apr 22 18:19:21 EDT 2020

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

#ifndef _NSPathComponentCell_h_GNUSTEP_GUI_INCLUDE
#define _NSPathComponentCell_h_GNUSTEP_GUI_INCLUDE

#import <AppKit/NSTextFieldCell.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSImage, NSURL;
  
APPKIT_EXPORT_CLASS
@interface NSPathComponentCell : NSTextFieldCell
{
  NSImage *_image;
  NSURL *_url;
  BOOL _lastComponent;
}

- (NSImage *) image;
- (void) setImage: (NSImage *)image;

- (NSURL *) URL;
- (void) setURL: (NSURL *)url;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSPathComponentCell_h_GNUSTEP_GUI_INCLUDE */

