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

include $(GNUSTEP_MAKEFILES)/common.make

include ../Version

# The library to be compiled
LIBRARY_NAME=libgnustep-gui

# The Objective-C source files to be compiled
libgnustep-gui_OBJC_FILES = Functions.m \
NSActionCell.m \
NSAffineTransform.m \
NSApplication.m \
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
NSControl.m \
NSCursor.m \
NSCustomImageRep.m \
NSDataLink.m \
NSDataLinkManager.m \
NSDataLinkPanel.m \
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
NSImage.m \
NSImageCell.m \
NSImageRep.m \
NSImageView.m \
NSInterfaceStyle.m \
NSMatrix.m \
NSMenu.m \
NSMenuItem.m \
NSOpenPanel.m \
NSPageLayout.m \
NSPanel.m \
NSParagraphStyle.m \
NSPrinter.m \
NSPrintInfo.m \
NSPrintOperation.m \
NSPrintPanel.m \
NSPopUpButton.m \
NSResponder.m \
NSSavePanel.m \
NSScreen.m \
NSScroller.m \
NSScrollView.m \
NSSelection.m \
NSSlider.m \
NSSliderCell.m \
NSSpellChecker.m \
NSSpellServer.m \
NSSplitView.m \
NSStringDrawing.m \
NSText.m \
NSTextContainer.m \
NSTextField.m \
NSTextFieldCell.m \
NSTextStorage.m \
NSTextView.m \
NSView.m \
NSWindow.m \
NSWorkspace.m \
GSTrackingRect.m \
GSServicesManager.m \
tiff.m \
externs.m

ifneq ($(FOUNDATION_LIB), fd)
libgnustep-gui_OBJC_FILES += NSPasteboard.m
endif

libgnustep-gui_HEADER_FILES_DIR = ../Headers
libgnustep-gui_HEADER_FILES_INSTALL_DIR = /gnustep/gui

libgnustep-gui_HEADER_FILES = \
AppKit/AppKit.h \
AppKit/NSActionCell.h \
AppKit/NSAffineTransform.h \
AppKit/NSApplication.h \
AppKit/NSBitmapImageRep.h \
AppKit/NSBox.h \
AppKit/NSBrowser.h \
AppKit/NSBrowserCell.h \
AppKit/NSButton.h \
AppKit/NSButtonCell.h \
AppKit/NSCStringText.h \
AppKit/NSCachedImageRep.h \
AppKit/NSCell.h \
AppKit/NSClipView.h \
AppKit/NSColor.h \
AppKit/NSColorList.h \
AppKit/NSColorPanel.h \
AppKit/NSColorPicker.h \
AppKit/NSColorPicking.h \
AppKit/NSColorWell.h \
AppKit/NSControl.h \
AppKit/NSCursor.h \
AppKit/NSCustomImageRep.h \
AppKit/NSDataLink.h \
AppKit/NSDataLinkManager.h \
AppKit/NSDataLinkPanel.h \
AppKit/NSDragging.h \
AppKit/NSEPSImageRep.h \
AppKit/NSEvent.h \
AppKit/NSFileWrapper.h \
AppKit/NSFont.h \
AppKit/NSFontManager.h \
AppKit/NSFontPanel.h \
AppKit/NSForm.h \
AppKit/NSFormCell.h \
AppKit/NSGraphics.h \
AppKit/NSGraphicsContext.h \
AppKit/NSHelpPanel.h \
AppKit/NSImage.h \
AppKit/NSImageCell.h \
AppKit/NSImageRep.h \
AppKit/NSImageView.h \
AppKit/NSInterfaceStyle.h \
AppKit/NSLayoutManager.h \
AppKit/NSMatrix.h \
AppKit/NSMenu.h \
AppKit/NSMenuItem.h \
AppKit/NSNibLoading.h \
AppKit/NSNibDeclarations.h \
AppKit/NSOpenPanel.h \
AppKit/NSPageLayout.h \
AppKit/NSPanel.h \
AppKit/NSParagraphStyle.h \
AppKit/NSPasteboard.h \
AppKit/NSPopUpButton.h \
AppKit/NSPrintInfo.h \
AppKit/NSPrintOperation.h \
AppKit/NSPrintPanel.h \
AppKit/NSPrinter.h \
AppKit/NSResponder.h \
AppKit/NSRulerMarker.h \
AppKit/NSRulerView.h \
AppKit/NSSavePanel.h \
AppKit/NSScreen.h \
AppKit/NSScrollView.h \
AppKit/NSScroller.h \
AppKit/NSSelection.h \
AppKit/NSSlider.h \
AppKit/NSSliderCell.h \
AppKit/NSSpellChecker.h \
AppKit/NSSpellProtocol.h \
AppKit/NSSpellServer.h \
AppKit/NSSplitView.h \
AppKit/NSStringDrawing.h \
AppKit/NSText.h \
AppKit/NSTextAttachment.h \
AppKit/NSTextContainer.h \
AppKit/NSTextField.h \
AppKit/NSTextFieldCell.h \
AppKit/NSTextStorage.h \
AppKit/NSTextView.h \
AppKit/NSView.h \
AppKit/NSWindow.h \
AppKit/NSWorkspace.h \
AppKit/GSTrackingRect.h \
AppKit/nsimage-tiff.h \
AppKit/GSMethodTable.h \
AppKit/DPSOperators.h \
AppKit/PSOperators.h \
AppKit/GSPasteboardServer.h \
AppKit/GSServicesManager.h

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/library.make

-include GNUmakefile.postamble
