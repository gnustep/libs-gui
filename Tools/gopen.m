/* This tool opens the appropriate application from the command line
   based on what type of file is being accessed. 

   Copyright (C) 2001 Free Software Foundation, Inc.

   Written by:  Gregory Casamento <greg_casamento@yahoo.com>
   Created: November 2001

   This file is part of the GNUstep Project

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.
    
   You should have received a copy of the GNU General Public  
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

   */

#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSTask.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSFileHandle.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSWorkspace.h>

int
main(int argc, char** argv, char **env_c)
{
  CREATE_AUTORELEASE_POOL(pool);
  NSEnumerator *argEnumerator = nil;
  NSWorkspace *workspace = nil;
  NSFileManager *fm = nil;
  NSString *arg = nil;
  NSString 
    *editor = nil,
    *terminal = nil;
  NSString 
    *application = nil, 
    *filetoopen = nil,
    *filetoprint = nil,
    *nxhost = nil;

#ifdef GS_PASS_ARGUMENTS
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env_c];
#endif
  argEnumerator = [[[NSProcessInfo processInfo] arguments] objectEnumerator];
  workspace = [NSWorkspace sharedWorkspace];
  fm = [NSFileManager defaultManager];
  
  // Default applications for opening unregistered file types....
  editor = [[NSUserDefaults standardUserDefaults]
    stringForKey: @"GSDefaultEditor"];
  terminal = [[NSUserDefaults standardUserDefaults]
    stringForKey: @"GSDefaultTerminal"];

  // Process options...
  application = [[NSUserDefaults standardUserDefaults] stringForKey: @"a"];
  filetoopen = [[NSUserDefaults standardUserDefaults] stringForKey: @"o"];
  filetoprint = [[NSUserDefaults standardUserDefaults] stringForKey: @"p"];
  nxhost = [[NSUserDefaults standardUserDefaults] stringForKey: @"NXHost"];

  if (application)
    {
      [workspace launchApplication: application];
    }
  
  if (filetoopen)
    {
      [workspace openFile: filetoopen];
    }

  if (filetoprint)
    {
      puts("Not implemented");
    }

  if (nxhost)
    {
      puts("Not implemented");
    }

  if (argc == 1)
    {
      NSFileHandle *fh = [NSFileHandle fileHandleWithStandardInput];
      NSData *data = [fh readDataToEndOfFile];
      NSString *tempFile = [NSTemporaryDirectory()
	stringByAppendingPathComponent: @"openfiletmp"];
      NSNumber *processId = [NSNumber numberWithInt:
	[[NSProcessInfo processInfo] processIdentifier]];

      tempFile = [tempFile stringByAppendingString: [processId stringValue]];
      tempFile = [tempFile stringByAppendingString: @".txt"];
      [data writeToFile: tempFile atomically: YES];
      [workspace openFile: tempFile withApplication: editor];      
    }

  [argEnumerator nextObject]; // skip the first element, which is empty.
  while ((arg = [argEnumerator nextObject]) != nil)
    {
      NSString *ext = [arg pathExtension];
      
      if ([arg isEqualToString: @"-a"])
	{
	  // skip since this is handled above...
	  arg = [argEnumerator nextObject];
	}
      else if ([arg isEqualToString: @"-o"])
	{
	  // skip since this is handled above...
	  arg = [argEnumerator nextObject];
	}
      else if ([arg isEqualToString: @"-p"])
	{
	  // skip since this is handled above...
	  arg = [argEnumerator nextObject];
	}
      else if ([arg isEqualToString: @"-NXHost"])
	{
	  // skip since this is handled above...
	  arg = [argEnumerator nextObject];
	}
      else // no option specified
	{
	  NS_DURING
	    {
	      BOOL isDir = NO, exists = NO;

	      exists = [fm fileExistsAtPath: arg isDirectory: &isDir];
	      if (exists && !isDir && [fm isExecutableFileAtPath: arg])
		{
		  [workspace openFile: arg withApplication: terminal];
		}
	      else // no argument specified
		{
		  // First check to see if it's an application
		  if ([ext isEqualToString: @"app"] ||
		      [ext isEqualToString: @"debug"] ||
		      [ext isEqualToString: @"profile"])
		    {
		      NSString *appName = 
			[[arg lastPathComponent] stringByDeletingPathExtension];
		      NSString *executable = 
			[arg stringByAppendingPathComponent: appName];
		      
		      if ([fm fileExistsAtPath: arg])
			{
			  if ([NSTask launchedTaskWithLaunchPath: executable 
				      arguments: nil] == nil)
			    {
			      NSLog(@"Unable to launch: %@",arg);
			    }
			}
		      else
			{
			  [workspace launchApplication: arg];
			}
		    }
		  else 
		    {
		      if (![workspace openFile: arg])
			{
			  // no recognized extension, 
			  // run application indicated by environment var.	
			  NSLog(@"Opening %@ with %@",arg,editor);
			  [workspace openFile: arg withApplication: editor];
			}
		    }
		}
	    }
	  NS_HANDLER
	    {
	      NSLog(@"Exception while attempting open file %@ - %@: %@",
		    arg, [localException name], [localException reason]);
	    }
	  NS_ENDHANDLER
	}
    }
  RELEASE(pool);
  exit(EXIT_SUCCESS);
}
