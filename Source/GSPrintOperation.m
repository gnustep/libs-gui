/* 
   GSPrintOperation.m

   Controls operations generating print jobs.

   Copyright (C) 1996,2004 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: November 2000
   Started implementation.
   Author: Chad Hardin <cehardin@mac.com>
   Date: June 2004
   Modified for printing backend support, split off from NSPrintOperation.m

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

#include <Foundation/NSData.h>
#include <Foundation/NSTask.h>
#include <Foundation/NSUserDefaults.h>
#include "AppKit/NSView.h"
#include "AppKit/NSPrintPanel.h"
#include "AppKit/NSPrintInfo.h"
#include "AppKit/NSWorkspace.h"
#include "GNUstepGUI/GSPrinting.h"
#include "GNUstepGUI/GSPrintOperation.h"




/**
  <unit>
  <heading>Class Description</heading>
  <p>
  GSPrintOperation is a generic class that should be subclasses
  by printing backend classes for the purpose of controlling and
  sending print jobs to a printing system.
  </p>
  </unit>
*/ 




@implementation GSPrintOperation

/** Load the appropriate bundle for the PrintInfo
    (eg: GSLPRPrintInfo, GSCUPSPrintInfo).
*/
+ (id) allocWithZone: (NSZone*) zone
{
  Class principalClass;

  principalClass = [[GSPrinting printingBundle] principalClass];

  if( principalClass == nil )
    return nil;
	
  return [[principalClass gsPrintOperationClass] allocWithZone: zone];
}



- (id)initWithView:(NSView *)aView
	       printInfo:(NSPrintInfo *)aPrintInfo
{
      
  self = [self initWithView: aView
	               insideRect: [aView bounds]
	                   toData: [NSMutableData data]
	                printInfo: aPrintInfo];
                  
  _showPanels = YES;

  return self;
}

- (NSGraphicsContext*)createContext
{
  [self subclassResponsibility: _cmd];
  return nil;
}


/**
/ !!!Here is the method that will be overridden in the printer bundle
*/
- (BOOL) _deliverSpooledResult
{
  [self subclassResponsibility: _cmd];
  return NO;
}


- (BOOL) deliverResult
{
  BOOL success;
  NSString *job;
  
  success = YES;
  job = [_printInfo jobDisposition];
  if ([job isEqual: NSPrintPreviewJob])
    {
      /* Check to see if there is a GNUstep app that can preview PS files.
	       It's not likely at this point, so also check for a standards
	       previewer, like gv.
      */
      NSTask *task;
      NSString *preview;
      NSWorkspace *ws = [NSWorkspace sharedWorkspace];
      [_printPanel _setStatusStringValue: @"Opening in previewer..."];
      
      preview = [ws getBestAppInRole: @"Viewer" 
                        forExtension: @"ps"];
      if (preview)
	      {
	        [ws openFile: _path withApplication: preview];
	      }
      else
	      {
	        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	        preview = [def objectForKey: @"NSPreviewApp"];
          
	        if (preview == nil || [preview length] == 0)
	          preview = @"gv";
            
	        task = [NSTask new];
	        [task setLaunchPath: preview];
	        [task setArguments: [NSArray arrayWithObject: _path]];
	        [task launch];
	        AUTORELEASE(task);
	      }
    }
  else if ([job isEqual: NSPrintSpoolJob])
    {
      success = [self _deliverSpooledResult];
    }
  else if ([job isEqual: NSPrintFaxJob])
    {
    }

  /* We can't remove the temp file because the previewer might still be
     using it, perhaps the printer is also?
  if ( _path )
    {
      [[NSFileManager defaultManager] removeFileAtPath: _path
				                                       handler: nil];
    }
  */
  return success;
}

@end

