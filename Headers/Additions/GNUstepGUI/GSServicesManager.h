/* 
   GSServicesManager.h

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: Novemeber 1998
  
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

#ifndef _GNUstep_H_GSServicesManager
#define _GNUstep_H_GSServicesManager

#include <Foundation/NSObject.h>

@class	NSApplication;
@class	NSArray;
@class	NSDate;
@class	NSMenu;
@class	NSMenuItem;
@class	NSMutableArray;
@class	NSMutableDictionary;
@class	NSMutableSet;
@class	NSString;
@class	NSTimer;

@interface      GSServicesManager : NSObject
{
  NSApplication         *_application;
  NSMenu                *_servicesMenu;
  NSMutableArray        *_languages;
  NSMutableSet          *_returnInfo;
  NSMutableDictionary   *_combinations;
  NSMutableDictionary   *_title2info;
  NSArray               *_menuTitles;
  NSString		*_disabledPath;
  NSString		*_servicesPath;
  NSDate		*_disabledStamp;
  NSDate		*_servicesStamp;
  NSMutableSet		*_allDisabled;
  NSMutableDictionary	*_allServices;
  NSTimer		*_timer;
}
+ (GSServicesManager*) newWithApplication: (NSApplication*)app;
+ (GSServicesManager*) manager;
- (BOOL) application: (NSApplication*)theApp
	    openFile: (NSString*)file;
- (BOOL) application: (NSApplication*)theApp
   openFileWithoutUI: (NSString*)file;
- (BOOL) application: (NSApplication*)theApp
	openTempFile: (NSString*)file;
- (BOOL) application: (NSApplication*)theApp
	   printFile: (NSString*)file;
- (void) doService: (NSMenuItem*)item;
- (NSArray*) filters;
- (BOOL) hasRegisteredTypes: (NSDictionary*)service;
- (NSString*) item2title: (NSMenuItem*)item;
- (void) loadServices;
- (NSDictionary*) menuServices;
- (void) rebuildServices;
- (void) rebuildServicesMenu;
- (void) registerAsServiceProvider;
- (void) registerSendTypes: (NSArray *)sendTypes
               returnTypes: (NSArray *)returnTypes;
- (NSMenu *) servicesMenu;
- (id) servicesProvider;
- (void) setServicesMenu: (NSMenu *)anObject;
- (void) setServicesProvider: (id)anObject;
- (int) setShowsServicesMenuItem: (NSString*)item to: (BOOL)enable;
- (BOOL) showsServicesMenuItem: (NSString*)item;
- (BOOL) validateMenuItem: (NSMenuItem*)item;
- (void) updateServicesMenu;
@end

#endif

