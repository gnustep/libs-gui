/* This tool terminates all applications.

   Copyright (C) 2006 Free Software Foundation, Inc.

   Written by:  Richard Frith-Macdoanld <rfm@gnu.org>
   Created: January 2006

   This file is part of the GNUstep Project

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.
    
   You should have received a copy of the GNU General Public  
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

   */

#include <Foundation/NSArray.h>
#include <Foundation/NSConnection.h>
#include <Foundation/NSString.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSWorkspace.h>

int
main(int argc, char** argv, char **env_c)
{
  CREATE_AUTORELEASE_POOL(pool);
  NSWorkspace	*workspace;
  NSEnumerator	*enumerator;
  NSArray	*launched;
  NSDictionary	*info;

#ifdef GS_PASS_ARGUMENTS
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env_c];
#endif
  
  workspace = [NSWorkspace sharedWorkspace];
  launched = [workspace launchedApplications];
  enumerator = [launched objectEnumerator];
  while ((info = [enumerator nextObject]) != nil)
    {
      NSString	*port = [info objectForKey: @"NSApplicationName"];

      GSPrintf(stdout, @"Terminating '%@'\n", port);
      NS_DURING
	{
	  id	app;

	  /*
	   *	Try to contact a running application.
	   */
	  app = [NSConnection
	    rootProxyForConnectionWithRegisteredName: port  host: @""];

	  NS_DURING
	    {
	      [app terminate: nil];
	    }
	  NS_HANDLER
	    {
	      /* maybe it terminated. */
	    }
	  NS_ENDHANDLER
	}
      NS_HANDLER
	{
	  NSLog(@"Exception while attempting to terminate %@ - %@: %@",
	    port, [localException name], [localException reason]);
	}
      NS_ENDHANDLER
    }
  RELEASE(pool);
  exit(EXIT_SUCCESS);
}
