/* 
   NSWorkspace.h

   Interface for workspace.

   Copyright (C) 1996-2002 Free Software Foundation, Inc.

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

#ifndef _GNUstep_H_NSWorkspace
#define _GNUstep_H_NSWorkspace

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>
#include <AppKit/AppKitDefines.h>

@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSNotificationCenter;
@class NSImage;
@class NSView;
@class NSURL;

@interface NSWorkspace : NSObject
{
  NSMutableDictionary	*_iconMap;
  NSMutableDictionary	*_launched;
  NSNotificationCenter	*_workspaceCenter;
  BOOL			_fileSystemChanged;
  BOOL			_userDefaultsChanged;
}

//
// Creating a Workspace
//
+ (NSWorkspace*) sharedWorkspace;

//
// Opening Files
//
- (BOOL) openFile: (NSString*)fullPath;
- (BOOL) openFile: (NSString*)fullPath
	fromImage: (NSImage*)anImage
	       at: (NSPoint)point
	   inView: (NSView*)aView;
- (BOOL) openFile: (NSString*)fullPath
  withApplication: (NSString*)appName;
- (BOOL) openFile: (NSString*)fullPath
  withApplication: (NSString*)appName
    andDeactivate: (BOOL)flag;
- (BOOL) openTempFile: (NSString*)fullPath;
#ifndef STRICT_OPENSTEP
- (BOOL) openURL: (NSURL*)url;
#endif

//
// Manipulating Files	
//
- (BOOL) performFileOperation: (NSString*)operation
		       source: (NSString*)source
		  destination: (NSString*)destination
			files: (NSArray*)files
			  tag: (int*)tag;
- (BOOL) selectFile: (NSString*)fullPath
  inFileViewerRootedAtPath: (NSString*)rootFullpath;

//
// Requesting Information about Files
//
- (NSString*) fullPathForApplication: (NSString*)appName;
- (BOOL) getFileSystemInfoForPath: (NSString*)fullPath
		      isRemovable: (BOOL*)removableFlag
		       isWritable: (BOOL*)writableFlag
		    isUnmountable: (BOOL*)unmountableFlag
		      description: (NSString**)description
			     type: (NSString**)fileSystemType;
- (BOOL) getInfoForFile: (NSString*)fullPath
	    application: (NSString**)appName
		   type: (NSString**)type;
- (NSImage*) iconForFile: (NSString*)fullPath;
- (NSImage*) iconForFiles: (NSArray*)pathArray;
- (NSImage*) iconForFileType: (NSString*)fileType;
#ifndef STRICT_OPENSTEP
- (BOOL) isFilePackageAtPath: (NSString*)fullPath;
#endif

//
// Tracking Changes to the File System
//
- (BOOL) fileSystemChanged;
- (void) noteFileSystemChanged;
#ifndef STRICT_OPENSTEP
- (void) noteFileSystemChanged: (NSString*)path;
#endif

//
// Updating Registered Services and File Types
//
- (void) findApplications;

//
// Launching and Manipulating Applications	
//
- (void) hideOtherApplications;
- (BOOL) launchApplication: (NSString*)appName;
- (BOOL) launchApplication: (NSString*)appName
		  showIcon: (BOOL)showIcon
		autolaunch: (BOOL)autolaunch;

//
// Unmounting a Device	
//
- (BOOL) unmountAndEjectDeviceAtPath: (NSString*)path;

//
// Tracking Status Changes for Devices
//
- (void) checkForRemovableMedia;
- (NSArray*) mountNewRemovableMedia;
- (NSArray*) mountedRemovableMedia;
#ifndef STRICT_OPENSTEP
- (NSArray*) mountedLocalVolumePaths;
#endif

//
// Notification Center
//
- (NSNotificationCenter*) notificationCenter;

//
// Tracking Changes to the User Defaults Database
//
- (void) noteUserDefaultsChanged;
- (BOOL) userDefaultsChanged;

//
// Animating an Image	
//
- (void) slideImage: (NSImage*)image
	       from: (NSPoint)fromPoint
		 to: (NSPoint)toPoint;

//
// Requesting Additional Time before Power Off or Logout
//
- (int) extendPowerOffBy: (int)requested;

@end

#ifndef	NO_GNUSTEP

@class NSBundle;

@interface	NSWorkspace (GNUstep)
- (NSString*) getBestAppInRole: (NSString*)role
		  forExtension: (NSString*)ext;
- (NSString*) getBestIconForExtension: (NSString*)ext;
- (NSDictionary*) infoForExtension: (NSString*)ext;
- (NSBundle*) bundleForApp:(NSString*)appName;
- (NSImage*) appIconForApp:(NSString*)appName;
- (NSString*) locateApplicationBinary: (NSString*)appName;
- (void) setBestApp: (NSString*)appName
	     inRole: (NSString*)role
       forExtension: (NSString*)ext;
- (void) setBestIcon: (NSString*)iconPath forExtension: (NSString*)ext;
@end
#endif

/* Notifications */
APPKIT_EXPORT NSString *NSWorkspaceDidLaunchApplicationNotification;
APPKIT_EXPORT NSString *NSWorkspaceDidMountNotification;
APPKIT_EXPORT NSString *NSWorkspaceDidPerformFileOperationNotification;
APPKIT_EXPORT NSString *NSWorkspaceDidTerminateApplicationNotification;
APPKIT_EXPORT NSString *NSWorkspaceDidUnmountNotification;
APPKIT_EXPORT NSString *NSWorkspaceWillLaunchApplicationNotification;
APPKIT_EXPORT NSString *NSWorkspaceWillPowerOffNotification;
APPKIT_EXPORT NSString *NSWorkspaceWillUnmountNotification;

//
// Workspace File Type Globals 
//
APPKIT_EXPORT NSString *NSPlainFileType;
APPKIT_EXPORT NSString *NSDirectoryFileType;
APPKIT_EXPORT NSString *NSApplicationFileType;
APPKIT_EXPORT NSString *NSFilesystemFileType;
APPKIT_EXPORT NSString *NSShellCommandFileType;

//
// Workspace File Operation Globals 
//
APPKIT_EXPORT NSString *NSWorkspaceCompressOperation;
APPKIT_EXPORT NSString *NSWorkspaceCopyOperation;
APPKIT_EXPORT NSString *NSWorkspaceDecompressOperation;
APPKIT_EXPORT NSString *NSWorkspaceDecryptOperation;
APPKIT_EXPORT NSString *NSWorkspaceDestroyOperation;
APPKIT_EXPORT NSString *NSWorkspaceDuplicateOperation;
APPKIT_EXPORT NSString *NSWorkspaceEncryptOperation;
APPKIT_EXPORT NSString *NSWorkspaceLinkOperation;
APPKIT_EXPORT NSString *NSWorkspaceMoveOperation;
APPKIT_EXPORT NSString *NSWorkspaceRecycleOperation;

#endif // _GNUstep_H_NSWorkspace
