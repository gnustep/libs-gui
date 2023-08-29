/* 
   NSViewPrivate.h

   The private methods of the NSView classes

   Copyright (C) 2010 Free Software Foundation, Inc.
   
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

#ifndef _GNUstep_H_NSViewPrivate
#define _GNUstep_H_NSViewPrivate

#import "AppKit/NSView.h"
#import "GSAutoLayoutEngine.h"

@interface NSView (KeyViewLoop)
- (void) _setUpKeyViewLoopWithNextKeyView: (NSView *)nextKeyView;
- (void) _recursiveSetUpKeyViewLoopWithNextKeyView: (NSView *)nextKeyView;
@end

@interface NSView (__NSViewPrivateMethods__)
- (void) _insertSubview: (NSView *)sv atIndex: (NSUInteger)idx;
@end

@interface NSView (NSConstraintBasedLayoutCorePrivateMethods)

- (void) _setNeedsUpdateConstraints: (BOOL)needsUpdateConstraints;

- (void) _layoutViewAndSubViews;

- (GSAutoLayoutEngine*) _layoutEngine;

- (void) _layoutEngineDidChangeAlignmentRect;

@end

#endif // _GNUstep_H_NSViewPrivate
