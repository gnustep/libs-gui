/** <title>GSCharacterPanel</title>

    <abstract>Character palette panel for text input and Unicode character selection</abstract>

    GSCharacterPanel provides a user interface for browsing and selecting
    Unicode characters, special symbols, and text input methods. It serves
    as a character palette that allows users to insert characters that may
    not be easily accessible through their keyboard layout.

    The character panel features:
    * Unicode character browsing by category and script
    * Search functionality for finding specific characters
    * Recent and favorite character collections
    * Character information display including Unicode details
    * Integration with text input systems and text views

    This panel is particularly useful for:
    * Inserting symbols, mathematical characters, and special punctuation
    * Working with multilingual text and international scripts
    * Accessing extended character sets not available on the keyboard
    * Educational and reference purposes for Unicode exploration

    The GSCharacterPanel integrates with the standard AppKit text input
    system and can insert selected characters into any text-accepting
    control or view that supports text input.

    Copyright (C) 2011 Free Software Foundation, Inc.

    Written by:  Eric Wasylishen <ewasylishen@gmail.com>
    Date: June 2011

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

#ifndef _GNUstep_H_GSCharacterPanel
#define _GNUstep_H_GSCharacterPanel

#import <AppKit/NSPanel.h>

@class NSTableView;
@class NSSearchField;
@class NSIndexSet;

APPKIT_EXPORT_CLASS
@interface GSCharacterPanel : NSPanel
{
	NSTableView *table;
	NSSearchField *searchfield;

	NSIndexSet *assignedCodepoints;
	NSIndexSet *visibleCodepoints;
}

+ (GSCharacterPanel *) sharedCharacterPanel;

@end

#endif // _GNUstep_H_GSCharacterPanel

