/* TypesandConstants.h

   Type and Constant definitions for the GNUstep GUI Library

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_GUITypes
#define _GNUstep_H_GUITypes

#include <Foundation/NSString.h>

//
// Application
//
extern id NSApp;
typedef struct _NSModalSession *NSModalSession;

enum {
  NSRunStoppedResponse,
  NSRunAbortedResponse,
  NSRunContinuesResponse
};

extern NSString *NSModalPanelRunLoopMode;
extern NSString *NSEventTrackingRunLoopMode;

//
// Box
//
typedef enum _NSTitlePosition {
  NSNoTitle,
  NSAboveTop,
  NSAtTop,
  NSBelowTop,
  NSAboveBottom,
  NSAtBottom,
  NSBelowBottom
} NSTitlePosition;

//
// Buttons
//
typedef enum _NSButtonType {
  NSMomentaryPushButton,
  NSPushOnPushOffButton,
  NSToggleButton,
  NSSwitchButton,  
  NSRadioButton,  
  NSMomentaryChangeButton, 
  NSOnOffButton 
} NSButtonType;

//
// Cells and Button Cells
//
typedef enum _NSCellType {
  NSNullCellType,
  NSTextCellType,
  NSImageCellType
} NSCellType;

typedef enum _NSCellImagePosition {
  NSNoImage,
  NSImageOnly,
  NSImageLeft,
  NSImageRight,   
  NSImageBelow,   
  NSImageAbove,   
  NSImageOverlaps  
} NSCellImagePosition;

typedef enum _NSCellAttribute {
  NSCellDisabled,
  NSCellState,
  NSPushInCell,
  NSCellEditable,
  NSChangeGrayCell,
  NSCellHighlighted,   
  NSCellLightsByContents,  
  NSCellLightsByGray,   
  NSChangeBackgroundCell,  
  NSCellLightsByBackground,  
  NSCellIsBordered,  
  NSCellHasOverlappingImage,  
  NSCellHasImageHorizontal,  
  NSCellHasImageOnLeftOrBottom, 
  NSCellChangesContents,  
  NSCellIsInsetButton
} NSCellAttribute;

enum {
  NSAnyType,
  NSIntType,
  NSPositiveIntType,   
  NSFloatType,
  NSPositiveFloatType,   
  NSDateType,
  NSDoubleType,   
  NSPositiveDoubleType
};

enum {
  NSNoCellMask,
  NSContentsCellMask,
  NSPushInCellMask,
  NSChangeGrayCellMask,  
  NSChangeBackgroundCellMask
};

//
// Color
//
enum {
  NSGrayModeColorPanel,
  NSRGBModeColorPanel,
  NSCMYKModeColorPanel,
  NSHSBModeColorPanel,
  NSCustomPaletteModeColorPanel,
  NSColorListModeColorPanel,
  NSWheelModeColorPanel 
};

enum {
  NSColorPanelGrayModeMask,
  NSColorPanelRGBModeMask,
  NSColorPanelCMYKModeMask,
  NSColorPanelHSBModeMask,
  NSColorPanelCustomPaletteModeMask,
  NSColorPanelColorListModeMask,
  NSColorPanelWheelModeMask,
  NSColorPanelAllModesMask  
};

//
// Data Link
//
typedef int NSDataLinkNumber;
extern NSString *NSDataLinkFileNameExtension;
typedef enum _NSDataLinkDisposition {
  NSLinkInDestination,
  NSLinkInSource,
  NSLinkBroken 
} NSDataLinkDisposition;

typedef enum _NSDataLinkUpdateMode {
  NSUpdateContinuously,
  NSUpdateWhenSourceSaved,
  NSUpdateManually,
  NSUpdateNever
} NSDataLinkUpdateMode;

//
// Drag Operation
//
typedef enum _NSDragOperation {
  NSDragOperationNone,
  NSDragOperationCopy,
  NSDragOperationLink,
  NSDragOperationGeneric,
  NSDragOperationPrivate,
  NSDragOperationAll   
} NSDragOperation;

//
// Event Handling
//
typedef enum _NSEventType {
  NSLeftMouseDown,
  NSLeftMouseUp,
  NSRightMouseDown,
  NSRightMouseUp,
  NSMouseMoved,
  NSLeftMouseDragged,
  NSRightMouseDragged,
  NSMouseEntered,
  NSMouseExited,
  NSKeyDown,
  NSKeyUp,
  NSFlagsChanged,
  NSPeriodic,
  NSCursorUpdate
} NSEventType;

enum {
  NSUpArrowFunctionKey = 0xF700,
  NSDownArrowFunctionKey = 0xF701,
  NSLeftArrowFunctionKey = 0xF702,
  NSRightArrowFunctionKey = 0xF703,
  NSF1FunctionKey  = 0xF704,
  NSF2FunctionKey  = 0xF705,
  NSF3FunctionKey  = 0xF706,
  NSF4FunctionKey  = 0xF707,
  NSF5FunctionKey  = 0xF708,
  NSF6FunctionKey  = 0xF709,
  NSF7FunctionKey  = 0xF70A,
  NSF8FunctionKey  = 0xF70B,
  NSF9FunctionKey  = 0xF70C,
  NSF10FunctionKey = 0xF70D,
  NSF11FunctionKey = 0xF70E,
  NSF12FunctionKey = 0xF70F,
  NSF13FunctionKey = 0xF710,
  NSF14FunctionKey = 0xF711,
  NSF15FunctionKey = 0xF712,
  NSF16FunctionKey = 0xF713,
  NSF17FunctionKey = 0xF714,
  NSF18FunctionKey = 0xF715,
  NSF19FunctionKey = 0xF716,
  NSF20FunctionKey = 0xF717,
  NSF21FunctionKey = 0xF718,
  NSF22FunctionKey = 0xF719,
  NSF23FunctionKey = 0xF71A,
  NSF24FunctionKey = 0xF71B,
  NSF25FunctionKey = 0xF71C,
  NSF26FunctionKey = 0xF71D,
  NSF27FunctionKey = 0xF71E,
  NSF28FunctionKey = 0xF71F,
  NSF29FunctionKey = 0xF720,
  NSF30FunctionKey = 0xF721,
  NSF31FunctionKey = 0xF722,
  NSF32FunctionKey = 0xF723,
  NSF33FunctionKey = 0xF724,
  NSF34FunctionKey = 0xF725,
  NSF35FunctionKey = 0xF726,
  NSInsertFunctionKey = 0xF727,
  NSDeleteFunctionKey = 0xF728,
  NSHomeFunctionKey = 0xF729,
  NSBeginFunctionKey = 0xF72A,
  NSEndFunctionKey = 0xF72B,
  NSPageUpFunctionKey = 0xF72C,
  NSPageDownFunctionKey = 0xF72D,
  NSPrintScreenFunctionKey = 0xF72E,
  NSScrollLockFunctionKey = 0xF72F,
  NSPauseFunctionKey = 0xF730,
  NSSysReqFunctionKey = 0xF731,
  NSBreakFunctionKey = 0xF732,
  NSResetFunctionKey = 0xF733,
  NSStopFunctionKey = 0xF734,
  NSMenuFunctionKey = 0xF735,
  NSUserFunctionKey = 0xF736,
  NSSystemFunctionKey = 0xF737,
  NSPrintFunctionKey = 0xF738,
  NSClearLineFunctionKey = 0xF739,
  NSClearDisplayFunctionKey = 0xF73A,
  NSInsertLineFunctionKey = 0xF73B,
  NSDeleteLineFunctionKey = 0xF73C,
  NSInsertCharFunctionKey = 0xF73D,
  NSDeleteCharFunctionKey = 0xF73E,
  NSPrevFunctionKey = 0xF73F,
  NSNextFunctionKey = 0xF740,
  NSSelectFunctionKey = 0xF741,
  NSExecuteFunctionKey = 0xF742,
  NSUndoFunctionKey = 0xF743,
  NSRedoFunctionKey = 0xF744,
  NSFindFunctionKey = 0xF745,
  NSHelpFunctionKey = 0xF746,
  NSModeSwitchFunctionKey = 0xF747
};

enum {
  NSAlphaShiftKeyMask = 1,
  NSShiftKeyMask = 2,
  NSControlKeyMask = 4,
  NSAlternateKeyMask = 8,
  NSCommandKeyMask = 16,
  NSNumericPadKeyMask = 32,
  NSHelpKeyMask = 64,
  NSFunctionKeyMask = 128
};

enum {
  NSLeftMouseDownMask = 1,
  NSLeftMouseUpMask = 2,
  NSRightMouseDownMask = 4,
  NSRightMouseUpMask = 8,
  NSMouseMovedMask = 16,
  NSLeftMouseDraggedMask = 32,
  NSRightMouseDraggedMask = 64,
  NSMouseEnteredMask = 128,
  NSMouseExitedMask = 256,
  NSKeyDownMask = 512,
  NSKeyUpMask = 1024,
  NSFlagsChangedMask = 2048,
  NSPeriodicMask = 4096,
  NSCursorUpdateMask = 8192,
// Note that NSAnyEventMask is an OR-combination of all other event masks
  NSAnyEventMask = 16383
};

//
// Exceptions
//

//
// Global Exception Strings 
//
extern NSString *NSAbortModalException;
extern NSString *NSAbortPrintingException;
extern NSString *NSAppKitIgnoredException;
extern NSString *NSAppKitVirtualMemoryException;
extern NSString *NSBadBitmapParametersException;
extern NSString *NSBadComparisonException;
extern NSString *NSBadRTFColorTableException;
extern NSString *NSBadRTFDirectiveException;
extern NSString *NSBadRTFFontTableException;
extern NSString *NSBadRTFStyleSheetException;
extern NSString *NSBrowserIllegalDelegateException;
extern NSString *NSColorListIOException;
extern NSString *NSColorListNotEditableException;
extern NSString *NSDraggingException;
extern NSString *NSFontUnavailableException;
extern NSString *NSIllegalSelectorException;
extern NSString *NSImageCacheException;
extern NSString *NSNibLoadingException;
extern NSString *NSPPDIncludeNotFoundException;
extern NSString *NSPPDIncludeStackOverflowException;
extern NSString *NSPPDIncludeStackUnderflowException;
extern NSString *NSPPDParseException;
extern NSString *NSPasteboardCommunicationException;
extern NSString *NSPrintOperationExistsException;
extern NSString *NSPrintPackageException;
extern NSString *NSPrintingCommunicationException;
extern NSString *NSRTFPropertyStackOverflowException;
extern NSString *NSTIFFException;
extern NSString *NSTextLineTooLongException;
extern NSString *NSTextNoSelectionException;
extern NSString *NSTextReadException;
extern NSString *NSTextWriteException;
extern NSString *NSTypedStreamVersionException;
extern NSString *NSWindowServerCommunicationException;
extern NSString *NSWordTablesReadException;
extern NSString *NSWordTablesWriteException;

//
// Fonts
//
typedef unsigned int NSFontTraitMask;

enum {
  NSItalicFontMask = 1,
  NSBoldFontMask = 2,
  NSUnboldFontMask = 4,
  NSNonStandardCharacterSetFontMask = 8,
  NSNarrowFontMask = 16,
  NSExpandedFontMask = 32,
  NSCondensedFontMask = 64,
  NSSmallCapsFontMask = 128,
  NSPosterFontMask = 256,
  NSCompressedFontMask = 512,
  NSUnitalicFontMask = 1024
};

typedef unsigned int NSGlyph;

enum {
  NSFPPreviewButton ,
  NSFPRevertButton,
  NSFPSetButton,
  NSFPPreviewField,
  NSFPSizeField,
  NSFPSizeTitle,
  NSFPCurrentField
};

const float *NSFontIdentityMatrix;

extern NSString *NSAFMAscender;
extern NSString *NSAFMCapHeight;
extern NSString *NSAFMCharacterSet;
extern NSString *NSAFMDescender;
extern NSString *NSAFMEncodingScheme;
extern NSString *NSAFMFamilyName;
extern NSString *NSAFMFontName;
extern NSString *NSAFMFormatVersion;
extern NSString *NSAFMFullName;
extern NSString *NSAFMItalicAngle;
extern NSString *NSAFMMappingScheme;
extern NSString *NSAFMNotice;
extern NSString *NSAFMUnderlinePosition;
extern NSString *NSAFMUnderlineThickness;
extern NSString *NSAFMVersion;
extern NSString *NSAFMWeight;
extern NSString *NSAFMXHeight;

//
// Graphics
//
typedef int NSWindowDepth;

typedef enum _NSTIFFCompression {
  NSTIFFCompressionNone  = 1,
  NSTIFFCompressionCCITTFAX3  = 3,
  NSTIFFCompressionCCITTFAX4  = 4,
  NSTIFFCompressionLZW  = 5,
  NSTIFFCompressionJPEG  = 6,
  NSTIFFCompressionNEXT  = 32766,
  NSTIFFCompressionPackBits  = 32773,
  NSTIFFCompressionOldJPEG  = 32865
} NSTIFFCompression;

enum {
  NSImageRepMatchesDevice
};

//
// Colorspace Names 
//
extern NSString *NSCalibratedWhiteColorSpace; 
extern NSString *NSCalibratedBlackColorSpace; 
extern NSString *NSCalibratedRGBColorSpace;
extern NSString *NSDeviceWhiteColorSpace;
extern NSString *NSDeviceBlackColorSpace;
extern NSString *NSDeviceRGBColorSpace;
extern NSString *NSDeviceCMYKColorSpace;
extern NSString *NSNamedColorSpace;
extern NSString *NSCustomColorSpace;

//
// Gray Values 
//
extern const float NSBlack;
extern const float NSDarkGray;
extern const float NSWhite;
extern const float NSLightGray;

//
// Device Dictionary Keys 
//
extern NSString *NSDeviceResolution;
extern NSString *NSDeviceColorSpaceName;
extern NSString *NSDeviceBitsPerSample;
extern NSString *NSDeviceIsScreen;
extern NSString *NSDeviceIsPrinter;
extern NSString *NSDeviceSize;

//
// Matrix
//
typedef enum _NSMatrixMode {
  NSRadioModeMatrix,
  NSHighlightModeMatrix,
  NSListModeMatrix,
  NSTrackModeMatrix 
} NSMatrixMode;

//
// Notifications
//
// NSApplication
extern NSString *NSApplicationDidBecomeActiveNotification;
extern NSString *NSApplicationDidFinishLaunchingNotification;
extern NSString *NSApplicationDidHideNotification;
extern NSString *NSApplicationDidResignActiveNotification;
extern NSString *NSApplicationDidUnhideNotification;
extern NSString *NSApplicationDidUpdateNotification;
extern NSString *NSApplicationWillBecomeActiveNotification;
extern NSString *NSApplicationWillFinishLaunchingNotification;
extern NSString *NSApplicationWillHideNotification;
extern NSString *NSApplicationWillResignActiveNotification;
extern NSString *NSApplicationWillUnhideNotification;
extern NSString *NSApplicationWillUpdateNotification;

// NSColorList
extern NSString *NSColorListChangedNotification;
// NSColorPanel
extern NSString *NSColorPanelColorChangedNotification;

// NSControl
extern NSString *NSControlTextDidBeginEditingNotification;
extern NSString *NSControlTextDidEndEditingNotification;
extern NSString *NSControlTextDidChangeNotification;

// NSImageRep
extern NSString *NSImageRepRegistryChangedNotification;

// NSSplitView
extern NSString *NSSplitViewDidResizeSubviewsNotification;
extern NSString *NSSplitViewWillResizeSubviewsNotification;

// NSText
extern NSString *NSTextDidBeginEditingNotification;
extern NSString *NSTextDidEndEditingNotification;
extern NSString *NSTextDidChangeNotification;

// NSView
extern NSString *NSViewFrameChangedNotification;
extern NSString *NSViewFocusChangedNotification;

// NSWindow
extern NSString *NSWindowDidBecomeKeyNotification;
extern NSString *NSWindowDidBecomeMainNotification;
extern NSString *NSWindowDidChangeScreenNotification;
extern NSString *NSWindowDidDeminiaturizeNotification;
extern NSString *NSWindowDidExposeNotification;
extern NSString *NSWindowDidMiniaturizeNotification;
extern NSString *NSWindowDidMoveNotification;
extern NSString *NSWindowDidResignKeyNotification;
extern NSString *NSWindowDidResignMainNotification;
extern NSString *NSWindowDidResizeNotification;
extern NSString *NSWindowDidUpdateNotification;
extern NSString *NSWindowWillCloseNotification;
extern NSString *NSWindowWillMiniaturizeNotification;
extern NSString *NSWindowWillMoveNotification;

// NSWorkspace
extern NSString *NSWorkspaceDidLaunchApplicationNotification;
extern NSString *NSWorkspaceDidMountNotification;
extern NSString *NSWorkspaceDidPerformFileOperationNotification;
extern NSString *NSWorkspaceDidTerminateApplicationNotification;
extern NSString *NSWorkspaceDidUnmountNotification;
extern NSString *NSWorkspaceWillLaunchApplicationNotification;
extern NSString *NSWorkspaceWillPowerOffNotification;
extern NSString *NSWorkspaceWillUnmountNotification;

//
// Panel
//
enum {
  NSOKButton = 1,
  NSCancelButton = 0
};

enum {
  NSAlertDefaultReturn = 1,
  NSAlertAlternateReturn = 0,
  NSAlertOtherReturn = -1,
  NSAlertErrorReturn  = -2
};	 

//
// Page Layout
//
enum {
  NSPLImageButton,
  NSPLTitleField,
  NSPLPaperNameButton,
  NSPLUnitsButton,
  NSPLWidthForm,
  NSPLHeightForm,
  NSPLOrientationMatrix,
  NSPLCancelButton,
  NSPLOKButton 
};

//
// Pasteboard
//

//
// Pasteboard Type Globals 
//
extern NSString *NSStringPboardType;
extern NSString *NSColorPboardType;
extern NSString *NSFileContentsPboardType;
extern NSString *NSFilenamesPboardType;
extern NSString *NSFontPboardType;
extern NSString *NSRulerPboardType;
extern NSString *NSPostScriptPboardType;
extern NSString *NSTabularTextPboardType;
extern NSString *NSRTFPboardType;
extern NSString *NSTIFFPboardType;
extern NSString *NSDataLinkPboardType;
extern NSString *NSGeneralPboardType;

//
// Pasteboard Name Globals 
//
extern NSString *NSDragPboard;
extern NSString *NSFindPboard;
extern NSString *NSFontPboard;
extern NSString *NSGeneralPboard;
extern NSString *NSRulerPboard;

//
// Printing
//
typedef enum _NSPrinterTableStatus {
  NSPrinterTableOK,
  NSPrinterTableNotFound,
  NSPrinterTableError
} NSPrinterTableStatus;

typedef enum _NSPrintingOrientation {
  NSPortraitOrientation,
  NSLandscapeOrientation
} NSPrintingOrientation;

typedef enum _NSPrintingPageOrder {
  NSDescendingPageOrder,
  NSSpecialPageOrder,
  NSAscendingPageOrder,
  NSUnknownPageOrder
} NSPrintingPageOrder;

typedef enum _NSPrintingPaginationMode {
  NSAutoPagination,
  NSFitPagination,
  NSClipPagination
} NSPrintingPaginationMode;

enum {
  NSPPSaveButton,
  NSPPPreviewButton,
  NSFaxButton,
  NSPPTitleField,
  NSPPImageButton,
  NSPPNameTitle,
  NSPPNameField,
  NSPPNoteTitle,
  NSPPNoteField,
  NSPPStatusTitle,
  NSPPStatusField,
  NSPPCopiesField,
  NSPPPageChoiceMatrix,
  NSPPPageRangeFrom,
  NSPPPageRangeTo,
  NSPPScaleField,
  NSPPOptionsButton,
  NSPPPaperFeedButton,
  NSPPLayoutButton
};

//
// Printing Information Dictionary Keys 
//
extern NSString *NSPrintAllPages;
extern NSString *NSPrintBottomMargin;
extern NSString *NSPrintCopies;
extern NSString *NSPrintFaxCoverSheetName;
extern NSString *NSPrintFaxHighResolution;
extern NSString *NSPrintFaxModem;
extern NSString *NSPrintFaxReceiverNames;
extern NSString *NSPrintFaxReceiverNumbers;
extern NSString *NSPrintFaxReturnReceipt;
extern NSString *NSPrintFaxSendTime;
extern NSString *NSPrintFaxTrimPageEnds;
extern NSString *NSPrintFaxUseCoverSheet;
extern NSString *NSPrintFirstPage;
extern NSString *NSPrintHorizonalPagination;
extern NSString *NSPrintHorizontallyCentered;
extern NSString *NSPrintJobDisposition;
extern NSString *NSPrintJobFeatures;
extern NSString *NSPrintLastPage;
extern NSString *NSPrintLeftMargin;
extern NSString *NSPrintManualFeed;
extern NSString *NSPrintOrientation;
extern NSString *NSPrintPackageException;
extern NSString *NSPrintPagesPerSheet;
extern NSString *NSPrintPaperFeed;
extern NSString *NSPrintPaperName;
extern NSString *NSPrintPaperSize;
extern NSString *NSPrintPrinter;
extern NSString *NSPrintReversePageOrder;
extern NSString *NSPrintRightMargin;
extern NSString *NSPrintSavePath;
extern NSString *NSPrintScalingFactor;
extern NSString *NSPrintTopMargin;
extern NSString *NSPrintVerticalPagination;
extern NSString *NSPrintVerticallyCentered;

//
// Print Job Disposition Values 
//
extern NSString *NSPrintCancelJob;
extern NSString *NSPrintFaxJob;
extern NSString *NSPrintPreviewJob;
extern NSString *NSPrintSaveJob;
extern NSString *NSPrintSpoolJob;

//
// Save Panel
//
enum {
  NSFileHandlingPanelImageButton,
  NSFileHandlingPanelTitleField,
  NSFileHandlingPanelBrowser,
  NSFileHandlingPanelCancelButton,
  NSFileHandlingPanelOKButton,
  NSFileHandlingPanelForm, 
  NSFileHandlingPanelHomeButton, 
  NSFileHandlingPanelDiskButton, 
  NSFileHandlingPanelDiskEjectButton 
};

//
// Scroller
//
typedef enum _NSScrollArrowPosition {
  NSScrollerArrowsMaxEnd,
  NSScrollerArrowsMinEnd,
  NSScrollerArrowsNone 
} NSScrollArrowPosition;

typedef enum _NSScrollerPart {
  NSScrollerNoPart,
  NSScrollerDecrementPage,
  NSScrollerKnob,
  NSScrollerIncrementPage,
  NSScrollerDecrementLine,
  NSScrollerIncrementLine,
  NSScrollerKnobSlot 
} NSScrollerPart;

typedef enum _NSScrollerUsablePart {
  NSNoScrollerParts,
  NSOnlyScrollerArrows,
  NSAllScrollerParts  
} NSUsableScrollerParts;

typedef enum _NSScrollerArrow {
  NSScrollerIncrementArrow,
  NSScrollerDecrementArrow
} NSScrollerArrow;

const float NSScrollerWidth;

//
// Text
//
typedef short NSLineDesc;

typedef struct _NSTextChunk {
  short   growby;
  int allocated;
  int used;
} NSTextChunk;

typedef struct _NSBreakArray {
  NSTextChunk chunk;
  NSLineDesc  breaks[1];
} NSBreakArray;

typedef struct _NSCharArray {
  NSTextChunk chunk;
  unsigned char text[1];
} NSCharArray;

typedef unsigned short (*NSCharFilterFunc) (unsigned short charCode,
					    int flags, 
					    NSStringEncoding theEncoding);

typedef struct _NSFSM {
  const struct _NSFSM  *next;
  short   delta;
  short   token;
} NSFSM;

typedef struct _NSHeightInfo {
  float newHeight;
  float oldHeight;
  NSLineDesc  lineDesc;
} NSHeightInfo;

typedef struct _NSHeightChange {
  NSLineDesc  lineDesc;
  NSHeightInfo heightInfo;
} NSHeightChange;

typedef struct {
  unsigned int underline:1;
  unsigned int dummy:1;
  unsigned int subclassWantsRTF:1;
  unsigned int graphic:1;
  unsigned int forcedSymbol:1;
  unsigned int RESERVED:11;
} NSRunFlags;

typedef struct _NSRun {
  id  font;
  int chars;
  void   *paraStyle;
  int  textRGBColor;
  unsigned char   superscript;
  unsigned char   subscript;
  id   info;
  NSRunFlags rFlags;
} NSRun;

typedef struct {
  unsigned int mustMove:1;
  unsigned int isMoveChar:1;
  unsigned int RESERVED:14;
} NSLayFlags;

typedef struct _NSLay {
  float x;
  float y;
  short   offset;
  short   chars;
  id  font;
  void   *paraStyle;
  NSRun *run;
  NSLayFlags lFlags;
} NSLay;

typedef struct _NSLayArray {
  NSTextChunk chunk;
  NSLay   lays[1];
} NSLayArray;

typedef struct _NSWidthArray {
  NSTextChunk chunk;
  float widths[1];
} NSWidthArray;

typedef struct _NSTextBlock {
  struct _NSTextBlock *next;
  struct _NSTextBlock *prior;
  struct _tbFlags {
    unsigned int malloced:1;
    unsigned int PAD:15;
  } tbFlags;
  short   chars;
  unsigned char *text;
} NSTextBlock;

typedef struct _NSTextCache {
  int curPos;
  NSRun *curRun;
  int runFirstPos;
  NSTextBlock *curBlock;
  int blockFirstPos;
} NSTextCache;

typedef struct _NSLayInfo {
  NSRect rect;
  float descent;
  float width;
  float left;
  float right;
  float rightIndent;
  NSLayArray *lays;
  NSWidthArray *widths;
  NSCharArray *chars;
  NSTextCache cache;
  NSRect *textClipRect;
  struct _lFlags {
    unsigned int horizCanGrow:1;
    unsigned int vertCanGrow:1;
    unsigned int erase:1;
    unsigned int ping:1;
    unsigned int endsParagraph:1;
    unsigned int resetCache:1;
    unsigned int RESERVED:10;
  } lFlags;
} NSLayInfo;

typedef enum _NSParagraphProperty {
  NSLeftAlignedParagraph,
  NSRightAlignedParagraph,
  NSCenterAlignedParagraph,
  NSJustificationAlignedParagraph,
  NSFirstIndentParagraph,
  NSIndentParagraph,
  NSAddTabParagraph,
  NSRemoveTabParagraph,
  NSLeftMarginParagraph,
  NSRightMarginParagraph  
} NSParagraphProperty;

typedef struct _NSRunArray {
  NSTextChunk chunk;
  NSRun   runs[1];
} NSRunArray;

typedef struct _NSSelPt {
  int cp;
  int line;
  float x;
  float y;
  int c1st;
  float ht;
} NSSelPt;

typedef struct _NSTabStop {
  short   kind;
  float x;
} NSTabStop;

typedef char  *(*NSTextFilterFunc) (id self,
				    unsigned char * insertText, 
				    int *insertLength, 
				    int position);

typedef int (*NSTextFunc) (id self,
			   NSLayInfo *layInfo);

typedef enum _NSTextAlignment {
  NSLeftTextAlignment,
  NSRightTextAlignment,
  NSCenterTextAlignment,
  NSJustifiedTextAlignment,
  NSNaturalTextAlignment
} NSTextAlignment;

typedef struct _NSTextStyle {
  float indent1st;
  float indent2nd;
  float lineHt;
  float descentLine;
  NSTextAlignment   alignment;
  short   numTabs;
  NSTabStop  *tabs;
} NSTextStyle;

enum {
  NSLeftTab
};

enum {
  NSBackspaceKey   = 8,
  NSCarriageReturnKey   = 13,
  NSDeleteKey= 0x7f,
  NSBacktabKey   = 25
};

enum {
  NSIllegalTextMovement  = 0,
  NSReturnTextMovement  = 0x10,
  NSTabTextMovement   = 0x11,
  NSBacktabTextMovement  = 0x12,
  NSLeftTextMovement   = 0x13,
  NSRightTextMovement   = 0x14,
  NSUpTextMovement   = 0x15,
  NSDownTextMovement   = 0x16
};	 	

enum {
  NSTextBlockSize   = 512
};

//
// Break Tables 
//
const NSFSM *NSCBreakTable;
int NSCBreakTableSize;
const NSFSM *NSEnglishBreakTable;
int NSEnglishBreakTableSize;
const NSFSM *NSEnglishNoBreakTable;
int NSEnglishNoBreakTableSize;

//
// Character Category Tables 
//
const unsigned char *NSCCharCatTable;
const unsigned char *NSEnglishCharCatTable;

//
// Click Tables 
//
const NSFSM *NSCClickTable;
int NSCClickTableSize;
const NSFSM *NSEnglishClickTable;
int NSEnglishClickTableSize;

//
// Smart Cut and Paste Tables 
//
const unsigned char *NSCSmartLeftChars;
const unsigned char *NSCSmartRightChars;
const unsigned char *NSEnglishSmartLeftChars;
const unsigned char *NSEnglishSmartRightChars;

//
// NSCStringText Internal State Structure
//
typedef struct _NSCStringTextInternalState  {
  const NSFSM *breakTable;
  const NSFSM *clickTable;
  const unsigned char *preSelSmartTable;
  const unsigned char *postSelSmartTable;
  const unsigned char *charCategoryTable;
  char delegateMethods;
  NSCharFilterFunc charFilterFunc;
  NSTextFilterFunc textFilterFunc;
  NSString *_string;
  NSTextFunc scanFunc;
  NSTextFunc drawFunc;
  id delegate;
  int tag;
  void *cursorTE;
  NSTextBlock *firstTextBlock;
  NSTextBlock *lastTextBlock;
  NSRunArray  *theRuns;
  NSRun  typingRun;
  NSBreakArray *theBreaks;
  int growLine;
  int textLength;
  float maxY;
  float maxX;
  NSRect bodyRect;
  float borderWidth;
  char clickCount;
  NSSelPt sp0;
  NSSelPt spN;
  NSSelPt anchorL;
  NSSelPt anchorR;
  NSSize maxSize;
  NSSize minSize;
  struct _tFlags {
#ifdef __BIG_ENDIAN__
    unsigned int _editMode:2;
    unsigned int _selectMode:2;
    unsigned int _caretState:2;
    unsigned int changeState:1;
    unsigned int charWrap:1;
    unsigned int haveDown:1;
    unsigned int anchorIs0:1;
    unsigned int horizResizable:1;
    unsigned int vertResizable:1;
    unsigned int overstrikeDiacriticals:1;
    unsigned int monoFont:1;
    unsigned int disableFontPanel:1;
    unsigned int inClipView:1;
#else
    unsigned int inClipView:1;
    unsigned int disableFontPanel:1;
    unsigned int monoFont:1;
    unsigned int overstrikeDiacriticals:1;
    unsigned int vertResizable:1;
    unsigned int horizResizable:1;
    unsigned int anchorIs0:1;
    unsigned int haveDown:1;
    unsigned int charWrap:1;
    unsigned int changeState:1;
    unsigned int _caretState:2;
    unsigned int _selectMode:2;
    unsigned int _editMode:2;
#endif
  } tFlags;
  void *_info;
  void *_textStr;
}  NSCStringTextInternalState;

//
// View
//
typedef int NSTrackingRectTag;

typedef enum _NSBorderType {
  NSNoBorder,
  NSLineBorder,
  NSBezelBorder,
  NSGrooveBorder 
} NSBorderType;

enum {
  NSViewNotSizable,
  NSViewMinXMargin,
  NSViewWidthSizable,
  NSViewMaxXMargin,
  NSViewMinYMargin,
  NSViewHeightSizable,
  NSViewMaxYMargin 
};

//
// Window 
//
enum {
  NSNormalWindowLevel   = 0,
  NSFloatingWindowLevel  = 3,
  NSDockWindowLevel   = 5,
  NSSubmenuWindowLevel  = 10,
  NSMainMenuWindowLevel  = 20
};

enum {
  NSBorderlessWindowMask = 1,
  NSTitledWindowMask = 2,
  NSClosableWindowMask = 4,
  NSMiniaturizableWindowMask = 8,
  NSResizableWindowMask = 16 
};

//
// Size Globals 
//
NSSize NSIconSize;
NSSize NSTokenSize;

//
// Workspace
//

//
// Workspace File Type Globals 
//

extern NSString *NSPlainFileType;
extern NSString *NSDirectoryFileType;
extern NSString *NSApplicationFileType;
extern NSString *NSFilesystemFileType;
extern NSString *NSShellCommandFileType;

//
// Workspace File Operation Globals 
//
extern NSString *NSWorkspaceCompressOperation;
extern NSString *NSWorkspaceCopyOperation;
extern NSString *NSWorkspaceDecompressOperation;
extern NSString *NSWorkspaceDecryptOperation;
extern NSString *NSWorkspaceDestroyOperation;
extern NSString *NSWorkspaceDuplicateOperation;
extern NSString *NSWorkspaceEncryptOperation;
extern NSString *NSWorkspaceLinkOperation;
extern NSString *NSWorkspaceMoveOperation;
extern NSString *NSWorkspaceRecycleOperation;

#endif // _GNUstep_H_GUITypes
