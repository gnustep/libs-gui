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
}

+ (NSAlert *)alertWithMessageText:(NSString *)messageTitle
		    defaultButton:(NSString *)defaultButtonTitle
		  alternateButton:(NSString *)alternateButtonTitle
		      otherButton:(NSString *)otherButtonTitle
	informativeTextWithFormat:(NSString *)format, ...;

//
// Alert text
//
- (void)setInformativeText:(NSString *)informativeText;
- (NSString *)informativeText;
- (void)setMessageText:(NSString *)messageText;
- (NSString *)messageText;

//
// Alert icon
//
- (void)setIcon:(NSImage *)icon;
- (NSImage *)icon;

//
// Buttons
//
- (NSButton *)addButtonWithTitle:(NSString *)aTitle;
- (NSArray *)buttons;

//
// Help
//
- (void)setShowsHelp:(BOOL)showsHelp;
- (BOOL)showsHelp;
- (void)setHelpAnchor:(NSString *)anchor;
- (NSString *)helpAnchor;

//
// Alert style
//
- (void)setAlertStyle:(NSAlertStyle)style;
- (NSAlertStyle)alertStyle;

//
// Delegate
//
- (void)setDelegate:(id)delegate;
- (id)delegate;

//
// Running the alert
//
- (int)runModal;
- (void)beginSheetModalForWindow:(NSWindow *)window
		   modalDelegate:(id)delegate
		  didEndSelector:(SEL)didEndSelector
		     contextInfo:(void *)contextInfo;

- (id)window;

@end


/*
 * Implemented by the delegate
 */

#ifdef GNUSTEP
@interface NSObject (NSAlertDelegate)
- (BOOL)alertShowHelp:(NSAlert *)alert;
@end
#endif

#endif /* _GNUstep_H_NSAlert */
