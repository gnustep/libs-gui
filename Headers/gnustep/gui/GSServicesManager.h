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

@class	NSApplication;
@class	NSArray;
@class	NSCell;
@class	NSDate;
@class	NSMenu;
@class	NSMutableArray;
@class	NSMutableDictionary;
@class	NSMutableSet;
@class	NSString;
@class	NSTimer;

@interface      GSServicesManager : NSObject
{
  NSApplication         *application;
  NSMenu                *servicesMenu;
  NSMutableArray        *languages;
  NSMutableSet          *returnInfo;
  NSMutableDictionary   *combinations;
  NSMutableDictionary   *title2info;
  NSArray               *menuTitles;
  NSString		*disabledPath;
  NSString		*servicesPath;
  NSDate		*disabledStamp;
  NSDate		*servicesStamp;
  NSMutableSet		*allDisabled;
  NSMutableDictionary	*allServices;
  NSTimer		*timer;
}
+ (GSServicesManager*) newWithApplication: (NSApplication*)app;
+ (GSServicesManager*) manager;
- (void) checkServices;
- (void) doService: (NSCell*)item;
- (BOOL) hasRegisteredTypes: (NSDictionary*)service;
- (NSString*) item2title: (NSCell*)item;
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
- (BOOL) validateMenuItem: (NSCell*)item;
- (void) updateServicesMenu;
@end

id GSContactApplication(NSString *appName, NSString *port, NSDate *expire);

#endif

