/* 
   externs.m

   External data

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: August 1997
   
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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <Foundation/NSString.h>
#include <AppKit/NSEvent.h>

/* The global application object */
/* This should really be accessed through [NSApplication sharedApplication] */
id NSApp = nil;

NSEvent *gnustep_gui_null_event = nil;

// Global strings
NSString *NSModalPanelRunLoopMode = @"ModalPanelMode";
NSString *NSEventTrackingRunLoopMode = @"EventTrackingMode";

//
// Global Exception Strings 
//
NSString *NSAbortModalException = @"AbortModal";
NSString *NSAbortPrintingException = @"AbortPrinting";
NSString *NSAppKitIgnoredException = @"AppKitIgnored";
NSString *NSAppKitVirtualMemoryException = @"AppKitVirtualMemory";
NSString *NSBadBitmapParametersException = @"BadBitmapParameters";
NSString *NSBadComparisonException = @"BadComparison";
NSString *NSBadRTFColorTableException = @"BadRTFColorTable";
NSString *NSBadRTFDirectiveException = @"BadRTFDirective";
NSString *NSBadRTFFontTableException = @"BadRTFFontTable";
NSString *NSBadRTFStyleSheetException = @"BadRTFStyleSheet";
NSString *NSBrowserIllegalDelegateException = @"BrowserIllegalDelegate";
NSString *NSColorListIOException = @"ColorListIO";
NSString *NSColorListNotEditableException = @"ColorListNotEditable";
NSString *NSDraggingException = @"Draggin";
NSString *NSFontUnavailableException = @"FontUnavailable";
NSString *NSIllegalSelectorException = @"IllegalSelector";
NSString *NSImageCacheException = @"ImageCache";
NSString *NSNibLoadingException = @"NibLoading";
NSString *NSPPDIncludeNotFoundException = @"PPDIncludeNotFound";
NSString *NSPPDIncludeStackOverflowException = @"PPDIncludeStackOverflow";
NSString *NSPPDIncludeStackUnderflowException = @"PPDIncludeStackUnderflow";
NSString *NSPPDParseException = @"PPDParse";
NSString *NSPasteboardCommunicationException = @"PasteboardCommunication";
NSString *NSPrintOperationExistsException = @"PrintOperationExists";
NSString *NSPrintPackageException = @"PrintPackage";
NSString *NSPrintingCommunicationException = @"PrintingCommunication";
NSString *NSRTFPropertyStackOverflowException = @"RTFPropertyStackOverflow";
NSString *NSTIFFException = @"TIFF";
NSString *NSTextLineTooLongException = @"TextLineTooLong";
NSString *NSTextNoSelectionException = @"TextNoSelection";
NSString *NSTextReadException = @"TextRead";
NSString *NSTextWriteException = @"TextWrite";
NSString *NSTypedStreamVersionException = @"TypedStreamVersion";
NSString *NSWindowServerCommunicationException = @"WindowServerCommunication";
NSString *NSWordTablesReadException = @"WordTablesRead";
NSString *NSWordTablesWriteException = @"WordTablesWrite";

// Application notifications
NSString *NSApplicationDidBecomeActiveNotification 
              = @"ApplicationDidBecomeActive";
NSString *NSApplicationDidFinishLaunchingNotification 
              = @"ApplicationDidFinishLaunching";
NSString *NSApplicationDidHideNotification = @"ApplicationDidHide";
NSString *NSApplicationDidResignActiveNotification 
              = @"ApplicationDidResignActive";
NSString *NSApplicationDidUnhideNotification = @"ApplicationDidUnhide";
NSString *NSApplicationDidUpdateNotification = @"ApplicationDidUpdate";
NSString *NSApplicationWillBecomeActiveNotification 
              = @"ApplicationWillBecomeActive";
NSString *NSApplicationWillFinishLaunchingNotification 
              = @"ApplicationWillFinishLaunching";
NSString *NSApplicationWillHideNotification = @"ApplicationWillHide";
NSString *NSApplicationWillResignActiveNotification 
              = @"ApplicationWillResignActive";
