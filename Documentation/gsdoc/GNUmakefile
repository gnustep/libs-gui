#
#  doc makefile for the GNUstep Gui Library
#  Copyright (C) 2000 Free Software Foundation, Inc.
#
#  Written by:	Richard Frith-Macdonald <rfm@gnu.org>
#
#  This file is part of the GNUstep Base Library.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; if not, write to the Free
#  Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.

# Install into the system root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=../../gui.make
include $(GNUSTEP_MAKEFILES)/common.make

# The documents to be generated
DOCUMENT_NAME = Gui

Gui_GSDOC_FILES = Gui.gsdoc \
	$(Gui_AUTOGSDOC_FILES) \
	Introduction.gsdoc \
	DefaultsSummary.gsdoc \
	NSBundleAdditions.gsdoc \
	NSCoderAdditions.gsdoc \
	NSMenuItem.gsdoc \
	NSMutableAttributedStringAdditions.gsdoc \
	NSMutableParagraphStyle.gsdoc \
	NSPICTImageRep.gsdoc \
	NSSecureTextFieldCell.gsdoc \
	NSStringAdditions.gsdoc \
	NSTableColumn.gsdoc \
	NSTextAttachment.gsdoc \
	NSTextAttachmentCell.gsdoc \
	NSTextTab.gsdoc

# These gsdoc files are automatically generated from class source/headers
Gui_AUTOGSDOC_FILES = \
	NSActionCell.gsdoc \
	NSAffineTransform.gsdoc \
	NSApplication.gsdoc \
	NSAttributedString.gsdoc \
	NSBezierPath.gsdoc \
	NSBitmapImageRep.gsdoc \
	NSBox.gsdoc \
	NSBrowser.gsdoc \
	NSBrowserCell.gsdoc \
	NSButton.gsdoc \
	NSButtonCell.gsdoc \
	NSCachedImageRep.gsdoc \
	NSCell.gsdoc \
	NSClipView.gsdoc \
	NSColor.gsdoc \
	NSColorList.gsdoc \
	NSColorPanel.gsdoc \
	NSColorPicker.gsdoc \
	NSColorWell.gsdoc \
	NSComboBox.gsdoc \
	NSComboBoxCell.gsdoc \
	NSControl.gsdoc \
	NSCursor.gsdoc \
	NSCustomImageRep.gsdoc \
	NSDocument.gsdoc \
	NSDocumentController.gsdoc \
	NSEPSImageRep.gsdoc \
	NSEvent.gsdoc \
	NSFileWrapper.gsdoc \
	NSFont.gsdoc \
	NSFontManager.gsdoc \
	NSFontPanel.gsdoc \
	NSForm.gsdoc \
	NSFormCell.gsdoc \
	NSGraphicsContext.gsdoc \
	NSHelpManager.gsdoc \
	NSImage.gsdoc \
	NSImageCell.gsdoc \
	NSImageRep.gsdoc \
	NSImageView.gsdoc \
	NSInputManager.gsdoc \
	NSInputServer.gsdoc \
	NSLayoutManager.gsdoc \
	NSMatrix.gsdoc \
	NSMenu.gsdoc \
	NSMenuItemCell.gsdoc \
	NSMenuView.gsdoc \
	NSOpenPanel.gsdoc \
	NSPageLayout.gsdoc \
	NSPanel.gsdoc \
	NSParagraphStyle.gsdoc \
	NSPasteboard.gsdoc \
	NSPopUpButton.gsdoc \
	NSPopUpButtonCell.gsdoc \
	NSPrintInfo.gsdoc \
	NSPrintOperation.gsdoc \
	NSPrintPanel.gsdoc \
	NSPrinter.gsdoc \
	NSProgressIndicator.gsdoc \
	NSResponder.gsdoc \
	NSRulerMarker.gsdoc \
	NSRulerView.gsdoc \
	NSSavePanel.gsdoc \
	NSScreen.gsdoc \
	NSScrollView.gsdoc \
	NSScroller.gsdoc \
	NSSecureTextField.gsdoc \
	NSSlider.gsdoc \
	NSSliderCell.gsdoc \
	NSSpellChecker.gsdoc \
	NSSpellServer.gsdoc \
	NSSplitView.gsdoc \
	NSTabView.gsdoc \
	NSTabViewItem.gsdoc \
	NSTableHeaderCell.gsdoc \
	NSTableHeaderView.gsdoc \
	NSTableView.gsdoc \
	NSText.gsdoc \
	NSTextContainer.gsdoc \
	NSTextField.gsdoc \
	NSTextFieldCell.gsdoc \
	NSTextStorage.gsdoc \
	NSTextView.gsdoc \
	NSView.gsdoc \
	NSWindow.gsdoc \
	NSWindowController.gsdoc \
	NSWorkspace.gsdoc

Gui_DOC_INSTALL_DIR = Developer/Gui/Reference

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/documentation.make

-include GNUmakefile.postamble
