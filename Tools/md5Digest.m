/* This tool creates an md5 digest using the example filter
   based on what type of file is being accessed. 

   Copyright (C) 2003 Free Software Foundation, Inc.

   Written by:  Rrichard Frith-Macdonald <rfm@gnu.org>
   Created: June 2003

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
#include <Foundation/NSData.h>
#include <Foundation/NSFileHandle.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSPasteboard.h>

int
main(int argc, char** argv, char **env_c)
{
  CREATE_AUTORELEASE_POOL(pool);
  NSFileHandle		*fh;
  NSData		*data;
  NSString		*string;
  NSPasteboard		*pb;
  NSUserDefaults	*defs;

#ifdef GS_PASS_ARGUMENTS
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env_c];
#endif

  defs = [NSUserDefaults standardUserDefaults];
  string = [defs stringForKey: @"CatFile"];
  if (string != nil)
    {
      data = [NSSerializer serializePropertyList: string];
      pb = [NSPasteboard pasteboardByFilteringData: data
					    ofType: NSFilenamesPboardType];
      NSLog(@"Types: %@", [pb types]);
      data = [pb dataForType: NSGeneralPboardType];
      NSLog(@"Got %@", data);
    }
  else
    {
      NSLog(@"This program expects to read utf8 text from stdin -");
      fh = [NSFileHandle fileHandleWithStandardInput];
      data = [fh readDataToEndOfFile];
      string = [[NSString alloc] initWithData: data
				     encoding: NSUTF8StringEncoding];
      data = [NSSerializer serializePropertyList: string];

      pb = [NSPasteboard pasteboardByFilteringData: data
					    ofType: NSStringPboardType];
      NSLog(@"Types: %@", [pb types]);
      data = [pb dataForType: @"md5Digest"];
      NSLog(@"Got %@", data);
    }

  RELEASE(pool);
  exit(EXIT_SUCCESS);
}
