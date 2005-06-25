/* 
   GSNibCompatibility.h

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
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/ 

#ifndef _GNUstep_H_GSNibCompatibility
#define _GNUstep_H_GSNibCompatibility

#include <Foundation/NSObject.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSView.h>
#include <AppKit/NSText.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSButton.h>
#include <GNUstepGUI/GSNibTemplates.h>

/*
  These classes are present for nib-level compatibility with Mac OS X.
*/

@protocol GSOSXTemplate
- (id) initWithObject: (id)object className: (NSString *)className;
- (NSString *)className;
- (void)setClassName: (NSString *)className;
@end

@interface NSWindowTemplate : NSObject <GSOSXTemplate> 
{
  NSString            *_className;
  BOOL                 _deferFlag;
  id                   _realObject;
}
- (BOOL) deferFlag;
- (void) setDeferFlag: (BOOL)flag;
@end

@interface NSViewTemplate : NSView <GSOSXTemplate> 
{
  NSString            *_className;
  id                   _realObject;
}
@end

@interface NSTextTemplate : NSViewTemplate
@end

@interface NSTextViewTemplate : NSViewTemplate 
@end

@interface NSMenuTemplate : NSObject <GSOSXTemplate> 
{
  NSString            *_className;
  id                   _realObject;
}
@end
#endif /* _GNUstep_H_GSNibCompatibility */
