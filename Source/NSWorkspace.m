/* 
   NSWorkspace.m

   Description...

   Copyright (C) 1996-1999 Free Software Foundation, Inc.

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
#include <AppKit/NSImage.h>
#include <AppKit/NSPanel.h>
#include <AppKit/GSServicesManager.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSTask.h>
#include <Foundation/NSException.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSNotificationQueue.h>
#include <Foundation/NSConnection.h>

#define stringify_it(X) #X
#define	mkpath(X) stringify_it(X) "/Tools"


@implementation	NSWorkspace

static NSWorkspace		*sharedWorkspace = nil;
static NSNotificationCenter	*workspaceCenter = nil;
static NSMutableDictionary	*iconMap = nil;
static BOOL 			userDefaultsChanged = NO;

static NSString			*appListName = @"Services/.GNUstepAppList";
static NSString			*appListPath = nil;
static NSDictionary		*applications = nil;

static NSString			*extPrefName = @"Services/.GNUstepExtPrefs";
static NSString			*extPrefPath = nil;
static NSDictionary		*extPreferences = nil;

static NSString			*_rootPath = @"/";

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSWorkspace class])
    {
      static BOOL	beenHere;
      NSFileManager	*mgr = [NSFileManager defaultManager];
      NSDictionary	*env;
      NSString		*home;
      NSData		*data;
      NSDictionary	*dict;

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
      iconMap = [NSMutableDictionary new];

      /*
       *	The home directory for per-user information is given by
       *	the GNUSTEP_USER_ROOT environment variable, or is assumed
       *	to be the 'GNUstep' subdirectory of the users home directory.
       */
      env = [[NSProcessInfo processInfo] environment];
      if (!env || !(home = [env objectForKey: @"GNUSTEP_USER_ROOT"]))
	{
	  home = [NSString stringWithFormat: @"%@/GNUstep", NSHomeDirectory()];
	}

      /*
       *	Load file extension preferences.
       */
      extPrefPath = [home stringByAppendingPathComponent: extPrefName];
      [extPrefPath retain];
      if ([mgr isReadableFileAtPath: extPrefPath] == YES)
	{
	  data = [NSData dataWithContentsOfFile: extPrefPath];
	  if (data)
	    {
	      dict = [NSDeserializer deserializePropertyListFromData: data
						   mutableContainers: NO];
	      extPreferences = [dict retain];
	    }
	}

      /*
       *	Load cached application information.
       */
      appListPath = [home stringByAppendingPathComponent: appListName];
      [appListPath retain];
      if ([mgr isReadableFileAtPath: appListPath] == YES)
	{
	  data = [NSData dataWithContentsOfFile: appListPath];
	  if (data)
	    {
	      dict = [NSDeserializer deserializePropertyListFromData: data
						   mutableContainers: NO];
	      applications = [dict retain];
	    }
	}
      [gnustep_global_lock unlock];
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

	  [NSNotificationCenter addObserver: sharedWorkspace
				   selector: @selector(noteUserDefaultsChanged)
				       name: NSUserDefaultsDidChangeNotification
				     object: nil];
	}
      [gnustep_global_lock unlock];
    }
  return sharedWorkspace;
}

static NSImage*
extIconForApp(NSWorkspace *ws, NSString *appName, NSDictionary *typeInfo)
{
  NSString	*file = [typeInfo objectForKey: @"NSIcon"];

  if (file)
    {
      if ([file isAbsolutePath] == NO)
	{
	  NSString	*path;

	  path = [ws fullPathForApplication: appName];
	  file = [path stringByAppendingPathComponent: file];
	}
      if ([[NSFileManager defaultManager] isReadableFileAtPath: file] == YES)
	{
	  return [[[NSImage alloc] initWithContentsOfFile: file] autorelease];
	}
    }
  return nil;
}

- (NSImage*) _getImageWithName: (NSString *)name
		     alternate: (NSString *)alternate
{
  NSImage	*image = nil;

  image = [NSImage imageNamed: name];
  if (image == nil)
    image = [NSImage imageNamed: alternate];
  return image;
}