NSString *NSApplicationWillUnhideNotification = @"ApplicationWillUnhide";
NSString *NSApplicationWillUpdateNotification = @"ApplicationWillUpdate";

// NSColor Global strings
NSString *NSCalibratedWhiteColorSpace = @"NSCalibratedWhiteColorSpace";
NSString *NSCalibratedBlackColorSpace = @"NSCalibratedBlackColorSpace";
NSString *NSCalibratedRGBColorSpace = @"NSCalibratedRGBColorSpace";
NSString *NSDeviceWhiteColorSpace = @"NSDeviceWhiteColorSpace";
NSString *NSDeviceBlackColorSpace = @"NSDeviceBlackColorSpace";
NSString *NSDeviceRGBColorSpace = @"NSDeviceRGBColorSpace";
NSString *NSDeviceCMYKColorSpace = @"NSDeviceCMYKColorSpace";
NSString *NSNamedColorSpace = @"NSNamedColorSpace";
NSString *NSCustomColorSpace = @"NSCustomColorSpace";

// NSColor Global gray values
const float NSBlack = 0;
const float NSDarkGray = .333;
const float NSGray = 0.5;
const float NSLightGray = .667;
const float NSWhite = 1;

// NSColorList notifications
NSString *NSColorListChangedNotification = @"NSColorListChange";

// NSColorPanel notifications
NSString *NSColorPanelColorChangedNotification =
@"NSColorPanelColorChangedNotification";

// NSControl notifications
NSString *NSControlTextDidBeginEditingNotification =
@"NSControlTextDidBeginEditingNotification";
NSString *NSControlTextDidEndEditingNotification =
@"NSControlTextDidEndEditingNotification";
NSString *NSControlTextDidChangeNotification =
@"NSControlTextDidChangeNotification";

// NSDataLink global strings
NSString *NSDataLinkFileNameExtension = @"dlf";

// NSFont Global Strings
NSString *NSAFMAscender = @"Ascender";
NSString *NSAFMCapHeight = @"CapHeight";
NSString *NSAFMCharacterSet = @"CharacterSet";
NSString *NSAFMDescender = @"Descender";
NSString *NSAFMEncodingScheme = @"EncodingScheme";
NSString *NSAFMFamilyName = @"FamilyName";
NSString *NSAFMFontName = @"FontName";
NSString *NSAFMFormatVersion = @"FormatVersion";
NSString *NSAFMFullName = @"FullName";
NSString *NSAFMItalicAngle = @"ItalicAngle";
NSString *NSAFMMappingScheme = @"MappingScheme";
NSString *NSAFMNotice = @"Notice";
NSString *NSAFMUnderlinePosition = @"UnderlinePosition";
NSString *NSAFMUnderlineThickness = @"UnderlineThickness";
NSString *NSAFMVersion = @"Version";
NSString *NSAFMWeight = @"Weight";
NSString *NSAFMXHeight = @"XHeight";

// NSScreen Global device dictionary key strings
NSString *NSDeviceResolution = @"Resolution";
NSString *NSDeviceColorSpaceName = @"ColorSpaceName";
NSString *NSDeviceBitsPerSample = @"BitsPerSample";
NSString *NSDeviceIsScreen = @"IsScreen";
NSString *NSDeviceIsPrinter = @"IsPrinter";
NSString *NSDeviceSize = @"Size";

// NSImageRep notifications
NSString *NSImageRepRegistryChangedNotification =
@"NSImageRepRegistryChangedNotification";

// NSPasteboard Type Globals 
NSString *NSStringPboardType = @"NSStringPboardType";
NSString *NSColorPboardType = @"NSColorPboardType";
NSString *NSFileContentsPboardType = @"NSFileContentsPboardType";
NSString *NSFilenamesPboardType = @"NSFilenamesPboardType";
NSString *NSFontPboardType = @"NSFontPboardType";
NSString *NSRulerPboardType = @"NSRulerPboardType";
NSString *NSPostScriptPboardType = @"NSPostScriptPboardType";
NSString *NSTabularTextPboardType = @"NSTabularTextPboardType";
NSString *NSRTFPboardType = @"NSRTFPboardType";
NSString *NSTIFFPboardType = @"NSTIFFPboardType";
NSString *NSDataLinkPboardType = @"NSDataLinkPboardType";
NSString *NSGeneralPboardType = @"NSGeneralPboardType";

