/* 
   GSNibTemplates.h

   Copyright (C) 1997, 1999 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2002
   
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

#ifndef _GNUstep_H_GSNibTemplates
#define _GNUstep_H_GSNibTemplates

#include <Foundation/NSObject.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSView.h>
#include <AppKit/NSText.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSButton.h>

#define GNUSTEP_NIB_VERSION 0

@class	NSString;
@class	NSDictionary;
@class	NSMutableDictionary;

/*
 * This is the class that holds objects within a nib.
 */
@interface GSNibContainer : NSObject <NSCoding>
{
  NSMutableDictionary	*nameTable;
  NSMutableArray	*connections;
  BOOL			_isAwake;
}
- (void) awakeWithContext: (NSDictionary*)context;
- (NSMutableDictionary*) nameTable;
- (NSMutableArray*) connections;
@end

/*
 * Template classes
 */

@interface GSNibItem : NSObject <NSCoding> 
{
  NSString		*theClass;
  NSRect		theFrame;
  unsigned int          autoresizingMask;
}
@end

@interface GSCustomView : GSNibItem <NSCoding>  
{
}
@end

// templates
@protocol GSTemplate
- (void) setClassName: (NSString *)className;
- (NSString *)className;
- (id) instantiateObject: (NSCoder *)coder;
@end

@interface NSWindowTemplate : NSWindow <GSTemplate>
{
  NSString            *_className;
  NSString            *_parentClassName;
  BOOL                 _deferFlag;
}
@end

@interface NSViewTemplate : NSView <GSTemplate>
{
  NSString            *_className;
  NSString            *_parentClassName;
}
@end

@interface NSTextTemplate : NSText <GSTemplate>
{
  NSString            *_className;
  NSString            *_parentClassName;
}
@end

@interface NSTextViewTemplate : NSTextView <GSTemplate> 
{
  NSString            *_className;
  NSString            *_parentClassName;
}
@end

@interface NSMenuTemplate : NSMenu <GSTemplate>
{
  NSString            *_className;
  NSString            *_parentClassName;
}
@end

@interface NSControlTemplate : NSControl <GSTemplate>
{
  NSString            *_className;
  NSString            *_parentClassName;
  id                   _delegate;
  id                   _dataSource;
  BOOL                 _usesDataSource;
}
@end

@interface NSButtonTemplate : NSButton <GSTemplate>
{
  NSString            *_className;
  NSString            *_parentClassName;
  NSButtonType         _buttonType;
}
@end

@interface GSClassSwapper : NSObject 
{
  NSString            *_className;
  id                   _template;
}
- (NSString *) className;
- (void) setClassName: (NSString *)name;
- (id) template;
- (void) setTemplate: (id)template;
@end

#endif /* _GNUstep_H_GSNibTemplates */
