/** <title>NSAlert</title>

   <abstract>Encapsulate an alert panel</abstract>

   Copyright <copy>(C) 2004 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: July 2004

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
   51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_NSAlert
#define _GNUstep_H_NSAlert
#import <GNUstepBase/GSVersionMacros.h>

#include <Foundation/NSObject.h>

@class NSArray;
@class NSString;
@class NSMutableArray;
@class NSButton;
@class NSImage;
@class NSWindow;

typedef enum _NSAlertStyle { 
  NSWarningAlertStyle = 0, 
  NSInformationalAlertStyle = 1, 
  NSCriticalAlertStyle = 2 
} NSAlertStyle;

enum { 
  NSAlertFirstButtonReturn = 1000,
  NSAlertSecondButtonReturn = 1001,
  NSAlertThirdButtonReturn = 1002
};

@interface NSAlert : NSObject 
{
  @private
  NSString *_informative_text;
  NSString *_message_text;
  NSImage *_icon;
  NSMutableArray *_buttons;
  NSString *_help_anchor;
  NSWindow *_window;
  id _delegate;
  NSAlertStyle _style;
  BOOL _shows_help;
  int	_result;
}

+ (NSAlert *) alertWithMessageText: (NSString *)messageTitle
		     defaultButton: (NSString *)defaultButtonTitle
		   alternateButton: (NSString *)alternateButtonTitle
		       otherButton: (NSString *)otherButtonTitle
	 informativeTextWithFormat: (NSString *)format, ...;


- (NSButton *) addButtonWithTitle: (NSString *)aTitle;
- (NSAlertStyle) alertStyle;
- (void) beginSheetModalForWindow: (NSWindow *)window
		    modalDelegate: (id)delegate
		   didEndSelector: (SEL)didEndSelector
		      contextInfo: (void *)contextInfo;
- (NSArray *) buttons;
- (id) delegate;
- (NSString *) helpAnchor;
- (NSImage *) icon;
- (NSString *) informativeText;
- (NSString *) messageText;
- (int) runModal;
- (void) setAlertStyle: (NSAlertStyle)style;
- (void) setDelegate: (id)delegate;
- (void) setHelpAnchor: (NSString *)anchor;
- (void) setIcon: (NSImage *)icon;
- (void) setInformativeText: (NSString *)informativeText;
- (void) setMessageText: (NSString *)messageText;
- (void) setShowsHelp: (BOOL)showsHelp;
- (BOOL) showsHelp;
- (id) window;

@end


/*
 * Implemented by the delegate
 */

#ifdef GNUSTEP
@interface NSObject (NSAlertDelegate)
- (BOOL) alertShowHelp: (NSAlert *)alert;
@end
#endif

#endif /* _GNUstep_H_NSAlert */
