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

// versions of the nib container and the templates.
#define GNUSTEP_NIB_VERSION 0
#define GSSWAPPER_VERSION   0
#define GSWINDOWT_VERSION   0
#define GSVIEWT_VERSION     0
#define GSCONTROLT_VERSION  0
#define GSTEXTT_VERSION     0
#define GSTEXTVIEWT_VERSION 0
#define GSMENUT_VERSION     0
#define GSOBJECTT_VERSION   0

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
@protocol GSTemplate
- (id) initWithObject: (id)object className: (NSString *)className superClassName: (NSString *)superClassName;
- (void) setClassName: (NSString *)className;
- (NSString *)className;
@end

@interface GSClassSwapper : NSObject <GSTemplate, NSCoding>
{
  id                   _object;
  NSString            *_className;
  Class                _superClass;
}
@end

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

@interface GSWindowTemplate : GSClassSwapper
{
  BOOL                 _deferFlag;
}
@end

@interface GSViewTemplate : GSClassSwapper
@end

@interface GSTextTemplate : GSClassSwapper
@end

@interface GSTextViewTemplate : GSClassSwapper 
@end

@interface GSMenuTemplate : GSClassSwapper
@end

@interface GSControlTemplate : GSClassSwapper
@end

@interface GSObjectTemplate : GSClassSwapper
@end

@interface GSTemplateFactory : NSObject
+ (id) templateForObject: (id) object 
	   withClassName: (NSString *)className
      withSuperClassName: (NSString *)superClassName;
@end

/*
  These templates are from the old system, which had some issues.  Currently I believe
  that NSWindowTemplate was the only one seeing use, so it is the only one included.
  if any more are needed they will be added back.   
  
  As these classes are deprecated, they should disappear from the gnustep distribution
  in the next major release.
*/

// DO NOT USE.

@protocol __DeprecatedTemplate__
- (void) setClassName: (NSString *)className;
- (NSString *)className;
- (id) instantiateObject: (NSCoder *)coder;
@end

@interface NSWindowTemplate : NSWindow <__DeprecatedTemplate__>
{
  NSString            *_className;
  NSString            *_parentClassName;
  BOOL                 _deferFlag;
}
@end

#endif /* _GNUstep_H_GSNibTemplates */