/** Returns the default icon to display for a directory */
- (NSImage *) folderImage
{
  static NSImage *image = nil;

  if (image == nil)
    {
      image = [[self _getImageWithName: @"Folder.tiff"
			     alternate: @"common_Folder.tiff"] retain];
    }

  return image;
}

/** Returns the default icon to display for a directory */
- (NSImage *) unknownFiletypeImage
{
  static NSImage *image = nil;

  if (image == nil)
    {
      image = [[self _getImageWithName: @"Unknown.tiff"
			     alternate: @"common_Unknown.tiff"] retain];
    }

  return image;
}

/** Returns the default icon to display for a directory */
- (NSImage *)rootImage
{
  static NSImage *image = nil;

  if (image == nil)
    {
      image = [[self _getImageWithName: @"Root_PC.tiff"
			     alternate: @"common_Root_PC.tiff"] retain];
    }

  return image;
}

- (NSImage*) _iconForExtension: (NSString*)ext
{
  NSImage	*icon = nil;

  if (ext == nil || [ext isEqualToString: @""])
    return nil;
  /*
   * extensions are case-insensitive - convert to lowercase.
   */
  ext = [ext lowercaseString];
  if ((icon = [iconMap objectForKey: ext]) == nil)
    {
      NSDictionary	*prefs;
      NSDictionary	*extInfo;
      NSString		*iconPath;

      /*
       * If there is a user-specified preference for an image -
       * try to use that one.
       */
      prefs = [extPreferences objectForKey: ext];
      iconPath = [prefs objectForKey: @"Icon"];
      if (iconPath)
	{
	  icon = [[NSImage alloc] initWithContentsOfFile: iconPath];
	  [icon autorelease];
	}

      if (icon == nil && (extInfo = [self infoForExtension: ext]) != nil)
	{
	  NSDictionary	*typeInfo;
	  NSString	*appName;

	  /*
	   * If there are any application preferences given, try to use the
	   * icon for this file that is used by the preferred app.
	   */
	  if (prefs)
	    {
	      if ((appName = [extInfo objectForKey: @"Editor"]) != nil)
		{
		  typeInfo = [extInfo objectForKey: appName];
		  icon = extIconForApp(self, appName, typeInfo);
		}
	      if (icon == nil
		&& (appName = [extInfo objectForKey: @"Viewer"]) != nil)
		{
		  typeInfo = [extInfo objectForKey: appName];
		  icon = extIconForApp(self, appName, typeInfo);
		}
	    }

	  if (icon == nil)
	    {
	      NSEnumerator	*enumerator;

	      /*
	       * Still no icon - try all the apps that handle this file
	       * extension.
	       */
	      enumerator = [extInfo keyEnumerator];
	      while (icon == nil && (appName = [enumerator nextObject]) != nil)
		{
		  typeInfo = [extInfo objectForKey: appName];
		  icon = extIconForApp(self, appName, typeInfo);
		}
	    }
	}

      if (icon == nil)
	{
	}

      /*
       * Nothing found at all - use the unknowntype icon.
       */
      if (icon == nil)
	{
	  icon = [self unknownFiletypeImage];
	}

      /*
       * Set the icon in the cache for next time.
       */
      if (icon != nil)
	[iconMap setObject: icon forKey: ext];
    }
  return icon;
}

