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
#include <AppKit/NSApplication.h>
#include <AppKit/NSWorkspace.h>

// This is being redefined here to prevent NSWorkspace from
// complaining when no application event-loop is running.
int
NSRunAlertPanel(
  NSString *title,
  NSString *msg,
  NSString *defaultButton,
  NSString *alternateButton,
  NSString *otherButton, ...)
{
  return 0;
}

int
main(int argc, char** argv, char **env_c)
{
  NSAutoreleasePool *pool;
  NSArray *arguments = nil;
  NSEnumerator *argEnumerator = nil;
  NSString *file = nil;
  NSWorkspace *workspace = nil;

#ifdef GS_PASS_ARGUMENTS
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env_c];
#endif
  pool = [NSAutoreleasePool new];
  argEnumerator = [[[NSProcessInfo processInfo] arguments] objectEnumerator];
  workspace = [NSWorkspace sharedWorkspace];

  [argEnumerator nextObject]; // skip the first element, which is empty.

  while((file = [argEnumerator nextObject]) != nil)
    {
      NSString *ext = [file pathExtension];
      NSString *appName = nil;
      
      NS_DURING
		
	if( ![workspace openFile: file] )
	  {
	    if( [ext isEqualToString: @"app"] )
	      {
		NSString *appName = 
		  [[file lastPathComponent] stringByDeletingPathExtension];
		NSString *executable = 
		  [file stringByAppendingPathComponent: appName];
		NSTask *task = nil;

		if ([NSTask launchedTaskWithLaunchPath: executable arguments: nil] == nil)
		  printf("Unable to launch application at path %s.\n",[file cString]);
	      }
	    else
	      {
		printf("No application for extension %s\n",[ext cString]);
	      }
	  }	   
      
      NS_HANDLER
	NSLog(@"Exception while attempting open file %@ - %@: %@",
	      file, [localException name], [localException reason]);
      NS_ENDHANDLER
    }

  [pool release];
  exit(0);
}
