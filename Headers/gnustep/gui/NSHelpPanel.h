/* 
   NSHelpPanel.h

   Standard panel for showing help information

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

#ifndef	STRICT_MACOS_X

#ifndef _GNUstep_H_NSHelpPanel
#define _GNUstep_H_NSHelpPanel

#include <AppKit/NSPanel.h>

@class NSString;

@interface NSHelpPanel : NSPanel <NSCoding>
{
  // Attributes
}

//
// Accessing the Help Panel
//
+ (NSHelpPanel *)sharedHelpPanel;
+ (NSHelpPanel *)sharedHelpPanelWithDirectory:(NSString *)helpDirectory;

//
// Managing the Contents
//
+ (void)setHelpDirectory:(NSString *)helpDirectory;
- (void)addSupplement:(NSString *)helpDirectory
	       inPath:(NSString *)supplementPath;
- (NSString *)helpDirectory;
- (NSString *)helpFile;

//
// Attaching Help to Objects 
//
+ (void)attachHelpFile:(NSString *)filename
	    markerName:(NSString *)markerName
		    to:(id)anObject;
+ (void)detachHelpFrom:(id)anObject;

//
// Showing Help 
//
- (void)showFile:(NSString *)filename
	atMarker:(NSString *)markerName;
- (BOOL)showHelpAttachedTo:(id)anObject;

//
// Printing 
//
- (void)print:(id)sender;

//
// NSCoding protocol
//
- (void)encodeWithCoder: (NSCoder *)aCoder;
- initWithCoder: (NSCoder *)aDecoder;

@end

#endif // _GNUstep_H_NSHelpPanel
#endif // STRICT_MACOS_X

