/* 
   set_show_servicaes.m

   GNUstep utility to enable or disable a service for the current user.

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: November 1998
   
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

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSString.h>
#include <AppKit/NSApplication.h>


int
main(int argc, char** argv, char **env)
{
  NSAutoreleasePool	*pool;
  NSProcessInfo		*proc;
  NSArray		*args;
  unsigned		index;

  // [NSObject enableDoubleReleaseCheck: YES];
#ifdef GS_PASS_ARGUMENTS
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif

  pool = [NSAutoreleasePool new];

  proc = [NSProcessInfo processInfo];
  if (proc == nil)
    {
      NSLog(@"unable to get process information!\n");
      [pool release];
      exit(0);
    }

  args = [proc arguments];

  for (index = 1; index < [args count]; index++)
    {
      if ([[args objectAtIndex: index] isEqual: @"--help"])
	{
	  printf(
"set_show_service enables or disables the display of a specified service\n"
"item.  It's should be in the form 'set_show_services --enable name' or \n"
"'set_show_service --disable name' where 'name' is a service name.\n");
	  exit(0);
	}
      if ([[args objectAtIndex: index] isEqual: @"--enable"])
	{
	  if (index >= [args count] - 1)
	    {
	      NSLog(@"No name specified for enable.\n");
	      exit(1);
	    }
	  NSSetShowsServicesMenuItem([args objectAtIndex: ++index], YES);
	  exit(0);
	}
      if ([[args objectAtIndex: index] isEqual: @"--disable"])
	{
	  if (index >= [args count] - 1)
	    {
	      NSLog(@"No name specified for disable.\n");
	      exit(1);
	    }
	  NSSetShowsServicesMenuItem([args objectAtIndex: ++index], NO);
	  exit(0);
	}
    }

  NSLog(@"Nothing to do.\n");
  return(1);
}

