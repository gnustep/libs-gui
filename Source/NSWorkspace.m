/* 
   NSWorkspace.m

   Description...

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Implementation: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 1998
   
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

#include <gnustep/gui/config.h>
#include <AppKit/NSWorkspace.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSPanel.h>
#include <AppKit/GSServicesManager.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSTask.h>
#include <Foundation/NSException.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSFileManager.h>

#define stringify_it(X) #X
#define	mkpath(X) stringify_it(X) "/Tools"

static NSDictionary	*applications = nil;

@interface	NSWorkspace (GNUstep)
- (NSTask*) launchProgram: (NSString *)prog
		   atPath: (NSString *)path;
@end


@implementation	NSWorkspace

static NSWorkspace		*sharedWorkspace = nil;
static NSNotificationCenter	*workspaceCenter = nil;
static BOOL 			userDefaultsChanged = NO;

static NSString			*appListName = @".GNUstepAppList";
static NSString			*appListPath = nil;

static NSString* gnustep_target_dir = 
#ifdef GNUSTEP_TARGET_DIR
  @GNUSTEP_TARGET_DIR;
#else
  nil;
#endif
static NSString* gnustep_target_cpu = 
#ifdef GNUSTEP_TARGET_CPU
  @GNUSTEP_TARGET_CPU;
#else
  nil;
#endif
static NSString* gnustep_target_os = 
#ifdef GNUSTEP_TARGET_OS
  @GNUSTEP_TARGET_OS;
#else
  nil;
#endif
static NSString* library_combo = 
#ifdef LIBRARY_COMBO
  @LIBRARY_COMBO;
#else
  nil;
#endif

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSWorkspace class])
    {
      static BOOL	beenHere;
      NSDictionary	*env;

      // Initial version
      [self setVersion: 1];

      [gnustep_global_lock lock];
      if (beenHere == YES)
	{
	  [gnustep_global_lock unlock];
	  return;
	}

      beenHere = YES;

      workspaceCenter = [NSNotificationCenter new];
      env = [[NSProcessInfo processInfo] environment];
      if (env)
	{
	  NSString	*str;
          NSData	*data;
          NSDictionary	*newApps;

	  str = [env objectForKey: @"GNUSTEP_USER_ROOT"];
	  if (str == nil)
	    str = [NSString stringWithFormat: @"%@/GNUstep",
		NSHomeDirectory()];
	  str = [str stringByAppendingPathComponent: @"Services"];
	  str = [str stringByAppendingPathComponent: appListName];
	  appListPath = [str retain];

	  if ((str = [env objectForKey: @"GNUSTEP_TARGET_DIR"]) != nil)
	    gnustep_target_dir = [str retain];
	  else if ((str = [env objectForKey: @"GNUSTEP_HOST_DIR"]) != nil)
	    gnustep_target_dir = [str retain];
	
	  if ((str = [env objectForKey: @"GNUSTEP_TARGET_CPU"]) != nil)
	    gnustep_target_cpu = [str retain];
	  else if ((str = [env objectForKey: @"GNUSTEP_HOST_CPU"]) != nil)
	    gnustep_target_cpu = [str retain];
	
	  if ((str = [env objectForKey: @"GNUSTEP_TARGET_OS"]) != nil)
	    gnustep_target_os = [str retain];
	  else if ((str = [env objectForKey: @"GNUSTEP_HOST_OS"]) != nil)
	    gnustep_target_os = [str retain];
	
	  if ((str = [env objectForKey: @"LIBRARY_COMBO"]) != nil)
	    library_combo = [str retain];

          data = [NSData dataWithContentsOfFile: appListPath];
          if (data)
            newApps = [NSDeserializer deserializePropertyListFromData: data
                                                    mutableContainers: NO];
          applications = [newApps retain];
	  [gnustep_global_lock unlock];
	}
    }
}

+ (id) allocWithZone: (NSZone*)zone
{
  [NSException raise: NSInvalidArgumentException
	      format: @"You may not allocate a workspace directly"];
  return nil;
}

//
// Creating a Workspace
//
+ (NSWorkspace *) sharedWorkspace
{
  if (sharedWorkspace == nil)
    {
      [gnustep_global_lock lock];
      if (sharedWorkspace == nil)
	{
	  sharedWorkspace =
		(NSWorkspace*)NSAllocateObject(self, 0, NSDefaultMallocZone());

	}
      [gnustep_global_lock unlock];
    }
  return sharedWorkspace;
}

//
// Instance methods
//
- (void) dealloc
{
  [NSException raise: NSInvalidArgumentException
	      format: @"Attempt to call dealloc for shared worksapace"];
}

- (id) init
{
  [NSException raise: NSInvalidArgumentException
	      format: @"Attempt to call init for shared worksapace"];
  return nil;
}

//
// Opening Files
//
- (BOOL) openFile: (NSString *)fullPath
{
  NSString      *ext = [fullPath pathExtension];
  NSDictionary  *map;
  NSArray       *apps;
  NSString      *appName;

  /*
   *    Get the applications cache (generated by the make_services tool)
   *    and lookup the special entry that contains a dictionary of all
   *    file extensions recognised by GNUstep applications.  Then find
   *    the array of applications that can handle our file.
   */
  if (applications == nil)
    [self findApplications];
  map = [applications objectForKey: @"GSExtensionsMap"];
  apps = [map objectForKey: ext];
  if (apps == nil || [apps count] == 0)
    {
      NSRunAlertPanel(nil,
	[NSString stringWithFormat: 
	    @"No known applications for file extension '%@'", ext],
	@"Continue", nil, nil);
      return NO;
    }

  /* FIXME - need a mechanism for determining default application */
  appName = [apps objectAtIndex: 0];

  return [self openFile: fullPath withApplication: appName];
}

