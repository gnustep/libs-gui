/* 
   NSHelpPanel.m

   Description...

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <AppKit/NSHelpPanel.h>

@implementation NSHelpPanel

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSHelpPanel class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Accessing the Help Panel
//
+ (NSHelpPanel *)sharedHelpPanel
{
  return nil;
}

+ (NSHelpPanel *)sharedHelpPanelWithDirectory:(NSString *)helpDirectory
{
  return nil;
}

//
// Managing the Contents
//
+ (void)setHelpDirectory:(NSString *)helpDirectory
{}

//
// Attaching Help to Objects 
//
+ (void)attachHelpFile:(NSString *)filename
	    markerName:(NSString *)markerName
to:(id)anObject
{}

+ (void)detachHelpFrom:(id)anObject
{}

//
// Instance methods
//
//
// Managing the Contents
//
- (void)addSupplement:(NSString *)helpDirectory
	       inPath:(NSString *)supplementPath
{}

- (NSString *)helpDirectory
{
  return nil;
}

- (NSString *)helpFile
{
  return nil;
}

//
// Showing Help 
//
- (void)showFile:(NSString *)filename
	atMarker:(NSString *)markerName
{}

- (BOOL)showHelpAttachedTo:(id)anObject
{
  return NO;
}

//
// Printing 
//
- (void)print:(id)sender
{}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  return self;
}

@end