// NSPasteboard Name Globals 
NSString *NSDragPboard = @"NSDragPboard";
NSString *NSFindPboard = @"NSFindPboard";
NSString *NSFontPboard = @"NSFontPboard";
NSString *NSGeneralPboard = @"NSGeneralPboard";
NSString *NSRulerPboard = @"NSRulerPboard";

// Printing Information Dictionary Keys 
NSString *NSPrintAllPages = @"PrintAllPages";
NSString *NSPrintBottomMargin = @"PrintBottomMargin";
NSString *NSPrintCopies = @"PrintCopies";
NSString *NSPrintFaxCoverSheetName = @"PrintFaxCoverSheetName";
NSString *NSPrintFaxHighResolution = @"PrintFaxHighResolution";
NSString *NSPrintFaxModem = @"PrintFaxModem";
NSString *NSPrintFaxReceiverNames = @"PrintFaxReceiverNames";
NSString *NSPrintFaxReceiverNumbers = @"PrintFaxReceiverNumbers";
NSString *NSPrintFaxReturnReceipt = @"PrintFaxReturnReceipt";
NSString *NSPrintFaxSendTime = @"PrintFaxSendTime";
NSString *NSPrintFaxTrimPageEnds = @"PrintFaxTrimPageEnds";
NSString *NSPrintFaxUseCoverSheet = @"PrintFaxUseCoverSheet";
NSString *NSPrintFirstPage = @"PrintFirstPage";
NSString *NSPrintHorizonalPagination = @"PrintHorizonalPagination";
NSString *NSPrintHorizontallyCentered = @"PrintHorizontallyCentered";
NSString *NSPrintJobDisposition = @"PrintJobDisposition";
NSString *NSPrintJobFeatures = @"PrintJobFeatures";
NSString *NSPrintLastPage = @"PrintLastPage";
NSString *NSPrintLeftMargin = @"PrintLeftMargin";
NSString *NSPrintManualFeed = @"PrintManualFeed";
NSString *NSPrintOrientation = @"PrintOrientation";
NSString *NSPrintPagesPerSheet = @"PrintPagesPerSheet";
NSString *NSPrintPaperFeed = @"PrintPaperFeed";
NSString *NSPrintPaperName = @"PrintPaperName";
NSString *NSPrintPaperSize = @"PrintPaperSize";
NSString *NSPrintPrinter = @"PrintPrinter";
NSString *NSPrintReversePageOrder = @"PrintReversePageOrder";
NSString *NSPrintRightMargin = @"PrintRightMargin";
NSString *NSPrintSavePath = @"PrintSavePath";
NSString *NSPrintScalingFactor = @"PrintScalingFactor";
NSString *NSPrintTopMargin = @"PrintTopMargin";
NSString *NSPrintVerticalPagination = @"PrintVerticalPagination";
NSString *NSPrintVerticallyCentered = @"PrintVerticallyCentered";

// Print Job Disposition Values 
NSString  *NSPrintCancelJob = @"PrintCancelJob";
NSString  *NSPrintFaxJob = @"PrintFaxJob";
NSString  *NSPrintPreviewJob = @"PrintPreviewJob";
NSString  *NSPrintSaveJob = @"PrintSaveJob";
NSString  *NSPrintSpoolJob = @"PrintSpoolJob";

// NSSplitView notifications
NSString *NSSplitViewDidResizeSubviewsNotification =
@"NSSplitViewDidResizeSubviewsNotification";
NSString *NSSplitViewWillResizeSubviewsNotification =
@"NSSplitViewWillResizeSubviewsNotification";