- (BOOL) openFile: (NSString *)fullPath
        fromImage: (NSImage *)anImage
	       at: (NSPoint)point
	   inView: (NSView *)aView
{
  /* FIXME - should do animation here */
  return [self openFile: fullPath];
}

- (BOOL) openFile: (NSString *)fullPath
  withApplication: (NSString *)appName
{
  return [self openFile: fullPath withApplication: appName andDeactivate: YES];
}

- (BOOL) openFile: (NSString *)fullPath
  withApplication: (NSString *)appName
    andDeactivate: (BOOL)flag
{
  NSString      *port = [appName stringByDeletingPathExtension];
  NSDate        *finish = [NSDate dateWithTimeIntervalSinceNow: 30.0];
  id            app;

  /*
   *    Try to connect to the application - launches if necessary.
   */
  app = GSContactApplication(appName, port, finish);
  if (app == nil)
    {
      NSRunAlertPanel(nil,
	[NSString stringWithFormat: 
	    @"Failed to contact '%@' to open file", port],
	@"Continue", nil, nil);
      return NO;
    }

  NS_DURING
    {
      if (flag == NO)
        [app application: nil openFileWithoutUI: fullPath];
      else
        [app application: nil openFile: fullPath];
    }
  NS_HANDLER
    {
      NSRunAlertPanel(nil,
	[NSString stringWithFormat: 
	    @"Failed to contact '%@' to open file", port],
	    @"Continue", nil, nil);
      return NO;
    }
  NS_ENDHANDLER

  if (flag)
    [[NSApplication sharedApplication] deactivate];

  return YES;
}

- (BOOL) openTempFile: (NSString *)appName
{
  return NO;
}

//
// Manipulating Files	
//
- (BOOL) performFileOperation: (NSString *)operation
		      source: (NSString *)source
		 destination: (NSString *)destination
		       files: (NSArray *)files
			 tag: (int *)tag
{
  return NO;
}

- (BOOL) selectFile: (NSString *)fullPath
inFileViewerRootedAtPath: (NSString *)rootFullpath
{
  return NO;
}

//
// Requesting Information about Files
//
- (NSString *) fullPathForApplication: (NSString *)appName
{
  NSString      *last = [appName lastPathComponent];

  if (applications == nil)
    [self findApplications];

  if ([appName isEqual: last])
    {
      NSString  *ext = [appName pathExtension];

      if (ext == nil)
        {
          appName = [appName stringByAppendingPathExtension: @"app"];
        }
      return [applications objectForKey: appName];
    }
  return nil;
}

- (BOOL) getFileSystemInfoForPath: (NSString *)fullPath
		      isRemovable: (BOOL *)removableFlag
		       isWritable: (BOOL *)writableFlag
		    isUnmountable: (BOOL *)unmountableFlag
		      description: (NSString **)description
			     type: (NSString **)fileSystemType
{
  return NO;
}

- (BOOL) getInfoForFile: (NSString *)fullPath
	    application: (NSString **)appName
		   type: (NSString **)type
{
  return NO;
}

- (NSImage *) iconForFile: (NSString *)fullPath
{
  return nil;
}

- (NSImage *) iconForFiles: (NSArray *)pathArray
{
  return nil;
}

- (NSImage *) iconForFileType: (NSString *)fileType
{
  return nil;
}

//
// Tracking Changes to the File System
//
- (BOOL) fileSystemChanged
{
  return NO;
}

- (void) noteFileSystemChanged
{
}

