#
#  Main makefile for GNUstep GUI Library
#  Copyright (C) 1997 Free Software Foundation, Inc.
#
#  Author: Scott Christley <scottc@net-community.com>
#
#  This file is part of the GNUstep GUI Library.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 3 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; see the file COPYING.LIB.
#  If not, see <http://www.gnu.org/licenses/> or write to the 
#  Free Software Foundation, 51 Franklin Street, Fifth Floor, 
#  Boston, MA 02110-1301, USA.

GNUSTEP_INSTALLATION_DOMAIN = SYSTEM

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=../gui.make
include $(GNUSTEP_MAKEFILES)/common.make

include ../Version
include ../config.make

# Interface version changes with each minor release
libgnustep-gui_INTERFACE_VERSION=${GNUSTEP_GUI_MAJOR_VERSION}.${GNUSTEP_GUI_MINOR_VERSION}

srcdir = .
PACKAGE_NAME = gnustep-gui
LIBRARY_VAR = GNUSTEP_GUI

# The library to be compiled
LIBRARY_NAME = libgnustep-gui

# The Objective-C source files to be compiled
libgnustep-gui_C_FILES =

# The Objective-C source files to be compiled
libgnustep-gui_OBJC_FILES = Functions.m \
NSActionCell.m \
NSAffineTransform.m \
NSAlert.m \
NSAnimation.m \
NSApplication.m \
NSArrayController.m \
NSAttributedString.m \
NSBezierPath.m \
NSBitmapImageRep.m \
NSBitmapImageRep+GIF.m \
NSBitmapImageRep+JPEG.m \
NSBitmapImageRep+PNG.m \
NSBitmapImageRep+PNM.m \
NSBox.m \
NSBrowser.m \
NSBrowserCell.m \
NSBundleAdditions.m \
NSButton.m \
NSButtonCell.m \
NSCachedImageRep.m \
NSCell.m \
NSClipView.m \
NSColor.m \
NSColorList.m \
NSColorPanel.m \
NSColorPicker.m \
NSColorSpace.m \
NSColorWell.m \
NSComboBox.m \
NSComboBoxCell.m \
NSControl.m \
NSController.m \
NSCursor.m \
NSCustomImageRep.m \
NSDataLink.m \
NSDataLinkManager.m \
NSDataLinkPanel.m \
NSDocument.m \
NSDocumentController.m \
NSDrawer.m \
NSEPSImageRep.m \
NSEvent.m \
NSFileWrapper.m \
NSFont.m \
NSFontDescriptor.m \
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
NSInputManager.m \
NSInputServer.m \
NSInterfaceStyle.m \
NSKeyValueBinding.m \
NSLayoutManager.m \
NSLevelIndicator.m \
NSLevelIndicatorCell.m \
NSMatrix.m \
NSMenu.m \
NSMenuView.m \
NSMenuItem.m \
NSMenuItemCell.m \
NSMovie.m \
NSMovieView.m \
NSNib.m \
NSNibBindingConnector.m \
NSNibAXAttributeConnector.m \
NSNibAXRelationshipConnector.m \
NSObjectController.m \
NSOpenGLContext.m \
NSOpenGLPixelFormat.m \
NSOpenGLView.m \
NSOpenPanel.m \
NSOutlineView.m \
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
NSRulerMarker.m \
NSRulerView.m \
NSSavePanel.m \
NSSearchField.m \
NSSearchFieldCell.m \
NSScreen.m \
NSScroller.m \
NSScrollView.m \
NSSecureTextField.m \
NSSelection.m \
NSSlider.m \
NSSliderCell.m \
NSSound.m  \
NSSpellChecker.m \
NSSplitView.m \
NSStepper.m \
NSStepperCell.m \
NSStringDrawing.m \
NSTabView.m \
NSTabViewItem.m \
NSTableColumn.m \
NSTableHeaderView.m \
NSTableHeaderCell.m \
NSTableView.m \
NSText.m \
NSTextAttachment.m \
NSTextBlock.m \
NSTextContainer.m \
NSTextField.m \
NSTextFieldCell.m \
NSTextList.m \
NSTextStorage.m \
NSTextTable.m \
NSTextTableBlock.m \
NSToolbar.m \
NSToolbarItem.m \
NSUserDefaultsController.m \
NSView.m \
NSWindow+Toolbar.m \
NSWindow.m \
NSWindowController.m \
NSWorkspace.m \
GSAnimator.m \
GSDisplayServer.m \
GSFusedSilica.m \
GSFusedSilicaContext.m \
GSHelpManagerPanel.m \
GSInfoPanel.m \
GSMemoryPanel.m \
GSSlideView.m \
GSTextStorage.m \
GSTrackingRect.m \
GSServicesManager.m \
tiff.m \
externs.m \
linking.m \
GSTheme.m \
GSDragView.m \
GSFontInfo.m \
GSTable.m \
GSHbox.m \
GSVbox.m \
GSKeyBindingAction.m \
GSKeyBindingTable.m \
NSTextView.m \
NSTextView_actions.m \
GSLayoutManager.m \
GSTypesetter.m \
GSHorizontalTypesetter.m \
GSNibTemplates.m \
GSNibCompatibility.m \
GSTitleView.m \
GSToolTips.m \
GSToolbar.m \
GSToolbarView.m \
GSStandardWindowDecorationView.m \
GSWindowDecorationView.m \
GSPrinting.m \
GSPrintOperation.m \
GSEPSPrintOperation.m \
GSPDFPrintOperation.m \
GSModelLoaderFactory.m \
GSGormLoader.m \
GSGModelLoader.m \
GSNibLoader.m \
NSManagedObjectContext.m

