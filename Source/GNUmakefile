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
#  version 2 of the License, or (at your option) any later version.
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

PACKAGE_NAME = gnustep-gui
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
NSAccessibility.m \
NSActionCell.m \
NSAffineTransform.m \
NSAlert.m \
NSAnimationContext.m \
NSAnimation.m \
NSAppearance.m \
NSApplication.m \
NSArrayController.m \
NSAttributedString.m \
NSBezierPath.m \
NSBitmapImageRep+GIF.m \
NSBitmapImageRep+ICNS.m \
NSBitmapImageRep+JPEG.m \
NSBitmapImageRep.m \
NSBitmapImageRep+PNG.m \
NSBitmapImageRep+PNM.m \
NSBox.m \
NSBrowserCell.m \
NSBrowser.m \
NSBundleAdditions.m \
NSButtonCell.m \
NSButton.m \
NSButtonTouchBarItem.m \
NSCachedImageRep.m \
NSCandidateListTouchBarItem.m \
NSCell.m \
NSCIImageRep.m \
NSClickGestureRecognizer.m \
NSClipView.m \
NSCollectionViewItem.m \
NSCollectionView.m \
NSColorList.m \
NSColor.m \
NSColorPanel.m \
NSColorPicker.m \
NSColorPickerTouchBarItem.m \
NSColorSpace.m \
NSColorWell.m \
NSComboBoxCell.m \
NSComboBox.m \
NSController.m \
NSControl.m \
NSCursor.m \
NSCustomImageRep.m \
NSCustomTouchBarItem.m \
NSDataAsset.m \
NSDataLink.m \
NSDataLinkManager.m \
NSDataLinkPanel.m \
NSDatePickerCell.m \
NSDatePicker.m \
NSDockTile.m \
NSDocumentController.m \
NSDocument.m \
NSDrawer.m \
NSEPSImageRep.m \
NSEvent.m \
NSFileWrapperExtensions.m \
NSFontDescriptor.m \
NSFont.m \
NSFontManager.m \
NSFontPanel.m \
NSFormCell.m \
NSForm.m \
NSGestureRecognizer.m \
NSGlyphGenerator.m \
NSGradient.m \
NSGraphicsContext.m \
NSGroupTouchBarItem.m \
NSHelpManager.m \
NSHelpPanel.m \
NSImageCell.m \
NSImage.m \
NSImageRep.m \
NSImageView.m \
NSInputManager.m \
NSInputServer.m \
NSInterfaceStyle.m \
NSKeyValueBinding.m \
NSLayoutManager.m \
NSLevelIndicatorCell.m \
NSLevelIndicator.m \
NSMagnificationGestureRecognizer.m \
NSMatrix.m \
NSMenuItemCell.m \
NSMenuItem.m \
NSMenu.m \
NSMenuView.m \
NSMovie.m \
NSMovieView.m \
NSNibAXAttributeConnector.m \
NSNibAXRelationshipConnector.m \
NSNibBindingConnector.m \
NSNibConnector.m \
NSNibControlConnector.m \
NSNib.m \
NSNibOutletConnector.m \
NSObjectController.m \
NSOpenGLContext.m \
NSOpenGLPixelFormat.m \
NSOpenGLView.m \
NSOpenPanel.m \
NSOutlineView.m \
NSPageLayout.m \
NSPanel.m \
NSPanGestureRecognizer.m \
NSParagraphStyle.m \
NSPasteboardItem.m \
NSPDFImageRep.m \
NSPDFInfo.m \
NSPDFPanel.m \
NSPickerTouchBarItem.m \
NSPICTImageRep.m \
NSPopover.m \
NSPopoverTouchBarItem.m \
NSPopUpButtonCell.m \
NSPopUpButton.m \
NSPredicateEditor.m \
NSPredicateEditorRowTemplate.m \
NSPressGestureRecognizer.m \
NSPrinter.m \
NSPrintInfo.m \
NSPrintOperation.m \
NSPrintPanel.m \
NSProgressIndicator.m \
NSResponder.m \
NSRotationGestureRecognizer.m \
NSRuleEditor.m \
NSRulerMarker.m \
NSRulerView.m \
NSRunningApplication.m \
NSSavePanel.m \
NSScreen.m \
NSScroller.m \
NSScrollView.m \
NSSearchFieldCell.m \
NSSearchField.m \
NSSecureTextField.m \
NSSegmentedCell.m \
NSSegmentedControl.m \
NSSelection.m \
NSShadow.m \
NSSharingService.m \
NSSharingServicePickerTouchBarItem.m \
NSSliderCell.m \
NSSlider.m \
NSSliderTouchBarItem.m \
NSSound.m  \
NSSpeechRecognizer.m \
NSSpeechSynthesizer.m \
NSSpellChecker.m \
NSSplitView.m \
NSStatusBar.m \
NSStatusItem.m \
NSStepperCell.m \
NSStepper.m \
NSStepperTouchBarItem.m \
NSStoryboard.m \
NSStoryboardSegue.m \
NSStringDrawing.m \
NSTableColumn.m \
NSTableHeaderCell.m \
NSTableHeaderView.m \
NSTableView.m \
NSTabViewItem.m \
NSTabView.m \
NSTextAlternatives.m \
NSTextAttachment.m \
NSTextBlock.m \
NSTextContainer.m \
NSTextFieldCell.m \
NSTextField.m \
NSTextList.m \
NSText.m \
NSTextStorage.m \
NSTextTableBlock.m \
NSTextTable.m \
NSTextView_actions.m \
NSTextView.m \
NSTokenFieldCell.m \
NSTokenField.m \
NSToolbarItemGroup.m \
NSToolbarItem.m \
NSToolbar.m \
NSTouchBarItem.m \
NSTouchBar.m \
NSTouch.m \
NSTrackingArea.m \
NSTreeController.m \
NSTreeNode.m \
NSUserDefaultsController.m \
NSViewController.m \
NSView.m \
NSVisualEffectView.m \
NSWindowController.m \
NSWindow.m \
NSWorkspace.m \
tiff.m \
externs.m \
GSAnimator.m \
GSAutocompleteWindow.m \
GSCharacterPanel.m \
GSDisplayServer.m \
GSDragView.m \
GSEPSPrintOperation.m \
GSFontInfo.m \
GSGModelLoader.m \
GSGormLoader.m \
GSGormLoading.m \
GSHbox.m \
GSHelpAttachment.m \
GSHelpManagerPanel.m \
GSHorizontalTypesetter.m \
GSIconManager.m \
GSImageMagickImageRep.m \
GSInfoPanel.m \
GSKeyBindingAction.m \
GSKeyBindingTable.m \
GSLayoutManager.m \
GSMemoryPanel.m \
GSModelLoaderFactory.m \
GSNibLoader.m \
GSNibLoading.m \
GSPDFPrintOperation.m \
GSPrinting.m \
GSPrintOperation.m \
GSServicesManager.m \
GSSlideView.m \
GSStandardWindowDecorationView.m \
GSTable.m \
GSTextFinder.m \
GSTextStorage.m \
GSThemeDrawing.m \
GSThemeInspector.m \
GSTheme.m \
GSThemeMenu.m \
GSThemeOpenSavePanels.m \
GSThemePanel.m \
GSThemePrintPanels.m \
GSThemeTools.m \
GSThemeWindow.m \
GSTitleView.m \
GSToolbarCustomizationPalette.m \
GSToolbarView.m \
GSToolTips.m \
GSTrackingRect.m \
GSTypesetter.m \
GSVbox.m \
GSWindowDecorationView.m \
GSXib5KeyedUnarchiver.m \
GSXibElement.m \
GSXibKeyedUnarchiver.m \
GSXibLoader.m \
GSXibLoading.m \
GSXibObjectContainer.m \
linking.m

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
AppKitDefines.h \
AppKitExceptions.h \
AppKit.h \
DPSOperators.h \
NSAccessibilityConstants.h \
NSAccessibility.h \
NSActionCell.h \
NSAffineTransform.h \
NSAlert.h \
NSAnimationContext.h \
NSAnimation.h \
NSAppearance.h \
NSApplication.h \
NSArrayController.h \
NSAttributedString.h \
NSBezierPath.h \
NSBitmapImageRep.h \
NSBox.h \
NSBrowserCell.h \
NSBrowser.h \
NSButtonCell.h \
NSButton.h \
NSButtonTouchBarItem.h \
NSCachedImageRep.h \
NSCandidateListTouchBarItem.h \
NSCell.h \
NSCIImageRep.h \
NSClickGestureRecognizer.h \
NSClipView.h \
NSCollectionView.h \
NSCollectionViewItem.h \
NSColor.h \
NSColorList.h \
NSColorPanel.h \
NSColorPicker.h \
NSColorPickerTouchBarItem.h \
NSColorPicking.h \
NSColorSpace.h \
NSColorWell.h \
NSComboBoxCell.h \
NSComboBox.h \
NSControl.h \
NSController.h \
NSCursor.h \
NSCustomImageRep.h \
NSCustomTouchBarItem.h \
NSDataAsset.h \
NSDataLink.h \
NSDataLinkManager.h \
NSDataLinkPanel.h \
NSDatePickerCell.h \
NSDatePicker.h \
NSDockTile.h \
NSDocumentController.h \
NSDocument.h \
NSDragging.h \
NSDrawer.h \
NSEPSImageRep.h \
NSEvent.h \
NSFileWrapperExtensions.h \
NSFileWrapper.h \
NSFontDescriptor.h \
NSFont.h \
NSFontManager.h \
NSFontPanel.h \
NSFormCell.h \
NSForm.h \
NSGestureRecognizer.h \
NSGlyphGenerator.h \
NSGradient.h \
NSGraphicsContext.h \
NSGraphics.h \
NSGroupTouchBarItem.h \
NSHelpManager.h \
NSHelpPanel.h \
NSImageCell.h \
NSImage.h \
NSImageRep.h \
NSImageView.h \
NSInputManager.h \
NSInputServer.h \
NSInterfaceStyle.h \
NSKeyValueBinding.h \
NSLayoutManager.h \
NSLevelIndicatorCell.h \
NSLevelIndicator.h \
NSMagnificationGestureRecognizer.h \
NSMatrix.h \
NSMenu.h \
NSMenuItemCell.h \
NSMenuItem.h \
NSMenuView.h \
NSMovie.h \
NSMovieView.h \
NSNibConnector.h \
NSNibControlConnector.h \
NSNibDeclarations.h \
NSNib.h \
NSNibLoading.h \
NSNibOutletConnector.h \
NSObjectController.h \
NSOpenGL.h \
NSOpenGLView.h \
NSOpenPanel.h \
NSOutlineView.h \
NSPageLayout.h \
NSPanel.h \
NSPanGestureRecognizer.h \
NSParagraphStyle.h \
NSPasteboard.h \
NSPasteboardItem.h \
NSPDFImageRep.h \
NSPDFInfo.h \
NSPDFPanel.h \
NSPickerTouchBarItem.h \
NSPICTImageRep.h \
NSPopover.h \
NSPopoverTouchBarItem.h \
NSPopUpButtonCell.h \
NSPopUpButton.h \
NSPredicateEditor.h \
NSPredicateEditorRowTemplate.h \
NSPressGestureRecognizer.h \
NSPrinter.h \
NSPrintInfo.h \
NSPrintOperation.h \
NSPrintPanel.h \
NSProgressIndicator.h \
NSResponder.h \
NSRotationGestureRecognizer.h \
NSRuleEditor.h \
NSRulerMarker.h \
NSRulerView.h \
NSRunningApplication.h \
NSSavePanel.h \
NSScreen.h \
NSScroller.h \
NSScrollView.h \
NSSearchFieldCell.h \
NSSearchField.h \
NSSecureTextField.h \
NSSegmentedCell.h \
NSSegmentedControl.h \
NSSelection.h \
NSShadow.h \
NSSharingService.h \
NSSharingServicePickerTouchBarItem.h \
NSSliderCell.h \
NSSlider.h \
NSSliderTouchBarItem.h \
NSSound.h  \
NSSpeechRecognizer.h \
NSSpeechSynthesizer.h \
NSSpellChecker.h \
NSSpellProtocol.h \
NSSpellServer.h \
NSSplitView.h \
NSStatusBar.h \
NSStatusItem.h \
NSStepperCell.h \
NSStepper.h \
NSStepperTouchBarItem.h \
NSStringDrawing.h \
NSTableColumn.h \
NSTableHeaderCell.h \
NSTableHeaderView.h \
NSTableView.h \
NSTabView.h \
NSTabViewItem.h \
NSTextAlternatives.h \
NSTextAttachment.h \
NSTextContainer.h \
NSTextFieldCell.h \
NSTextField.h \
NSText.h \
NSTextList.h \
NSTextStorage.h \
NSTextTable.h \
NSTextView.h \
NSTokenFieldCell.h \
NSTokenField.h \
NSToolbar.h \
NSToolbarItemGroup.h \
NSToolbarItem.h \
NSTouchBar.h \
NSTouchBarItem.h \
NSTouch.h \
NSTrackingArea.h \
NSTreeController.h \
NSTreeNode.h \
NSUserDefaultsController.h \
NSUserInterfaceItemIdentification.h \
NSUserInterfaceLayout.h \
NSUserInterfaceValidation.h \
NSViewController.h \
NSView.h \
NSVisualEffectView.h \
NSWindowController.h \
NSWindow.h \
NSWorkspace.h \
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
GSGormLoading.h \
GSNibContainer.h \
GSDisplayServer.h \
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
GSToolbarView.h \
GSNibLoading.h \
GSDragView.h \
GSTitleView.h \
GSPrinting.h \
GSPrintOperation.h \
GSEPSPrintOperation.h \
GSPDFPrintOperation.h \
GSModelLoaderFactory.h \
GSImageMagickImageRep.h \
GSInstantiator.h \
GSSoundSink.h \
GSSoundSource.h \
GSWindowDecorationView.h \
GSXibElement.h \
GSXibLoading.h \
GSXibKeyedUnarchiver.h \
GSXibObjectContainer.h \
GSHelpAttachment.h

libgnustep-gui_HEADER_FILES = ${GUI_HEADERS}

HEADERS_INSTALL = ${APPKIT_HEADERS} \
                  ${GUI_HEADERS} \
                  ${COCOA_HEADERS}

# Resources
RESOURCE_SET_NAME = libgui-resources
libgui-resources_INSTALL_DIR = $(GNUSTEP_LIBRARY)/Libraries/gnustep-gui/Versions/$(libgnustep-gui_INTERFACE_VERSION)/Resources
libgui-resources_RESOURCE_DIRS =
libgui-resources_RESOURCE_FILES = Info-gnustep.plist


# Extra DLL exports file
libgnustep-gui_DLL_DEF = libgnustep-gui.def

include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/resource-set.make

include GNUmakefile.postamble

include CompatibilityHeaders.make
