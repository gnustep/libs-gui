/* 
   NSWorkspace.m

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/NSWorkspace.h>

// Workspace File Type Globals 
NSString *NSPlainFileType;
NSString *NSDirectoryFileType;
NSString *NSApplicationFileType;
NSString *NSFilesystemFileType;
NSString *NSShellCommandFileType;

// Workspace File Operation Globals 
NSString *NSWorkspaceCompressOperation;
NSString *NSWorkspaceCopyOperation;
NSString *NSWorkspaceDecompressOperation;
NSString *NSWorkspaceDecryptOperation;
NSString *NSWorkspaceDestroyOperation;
NSString *NSWorkspaceDuplicateOperation;
NSString *NSWorkspaceEncryptOperation;
NSString *NSWorkspaceLinkOperation;
NSString *NSWorkspaceMoveOperation;
NSString *NSWorkspaceRecycleOperation;

// NSWorkspace notifications
NSString *NSWorkspaceDidLaunchApplicationNotification;
NSString *NSWorkspaceDidMountNotification;
NSString *NSWorkspaceDidPerformFileOperationNotification;
NSString *NSWorkspaceDidTerminateApplicationNotification;
NSString *NSWorkspaceDidUnmountNotification;
NSString *NSWorkspaceWillLaunchApplicationNotification;
NSString *NSWorkspaceWillPowerOffNotification;
NSString *NSWorkspaceWillUnmountNotification;

@implementation NSWorkspace

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSWorkspace class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Creating a Workspace
//
+ (NSWorkspace *)sharedWorkspace
{
  return nil;
}

//
// Instance methods
//

//
// Opening Files
//
- (BOOL)openFile:(NSString *)fullPath
{
  return NO;
}

- (BOOL)openFile:(NSString *)fullPath
       fromImage:(NSImage *)anImage
at:(NSPoint)point
       inView:(NSView *)aView
{
  return NO;
}

- (BOOL)openFile:(NSString *)fullPath
 withApplication:(NSString *)appName
{
  return NO;
}

- (BOOL)openFile:(NSString *)fullPath
 withApplication:(NSString *)appName
andDeactivate:(BOOL)flag
{
  return NO;
}

- (BOOL)openTempFile:(NSString *)fullPath
{
  return NO;
}

//
// Manipulating Files	
//
- (BOOL)performFileOperation:(NSString *)operation
		      source:(NSString *)source
destination:(NSString *)destination
		      files:(NSArray *)files
tag:(int *)tag
{
  return NO;
}

- (BOOL)selectFile:(NSString *)fullPath
inFileViewerRootedAtPath:(NSString *)rootFullpath
{
  return NO;
}

//
// Requesting Information about Files
//
- (NSString *)fullPathForApplication:(NSString *)appName
{
  return nil;
}

- (BOOL)getFileSystemInfoForPath:(NSString *)fullPath
		     isRemovable:(BOOL *)removableFlag
isWritable:(BOOL *)writableFlag
		     isUnmountable:(BOOL *)unmountableFlag
description:(NSString **)description
		     type:(NSString **)fileSystemType
{
  return NO;
}

- (BOOL)getInfoForFile:(NSString *)fullPath
	   application:(NSString **)appName
type:(NSString **)type
{
  return NO;
}

- (NSImage *)iconForFile:(NSString *)fullPath
{
  return nil;
}

- (NSImage *)iconForFiles:(NSArray *)pathArray
{
  return nil;
}

- (NSImage *)iconForFileType:(NSString *)fileType
{
  return nil;
}

//
// Tracking Changes to the File System
//
- (BOOL)fileSystemChanged
{
  return NO;
}

- (void)noteFileSystemChanged
{}

//
// Updating Registered Services and File Types
//
- (void)findApplications
{}

//
// Launching and Manipulating Applications	
//
- (void)hideOtherApplications
{}

- (BOOL)launchApplication:(NSString *)appName
{
  return NO;
}

- (BOOL)launchApplication:(NSString *)appName
		 showIcon:(BOOL)showIcon
autolaunch:(BOOL)autolaunch
{
  return NO;
}

//
// Unmounting a Device	
//
- (BOOL)unmountAndEjectDeviceAtPath:(NSString *)path
{
  return NO;
}

//
// Tracking Status Changes for Devices
//
- (void)checkForRemovableMedia
{}

- (NSArray *)mountNewRemovableMedia
{
  return nil;
}

- (NSArray *)mountedRemovableMedia
{
  return nil;
}

//
// Notification Center
//
- (NSNotificationCenter *)notificationCenter
{
  return nil;
}

//
// Tracking Changes to the User Defaults Database
//
- (void)noteUserDefaultsChanged
{}

- (BOOL)userDefaultsChanged
{
  return NO;
}

//
// Animating an Image	
//
- (void)slideImage:(NSImage *)image
	      from:(NSPoint)fromPoint
to:(NSPoint)toPoint
{}

//
// Requesting Additional Time before Power Off or Logout
//
- (int)extendPowerOffBy:(int)requested
{
  return 0;
}

@end