- (BOOL) _extension: (NSString*)ext
               role: (NSString*)role
	        app: (NSString**)app
	    andInfo: (NSDictionary**)inf
{
  NSEnumerator	*enumerator;
  NSString      *appName = nil;
  NSDictionary	*apps;
  NSDictionary	*prefs;
  NSDictionary	*info;

  ext = [ext lowercaseString];
  apps = [self infoForExtension: ext];
  if (apps == nil || [apps count] == 0)
    return NO;

  /*
   *	Look for the name of the preferred app in this role.
   *	A 'nil' roll is a wildcard - find the preferred Editor or Viewer.
   */
  prefs = [extPreferences objectForKey: ext];

  if (role == nil || [role isEqualToString: @"Editor"])
    {
      appName = [prefs objectForKey: @"Editor"];
      if (appName)
	{
	  info = [apps objectForKey: appName];
	  if (info)
	    {
	      if (app)
		*app = appName;
	      if (inf)
		*inf = info;
	      return YES;
	    }
	}
    }
  if (role == nil || [role isEqualToString: @"Viewer"])
    {
      appName = [prefs objectForKey: @"Viewer"];
      if (appName)
	{
	  info = [apps objectForKey: appName];
	  if (info)
	    {
	      if (app)
		*app = appName;
	      if (inf)
		*inf = info;
	      return YES;
	    }
	}
    }

  /*
   * Go through the dictionary of apps that know about this file type and
   * determine the best application to open the file by examining the
   * type information for each app.
   * The 'NSRole' field specifies what the app can do with the file - if it
   * is missing, we assume an 'Editor' role.
   */
  enumerator = [apps keyEnumerator];

  if (role == nil)
    {
      BOOL	found = NO;

      /*
       * If the requested role is 'nil', we can accept an app that is either
       * an Editor (preferred) or a Viewer.
       */
      while ((appName = [enumerator nextObject]) != nil)
	{
	  NSString	*str;

	  info = [apps objectForKey: appName];
	  str = [info objectForKey: @"NSRole"];
	  if (str == nil || [str isEqualToString: @"Editor"])
	    {
	      if (app)
		*app = appName;
	      if (inf)
		*inf = info;
	      return YES;
	    }
	  else if ([str isEqualToString: @"Viewer"])
	    {
	      if (app)
		*app = appName;
	      if (inf)
		*inf = info;
	      found = YES;
	    }
	}
      return found;
    }
  else
    {
      while ((appName = [enumerator nextObject]) != nil)
	{
	  NSString	*str;

	  info = [apps objectForKey: appName];
	  str = [info objectForKey: @"NSRole"];
	  if ((str == nil && [role isEqualToString: @"Editor"])
	    || [str isEqualToString: role])
	    {
	      if (app)
		*app = appName;
	      if (inf)
		*inf = info;
	      return YES;
	    }
	}
      return NO;
    }
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
  NSString      *appName;

  if ([self _extension: ext role: nil app: &appName andInfo: 0] == NO)
    {
      NSRunAlertPanel(nil,
	[NSString stringWithFormat: 
	    @"No known applications for file extension '%@'", ext],
	@"Continue", nil, nil);
      return NO;
    }

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
  id            app;

  /*
   *	Try to contact a running application.
   */
  NS_DURING
    {
      app = [NSConnection rootProxyForConnectionWithRegisteredName: port  
                                                              host: @""];
    }
  NS_HANDLER
    {
      app = nil;		/* Fatal error in DO	*/
    }
  NS_ENDHANDLER

  if (app == nil)
    {
      NSString	*path;
      NSArray	*args;

      path = [self locateApplicationBinary: appName];
      if (path == nil)
	{
	  NSRunAlertPanel(nil,
	    [NSString stringWithFormat: 
	      @"Failed to locate '%@' to open file", port],
	    @"Continue", nil, nil);
	  return NO;
	}
      args = [NSArray arrayWithObjects: @"-GSFilePath", fullPath, nil];
      if ([NSTask launchedTaskWithLaunchPath: path arguments: args] == nil)
	{
	  NSRunAlertPanel(nil,
	    [NSString stringWithFormat: 
	      @"Failed to launch '%@' to open file", port],
	    @"Continue", nil, nil);
	  return NO;
	}
      return YES;
    }
  else
    {
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
    }

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

- (NSImage *) iconForFile: (NSString *)aPath
{
  NSImage	*image = nil;
  BOOL		isDir = NO;
  NSString	*iconPath = nil;
  NSString	*pathExtension = [[aPath pathExtension] lowercaseString];
  NSFileManager	*mgr = [NSFileManager defaultManager];

  if ([mgr fileExistsAtPath: aPath isDirectory: &isDir] && isDir)
    {
      if ([pathExtension isEqualToString: @"app"]
	|| [pathExtension isEqualToString: @"debug"]
	|| [pathExtension isEqualToString: @"profile"])
	{
	  NSBundle	*bundle;

	  bundle = [NSBundle bundleWithPath: aPath];
	  iconPath = [[bundle infoDictionary] objectForKey: @"NSIcon"];
	  if (iconPath && [iconPath isAbsolutePath] == NO)
	    {
	      iconPath = [aPath stringByAppendingPathComponent: iconPath];
	    }
	  /*
	   *	If there is no icon specified in the Info.plist for app
	   *	try 'wrapper/app.tiff' and 'wrapper/.dir.tiff' as
	   *	possible locations for the application icon.
	   */
	  if (iconPath == nil)
	    {
	      NSString	*str;

	      str = [[aPath lastPathComponent] stringByDeletingPathExtension];
	      iconPath = [aPath stringByAppendingPathComponent: str];
	      iconPath = [iconPath stringByAppendingPathExtension: @"tiff"];
	      if ([mgr isReadableFileAtPath: iconPath] == NO)
		{
		  str = @".dir.tiff";
		  iconPath = [aPath stringByAppendingPathComponent: str];
		  if ([mgr isReadableFileAtPath: iconPath] == NO)
		    iconPath = nil;
		}
	    }

	  if (iconPath)
	    {
	      NS_DURING
		{
		  image = [[NSImage alloc] initWithContentsOfFile: iconPath];
		  [image autorelease];
		}
	      NS_HANDLER
		{
		  NSLog(@"BAD TIFF FILE '%@'", iconPath);
		}
	      NS_ENDHANDLER
	    }
	}

      if (image == nil)
	{
	  image = [self _iconForExtension: pathExtension];
	}

      if (image == nil)
	{
	  if ([aPath isEqual: _rootPath])
	    image = [self rootImage];
	  else
	    image= [self folderImage];
	}
    }
  else
    {
      NSDebugLog(@"pathExtension is '%@'", pathExtension);

      image = [self _iconForExtension: pathExtension];
    }

  if (image == nil)
    {
      image = [self unknownFiletypeImage];
    }

  return image;
}

- (NSImage *) iconForFiles: (NSArray *)pathArray
{
  static NSImage	*multipleFiles = nil;

  if (multipleFiles == nil)
    {
      multipleFiles = [NSImage imageNamed: @"FileIcon_multi"];
    }

  return multipleFiles;
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
  NSFileManager		*mgr = [NSFileManager defaultManager];
  NSData		*data;
  NSDictionary		*dict;
  NSTask		*task;

  /*
   * Try to locate and run an executable copy of 'make_services'
   */
  if (path == nil)
    path = [[NSString alloc] initWithFormat: @"%s/make_services",
		mkpath(GNUSTEP_INSTALL_PREFIX)];
  task = [NSTask launchedTaskWithLaunchPath: path
				  arguments: nil];
  if (task != nil)
    [task waitUntilExit];

  if ([mgr isReadableFileAtPath: extPrefPath] == YES)
    {
      data = [NSData dataWithContentsOfFile: extPrefPath];
      if (data)
	{
	  dict = [NSDeserializer deserializePropertyListFromData: data
					       mutableContainers: NO];
	  ASSIGN(extPreferences, dict);
	}
    }

  if ([mgr isReadableFileAtPath: appListPath] == YES)
    {
      data = [NSData dataWithContentsOfFile: appListPath];
      if (data)
	{
	  dict = [NSDeserializer deserializePropertyListFromData: data
					       mutableContainers: NO];
	  ASSIGN(applications, dict);
	}
    }
  /*
   *	Invalidate the cache of icons for file extensions.
   */
  [iconMap removeAllObjects];
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

  path = [self locateApplicationBinary: appName];
  if (path == nil)
    return NO;
  if ([NSTask launchedTaskWithLaunchPath: path arguments: nil] == nil)
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

- (NSString*) getBestAppInRole: (NSString*)role
		  forExtension: (NSString*)ext
{
  NSString	*appName = nil;

  if (extPreferences != nil)
    {
      NSDictionary	*inf;

      inf = [extPreferences objectForKey: [ext lowercaseString]];
      if (inf != nil)
	{
	  if (role == nil)
	    {
	      appName = [inf objectForKey: @"Editor"];
	      if (appName == nil)
		appName = [inf objectForKey: @"Viewer"];
	    }
	  else
	    {
	      appName = [inf objectForKey: role];
	    }
	}
    }
  return appName;
}

- (NSString*) getBestIconForExtension: (NSString*)ext
{
  NSString	*iconPath = nil;

  if (extPreferences != nil)
    {
      NSDictionary	*inf;

      inf = [extPreferences objectForKey: [ext lowercaseString]];
      if (inf != nil)
	iconPath = [inf objectForKey: @"Icon"];
    }
  return iconPath;
}

- (NSDictionary*) infoForExtension: (NSString*)ext
{
  NSDictionary  *map;

  ext = [ext lowercaseString];
  /*
   *    Get the applications cache (generated by the make_services tool)
   *    and lookup the special entry that contains a dictionary of all
   *    file extensions recognised by GNUstep applications.  Then find
   *    the dictionary of applications that can handle our file.
   */
  if (applications == nil)
    [self findApplications];
  map = [applications objectForKey: @"GSExtensionsMap"];
  return [map objectForKey: ext];
}

- (NSString*) locateApplicationBinary: (NSString*)appName
{
  NSString	*path;
  NSString	*file;
  NSBundle	*bundle;

  if (appName == nil)
    return nil;

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
    return nil;

  /*
   *	See if the 'Info-gnustep.plist' specifies the location of the
   *	executable - if it does, replace our app name with the specified
   *	value.  If the executable name is an absolute path name, we also
   *	replace the path with that specified.
   */
  bundle = [NSBundle bundleWithPath: path];
  file = [[bundle infoDictionary] objectForKey: @"NSExecutable"];
  if (file != nil)
    {
      NSString	*exepath;

      appName = [file lastPathComponent];
      exepath = [file stringByDeletingLastPathComponent];
      if ([exepath isEqualToString: @""] == NO)
	{
	  if ([file isAbsolutePath] == YES)
	    path = exepath;
	  else
	    path = [path stringByAppendingPathComponent: exepath];
	}
    }

  return [path stringByAppendingPathComponent: appName];
}

- (void) setBestApp: (NSString*)appName
	     inRole: (NSString*)role
       forExtension: (NSString*)ext
{
  NSMutableDictionary	*map;
  NSMutableDictionary	*inf;
  NSData		*data;

  ext = [ext lowercaseString];
  if (extPreferences)
    map = [extPreferences mutableCopy];
  else
    map = [NSMutableDictionary new];

  inf = [[map objectForKey: ext] mutableCopy];
  if (inf == nil)
    {
      inf = [NSMutableDictionary new];
    }
  if (appName == nil)
    {
      if (role == nil)
	{
	  NSString	*iconPath = [inf objectForKey: @"Icon"];

	  [iconPath retain];
	  [inf removeAllObjects];
	  if (iconPath)
	    {
	      [inf setObject: iconPath forKey: @"Icon"];
	    }
	}
      else
	{
	  [inf removeObjectForKey: role];
	}
    }
  else
    {
      [inf setObject: appName forKey: (role ? role : @"Editor")];
    }
  [map setObject: inf forKey: ext];
  [inf release];
  [extPreferences release];
  extPreferences = inf;
  data = [NSSerializer serializePropertyList: extPreferences];
  [data writeToFile: extPrefPath atomically: YES];
}

- (void) setBestIcon: (NSString*)iconPath forExtension: (NSString*)ext
{
  NSMutableDictionary	*map;
  NSMutableDictionary	*inf;
  NSData		*data;

  ext = [ext lowercaseString];
  if (extPreferences)
    map = [extPreferences mutableCopy];
  else
    map = [NSMutableDictionary new];

  inf = [[map objectForKey: ext] mutableCopy];
  if (inf == nil)
    inf = [NSMutableDictionary new];
  if (iconPath)
    [inf setObject: iconPath forKey: @"Icon"];
  else
    [inf removeObjectForKey: @"Icon"];
  [map setObject: inf forKey: ext];
  [inf release];
  [extPreferences release];
  extPreferences = inf;
  data = [NSSerializer serializePropertyList: extPreferences];
  [data writeToFile: extPrefPath atomically: YES];
}

@end
