/* 
   NSCStringText.h

   C string text class

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: 1997
   
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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/ 

#ifndef _GNUstep_H_NSCStringText
#define _GNUstep_H_NSCStringText

#include <Foundation/NSString.h>
#include <AppKit/NSText.h>
#include <AppKit/NSFontManager.h>

@class NSCell;
@class NSPasteBoard;

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
  NSTextBlockSize   = 512
};

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


@interface NSCStringText : NSText
           <NSChangeSpelling, NSIgnoreMisspelledWords, NSCoding>

{
  // Attributes
}


//
// Initializing a New NSCStringText Object
//
- (id)initWithFrame:(NSRect)frameRect
               text:(NSString *)theText
          alignment:(NSTextAlignment)mode;

//
// Modifying the Frame Rectangle
//
- (void)resizeTextWithOldBounds:(NSRect)oldBounds
                        maxRect:(NSRect)maxRect;

//
// Laying Out the Text
//
- (int)calcLine;
- (BOOL)changeTabStopAt:(float)oldX
                     to:(float)newX;
- (BOOL)charWrap;
- (void *)defaultParagraphStyle;
- (float)descentLine;
- (void)getMarginLeft:(float *)leftMargin
                right:(float *)rightMargin
		  top:(float *)topMargin
	       bottom:(float *)bottomMargin;
- (void)getMinWidth:(float *)width
          minHeight:(float *)height
           maxWidth:(float)widthMax
          maxHeight:(float)heightMax;
- (float)lineHeight;
- (void *)paragraphStyleForFont:(NSFont *)fontId
                      alignment:(int)alignment;
- (void)setCharWrap:(BOOL)flag;
- (void)setDescentLine:(float)value;
- (void)setLineHeight:(float)value;
- (void)setMarginLeft:(float)leftMargin
                right:(float)rightMargin
                  top:(float)topMargin
               bottom:(float)bottomMargin;
- (void)setNoWrap;
- (void)setParagraphStyle:(void *)paraStyle;
- (BOOL)setSelProp:(NSParagraphProperty)property
                to:(float)value;

//
// Reporting Line and Position
//
- (int)lineFromPosition:(int)position;
- (int)positionFromLine:(int)line;

//
// Reading and Writing Text
//
- (void)finishReadingRichText;
- (NSTextBlock *)firstTextBlock;
- (NSRect)paragraphRect:(int)paraNumber
                  start:(int *)startPos
                    end:(int *)endPos;
- (void)startReadingRichText;

//
// Editing Text
//
- (void)clear:(id)sender;
- (void)hideCaret;
- (void)showCaret;

//
// Managing the Selection
//
- (void)getSelectionStart:(NSSelPt *)start
                      end:(NSSelPt *)end;
- (void)replaceSel:(NSString *)aString;
- (void)replaceSel:(NSString *)aString
            length:(int)length;
- (void)replaceSel:(NSString *)aString
            length:(int)length
              runs:(NSRunArray *)insertRuns;
- (void)scrollSelToVisible;
- (void)selectError;
- (void)selectNull;
- (void)setSelectionStart:(int)start
                      end:(int)end;
- (void)selectText:(id)sender;

//
// Setting the font
//
+ (NSFont *)defaultFont;
+ (void)setDefaultFont:(NSFont *)anObject;
- (void)setFont:(NSFont *)fontObj
 paragraphStyle:(void *)paragraphStyle;
- (void)setSelFont:(NSFont *)fontObj;
- (void)setSelFont:(NSFont *)fontObj
    paragraphStyle:(void *)paragraphStyle;
- (void)setSelFontFamily:(NSString *)fontName;
- (void)setSelFontSize:(float)size;
- (void)setSelFontStyle:(NSFontTraitMask)traits;

//
// Finding Text
//
- (BOOL)findText:(NSString *)textPattern
      ignoreCase:(BOOL)ignoreCase
       backwards:(BOOL)backwards
            wrap:(BOOL)wrap;

//
// Modifying Graphics Attributes
//
- (NSColor *)runColor:(NSRun *)run;
- (NSColor *)selColor;
- (void)setSelColor:(NSColor *)color;

//
// Reusing an NSCStringText Object
//
- (void)renewFont:(NSFont *)newFontObj
             text:(NSString *)newText
            frame:(NSRect)newFrame
              tag:(int)newTag;
- (void)renewFont:(NSString *)newFontName
             size:(float)newFontSize
            style:(int)newFontStyle
	     text:(NSString *)newText
            frame:(NSRect)newFrame
              tag:(int)newTag;
- (void)renewRuns:(NSRunArray *)newRuns
             text:(NSString *)newText
            frame:(NSRect)newFrame
              tag:(int)newTag;

//
// Setting Window Attributes
//
- (BOOL)isRetainedWhileDrawing;
- (void)setRetainedWhileDrawing:(BOOL)flag;

//
// Assigning a Tag
//
- (void)setTag:(int)anInt;
- (int)tag;

//
// Handling Event Messages
//
- (void)becomeKeyWindow;
- (void)moveCaret:(unsigned short)theKey;
- (void)resignKeyWindow;

//
// Displaying Graphics within the Text
//
+ registerDirective:(NSString *)directive
           forClass:class;
- (NSPoint)locationOfCell:(NSCell *)cell;
- (void)replaceSelWithCell:(NSCell *)cell;
- (void)setLocation:(NSPoint)origin
             ofCell:(NSCell *)cell;
+ excludeFromServicesMenu:(BOOL)flag;
- (BOOL)readSelectionFromPasteboard:(NSPasteBoard *)pboard;
- (id)validRequestorForSendType:(NSString *)sendType
                     returnType:(NSString *)returnType;
- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
                             types:(NSArray *)types;

//
// Setting Tables and Functions
//
- (const NSFSM *)breakTable;
- (const unsigned char *)charCategoryTable;
- (NSCharFilterFunc)charFilter;
- (const NSFSM *)clickTable;
- (NSTextFunc)drawFunc;
- (const unsigned char *)postSelSmartTable;
- (const unsigned char *)preSelSmartTable;
- (NSTextFunc)scanFunc;
- (void)setBreakTable:(const NSFSM *)aTable;
- (void)setCharCategoryTable:(const unsigned char *)aTable;
- (void)setCharFilter:(NSCharFilterFunc)aFunction;
- (void)setClickTable:(const NSFSM *)aTable;
- (void)setDrawFunc:(NSTextFunc)aFunction;
- (void)setPostSelSmartTable:(const unsigned char *)aTable;
- (void)setPreSelSmartTable:(const unsigned char *)aTable;
- (void)setScanFunc:(NSTextFunc)aFunction;
- (void)setTextFilter:(NSTextFilterFunc)aFunction;
- (NSTextFilterFunc)textFilter;

//
// Printing
//
- (void)adjustPageHeightNew:(float *)newBottom
                        top:(float)oldTop
                     bottom:(float)oldBottom
                      limit:(float)bottomLimit;
- (NSSize)cellSize;
- (void)drawWithFrame:(NSRect)cellFrame
               inView:(NSView *)controlView;
- (void)highlight:(BOOL)flag
        withFrame:(NSRect)cellFrame
           inView:(NSView *)controlView;
- (void)readRichText:(NSString *)stringObject
             forView:(NSView *)view;
- (NSString *)richTextForView:(NSView *)view;
- (BOOL)trackMouse:(NSEvent *)theEvent
            inRect:(NSRect)cellFrame
            ofView:(NSView *)controlView
      untilMouseUp:(BOOL)untilMouseUp;

//
// Implemented by the Delegate
//
- (void)textDidRead:(NSCStringText *)textObject
          paperSize:(NSSize)paperSize;
- (NSRect)textDidResize:(NSCStringText *)textObject
              oldBounds:(NSRect)oldBounds;
- (NSFont *)textWillConvert:(NSCStringText *)textObject
                     toFont:(NSFont *)font;
- (void)textWillFinishReadingRichText:(NSCStringText *)textObject;
- (void)textWillSetSel:(NSCStringText *)textObject
                toFont:(NSFont *)font;
- (void)textWillStartReadingRichText:(NSCStringText *)textObject;
- (NSSize)textWillWrite:(NSCStringText *)textObject;

//
// Compatibility Methods
//
- (NSCStringTextInternalState *)cStringTextInternalState;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

//
// NSChangeSpelling protocol
//
- (void) changeSpelling:(id)sender;

//
// NSIgnoreMisspelledWords protocol
//
- (void)ignoreSpelling:(id)sender;

@end

//
// Break Tables 
//
extern const NSFSM *NSCBreakTable;
extern int NSCBreakTableSize;
extern const NSFSM *NSEnglishBreakTable;
extern int NSEnglishBreakTableSize;
extern const NSFSM *NSEnglishNoBreakTable;
extern int NSEnglishNoBreakTableSize;

//
// Character Category Tables 
//
extern const unsigned char *NSCCharCatTable;
extern const unsigned char *NSEnglishCharCatTable;

//
// Click Tables 
//
extern const NSFSM *NSCClickTable;
extern int NSCClickTableSize;
extern const NSFSM *NSEnglishClickTable;
extern int NSEnglishClickTableSize;

//
// Smart Cut and Paste Tables 
//
extern const unsigned char *NSCSmartLeftChars;
extern const unsigned char *NSCSmartRightChars;
extern const unsigned char *NSEnglishSmartLeftChars;
extern const unsigned char *NSEnglishSmartRightChars;

//
// Calculate or Draw a Line of Text (in Text Object)
//
int NSDrawALine(id self, NSLayInfo *layInfo);
int NSScanALine(id self, NSLayInfo *layInfo);

//
// Calculate Font Ascender, Descender, and Line Height (in Text Object)
//
void NSTextFontInfo(id fid, 
		    float *ascender, float *descender, 
		    float *lineHeight);

//
// Access Text Object's Word Tables
//
NSData * NSDataWithWordTable(const unsigned char *smartLeft,
			     const unsigned char *smartRight,
			     const unsigned char *charClasses,
			     const NSFSM *wrapBreaks,
			     int wrapBreaksCount,
			     const NSFSM *clickBreaks, 
			     int clickBreaksCount, 
			     BOOL charWrap);
void NSReadWordTable(NSZone *zone,
		     NSData *data,
		     unsigned char **smartLeft,
		     unsigned char **smartRight,
		     unsigned char **charClasses,
		     NSFSM **wrapBreaks,
		     int *wrapBreaksCount,
		     NSFSM **clickBreaks,
		     int *clickBreaksCount, 
		     BOOL *charWrap);

//
// Array Allocation Functions for Use by the NSText Class
//
NSTextChunk *NSChunkCopy(NSTextChunk *pc, NSTextChunk *dpc);
NSTextChunk *NSChunkGrow(NSTextChunk *pc, int newUsed);
NSTextChunk *NSChunkMalloc(int growBy, int initUsed);
NSTextChunk *NSChunkRealloc(NSTextChunk *pc);
NSTextChunk *NSChunkZoneCopy(NSTextChunk *pc, 
                             NSTextChunk *dpc,
                             NSZone *zone);
NSTextChunk *NSChunkZoneGrow(NSTextChunk *pc, int newUsed, NSZone *zone);
NSTextChunk *NSChunkZoneMalloc(int growBy, int initUsed, NSZone *zone);
NSTextChunk *NSChunkZoneRealloc(NSTextChunk *pc, NSZone *zone);

//
// Filter Characters Entered into a Text Object
//
unsigned short NSEditorFilter(unsigned short theChar, 
			      int flags, NSStringEncoding theEncoding);
unsigned short NSFieldFilter(unsigned short theChar, 
			     int flags, NSStringEncoding theEncoding);

#endif // _GNUstep_H_NSCStringText
