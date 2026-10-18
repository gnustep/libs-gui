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

/*
 * GSIconManager is the private distributed-object protocol used between
 * gui/AppKit clients and an optional external icon manager process registered
 * as "GSIconManager".
 *
 * The client side of the conversation is deliberately hidden behind the C
 * functions declared in GSIconManager.h:
 *
 *   - On first use, the client lazily looks up the registered NSConnection
 *     root proxy and records the application's process id.
 *   - When an application icon window or a miniwindow needs placement,
 *     GSGetIconFrame() sends -setWindow:appProcessId:.  The manager records
 *     the global window number and returns the frame where the client should
 *     put that icon window.
 *   - When a registered icon/miniwindow goes away, GSRemoveIcon() sends
 *     -removeWindow:.  The client tracks which windows it registered so it
 *     only removes windows the manager knows about.
 *   - When AppKit needs the icon size, GSGetIconSize() asks the manager via
 *     -getSizeWindow.  Without a manager it falls back to the display server's
 *     icon size.
 *   - When the app icon or NSDockTile badge changes, GSUpdateIconManager()
 *     converts the image to TIFF data and sends
 *     -setApplicationIconData:badgeText:appProcessId:.  The last icon payload
 *     is cached so a newly reconnected manager can be brought up to date.
 *   - User-attention requests are forwarded, when supported by the manager,
 *     with -requestUserAttention:appProcessId: and
 *     -cancelUserAttentionRequest:appProcessId:.
 *
 * All messages to the remote object are treated as best-effort.  If lookup
 * fails, GSUseIconManager has not been explicitly enabled, the connection
 * dies, or a remote message raises, the client drops the proxy and keeps
 * running with local fallback behavior.  NSConnectionDidDieNotification is
 * observed so that a disappearing manager clears all registered icon state.
 * Reconnect attempts after repeated dock tile updates are throttled to avoid
 * repeatedly probing a missing service.
 */
@protocol GSIconManager <NSObject>
 - (NSRect) setWindow: (unsigned int)aWindowNumber appProcessId: (int)aProcessId;
 - (void) removeWindow: (unsigned int)aWindowNumber;
 - (NSSize) getSizeWindow;
 - (void) setApplicationIconData: (NSData *)data
                       badgeText: (NSString *)badgeText
                    appProcessId: (int)aProcessId;
 - (void) requestUserAttention: (NSInteger)requestType
		   appProcessId: (int)aProcessId;
 - (void) cancelUserAttentionRequest: (NSInteger)request
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

  if ([defaults boolForKey: @"GSUseIconManager"])
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

  if (gsim && window)
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

void
GSRequestUserAttention(NSUInteger requestType)
{
  checkVerify();

  if (gsim == nil)
    {
      return;
    }

  NS_DURING
    {
      if ([gsim respondsToSelector: @selector(requestUserAttention:appProcessId:)])
	{
	  [gsim requestUserAttention: requestType
			appProcessId: appId];
	}
    }
  NS_HANDLER
    {
      GSLostIconManager();
    }
  NS_ENDHANDLER
}

void
GSCancelUserAttentionRequest(NSInteger request)
{
  checkVerify();

  if (gsim == nil)
    {
      return;
    }

  NS_DURING
    {
      if ([gsim respondsToSelector: @selector(cancelUserAttentionRequest:appProcessId:)])
	{
	  [gsim cancelUserAttentionRequest: request
			      appProcessId: appId];
	}
    }
  NS_HANDLER
    {
      GSLostIconManager();
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