//
// Updating Registered Services and File Types
//
- (void) findApplications
{
  static NSString	*path = nil;
  NSData		*data;
  NSDictionary		*newApps;
  NSTask		*task;

  /*
   * Try to locate and run an executable copy of 'make_services'
   */
  if (path == nil)
    path = [[NSString alloc] initWithCString: mkpath(GNUSTEP_INSTALL_PREFIX)];
  task = [self launchProgram: @"make_services" atPath: path];
  if (task != nil)
    [task waitUntilExit];

  data = [NSData dataWithContentsOfFile: appListPath];
  if (data)
    newApps = [NSDeserializer deserializePropertyListFromData: data
					    mutableContainers: NO];
  else
    newApps = [NSDictionary dictionary];

  ASSIGN(applications, newApps);
}

//
// Launching and Manipulating Applications	
//
- (void) hideOtherApplications
{
}

- (BOOL) launchApplication: (NSString *)appName
{
  return [self launchApplication: appName
			showIcon: YES
		      autolaunch: NO];
}

- (BOOL) launchApplication: (NSString *)appName
		  showIcon: (BOOL)showIcon
	        autolaunch: (BOOL)autolaunch
{
  NSString	*path;
  NSString	*file;
  NSDictionary	*info;

  if (appName == nil)
    return NO;

  path = appName;
  appName = [path lastPathComponent];
  if ([appName isEqual: path])
    {
      path = [self fullPathForApplication: appName];
      appName = [[path lastPathComponent] stringByDeletingPathExtension];
    }
  else if ([appName pathExtension] == nil)
    {
      path = [path stringByAppendingPathExtension: @"app"];
    }
  else
    {
      appName = [[path lastPathComponent] stringByDeletingPathExtension];
    }

  if (path == nil)
    return NO;

  /*
   *	See if the 'Info-gnustep.plist' specifies the location of the
   *	executable - if it does, replace our app name with the specified
   *	value.  If the executable name is an absolute path name, we also
   *	replace the path with that specified.
   */
  file = [path stringByAppendingPathComponent: @"Resources/Info-gnustep.plist"];
  info = [NSDictionary dictionaryWithContentsOfFile: file];
  file = [info objectForKey: @"NSExecutable"];
  if (file != nil)
    {
      appName = [file lastPathComponent];
      if ([file isAbsolutePath] == YES)
	{
	  path = [file stringByDeletingLastPathComponent];
	}
    }

  if ([self launchProgram: appName atPath: path] == nil)
    return NO;
  return YES;
}

//
// Unmounting a Device	
//
- (BOOL) unmountAndEjectDeviceAtPath: (NSString *)path
{
  return NO;
}

//
// Tracking Status Changes for Devices
//
- (void) checkForRemovableMedia
{
}

- (NSArray *) mountNewRemovableMedia
{
  return nil;
}

- (NSArray *) mountedRemovableMedia
{
  return nil;
}

//
// Notification Center
//
- (NSNotificationCenter *) notificationCenter
{
  return workspaceCenter;
}

//
// Tracking Changes to the User Defaults Database
//
- (void) noteUserDefaultsChanged
{
  userDefaultsChanged = YES;
}

- (BOOL) userDefaultsChanged
{
  BOOL	hasChanged = userDefaultsChanged;
  userDefaultsChanged = NO;
  return hasChanged;
}

//
// Animating an Image	
//
- (void) slideImage: (NSImage *)image
	       from: (NSPoint)fromPoint
		 to: (NSPoint)toPoint
{
}

//
// Requesting Additional Time before Power Off or Logout
//
- (int) extendPowerOffBy: (int)requested
{
  return 0;
}

@end


@implementation	NSWorkspace (GNUstep)
/*
 *	Attempt to start a program.  First look in machine/os/libs directory,
 *	then in machine/os directory, then at top level.
 */
- (NSTask*) launchProgram: (NSString *)prog
		   atPath: (NSString *)path
{
  NSArray	*args;
  NSTask	*task;
  NSString	*path0;
  NSString	*path1;
  NSString	*path2;
  NSFileManager	*mgr;

  /*
   *	Try to locate the actual executable file and start it running.
   */
  path2 = [path stringByAppendingPathComponent: prog];
  path = [path stringByAppendingPathComponent: gnustep_target_dir]; 
  path1 = [path stringByAppendingPathComponent: prog];
  path = [path stringByAppendingPathComponent: library_combo]; 
  path0 = [path stringByAppendingPathComponent: prog]; 

  mgr = [NSFileManager defaultManager];
  if ([mgr isExecutableFileAtPath: path0])
    path = path0;
  else if ([mgr isExecutableFileAtPath: path1])
    path = path1;
  else if ([mgr isExecutableFileAtPath: path2])
    path = path2;
  else
    return nil;

  args = [NSArray arrayWithObjects: nil];
  task = [NSTask launchedTaskWithLaunchPath: path
				  arguments: args];

  return task;
}

@end

