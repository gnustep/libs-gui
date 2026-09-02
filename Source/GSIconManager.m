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
#import <Foundation/NSObject.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSProcessInfo.h>

#import <GNUstepGUI/GSDisplayServer.h>
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "GSIconManager.h"

@protocol GSIconManager <NSObject>
 - (NSRect) setWindow: (unsigned int)aWindowNumber appProcessId: (int)aProcessId;
 - (void) removeWindow: (unsigned int)aWindowNumber;
 - (NSSize) getSizeWindow;
 - (void) setApplicationIconData: (NSData *)data
                       badgeText: (NSString *)badgeText
                    appProcessId: (int)aProcessId;
@end

static BOOL verify = NO;
static id <GSIconManager>gsim = nil;
static NSConnection *gsimConnection = nil;
static int appId = 0;
static NSMutableSet *registeredIcons = nil;
static unsigned int iconManagerUpdateCount = 0;
static unsigned int lastIconManagerAttemptUpdate = 0;
static NSData *lastApplicationIconData = nil;
static NSString *lastApplicationIconBadgeText = nil;

static void GSReleaseIconManager(void);
static void GSLostIconManager(void);
static BOOL GSSendApplicationIconData(NSData *data, NSString *badgeText);

@interface GSIconManagerMonitor : NSObject
+ (id) _lostIconManager: (NSNotification *)notification;
@end

@implementation GSIconManagerMonitor
+ (id) _lostIconManager: (NSNotification *)notification
{
  if ([notification object] == gsimConnection)
    {
      GSLostIconManager();
    }
  return self;
}
@end

static void
GSGetIconManager(void)
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  lastIconManagerAttemptUpdate = iconManagerUpdateCount;

  if ([defaults objectForKey: @"GSUseIconManager"] == nil ||
      [defaults boolForKey: @"GSUseIconManager"])
    {
      id <GSIconManager>proxy = nil;
      BOOL retainedProxy = NO;

      appId = [[NSProcessInfo processInfo] processIdentifier];

      NS_DURING
	{
	  proxy = (id <GSIconManager>)
	    [NSConnection rootProxyForConnectionWithRegisteredName: @"GSIconManager"
							      host: @""];

	  if (proxy != nil && RETAIN(proxy) != nil)
	    {
	      retainedProxy = YES;
	      gsimConnection = RETAIN([(NSDistantObject *)proxy connectionForProxy]);
	      gsim = proxy;
	      [[NSNotificationCenter defaultCenter]
		addObserver: [GSIconManagerMonitor class]
		   selector: @selector(_lostIconManager:)
		       name: NSConnectionDidDieNotification
		     object: gsimConnection];
	      if (lastApplicationIconData != nil
		  || lastApplicationIconBadgeText != nil)
		{
		  GSSendApplicationIconData(lastApplicationIconData,
					   lastApplicationIconBadgeText);
		}
	    }
	}
      NS_HANDLER
	{
	  if (retainedProxy == YES)
	    {
	      RELEASE(proxy);
	    }
	  DESTROY(gsimConnection);
	  gsim = nil;
	}
      NS_ENDHANDLER
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

static void
GSLostIconManager(void)
{
  GSReleaseIconManager();
  [registeredIcons removeAllObjects];
  verify = YES;
  lastIconManagerAttemptUpdate = iconManagerUpdateCount;
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
	  GSLostIconManager();
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
      NSNumber *winNumObject;

      NSConvertWindowNumberToGlobal([window windowNumber], &winNum);
      winNumObject = [NSNumber numberWithUnsignedInt: winNum];

      if ([registeredIcons containsObject: winNumObject] == NO)
	{
	  return;
	}

      NS_DURING
	{
	  [gsim removeWindow: winNum];
	  removed = YES;
	}
      NS_HANDLER
	{
	  GSLostIconManager();
	}
      NS_ENDHANDLER

      if (removed == NO)
	{
	  return;
	}

      [registeredIcons removeObject: winNumObject];

      if ([registeredIcons count] == 0)
	{
	  GSReleaseIconManager();
	}
    }
}

void
GSUpdateIconManager(NSImage *image, NSString *badgeLabel)
{
  NSData *iconData = nil;

  iconManagerUpdateCount++;

  if (image != nil)
    {
      iconData = [image TIFFRepresentation];
    }
  ASSIGN(lastApplicationIconData, iconData);
  ASSIGNCOPY(lastApplicationIconBadgeText, badgeLabel);

  if (gsim == nil && verify)
    {
      if (iconManagerUpdateCount - lastIconManagerAttemptUpdate < 5)
	{
	  return;
	}

      verify = NO;
    }

  checkVerify();

  if (gsim == nil)
    {
      return;
    }

  GSSendApplicationIconData(lastApplicationIconData,
			   lastApplicationIconBadgeText);
}

static BOOL
GSSendApplicationIconData(NSData *data, NSString *badgeText)
{
  BOOL sent = NO;

  if (gsim == nil)
    {
      return NO;
    }

  NS_DURING
    {
      if ([gsim respondsToSelector: @selector(setApplicationIconData:badgeText:appProcessId:)])
	{
	  [gsim setApplicationIconData: data
			     badgeText: badgeText
			  appProcessId: appId];
	  sent = YES;
	}
    }
  NS_HANDLER
    {
      GSLostIconManager();
    }
  NS_ENDHANDLER

  return sent;
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
      NSNumber *winNumObject;

      NSConvertWindowNumberToGlobal([window windowNumber], &winNum);
      NS_DURING
	{
	  iconRect = [gsim setWindow: winNum
			appProcessId: appId];
	  added = YES;
	}
      NS_HANDLER
	{
	  GSLostIconManager();
	  iconRect = [window frame];
	  iconRect.size = [GSCurrentServer() iconSize];
	}
      NS_ENDHANDLER

      if (added == YES)
	{
	  winNumObject = [NSNumber numberWithUnsignedInt: winNum];
	  if (registeredIcons == nil)
	    {
	      registeredIcons = [[NSMutableSet alloc] initWithCapacity: 1];
	    }
	  [registeredIcons addObject: winNumObject];
	}
    }
  else
    {
      iconRect = [window frame];
      iconRect.size = [GSCurrentServer() iconSize];
    }

  return iconRect;
}
