#
#  Main makefile for GNUstep GUI Library
#  Copyright (C) 1997 Free Software Foundation, Inc.
#
#  Author: Scott Christley <scottc@net-community.com>
#
#  This file is part of the GNUstep GUI Library.
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
#  If you are interested in a warranty or support for this source code,
#  contact Scott Christley at scottc@net-community.com
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; see the file COPYING.LIB.
#  If not, write to the Free Software Foundation,
#  59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=../gui.make
include $(GNUSTEP_MAKEFILES)/common.make

include ../Version
include ../config.make

# The library to be compiled
LIBRARY_NAME = libgnustep-gui

# The Objective-C source files to be compiled
libgnustep-gui_C_FILES = \
Parsers/rtfGrammer.tab.c \
Parsers/rtfScanner.c

# The Objective-C source files to be compiled
libgnustep-gui_OBJC_FILES = Functions.m \
NSActionCell.m \
NSAffineTransform.m \
NSApplication.m \
NSAttributedString.m \
NSBezierPath.m \
NSBitmapImageRep.m \
NSBox.m \
NSBrowser.m \
NSBrowserCell.m \
NSBundleAdditions.m \
NSButton.m \
NSButtonCell.m \
NSCStringText.m \
NSCachedImageRep.m \
NSCell.m \
NSClipView.m \
NSColor.m \
NSColorList.m \
NSColorPanel.m \
NSColorPicker.m \
NSColorWell.m \
NSComboBox.m \
NSComboBoxCell.m \
NSControl.m \
NSCursor.m \
NSCustomImageRep.m \
NSDataLink.m \
NSDataLinkManager.m \
NSDataLinkPanel.m \
NSDocument.m \
NSDocumentController.m \
NSEPSImageRep.m \
NSEvent.m \
NSFileWrapper.m \
NSFont.m \
NSFontManager.m \
NSFontPanel.m \
NSForm.m \
NSFormCell.m \
NSGraphicsContext.m \
NSHelpPanel.m \
NSHelpManager.m \
NSImage.m \
NSImageCell.m \
NSImageRep.m \
NSImageView.m \
NSInterfaceStyle.m \
NSLayoutManager.m \
NSMatrix.m \
NSMenu.m \
NSMenuView.m \
NSMenuItem.m \
NSMenuItemCell.m \
NSOpenPanel.m \
NSObjectProtocols.m \
NSPageLayout.m \
NSPanel.m \
NSParagraphStyle.m \
NSPopUpButton.m \
NSPopUpButtonCell.m \
NSPrinter.m \
NSPrintInfo.m \
NSPrintOperation.m \
NSPrintPanel.m \
NSProgressIndicator.m \
NSResponder.m \
NSSavePanel.m \
NSScreen.m \
NSScroller.m \
NSScrollView.m \
NSSecureTextField.m \
NSSelection.m \
NSSlider.m \
NSSliderCell.m \
NSSpellChecker.m \
NSSpellServer.m \
NSSplitView.m \
NSStringDrawing.m \
NSTabView.m \
NSTabViewItem.m \
NSTableColumn.m \
NSTableHeaderView.m \
NSTableHeaderCell.m \
NSTableView.m \
NSText.m \
NSTextAttachment.m \
NSTextContainer.m \
NSTextField.m \
NSTextFieldCell.m \
NSTextStorage.m \
NSTextView.m \
NSView.m \
NSWindow.m \
NSWindowController.m \
NSWorkspace.m \
GSComboSupport.m \
GSHelpManagerPanel.m \
GSInfoPanel.m \
GSTextStorage.m \
GSTrackingRect.m \
GSServicesManager.m \
tiff.m \
externs.m \
GSFontInfo.m \
GSTable.m \
GSHbox.m \
GSVbox.m \
GSSimpleLayoutManager.m \
Parsers/attributedStringConsumer.m \
Parsers/RTFProducer.m

ifneq ($(FOUNDATION_LIB), fd)
libgnustep-gui_OBJC_FILES += NSPasteboard.m
endif

libgnustep-gui_HEADER_FILES_DIR = ../Headers/AppKit
libgnustep-gui_HEADER_FILES_INSTALL_DIR = /AppKit

libgnustep-gui_HEADER_FILES = \
AppKit.h \
GSVersion.h \
AppKitExceptions.h \
DPSOperators.h \
GMAppKit.h \
GMArchiver.h \
GSFontInfo.h \
GSInfoPanel.h \
GSMethodTable.h \
GSPasteboardServer.h \
GSServicesManager.h \
GSTrackingRect.h \
GSHelpManagerPanel.h \
GSTable.h \
GSHbox.h \
GSVbox.h \
IMConnectors.h \
IMCustomObject.h \
IMLoading.h \
NSActionCell.h \
NSAffineTransform.h \
NSApplication.h \
NSAttributedString.h \
NSBezierPath.h \
NSBox.h \
NSBitmapImageRep.h \
NSBrowser.h \
NSBrowserCell.h \
NSButton.h \
NSButtonCell.h \
NSCStringText.h \
NSCachedImageRep.h \
NSCell.h \
NSClipView.h \
NSColor.h \
NSColorList.h \
NSColorPanel.h \
NSColorPicker.h \
NSColorPicking.h \
NSColorWell.h \
NSComboBox.h \
NSComboBoxCell.h \
NSControl.h \
NSCursor.h \
NSCustomImageRep.h \
NSDataLink.h \
NSDataLinkManager.h \
NSDataLinkPanel.h \
NSDocument.h \
NSDocumentController.h \
NSDocumentFrameworkPrivate.h \
NSDragging.h \
NSEPSImageRep.h \
NSEvent.h \
NSFileWrapper.h \
NSFont.h \
NSFontManager.h \
NSFontPanel.h \
NSForm.h \
NSFormCell.h \
NSGraphics.h \
NSGraphicsContext.h \
NSHelpPanel.h \
NSHelpManager.h \
NSImage.h \
NSImageCell.h \
NSImageRep.h \
NSImageView.h \
NSInterfaceStyle.h \
NSLayoutManager.h \
NSMatrix.h \
NSMenu.h \
NSMenuItem.h \
NSMenuItemCell.h \
NSMenuView.h \
NSNibConnector.h \
NSNibDeclarations.h \
NSNibLoading.h \
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
NSSelection.h \
NSSlider.h \
NSSliderCell.h \
NSText.h \
NSSpellChecker.h \
NSSpellProtocol.h \
NSSpellServer.h \
NSSplitView.h \
NSStringDrawing.h \
NSTabView.h \
NSTabViewItem.h \
NSTableColumn.h \
NSTableHeaderCell.h \
NSTableHeaderView.h \
NSTableView.h \
NSTextAttachment.h \
NSTextContainer.h \
NSTextField.h \
NSTextFieldCell.h \
NSTextStorage.h \
NSTextView.h \
NSUserInterfaceValidation.h \
NSView.h \
NSWindow.h \
NSWindowController.h \
NSWorkspace.h \
PSOperators.h \
nsimage-tiff.h

include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/library.make

include GNUmakefile.postamble
