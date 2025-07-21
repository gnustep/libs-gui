/** <title>NSAlert</title>

   <abstract>Encapsulate an alert panel</abstract>

   Copyright <copy>(C) 2004 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: July 2004

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

/*
 *  Class: NSAlert
 *  Description: Encapsulates and manages alert panels for displaying messages to the user.
 *
 *  This class provides methods to configure and display alerts with customizable buttons,
 *  informative and message text, icons, and style. Alerts can be presented modally or as sheets.
 *
 *  Instance Variables:
 *    _informative_text - Supplementary information displayed in the alert.
 *    _message_text     - Primary message displayed in bold.
 *    _icon             - Icon shown in the alert panel.
 *    _buttons          - List of buttons presented to the user.
 *    _help_anchor      - Identifier for associated help documentation.
 *    _window           - Window used for sheet presentation.
 *    _delegate         - Delegate receiving alert-related callbacks.
 *    _style            - Style of alert (warning, informational, critical).
 *    _shows_help       - Indicates if the Help button is shown.
 *    _modalDelegate    - Modal delegate handling sheet callbacks.
 *    _didEndSelector   - Selector called when sheet ends.
 *    _result           - Result of the modal session.
 *
 *  Usage:
 *    Example: Displaying a modal alert
 *      NSAlert *alert = [NSAlert alertWithMessageText:@"Confirm"
 *                                  defaultButton:@"OK"
 *                                alternateButton:@"Cancel"
 *                                    otherButton:nil
 *                  informativeTextWithFormat:@"Are you sure you want to proceed?"];
 *      NSInteger result = [alert runModal];
 *
 *    Example: Displaying an alert as a sheet
 *      [alert beginSheetModalForWindow:mainWindow
 *                        modalDelegate:self
 *                       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
 *                          contextInfo:nil];
 *
 *    Example: Handling Help button via delegate
 *      - (BOOL)alertShowHelp:(NSAlert *)alert {
 *        [[NSHelpManager sharedHelpManager] openHelpAnchor:@"exampleHelp" inBook:nil];
 *        return YES;
 *      }
 *
 *  Button Roles:
 *    Default Button   - Represents the primary affirmative action (e.g., "OK", "Yes").
 *    Alternate Button - Represents a secondary option (e.g., "Cancel", "No").
 *    Other Button     - Optional extra option (e.g., "More Info"). Can be nil.
 *
 *  Alert Styles:
 *    NSWarningAlertStyle       - Used for warnings that require user acknowledgment.
 *    NSInformationalAlertStyle - Used for informative messages without critical implications.
 *    NSCriticalAlertStyle      - Used for serious errors requiring immediate attention.
 */

#ifndef _GNUstep_H_NSAlert
#define _GNUstep_H_NSAlert
#import <AppKit/NSWindow.h>
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>

@class NSArray;
@class NSError;
@class NSString;
@class NSMutableArray;
@class NSButton;
@class NSImage;
@class NSWindow;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)

enum _NSAlertStyle {
  NSWarningAlertStyle = 0,
  NSInformationalAlertStyle = 1,
  NSCriticalAlertStyle = 2
};
typedef NSUInteger NSAlertStyle;

APPKIT_EXPORT_CLASS
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
  id _modalDelegate;
  SEL _didEndSelector;
  NSInteger _result;
}

#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 *  Creates and returns an alert initialized with the given error's description.
 */
+ (NSAlert *) alertWithError: (NSError *)error;
#endif
/**
 *  Creates and returns a fully initialized alert with a title, button labels,
 *  and informative text formatted with optional arguments.
 */
+ (NSAlert *) alertWithMessageText: (NSString *)messageTitle
		     defaultButton: (NSString *)defaultButtonTitle
		   alternateButton: (NSString *)alternateButtonTitle
		       otherButton: (NSString *)otherButtonTitle
	 informativeTextWithFormat: (NSString *)format, ...;


/**
 *  Adds a button with the specified title to the alert.
 */
- (NSButton *) addButtonWithTitle: (NSString *)aTitle;

/**
 *  Returns the alert style.
 */
- (NSAlertStyle) alertStyle;

/**
 *  Presents the alert as a sheet for the specified window.
 *  Calls the delegate's selector when the alert is dismissed.
 */
- (void) beginSheetModalForWindow: (NSWindow *)window
		    modalDelegate: (id)delegate
		   didEndSelector: (SEL)didEndSelector
		      contextInfo: (void *)contextInfo;

/**
 *  Returns the array of buttons currently displayed in the alert.
 */
- (NSArray *) buttons;

/**
 *  Returns the delegate for the alert.
 */
- (id) delegate;

/**
 *  Returns the help anchor identifier.
 */
- (NSString *) helpAnchor;

/**
 *  Returns the icon associated with the alert.
 */
- (NSImage *) icon;

/**
 *  Returns the informative text displayed in the alert.
 */
- (NSString *) informativeText;

/**
 *  Returns the primary message text displayed in the alert.
 */
- (NSString *) messageText;

/**
 *  Runs the alert as an application-modal dialog.
 *  Returns the response code.
 */
- (NSInteger) runModal;

/**
 *  Sets the alert style.
 */
- (void) setAlertStyle: (NSAlertStyle)style;

/**
 *  Sets the delegate that handles alert behavior.
 */
- (void) setDelegate: (id)delegate;

/**
 *  Sets the help anchor used to link help information.
 */
- (void) setHelpAnchor: (NSString *)anchor;

/**
 *  Sets the icon displayed in the alert.
 */
- (void) setIcon: (NSImage *)icon;

/**
 *  Sets the informative text for the alert.
 */
- (void) setInformativeText: (NSString *)informativeText;

/**
 *  Sets the message text for the alert.
 */
- (void) setMessageText: (NSString *)messageText;

/**
 *  Sets whether the alert displays a Help button.
 */
- (void) setShowsHelp: (BOOL)showsHelp;

/**
 *  Returns whether the alert displays a Help button.
 */
- (BOOL) showsHelp;

/**
 *  Returns the internal window used by the alert.
 */
- (id) window;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_9, GS_API_LATEST)
/**
 *  Presents the alert as a sheet using a completion handler.
 */
- (void) beginSheetModalForWindow:(NSWindow *)sheetWindow
		completionHandler:(GSNSWindowDidEndSheetCallbackBlock)handler;
#endif

@end

/*
 *  Protocol: NSAlertDelegate
 *  Description: Declares optional delegate method for handling help button actions.
 */

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
@protocol NSAlertDelegate <NSObject>
#if OS_API_VERSION(MAC_OS_X_VERSION_10_6, GS_API_LATEST) && GS_PROTOCOLS_HAVE_OPTIONAL
@optional
#else
@end
@interface NSObject (NSAlertDelegate)
#endif
/**
 *  Called when the user clicks the Help button.
 *  Return YES to indicate the help was shown.
 */
- (BOOL) alertShowHelp: (NSAlert *)alert;
@end
#endif

#endif /* MAC_OS_X_VERSION_10_3 */
#endif /* _GNUstep_H_NSAlert */
