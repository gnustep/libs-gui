/* 
   NSWorkspace.h

   Interface for workspace.

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSWorkspace
#define _GNUstep_H_NSWorkspace

#include <AppKit/stdappkit.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSView.h>
#include <Foundation/NSNotification.h>

@interface NSWorkspace : NSObject

{
  // Attributes
}

//
// Creating a Workspace
//
+ (NSWorkspace *)sharedWorkspace;

//
// Opening Files
//
- (BOOL)openFile:(NSString *)fullPath;
- (BOOL)openFile:(NSString *)fullPath
       fromImage:(NSImage *)anImage
at:(NSPoint)point
       inView:(NSView *)aView;
- (BOOL)openFile:(NSString *)fullPath
 withApplication:(NSString *)appName;
- (BOOL)openFile:(NSString *)fullPath
 withApplication:(NSString *)appName
andDeactivate:(BOOL)flag;
- (BOOL)openTempFile:(NSString *)fullPath;

//
// Manipulating Files	
//
- (BOOL)performFileOperation:(NSString *)operation
		      source:(NSString *)source
destination:(NSString *)destination
		      files:(NSArray *)files
tag:(int *)tag;
- (BOOL)selectFile:(NSString *)fullPath
inFileViewerRootedAtPath:(NSString *)rootFullpath;

//
// Requesting Information about Files
//
- (NSString *)fullPathForApplication:(NSString *)appName;
- (BOOL)getFileSystemInfoForPath:(NSString *)fullPath
		     isRemovable:(BOOL *)removableFlag
isWritable:(BOOL *)writableFlag
		     isUnmountable:(BOOL *)unmountableFlag
description:(NSString **)description
		     type:(NSString **)fileSystemType;
- (BOOL)getInfoForFile:(NSString *)fullPath
	   application:(NSString **)appName
type:(NSString **)type;
- (NSImage *)iconForFile:(NSString *)fullPath;
- (NSImage *)iconForFiles:(NSArray *)pathArray;
- (NSImage *)iconForFileType:(NSString *)fileType;

//
// Tracking Changes to the File System
//
- (BOOL)fileSystemChanged;
- (void)noteFileSystemChanged;

//
// Updating Registered Services and File Types
//
- (void)findApplications;

//
// Launching and Manipulating Applications	
//
- (void)hideOtherApplications;
- (BOOL)launchApplication:(NSString *)appName;
- (BOOL)launchApplication:(NSString *)appName
		 showIcon:(BOOL)showIcon
autolaunch:(BOOL)autolaunch;

//
// Unmounting a Device	
//
- (BOOL)unmountAndEjectDeviceAtPath:(NSString *)path;

//
// Tracking Status Changes for Devices
//
- (void)checkForRemovableMedia;
- (NSArray *)mountNewRemovableMedia;
- (NSArray *)mountedRemovableMedia;

//
// Notification Center
//
- (NSNotificationCenter *)notificationCenter;

//
// Tracking Changes to the User Defaults Database
//
- (void)noteUserDefaultsChanged;
- (BOOL)userDefaultsChanged;

//
// Animating an Image	
//
- (void)slideImage:(NSImage *)image
	      from:(NSPoint)fromPoint
to:(NSPoint)toPoint;

//
// Requesting Additional Time before Power Off or Logout
//
- (int)extendPowerOffBy:(int)requested;

@end

#endif // _GNUstep_H_NSWorkspace
