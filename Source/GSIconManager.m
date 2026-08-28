/* Copyright (C) 2009 Free Software Foundation, Inc.

   Written by:  German Arias <german@xelalug.org>
   Created: December 2009

   This file is part of the GNUstep Project

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 3
   of the License, or (at your option) any later version.
    
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public  
   License along with this library; see the file COPYING.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#import <Foundation/NSConnection.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDistantObject.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSProcessInfo.h>

#import <GNUstepGUI/GSDisplayServer.h>
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "GSIconManager.h"

@protocol GSIconManager
 - (NSRect) setWindow: (unsigned int)aWindowNumber appProcessId: (int)aProcessId;
 - (void) removeWindow: (unsigned int)aWindowNumber;
 - (NSSize) getSizeWindow;
 - (void) setApplicationIconData: (NSData *)data
                       badgeText: (NSString *)badgeText
                    appProcessId: (int)aProcessId;
 - (BOOL) respondsToSelector: (SEL)aSelector;
 - (id) retain;
 - (void) release; 
@end

static BOOL verify = NO;
static id <GSIconManager>gsim = nil;
static NSConnection *gsimConnection = nil;
static int appId = 0;
static int iconCount = 0;

static void GSReleaseIconManager(void);

@interface GSIconManagerMonitor : NSObject
+ (id) _lostIconManager: (NSNotification *)notification;
@end

@implementation GSIconManagerMonitor
+ (id) _lostIconManager: (NSNotification *)notification
{
  if ([notification object] == gsimConnection)
    {
      GSReleaseIconManager();
    }
  return self;
}
@end

static void
GSGetIconManager(void)
{
  if ([[NSUserDefaults standardUserDefaults] boolForKey: @"GSUseIconManager"])
    {
      appId = [[NSProcessInfo processInfo] processIdentifier];

      gsim = (id <GSIconManager>)[NSConnection rootProxyForConnectionWithRegisteredName: @"GSIconManager" 
                                                                                   host: @""];
   
      if (gsim == nil)
	{
	  NSLog (@"Error: could not connect to server GSIconManager");
	}
      else if (RETAIN(gsim) != nil)
	{
	  gsimConnection = RETAIN([(NSDistantObject *)gsim connectionForProxy]);
	  [[NSNotificationCenter defaultCenter]
	    addObserver: [GSIconManagerMonitor class]
	       selector: @selector(_lostIconManager:)
		   name: NSConnectionDidDieNotification
		 object: gsimConnection];
	}
    }
}

static void
GSReleaseIconManager(void)
{
  if (gsimConnection != nil)
    {
      [[NSNotificationCenter defaultCenter]
	removeObserver: [GSIconManagerMonitor class]
		  name: NSConnectionDidDieNotification
		object: gsimConnection];
      DESTROY(gsimConnection);
    }
  DESTROY(gsim);
  verify = NO;
}

static inline void
checkVerify()
{
  if (!verify)
   {
      GSGetIconManager();
      verify = YES;
   }
}

NSSize
GSGetIconSize(void)
{
  NSSize iconSize;

  checkVerify();

  if (gsim != nil)
    {
      NS_DURING
	{
	  iconSize = [gsim getSizeWindow];
	}
      NS_HANDLER
	{
	  GSReleaseIconManager();
	  iconSize = [GSCurrentServer() iconSize];
	}
      NS_ENDHANDLER
    }
  else
    {
      iconSize = [GSCurrentServer() iconSize];
    }

  return iconSize;
}

void
GSRemoveIcon(NSWindow *window)
{
  checkVerify();

  if (gsim != nil)
    {
      unsigned int winNum = 0;
      BOOL removed = NO;

      NSConvertWindowNumberToGlobal([window windowNumber], &winNum);
      NS_DURING
	{
	  [gsim removeWindow: winNum];
	  removed = YES;
	}
      NS_HANDLER
	{
	  GSReleaseIconManager();
	}
      NS_ENDHANDLER

      if (removed == NO)
	{
	  return;
	}

      iconCount--;

      if (iconCount == 0)
	{
	  GSReleaseIconManager();
	}
    }
}

void
GSUpdateIconManager(NSImage *image, NSString *badgeLabel)
{
  NSData *iconData = nil;

  checkVerify();

  if (gsim == nil)
    {
      return;
    }

  NS_DURING
    {
      if ([gsim respondsToSelector: @selector(setApplicationIconData:badgeText:appProcessId:)])
	{
	  if (image != nil)
	    {
	      iconData = [image TIFFRepresentation];
	    }

	  [gsim setApplicationIconData: iconData
			     badgeText: badgeLabel
			  appProcessId: appId];
	}
    }
  NS_HANDLER
    {
      GSReleaseIconManager();
    }
  NS_ENDHANDLER
}

NSRect
GSGetIconFrame(NSWindow *window)
{
  NSRect iconRect;

  checkVerify();

  if (gsim != nil)
    {
      unsigned int winNum = 0;
      BOOL added = NO;

      NSConvertWindowNumberToGlobal([window windowNumber], &winNum);
      NS_DURING
	{
	  iconRect = [gsim setWindow: winNum
			appProcessId: appId];
	  added = YES;
	}
      NS_HANDLER
	{
	  GSReleaseIconManager();
	  iconRect = [window frame];
	  iconRect.size = [GSCurrentServer() iconSize];
	}
      NS_ENDHANDLER

      if (added == YES)
	{
	  iconCount++;
	}
    }
  else
    {
      iconRect = [window frame];
      iconRect.size = [GSCurrentServer() iconSize];
    }

  return iconRect;
}
