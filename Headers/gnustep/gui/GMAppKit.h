/*
   GMAppKit.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: November 1997
   
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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#ifndef _GNUstep_H_GMAppKit
#define _GNUstep_H_GMAppKit

#include <AppKit/AppKit.h>
#include <gnustep/gui/GMArchiver.h>

@interface NSApplication (GMArchiverMethods) <ModelCoding>
@end

@interface NSBox (GMArchiverMethods) <ModelCoding>
@end

@interface NSButton (GMArchiverMethods) <ModelCoding>
@end

@interface NSCell (GMArchiverMethods) <ModelCoding>
@end

@interface NSClipView (GMArchiverMethods) <ModelCoding>
@end

@interface NSColor (GMArchiverMethods) <ModelCoding>
@end

@interface NSControl (GMArchiverMethods) <ModelCoding>
@end

@interface NSFont (GMArchiverMethods) <ModelCoding>
@end

@interface NSImage (GMArchiverMethods) <ModelCoding>
@end

@interface NSMenuItem (GMArchiverMethods) <ModelCoding>
@end

@interface NSMenu (GMArchiverMethods) <ModelCoding>
@end

@interface NSPopUpButton (GMArchiverMethods) <ModelCoding>
@end

@interface NSResponder (GMArchiverMethods) <ModelCoding>
@end

@interface NSTextField (GMArchiverMethods) <ModelCoding>
@end

@interface NSSecureTextFieldCell (GMArchiverMethods) <ModelCoding>
@end

@interface NSView (GMArchiverMethods) <ModelCoding>
@end

@interface NSWindow (GMArchiverMethods) <ModelCoding>
@end

@interface NSPanel (GMArchiverMethods) <ModelCoding>
@end

@interface NSSavePanel (GMArchiverMethods) <ModelCoding>
@end

@interface NSBrowser (GMArchiverMethods) <ModelCoding>
@end

@interface NSText (GMArchiverMethods) <ModelCoding>
@end

@interface NSTextView (GMArchiverMethods) <ModelCoding>
@end

#endif /* _GNUstep_H_GMAppKit */
