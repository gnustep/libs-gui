/* GPSDrawContext - Generic drawing DrawContext class.

   Copyright (C) 1998 Free Software Foundation, Inc.

   Written by:  Adam Fedor <fedor@gnu.org>
   Date: Nov 1998
   
   This file is part of the GNU Objective C User interface library.

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
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   */

#ifndef _GPSDrawContext_h_INCLUDE
#define _GPSDrawContext_h_INCLUDE

#include <Foundation/NSObject.h>
#include <AppKit/GPSOperators.h>
#include <AppKit/GPSDefinitions.h>

@class NSMutableData;
@class NSDictionary;

@interface GPSDrawContext : NSObject
{
  NSDictionary  *context_info;
  NSMutableData *context_data;
}

+ (void) setDefaultContextClass: (Class)defaultContextClass;
+ defaultContextWithInfo: (NSDictionary *)info;
+ streamContextWithPath: (NSString *)path;

- initWithContextInfo: (NSDictionary *)info;

- (BOOL) isDrawingToScreen;

- (NSMutableData *) mutableData;

+ (GPSDrawContext *) currentContext;
+ (void)setCurrentContext: (GPSDrawContext *)context;

- (void) destroyContext;

@end

#include "GPSDrawContextOps.h"

extern GPSDrawContext *_currentGPSContext;

/* If NO_GNUSTEP defined, leave out GPSDrawContext definition. This
   requires the xdps backend to be used. */
#ifdef NO_GNUSTEP
#define GPSDrawContext NSDPSContext
#endif

/* Current keys used for the info dictionary:
       Key:           Value:
     DisplayName  -- (NSString)name of X server
     ScreenNumber -- (NSNumber)screen number
     ContextData  -- (NSData)context data
     DebugContext -- (NSNumber)YES or NO
*/

extern NSString *DPSconfigurationerror;
extern NSString *DPSinvalidaccess;
extern NSString *DPSinvalidcontext;
extern NSString *DPSinvalidexit;
extern NSString *DPSinvalidfileaccess;
extern NSString *DPSinvalidfont;
extern NSString *DPSinvalidid;
extern NSString *DPSinvalidrestore;
extern NSString *DPSinvalidparam;
extern NSString *DPSioerror;
extern NSString *DPSlimitcheck;
extern NSString *DPSnocurrentpoint;
extern NSString *DPSnulloutput;
extern NSString *DPSrangecheck;
extern NSString *DPSstackoverflow;
extern NSString *DPSstackunderflow;
extern NSString *DPStypecheck;
extern NSString *DPSundefined;
extern NSString *DPSundefinedfilename;
extern NSString *DPSundefinedresource;
extern NSString *DPSundefinedresult;
extern NSString *DPSunmatchedmark;
extern NSString *DPSunregistered;
extern NSString *DPSVMerror;

#endif /* _GPSDrawContext_h_INCLUDE */
