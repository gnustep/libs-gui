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
Gui_AGSDOC_FILES = \
	NSActionCell.h \
	NSAffineTransform.h \
	NSApplication.h \
	NSAttributedString.h \
	NSBezierPath.h \
	NSBitmapImageRep.h \
	NSBox.h \
	NSBrowser.h \
	NSBrowserCell.h \
	NSButton.h \
	NSButtonCell.h \
	NSCachedImageRep.h \
	NSCell.h \
	NSClipView.h \
	NSColor.h \
	NSColorList.h \
	NSColorPanel.h \
	NSColorPicker.h \
	NSColorWell.h \
	NSComboBox.h \
	NSComboBoxCell.h \
	NSControl.h \
	NSCursor.h \
	NSCustomImageRep.h \
	NSDocument.h \
	NSDocumentController.h \
	NSEPSImageRep.h \
	NSEvent.h \
	NSFileWrapper.h \
	NSFont.h \
	NSFontManager.h \
	NSFontPanel.h \
	NSForm.h \
	NSFormCell.h \
	NSGraphicsContext.h \
	NSHelpManager.h \
	NSImage.h \
	NSImageCell.h \
	NSImageRep.h \
	NSImageView.h \
	NSInputManager.h \
	NSInputServer.h \
	NSLayoutManager.h \
	NSMatrix.h \
	NSMenu.h \
	NSMenuItemCell.h \
	NSMenuView.h \
	NSOpenPanel.h \
	NSPageLayout.h \
	NSPanel.h \
	NSParagraphStyle.h \
	NSPasteboard.h \
	NSPopUpButton.h \
	NSPopUpButtonCell.h \
	NSPrintInfo.h \
	NSPrintOperation.h \
	NSPrintPanel.h \
	NSPrinter.h \
	NSProgressIndicator.h \
	NSResponder.h \
	NSRulerMarker.h \
	NSRulerView.h \
	NSSavePanel.h \
	NSScreen.h \
	NSScrollView.h \
	NSScroller.h \
	NSSecureTextField.h \
	NSSlider.h \
	NSSliderCell.h \
	NSSpellChecker.h \
	NSSpellServer.h \
	NSSplitView.h \
	NSTabView.h \
	NSTabViewItem.h \
	NSTableHeaderCell.h \
	NSTableHeaderView.h \
	NSTableView.h \
	NSText.h \
	NSTextContainer.h \
	NSTextField.h \
	NSTextFieldCell.h \
	NSTextStorage.h \
	NSTextView.h \
	NSView.h \
	NSWindow.h \
	NSWindowController.h \
	NSWorkspace.h

Gui_AGSDOC_FLAGS = -HeaderDirectory ../../Headers/AppKit -Declared AppKit \
	-SourceDirectory ../../Source

Gui_DOC_INSTALL_DIR = Developer/Gui/Reference

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/documentation.make

-include GNUmakefile.postamble