# Turn off NSMenuItem warning that NSMenuItem conforms to <NSObject>,
# but does not implement <NSObject>'s methods itself (it inherits
# their implementation)
NSMenuItem.m_FILE_FLAGS = -Wno-protocol

ifneq ($(FOUNDATION_LIB), fd)
libgnustep-gui_OBJC_FILES += NSPasteboard.m
endif

libgnustep-gui_HEADER_FILES_DIR = ../Headers/Additions/GNUstepGUI
libgnustep-gui_HEADER_FILES_INSTALL_DIR = /GNUstepGUI

COCOA_HEADERS = \
Cocoa.h 

APPKIT_HEADERS = \
AppKit.h \
AppKitDefines.h \
AppKitExceptions.h \
NSActionCell.h \
NSAffineTransform.h \
NSAlert.h \
NSAnimation.h \
NSApplication.h \
NSArrayController.h \
NSBezierPath.h \
NSBox.h \
NSBitmapImageRep.h \
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
NSColorSpace.h \
NSColorWell.h \
NSComboBox.h \
NSComboBoxCell.h \
NSControl.h \
NSController.h \
NSCursor.h \
NSCustomImageRep.h \
NSDataLink.h \
NSDataLinkManager.h \
NSDataLinkPanel.h \
NSDocument.h \
NSDocumentController.h \
NSDrawer.h \
NSEPSImageRep.h \
NSEvent.h \
NSFileWrapper.h \
NSFont.h \
NSFontDescriptor.h \
NSFontManager.h \
NSFontPanel.h \
NSForm.h \
NSFormCell.h \
NSGraphicsContext.h \
NSHelpPanel.h \
NSHelpManager.h \
NSImage.h \
NSImageCell.h \
NSImageRep.h \
NSImageView.h \
NSInputManager.h \
NSInputServer.h \
NSInterfaceStyle.h \
NSKeyValueBinding.h \
NSLayoutManager.h \
NSLevelIndicator.h \
NSLevelIndicatorCell.h \
NSMatrix.h \
NSMenu.h \
NSMenuItem.h \
NSMenuItemCell.h \
NSMenuView.h \
NSMovie.h \
NSMovieView.h \
NSObjectController.h \
NSOpenPanel.h \
NSOpenGL.h \
NSOpenGLView.h \
NSOutlineView.h \
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
NSSearchField.h \
NSSearchFieldCell.h \
NSSecureTextField.h \
NSSelection.h \
NSSlider.h \
NSSliderCell.h \
NSSound.h  \
NSSpellChecker.h \
NSSpellServer.h \
NSSplitView.h \
NSStepper.h \
NSStepperCell.h \
NSStringDrawing.h \
NSTabView.h \
NSTabViewItem.h \
NSTableColumn.h \
NSTableHeaderCell.h \
NSTableHeaderView.h \
NSTableView.h \
NSText.h \
NSTextAttachment.h \
NSTextContainer.h \
NSTextField.h \
NSTextFieldCell.h \
NSTextList.h \
NSTextStorage.h \
NSTextTable.h \
NSTextView.h \
NSToolbar.h \
NSToolbarItem.h \
NSUserDefaultsController.h \
NSView.h \
NSWindow.h \
NSWindowController.h \
NSWindow+Toolbar.h \
NSWorkspace.h \
NSAttributedString.h \
NSColorPicking.h \
NSDragging.h \
NSGraphics.h \
NSNibConnector.h \
NSNibDeclarations.h \
NSNibLoading.h \
NSNib.h \
NSSpellProtocol.h \
NSUserInterfaceValidation.h \
DPSOperators.h \
PSOperators.h 

GUI_HEADERS = \
GSVersion.h \
GMAppKit.h \
GMArchiver.h \
GSAnimator.h \
GSTheme.h \
GSFontInfo.h \
GSMemoryPanel.h \
GSInfoPanel.h \
GSMethodTable.h \
GSPasteboardServer.h \
GSServicesManager.h \
GSTextConverter.h \
GSTrackingRect.h \
GSHelpManagerPanel.h \
GSNibTemplates.h \
GSNibContainer.h \
GSDisplayServer.h \
GSFusedSilica.h \
GSTable.h \
GSHbox.h \
GSVbox.h \
IMConnectors.h \
IMCustomObject.h \
IMLoading.h \
GSLayoutManager.h \
GSLayoutManager_internal.h \
GSTypesetter.h \
GSHorizontalTypesetter.h \
GSToolbar.h \
GSToolbarView.h \
GSNibCompatibility.h \
GSDragView.h \
GSTitleView.h \
GSPrinting.h \
GSPrintOperation.h \
GSEPSPrintOperation.h \
GSPDFPrintOperation.h \
GSModelLoaderFactory.h \
GSInstantiator.h 

libgnustep-gui_HEADER_FILES = ${GUI_HEADERS}

HEADERS_INSTALL = ${APPKIT_HEADERS} \
                  ${GUI_HEADERS} \
                  ${COCOA_HEADERS}

# Resources
RESOURCE_SET_NAME = libgui-resources
# Defined twice, one for old gnustep-makes, one for new ones.  In the long
# run, keep only the new xxx_INSTALL_DIR one.
libgui-resources_RESOURCE_FILES_INSTALL_DIR = Library/Libraries/Resources/gnustep-gui
libgui-resources_INSTALL_DIR = $(GNUSTEP_LIBRARY)/Libraries/gnustep-gui/Versions/$(libgnustep-gui_INTERFACE_VERSION)/Resources
libgui-resources_RESOURCE_DIRS =
libgui-resources_RESOURCE_FILES = Info-gnustep.plist


# Extra DLL exports file
libgnustep-gui_DLL_DEF = libgnustep-gui.def

include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/resource-set.make

include GNUmakefile.postamble

include CompatibilityHeaders.make
