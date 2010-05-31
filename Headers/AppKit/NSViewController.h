/* 
 NSViewController.h

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

#ifndef _GNUstep_H_NSViewController
#define _GNUstep_H_NSViewController

#import <AppKit/NSNibDeclarations.h>
#import <AppKit/NSResponder.h>

@class NSArray, NSBundle, NSPointerArray, NSView;


@interface NSViewController : NSResponder
{
@private
  NSString            *_nibName;
  NSBundle            *_nibBundle;
  id                   _representedObject;
  NSString            *_title;
  IBOutlet NSView     *view;
  NSArray             *_topLevelObjects;
  NSPointerArray      *_editors;
  id                   _autounbinder;
  NSString            *_designNibBundleIdentifier;
  id                   _reserved[2];
}


- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil;

- (void)setRepresentedObject:(id)representedObject;

- (id)representedObject;

- (void)setTitle:(NSString *)title;
- (NSString *)title;

- (NSView *)view;

- (NSString *)nibName;
- (NSBundle *)nibBundle;

- (void)setView:(NSView *)aView;

- (void)commitEditingWithDelegate:(id)delegate 
                didCommitSelector:(SEL)didCommitSelector 
                      contextInfo:(void *)contextInfo;

- (BOOL)commitEditing;
- (void)discardEditing;

@end

#endif /* _GNUstep_H_NSViewController */
