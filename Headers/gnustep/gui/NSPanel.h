/* 
   NSPanel.h

   Panel window class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#ifndef _GNUstep_H_NSPanel
#define _GNUstep_H_NSPanel

#include <AppKit/NSWindow.h>

@class NSString;

enum {
  NSUtilityWindowMask = 16,
  NSDocModalWindowMask = 32
};

enum {
  NSOKButton = 1,
  NSCancelButton = 0
};

enum {
  NSAlertDefaultReturn = 1,
  NSAlertAlternateReturn = 0,
  NSAlertOtherReturn = -1,
  NSAlertErrorReturn  = -2
};

// from MacOS X docs
#define NSAlertDefault NSAlertDefaultReturn
#define NSAlertAlternate NSAlertAlternateReturn
#define NSAlertOther NSAlertOtherReturn

#ifndef	STRICT_OPENSTEP
#define	NS_ALERTDEFAULT		NSAlertDefaultReturn
#define	NS_ALERTALTERNATE	NSAlertAlternateReturn
#define	NS_ALERTOTHER		NSAlertOtherReturn
#define	NS_ALERTERROR		NSAlertErrorReturn
#endif

@interface NSPanel : NSWindow
{
  // Think of the following as BOOL ivars
#define _becomesKeyOnlyIfNeeded _f.subclass_bool_one
#define _isFloatingPanel _f.subclass_bool_two
#define _worksWhenModal _f.subclass_bool_three
}

//
// Determining the Panel Behavior 
//
- (BOOL)becomesKeyOnlyIfNeeded;
- (BOOL)isFloatingPanel;
- (void)setBecomesKeyOnlyIfNeeded:(BOOL)flag;
- (void)setFloatingPanel:(BOOL)flag;
- (void)setWorksWhenModal:(BOOL)flag;
- (BOOL)worksWhenModal;

@end

//
// Create an Attention Panel without Running It Yet
//
id NSGetAlertPanel(NSString *title,
                   NSString *msg,
                   NSString *defaultButton,
                   NSString *alternateButton, 
                   NSString *otherButton, ...);

#ifndef	STRICT_OPENSTEP
id NSGetCriticalAlertPanel(NSString *title,
			   NSString *msg,
			   NSString *defaultButton,
			   NSString *alternateButton, 
			   NSString *otherButton, ...);

id NSGetInformationalAlertPanel(NSString *title,
				NSString *msg,
				NSString *defaultButton,
				NSString *alternateButton, 
				NSString *otherButton, ...);
#endif

//
// Create and Run an Attention Panel
//
int NSRunAlertPanel(NSString *title,
                    NSString *msg,
                    NSString *defaultButton,
                    NSString *alternateButton,
                    NSString *otherButton, ...);

#ifndef	STRICT_OPENSTEP
int NSRunCriticalAlertPanel(NSString *title,
			    NSString *msg,
			    NSString *defaultButton,
			    NSString *alternateButton, 
			    NSString *otherButton, ...);

int NSRunInformationalAlertPanel(NSString *title,
				 NSString *msg,
				 NSString *defaultButton,
				 NSString *alternateButton, 
				 NSString *otherButton, ...);
#endif

#ifndef	STRICT_MACOS_X
int NSRunLocalizedAlertPanel(NSString *table,
                             NSString *title,
                             NSString *msg,
                             NSString *defaultButton, 
                             NSString *alternateButton, 
                             NSString *otherButton, ...);
#endif

#ifndef	STRICT_OPENSTEP
//
// New alert interface of Mac OS X
//
void NSBeginAlertSheet(NSString *title, 
		       NSString *defaultButton, 
		       NSString *alternateButton, 
		       NSString *otherButton, 
		       NSWindow *docWindow, 
		       id modalDelegate, 
		       SEL willEndSelector, 
		       SEL didEndSelector, 
		       void *contextInfo, 
		       NSString *msg, ...);

void NSBeginCriticalAlertSheet(NSString *title, 
			       NSString *defaultButton, 
			       NSString *alternateButton, 
			       NSString *otherButton, 
			       NSWindow *docWindow, 
			       id modalDelegate, 
			       SEL willEndSelector, 
			       SEL didEndSelector, 
			       void *contextInfo, 
			       NSString *msg, ...);

void NSBeginInformationalAlertSheet(NSString *title, 
				    NSString *defaultButton, 
				    NSString *alternateButton, 
				    NSString *otherButton,
				    NSWindow *docWindow, 
				    id modalDelegate, 
				    SEL willEndSelector, 
				    SEL didEndSelector, 
				    void *contextInfo, 
				    NSString *msg, ...);

#endif

//
// Release an Attention Panel
//
void NSReleaseAlertPanel(id panel);

#endif // _GNUstep_H_NSPanel
