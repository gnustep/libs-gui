/* 
 NSViewController.m
 
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

#import "AppKit/NSViewController.h"


@implementation NSViewController

- (void) dealloc
{
  DESTROY(_nibName);
  DESTROY(_nibBundle);
  DESTROY(_representedObject);
  DESTROY(_title);
  DESTROY(_topLevelObjects);
  DESTROY(_editors);
  DESTROY(_autounbinder);
  DESTROY(_designNibBundleIdentifier);
  
  [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil
{
  [super init];
  
  ASSIGN(_nibName, nibNameOrNil);
  ASSIGN(_nibBundle, nibBundleOrNil);
  
  return self;
}

- (void)setRepresentedObject:(id)representedObject
{
  ASSIGN(_representedObject, representedObject);
}

- (id)representedObject
{
  return _representedObject;
}

- (void)setTitle:(NSString *)title
{
  ASSIGN(_title, title);
}

- (NSString *)title
{
  return _title;
}

- (NSView *)view
{
  return view;
}

- (void)setView:(NSView *)aView
{
  view = aView;
}

- (NSString *)nibName
{
  return _nibName;
}

- (NSBundle *)nibBundle
{
  return _nibBundle;
}


- (void)commitEditingWithDelegate:(id)delegate 
                didCommitSelector:(SEL)didCommitSelector 
                      contextInfo:(void *)contextInfo
{
  [self notImplemented: _cmd];
}

- (BOOL)commitEditing
{
  [self notImplemented: _cmd];

  return NO;
}

- (void)discardEditing
{
  [self notImplemented: _cmd];
}


@end