// NSText notifications
NSString *NSTextDidBeginEditingNotification =
@"NSTextDidBeginEditingNotification";
NSString *NSTextDidEndEditingNotification = @"NSTextDidEndEditingNotification";
NSString *NSTextDidChangeNotification = @"NSTextDidChangeNotification";

// NSView notifications
NSString *NSViewFrameChangedNotification = @"NSViewFrameChangedNotification";
NSString *NSViewFocusChangedNotification = @"NSViewFocusChangedNotification";

// NSWindow notifications
NSString *NSWindowDidBecomeKeyNotification = @"WindowDidBecomeKey";
NSString *NSWindowDidBecomeMainNotification = @"WindowDidBecomeMain";
NSString *NSWindowDidChangeScreenNotification = @"WindowDidChangeScreen";
NSString *NSWindowDidDeminiaturizeNotification = @"WindowDidDeminiaturize";
NSString *NSWindowDidExposeNotification = @"WindowDidExpose";
NSString *NSWindowDidMiniaturizeNotification = @"WindowDidMiniaturize";
NSString *NSWindowDidMoveNotification = @"WindowDidMove";
NSString *NSWindowDidResignKeyNotification = @"WindowDidResignKey";
NSString *NSWindowDidResignMainNotification = @"WindowDidResignMain";
NSString *NSWindowDidResizeNotification = @"WindowDidResize";
NSString *NSWindowDidUpdateNotification = @"WindowDidUpdate";
NSString *NSWindowWillCloseNotification = @"WindowWillClose";
NSString *NSWindowWillMiniaturizeNotification = @"WindowWillMiniaturize";
NSString *NSWindowWillMoveNotification = @"WindowWillMove";

// Workspace File Type Globals 
NSString *NSPlainFileType = @"NSPlainFileType";
NSString *NSDirectoryFileType = @"NSDirectoryFileType";
NSString *NSApplicationFileType = @"NSApplicationFileType";
NSString *NSFilesystemFileType = @"NSFilesystemFileType";
NSString *NSShellCommandFileType = @"NSShellCommandFileType";

// Workspace File Operation Globals 
NSString *NSWorkspaceCompressOperation = @"NSWorkspaceCompressOperation";
NSString *NSWorkspaceCopyOperation = @"NSWorkspaceCopyOperation";
NSString *NSWorkspaceDecompressOperation = @"NSWorkspaceDecompressOperation";
NSString *NSWorkspaceDecryptOperation = @"NSWorkspaceDecryptOperation";
NSString *NSWorkspaceDestroyOperation = @"NSWorkspaceDestroyOperation";
NSString *NSWorkspaceDuplicateOperation = @"NSWorkspaceDuplicateOperation";
NSString *NSWorkspaceEncryptOperation = @"NSWorkspaceEncryptOperation";
NSString *NSWorkspaceLinkOperation = @"NSWorkspaceLinkOperation";
NSString *NSWorkspaceMoveOperation = @"NSWorkspaceMoveOperation";
NSString *NSWorkspaceRecycleOperation = @"NSWorkspaceRecycleOperation";

// NSWorkspace notifications
NSString *NSWorkspaceDidLaunchApplicationNotification =
@"NSWorkspaceDidLaunchApplicationNotification";
NSString *NSWorkspaceDidMountNotification = @"NSWorkspaceDidMountNotification";
NSString *NSWorkspaceDidPerformFileOperationNotification =
@"NSWorkspaceDidPerformFileOperationNotification";
NSString *NSWorkspaceDidTerminateApplicationNotification =
@"NSWorkspaceDidTerminateApplicationNotification";
NSString *NSWorkspaceDidUnmountNotification =
@"NSWorkspaceDidUnmountNotification";
NSString *NSWorkspaceWillLaunchApplicationNotification =
@"NSWorkspaceWillLaunchApplicationNotification";
NSString *NSWorkspaceWillPowerOffNotification =
@"NSWorkspaceWillPowerOffNotification";
NSString *NSWorkspaceWillUnmountNotification =
@"NSWorkspaceWillUnmountNotification";

