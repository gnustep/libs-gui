/* 
   NSPrintOperation.m

   Controls operations generating EPS, PDF or PS print jobs.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: November 2000
   Started implementation.

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

#include <math.h>
#include "gnustep/gui/config.h"
#include <Foundation/NSString.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSData.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSException.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSTask.h>
#include <Foundation/NSThread.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSValue.h>
#include "AppKit/AppKitExceptions.h"
#include "AppKit/NSAffineTransform.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSGraphicsContext.h"
#include "AppKit/NSView.h"
#include "AppKit/NSPrinter.h"
#include "AppKit/NSPrintPanel.h"
#include "AppKit/NSPrintInfo.h"
#include "AppKit/NSPrintOperation.h"
#include "AppKit/NSWorkspace.h"
#include "AppKit/PSOperators.h"

#define NSNUMBER(a) [NSNumber numberWithInt: (a)]
#define NSFNUMBER(a) [NSNumber numberWithFloat: (a)]

/* Local pagination variables needed while printing */
typedef struct _page_info_t {
  NSRect scaledBounds;       /* View's rect scaled by the user specified scale
			        and page fitting */
  NSRect paperBounds;        /* Print area of a page in default user space, possibly
				rotated if printing Landscape */
  NSRect sheetBounds;        /* Print are of a page in default user space */
  NSSize paperSize;          /* Size of the paper */
  int xpages, ypages;
  int first, last;
  double pageScale;          /* Scaling determined from page fitting */
  double printScale;         /* User specified scaling */
  double nupScale;           /* Scale required to fit nup pages on the sheet */
  int    nup;                /* Number up pages to print on a sheet */
  double lastWidth, lastHeight;
  NSPrintingOrientation orient;
  int    pageDirection;      /* NSPrintPageDirection */
} page_info_t;

@interface NSPrintOperation (Private)

- (id) initWithView:(NSView *)aView
	 insideRect:(NSRect)rect
	     toData:(NSMutableData *)data
	  printInfo:(NSPrintInfo *)aPrintInfo;

- (void) _print;

@end

@interface NSPrintPanel (Private)
- (void) _setStatusStringValue: (NSString *)string;
@end


@interface NSView (NSPrintOperation)
- (void) _displayPageInRect: (NSRect)pageRect
	        atPlacement: (NSPoint)location
	           withInfo: (page_info_t)info;
- (void) _endSheet;
@end

@interface NSView (NPrintOperationPrivate)
- (void) _cleanupPrinting;
@end

// Subclass for the regular printing
@interface GSPrintOperation: NSPrintOperation
{
}

@end

// subclass for EPS output
@interface GSEPSPrintOperation: NSPrintOperation
{
}

- (id) initEPSOperationWithView:(NSView *)aView	
		     insideRect:(NSRect)rect
			 toPath:(NSString *)path
		      printInfo:(NSPrintInfo *)aPrintInfo;

@end

// subclass for PDF output
@interface GSPDFPrintOperation: NSPrintOperation
{
}

- (id) initPDFOperationWithView:(NSView *)aView 
		     insideRect:(NSRect)rect 
			 toData:(NSMutableData *)data 
		      printInfo:(NSPrintInfo*)aPrintInfo;
- (id) initPDFOperationWithView:(NSView *)aView 
		     insideRect:(NSRect)rect 
			 toPath:(NSString *)path 
		      printInfo:(NSPrintInfo*)aPrintInfo;

@end

static NSString *NSPrintOperationThreadKey = @"NSPrintOperationThreadKey";

/**
  <unit>
  <heading>Class Description</heading>
  <p>
  NSPrintOperation controls printing of an NSView. When invoked normally
  it will (optionally) display a standard print panel (NSPrintPanel), and
  based on the information entered by the user here as well as information
  about page layout (see NSPageLayout) tells the NSView to print it's 
  contents. NSPrintOperation works with the NSView to paginate the output
  into appropriately sized and oriented pages and finally delivers the result
  to the appropriate place, whether it be a printer, and PostScript file,
  or another output.
  </p>
  </unit>
*/ 
@implementation NSPrintOperation

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSPrintOperation class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Creating and Initializing an NSPrintOperation Object
//
+ (NSPrintOperation *)EPSOperationWithView:(NSView *)aView
				insideRect:(NSRect)rect
				    toData:(NSMutableData *)data
{
  return [self EPSOperationWithView: aView	
	       insideRect: rect
	       toData: data
	       printInfo: nil];
}

+ (NSPrintOperation *)EPSOperationWithView:(NSView *)aView	
				insideRect:(NSRect)rect
				    toData:(NSMutableData *)data
				 printInfo:(NSPrintInfo *)aPrintInfo
{
  return AUTORELEASE([[GSEPSPrintOperation alloc] initEPSOperationWithView: aView
						  insideRect: rect
						  toData: data
						  printInfo: aPrintInfo]);
}

+ (NSPrintOperation *)EPSOperationWithView:(NSView *)aView	
				insideRect:(NSRect)rect
				    toPath:(NSString *)path
				 printInfo:(NSPrintInfo *)aPrintInfo
{
  return AUTORELEASE([[GSEPSPrintOperation alloc] initEPSOperationWithView: aView	
						  insideRect: rect
						  toPath: path
						  printInfo: aPrintInfo]);
}

+ (NSPrintOperation *)printOperationWithView:(NSView *)aView
{
  return [self printOperationWithView: aView
	       printInfo: nil];
}

+ (NSPrintOperation *)printOperationWithView:(NSView *)aView
				   printInfo:(NSPrintInfo *)aPrintInfo
{
  return AUTORELEASE([[GSPrintOperation alloc] initWithView: aView
					       printInfo: aPrintInfo]);
}

+ (NSPrintOperation *)PDFOperationWithView:(NSView *)aView 
				insideRect:(NSRect)rect 
				    toData:(NSMutableData *)data
{
  return [self PDFOperationWithView: aView 
	       insideRect: rect 
	       toData: data 
	       printInfo: nil];
}

+ (NSPrintOperation *)PDFOperationWithView:(NSView *)aView 
				insideRect:(NSRect)rect 
				    toData:(NSMutableData *)data 
				 printInfo:(NSPrintInfo*)aPrintInfo
{
  return AUTORELEASE([[self alloc] initPDFOperationWithView: aView 
				   insideRect: rect 
				   toData: data 
				   printInfo: aPrintInfo]);
}

+ (NSPrintOperation *)PDFOperationWithView:(NSView *)aView 
				insideRect:(NSRect)rect 
				    toPath:(NSString *)path 
				 printInfo:(NSPrintInfo*)aPrintInfo
{
  return AUTORELEASE([[self alloc] initPDFOperationWithView: aView 
				   insideRect: rect 
				   toPath: path 
				   printInfo: aPrintInfo]);
}

//
// Setting the Print Operation
//
/** Returns the NSPrintOperation object that is currently performing
    a print operation (if any).
*/
+ (NSPrintOperation *)currentOperation
{
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];

  return (NSPrintOperation*)[dict objectForKey: NSPrintOperationThreadKey];
}

/** Set the current NSPrintOperation to the supplied operation
    object. As this is currently implemented, if a NSPrintOperation
    is currently running, that operation is lost (along with any
    associated context), so be careful to call this only when there is
    no current operation.
*/
+ (void)setCurrentOperation:(NSPrintOperation *)operation
{
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];

  if (operation == nil)
    [dict removeObjectForKey: NSPrintOperationThreadKey];
  else
    [dict setObject: operation forKey: NSPrintOperationThreadKey];
}

//
// Instance methods
//
//
// Creating and Initializing an NSPrintOperation Object
//

- (id)initEPSOperationWithView:(NSView *)aView
		    insideRect:(NSRect)rect
			toData:(NSMutableData *)data
		     printInfo:(NSPrintInfo *)aPrintInfo
{
  RELEASE(self);
  
  return [[GSEPSPrintOperation alloc] initEPSOperationWithView: aView	
				      insideRect: rect
				      toData: data
				      printInfo: aPrintInfo];
}

- (id)initWithView:(NSView *)aView
	 printInfo:(NSPrintInfo *)aPrintInfo
{
  RELEASE(self);
  
  return [[GSPrintOperation alloc] initWithView: aView
				   printInfo: aPrintInfo];
}

- (void) dealloc
{
  RELEASE(_printInfo);
  RELEASE(_view);  
  RELEASE(_data);
  TEST_RELEASE(_context);
  TEST_RELEASE(_printPanel);  
  TEST_RELEASE(_accessoryView);  
  TEST_RELEASE(_path);  

  [super dealloc];
}

//
// Determining the Type of Operation
//
/** Returns YES if the receiver is performing an operation whose output
    is EPS format.
*/
- (BOOL)isEPSOperation
{
  return NO;
}

- (BOOL)isCopyingOperation
{
  return NO;
}

//
// Controlling the User Interface
//
/** Returns the NSPrintPanel associated with the receiver.
 */
- (NSPrintPanel *)printPanel
{
  if (_printPanel == nil)
    ASSIGN(_printPanel, [NSPrintPanel printPanel]); 

  return _printPanel;
}

/** Returns YES if the reciever display an NSPrintPanel and other information
    when running a print operation. */
- (BOOL)showPanels
{
  return _showPanels;
}

/** Sets the NSPrintPanel used by the receiver obtaining and displaying
    printing information from/to the user.
*/
- (void)setPrintPanel:(NSPrintPanel *)panel
{
  ASSIGN(_printPanel, panel);
}

/** Use this to set whether a print panel is displayed during a printing
    operation. If set to NO, then the receiver uses information that
    was previously set and does not display any status information about the
    progress of the printing operation.
*/
- (void)setShowPanels:(BOOL)flag
{
  _showPanels = flag;
}

/** Returns the accessory view used by the NSPrintPanel associated with
    the receiver.
*/
- (NSView *)accessoryView
{
  return _accessoryView;
}

/** Set the accessory view used by the NSPrintPanel associated with the
    receiver.
*/
- (void)setAccessoryView:(NSView *)aView
{
  ASSIGN(_accessoryView, aView);
}

//
// Managing the drawing Context
//
/** This method is used by the print operation to create a special
   graphics context for use while running the print operation.
*/
- (NSGraphicsContext*)createContext
{
  [self subclassResponsibility: _cmd];
  return nil;
}

/** Returns the graphic contexts used by the print operation.
*/
- (NSGraphicsContext *)context
{
  return _context;
}

/** This method is used by the print operation to destroy the special
    graphic context used while running the print operation.
*/
- (void)destroyContext
{
  DESTROY(_context);
}

//
// Page Information
//
/** Returns the page currently being printing. Returns 0 if no page
    is currently being printed
*/
- (int)currentPage
{
  return _currentPage;
}

/** Returns the page order of printing.
*/
- (NSPrintingPageOrder)pageOrder
{
  return _pageOrder;
}

/** Set the page order used when printing.
 */
- (void)setPageOrder:(NSPrintingPageOrder)order
{
  _pageOrder = order;
}

//
// Running a Print Operation
//
/** Called by the print operation after it has finished running a printing
    operation.
*/
- (void)cleanUpOperation
{
  [[self printPanel] orderOut: self];
  _currentPage = 0;
  [NSPrintOperation setCurrentOperation: nil];
}

/** Called by the print operation to deliver the results of the printing
    operation. This might include sending the output to a printer, a file
    or a previewing program. Returns YES if the output was delivered 
    sucessfully.
*/
- (BOOL)deliverResult
{
  return NO;
}

/* Private method to run the printing operation. Needs to create an
   autoreleaes pool to make sure the print context is destroyed before
   returning (which closes the print file.) */
- (BOOL) _runOperation
{
  BOOL result;
  CREATE_AUTORELEASE_POOL(pool);
  NSGraphicsContext *oldContext = [NSGraphicsContext currentContext];

  [self createContext];
  if (_context == nil)
    return NO;

  result = NO;
  if (_pageOrder == NSUnknownPageOrder)
    {
      if ([[[_printInfo dictionary] objectForKey: NSPrintReversePageOrder] 
	    boolValue] == YES)
	_pageOrder = NSDescendingPageOrder;
      else
	_pageOrder = NSAscendingPageOrder;
    }

  [NSGraphicsContext setCurrentContext: _context];
  NS_DURING
    {
      [self _print];
      result = YES;
      [NSGraphicsContext setCurrentContext: oldContext];
    }
  NS_HANDLER
    {
      [_view _cleanupPrinting];
      [NSGraphicsContext setCurrentContext: oldContext];
      NSRunAlertPanel(@"Error", @"Printing error: %@", 
		      @"OK", NULL, NULL, localException);
    }
  NS_ENDHANDLER
  [self destroyContext];
  RELEASE(pool);
  return result;
}

- (void) _setupPrintInfo
{
  BOOL knowsPageRange;
  NSRange viewPageRange;
  NSMutableDictionary *dict = [_printInfo dictionary];

  knowsPageRange = [_view knowsPageRange: &viewPageRange]; 
  if (knowsPageRange == YES)
    {
      int first = viewPageRange.location;
      int last = NSMaxRange(viewPageRange) - 1;
      [dict setObject: NSNUMBER(first) forKey: NSPrintFirstPage];
      [dict setObject: NSNUMBER(last) forKey: NSPrintLastPage];
    }
}

/** Call this message to run the print operation on a view. This includes
    (optionally) displaying a print panel and working with the NSView to
    paginate and draw the contents of the view.
*/
- (BOOL)runOperation
{
  BOOL result;

  if (_showPanels)
    {
      NSPrintPanel *panel = [self printPanel];
      int button;
      
      [panel setAccessoryView: _accessoryView];
      [self _setupPrintInfo];
      [panel updateFromPrintInfo];
      button = [panel runModal];
      [panel setAccessoryView: nil];

      if (button != NSOKButton)
	{
	  [self cleanUpOperation];
	  return NO;
	}
      [panel finalWritePrintInfo];
    }

  result = NO;
  if ([self _runOperation])
    result = [self deliverResult];
  [self cleanUpOperation];

  return result;
}

- (void)_printOperationDidRun:(NSPrintOperation *)printOperation 
		      success:(BOOL)success  
		  contextInfo:(void *)contextInfo
{
  id delegate;
  SEL *didRunSelector;
  NSMutableDictionary *dict;
  void (*didRun)(id, SEL, BOOL, id);

  if (success == YES)
    {
      NSPrintPanel *panel = [self printPanel];
      [panel finalWritePrintInfo];
      success = NO;
      if ([self _runOperation])
	success = [self deliverResult];
    }
  [self cleanUpOperation];
  dict = [_printInfo dictionary];
  didRunSelector = [[dict objectForKey: @"GSModalRunSelector"] pointerValue];
  delegate = [dict objectForKey: @"GSModalRunDelegate"];
  didRun = (void (*)(id, SEL, BOOL, id))[delegate methodForSelector: 
						    *didRunSelector];
  didRun (delegate, *didRunSelector, success, contextInfo);
}

/** Run a print operation modally with respect to a window.
 */
- (void)runOperationModalForWindow: (NSWindow *)docWindow 
			  delegate: (id)delegate 
		    didRunSelector: (SEL)didRunSelector 
		       contextInfo:(void *)contextInfo
{
  NSMutableDictionary *dict;
  NSPrintPanel *panel = [self printPanel];

  /* Save the selector so we can use it later */
  dict = [_printInfo dictionary];
  [dict setObject: [NSValue value: &didRunSelector withObjCType: @encode(SEL)]
	   forKey: @"GSModalRunSelector"];
  [dict setObject: delegate
	   forKey: @"GSModalRunDelegate"];

  /* Assume we want to show the panel regardless of the value
     of _showPanels 
  */
  [panel setAccessoryView: _accessoryView];
  [self _setupPrintInfo];
  [panel updateFromPrintInfo];
  [panel beginSheetWithPrintInfo: _printInfo 
	          modalForWindow: docWindow 
			delegate: delegate 
		  didEndSelector: 
		          @selector(_printOperationDidRun:sucess:contextInfo:)
		      contextInfo: contextInfo];
  [panel setAccessoryView: nil];
}

//
// Getting the NSPrintInfo Object
//
/** Returns the NSPrintInfo object associated with the receiver.
*/
- (NSPrintInfo *)printInfo
{
  return _printInfo;
}

/** Set the NSPrintInfo object associated with the receiver.
 */
- (void)setPrintInfo:(NSPrintInfo *)aPrintInfo
{
  if (aPrintInfo == nil)
    aPrintInfo = [NSPrintInfo sharedPrintInfo];

  ASSIGNCOPY(_printInfo, aPrintInfo);
}

//
// Getting the NSView Object
//
/** Return the view that is the being printed.
*/
- (NSView *)view
{
  return _view;
}

@end


@implementation NSPrintOperation (Private)

- (id) initWithView:(NSView *)aView
	 insideRect:(NSRect)rect
	     toData:(NSMutableData *)data
	  printInfo:(NSPrintInfo *)aPrintInfo
{
  if ([NSPrintOperation currentOperation] != nil)
    [NSException raise: NSPrintOperationExistsException
		 format: @"There is already a printoperation for this thread"];

  ASSIGN(_view, aView);
  _rect = rect;
  ASSIGN(_data, data);
  _pageOrder = NSUnknownPageOrder;
  _showPanels = NO;
  [self setPrintInfo: aPrintInfo];

  _path = [NSTemporaryDirectory() stringByAppendingPathComponent: @"GSPrint-"];
  _path = [_path stringByAppendingString: 
		   [[NSProcessInfo processInfo] globallyUniqueString]];
  _path = [_path stringByAppendingPathExtension: @"ps"];
  RETAIN(_path);
  _pathSet = NO;
  _currentPage = 0;

  [NSPrintOperation setCurrentOperation: self];
  return self;
}

static NSSize
scaleSize(NSSize size, double scale)
{
  size.height *= scale;
  size.width  *= scale;
  return size;
}

static NSRect
scaleRect(NSRect rect, double scale)
{
  return NSMakeRect(NSMinX(rect) * scale,
		    NSMinY(rect) * scale,
		    NSWidth(rect) * scale,
		    NSHeight(rect) * scale);
}

/* Pagination - guess how many pages we need to print. This could be off
   by one in both X and Y because of the view's ability to adjust the
   width and height of the printRect during printing. Also set up a bunch
   of other information needed for printing.
*/
- (void) _printPaginateWithInfo: (page_info_t *)info knowsRange: (BOOL)knowsRange
{
  NSMutableDictionary *dict;
  dict = [_printInfo dictionary];

  info->paperSize = [_printInfo paperSize];
  info->orient = [_printInfo orientation];
  info->printScale = [[dict objectForKey: NSPrintScalingFactor] doubleValue];
  info->nup = [[dict objectForKey: NSPrintPagesPerSheet] intValue];
  info->nupScale = 1;
  if (info->nup < 1 || (info->nup > 1 && (((info->nup) & 0x1) == 1)))
    {
      /* Bad nup value */
      info->nup = 1;
      [dict setObject: NSNUMBER(1) forKey: NSPrintPagesPerSheet];
    }

  /* Subtract the margins from the paper size to get print boundary */
  info->paperBounds.size = info->paperSize;
  info->paperBounds.origin.x = [_printInfo leftMargin];
  info->paperBounds.origin.y = [_printInfo bottomMargin];
  info->paperBounds.size.width -= 
    ([_printInfo rightMargin]+[_printInfo leftMargin]);
  info->paperBounds.size.height -= 
    ([_printInfo topMargin]+[_printInfo bottomMargin]);

  info->sheetBounds = info->paperBounds;
  if (info->orient == NSLandscapeOrientation)
    {
      /* Bounding box needs to be in default user space, but the bbox
	 we get is rotated */
      info->sheetBounds = NSMakeRect(NSMinY(info->paperBounds), 
				     NSMinX(info->paperBounds), 
				     NSHeight(info->paperBounds), 
				     NSWidth(info->paperBounds));
    }
  /* Save this for the view to look at */
  [dict setObject: [NSValue valueWithRect: info->paperBounds]
 	   forKey: @"NSPrintPaperBounds"];
  [dict setObject: [NSValue valueWithRect: info->sheetBounds]
 	   forKey: @"NSPrintSheetBounds"];

   /* Scale bounds by the user specified scaling */
  info->scaledBounds = scaleRect(_rect, info->printScale);

  if (knowsRange == NO)
    {
      /* Now calculate page fitting to get page scale */
      info->pageScale = 1;
      if ([_printInfo horizontalPagination] == NSFitPagination)
	info->pageScale  = info->paperBounds.size.width 
	  / NSWidth(info->scaledBounds);
      if ([_printInfo verticalPagination] == NSFitPagination)
	info->pageScale = MIN(info->pageScale,
	  NSHeight(info->paperBounds)/NSHeight(info->scaledBounds));
      /* Scale bounds by pageScale */
      info->scaledBounds = scaleRect(info->scaledBounds, info->pageScale);

      /* Now find out how many pages */
      info->xpages = ceil(NSWidth(info->scaledBounds)/NSWidth(info->paperBounds));
      info->ypages = ceil(NSHeight(info->scaledBounds)/NSHeight(info->paperBounds));
      if ([_printInfo horizontalPagination] == NSClipPagination)
	info->xpages = 1;
      if ([_printInfo verticalPagination] == NSClipPagination)
	info->ypages = 1;
    }

  /* Calculate nup. If nup is an odd multiple of two, secretly change the
     page orientation to it's complement to make pages fit better.
  */
  if (((int)(info->nup / 2) & 0x1) == 1)
    {
      float tmp;
      if (info->orient == NSLandscapeOrientation)
	info->nupScale = 
	  info->paperSize.width/(2*info->paperSize.height);
      else
	info->nupScale = 
	  info->paperSize.height/(2*info->paperSize.width);
      info->nupScale /= (info->nup / 2);
      info->orient = (info->orient == NSPortraitOrientation) ? 
	NSLandscapeOrientation : NSPortraitOrientation;
      tmp = info->paperSize.width;
      info->paperSize.width = info->paperSize.height;
      info->paperSize.height = tmp;
      [dict setObject: NSNUMBER(info->orient) forKey: NSPrintOrientation];
    }
  else if (info->nup > 1)
    {
      info->nupScale = 2.0 / (float)info->nup;
    }

  if ([[dict objectForKey: NSPrintPageDirection] isEqual: @"Columns"])
    info->pageDirection = 1;
  else
    info->pageDirection = 0;
}

/* Our personnel method to calculate the print rect for the specified page.
   Note, we assume this function is called in order from our first to last
   page. The returned pageRect is in the view's coordinate system
*/
- (NSRect) _rectForPage: (int)page info: (page_info_t *)info 
		  xpage: (int *)xptr
		  ypage: (int *)yptr
{
  int xpage, ypage;
  NSRect pageRect;

  if (info->pageDirection == 1)
    {
      xpage = (page - 1) / info->ypages;
      ypage = (page - 1) % info->ypages;
    }
  else
    {
      xpage = (page - 1) % info->xpages;
      ypage = (page - 1) / info->xpages;
    }
  *xptr = xpage;
  *yptr = ypage;
  if (xpage == 0)
    info->lastWidth = 0;
  if (ypage == 0)
    info->lastHeight = 0;
  pageRect = NSMakeRect(info->lastWidth, info->lastHeight,
			NSWidth(info->paperBounds), NSHeight(info->paperBounds));
  pageRect = NSIntersectionRect(pageRect, info->scaledBounds);
  /* Scale to view's coordinate system */
  return scaleRect(pageRect, 1/(info->pageScale*info->printScale));
  
}

/* Let the view adjust the page rect we calculated. See assumptions for
   _rectForPage:
*/
- (NSRect) _adjustPagesFirst: (int)first 
			last: (int)last 
			info: (page_info_t *)info
{
  int i, xpage, ypage;
  double hlimit, wlimit;
  NSRect pageRect;
  hlimit = [_view heightAdjustLimit];
  wlimit = [_view widthAdjustLimit];
  for (i = first; i <= last; i++)
    {
      float newVal, limitVal;
      pageRect = [self _rectForPage: i info: info xpage: &xpage ypage: &ypage];
      limitVal = NSMaxY(pageRect) - hlimit * NSHeight(pageRect);
      [_view adjustPageHeightNew: &newVal
	                     top: NSMinY(pageRect)
	                  bottom: NSMaxY(pageRect)
	                   limit: limitVal];
      if (newVal < NSMaxY(pageRect))
	pageRect.size.height = MAX(newVal, limitVal) - NSMinY(pageRect);
      limitVal = NSMaxX(pageRect) - wlimit * NSWidth(pageRect);
      [_view adjustPageWidthNew: &newVal
	                   left: NSMinX(pageRect)
	                  right: NSMaxX(pageRect)
	                   limit: limitVal];
      if (newVal < NSMaxX(pageRect))
	pageRect.size.width = MAX(newVal, limitVal) - NSMinX(pageRect);
      if (info->pageDirection == 0 || ypage == info->ypages - 1)
	info->lastWidth = NSMaxX(pageRect)*(info->pageScale*info->printScale);
      if (info->pageDirection == 1 || xpage == info->xpages - 1)
	info->lastHeight = NSMaxY(pageRect)*(info->pageScale*info->printScale);
    }
  return pageRect;
}

- (void) _print
{
  int i, dir;
  BOOL knowsPageRange, allPages;
  NSRange viewPageRange;
  NSMutableDictionary *dict;
  page_info_t info;
  
  dict = [_printInfo dictionary];

  /* Setup pagination */
  allPages = [[dict objectForKey: NSPrintAllPages] boolValue];
  knowsPageRange = [_view knowsPageRange: &viewPageRange]; 
  [self _printPaginateWithInfo: &info knowsRange: knowsPageRange];
  if (knowsPageRange == NO)
    {
      viewPageRange = NSMakeRange(1, (info.xpages * info.ypages));
    }
  [dict setObject: NSNUMBER(NSMaxRange(viewPageRange) )
	   forKey: @"NSPrintTotalPages"];
  if (allPages == YES)
    {
      info.first = viewPageRange.location;
      info.last = NSMaxRange(viewPageRange) - 1;
    }
  else
    {
      info.first = [[dict objectForKey: NSPrintFirstPage] intValue];
      info.last  = [[dict objectForKey: NSPrintLastPage] intValue];
      info.first = MAX(info.first, viewPageRange.location);
      info.first = MIN(info.first, NSMaxRange(viewPageRange) - 1);
      info.last = MAX(info.last, info.first);
      info.last = MIN(info.last, NSMaxRange(viewPageRange) - 1);
      viewPageRange = NSMakeRange(info.first, (info.last-info.first)+1);
    }
  info.lastWidth = info.lastHeight = 0;
  [dict setObject: NSFNUMBER(info.nupScale) forKey: @"NSNupScale"];
  [dict setObject: NSNUMBER(info.first) forKey: NSPrintFirstPage];
  if (allPages == YES && knowsPageRange == NO)
    [dict setObject: NSNUMBER(info.first-1) forKey: NSPrintLastPage];
  else
    [dict setObject: NSNUMBER(info.last) forKey: NSPrintLastPage];
  NSDebugLLog(@"NSPrinting", @"Printing pages %d to %d", 
	      info.first, info.last);
  NSDebugLLog(@"NSPrinting", @"Printing rect %@, scaled %@",
	      NSStringFromRect(_rect),
	      NSStringFromRect(info.scaledBounds));

  _currentPage = info.first;
  dir = 1;
  if (_pageOrder == NSDescendingPageOrder)
    {
      _currentPage = info.last;
      dir = -1;
    }
  if (dir > 0 && _currentPage != 1)
    {
      /* Calculate page rects we aren't processing to catch up to the
	 first page we are */
      NSRect pageRect;
      pageRect = [self _adjustPagesFirst: 1
			           last: _currentPage-1 
		                   info: &info];
    }

  /* Print the header information */
  [_view beginDocument];

  /* Print each page */
  i = 0;
  while (i < (info.last-info.first+1))
    {
      NSPoint location;
      NSRect pageRect, scaledPageRect;
      if (knowsPageRange == YES)
	{
	  pageRect = [_view rectForPage: _currentPage];
	}
      else
	{
	  if (dir < 0)
	    pageRect = [self _adjustPagesFirst: 1 
			                  last: _currentPage 
			                  info: &info];
	  else
	    pageRect = [self _adjustPagesFirst: _currentPage 
			                  last: _currentPage 
			                  info: &info];
	}

      NSDebugLLog(@"NSPrinting", @" current page %d, rect %@", 
		  _currentPage, NSStringFromRect(pageRect));
      if (NSIsEmptyRect(pageRect))
	break;

      scaledPageRect = scaleRect(pageRect, info.printScale*info.pageScale);
      location = [_view locationOfPrintRect: scaledPageRect];

      /* Draw using our special view routine */
      [_view _displayPageInRect: pageRect
	            atPlacement: location
	               withInfo: info];
	     
      if (dir > 0 && _currentPage == info.last && allPages == YES)
	{
	  /* Check if adjust pages forced part of the bounds onto 
	     another page */
	  if (NSMaxX(pageRect) < NSMaxX(_rect) 
	      && [_printInfo horizontalPagination] != NSClipPagination)
	    {
	      info.xpages++;
	    }
	  if (NSMaxY(pageRect) < NSMaxY(_rect)
	      && [_printInfo verticalPagination] != NSClipPagination)
	    {
	      info.ypages++;
	    }
	  viewPageRange = NSMakeRange(1, (info.xpages * info.ypages));
	  info.last = NSMaxRange(viewPageRange) - 1;
	}
      i++;
      _currentPage += dir;
    } /* Print each page */
  
  /* Make sure we end the sheet */
  if ( info.nup > 1 && (info.last - info.first) % info.nup != info.nup - 1 )
    {
      [_view drawSheetBorderWithSize: info.paperBounds.size];
      [_view _endSheet];
    }
  [_view endDocument];

  /* Setup/reset for next time */
  [dict setObject: NSNUMBER(info.last) forKey: NSPrintLastPage];
  if (((int)(info.nup / 2) & 0x1) == 1)
    {
      info.orient = (info.orient == NSPortraitOrientation) ? 
	NSLandscapeOrientation : NSPortraitOrientation;
      [dict setObject: NSNUMBER(info.orient) forKey: NSPrintOrientation];
    }
}

@end

@implementation NSView (NSPrintOperation)
- (void) _displayPageInRect: (NSRect)pageRect
	        atPlacement: (NSPoint)location
	           withInfo: (page_info_t)info
{
  int currentPage;
  float xoffset, yoffset, scale;
  NSString *label;
  NSGraphicsContext *ctxt = GSCurrentContext();
  NSPrintOperation *printOp = [NSPrintOperation currentOperation];

  currentPage = [printOp currentPage];

  label = nil;
  if (info.nup == 1)
    label = [NSString stringWithFormat: @"%d", currentPage];

  /* Begin a sheet (i.e. a physical page in Postscript terms). If 
     nup > 1 then this occurs only once every nup pages */
  if ((currentPage - info.first) % info.nup == 0)
    {
      [self beginPage: floor((currentPage - info.first)/info.nup)+1
	    label: label
	    bBox: info.sheetBounds
	    fonts: nil];
      if (info.orient == NSLandscapeOrientation)
	{
	  DPSrotate(ctxt, 90);
	  DPStranslate(ctxt, 0, -info.paperSize.height);
	}
      /* Also offset by margins */
      DPStranslate(ctxt, NSMinX(info.paperBounds), NSMinY(info.paperBounds));
    }

  /* Begin a logical page */
  [self beginPageInRect: pageRect atPlacement: location];
  scale = info.pageScale * info.printScale;
  if (scale != 1.0)
    DPSscale(ctxt, scale, scale);
  if ([self isFlipped])
    {
      NSAffineTransformStruct	ats = { 1, 0, 0, -1, 0, 1 };
      NSAffineTransform *matrix, *flip;
      flip = [NSAffineTransform new];
      matrix = [NSAffineTransform new];
      [matrix makeIdentityMatrix];
      [matrix appendTransform: _boundsMatrix];
      /*
       * The flipping process must result in a coordinate system that
       * exactly overlays the original.	 To do that, we must translate
       * the origin by the height of the view.
       */
      [flip setTransformStruct: ats];
      flip->matrix.ty = NSHeight(_bounds);
      [matrix appendTransform: flip];
      [matrix concat];
      yoffset = NSHeight(_frame) - NSMaxY(pageRect);
    }
  else
    yoffset = 0 - NSMinY(pageRect);

  /* Translate so the rect we're printing is on the page */
  xoffset = 0 - NSMinX(pageRect);
  DPStranslate(ctxt, xoffset, yoffset);

  if ((currentPage - info.first) % info.nup == 0)
    [self endPageSetup];

  /* Do the actual drawing */
  [self displayRectIgnoringOpacity: pageRect];

  /* End a logical page */
  DPSgrestore(ctxt); // Balance gsave in beginPageInRect:
  [self drawPageBorderWithSize: 
	   scaleSize(info.paperBounds.size, info.nupScale)];
  [self endPage];

  /* End a physical page */
  if ( ((currentPage - info.first) % info.nup == info.nup-1) )
    {
      [self drawSheetBorderWithSize: info.paperBounds.size];
      [self _endSheet];
    }
}

- (void) _endSheet
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  NSPrintOperation *printOp = [NSPrintOperation currentOperation];
  if ([printOp isEPSOperation] == NO)
    DPSPrintf(ctxt, "showpage\n");
  DPSPrintf(ctxt, "%%%%PageTrailer\n");
  DPSPrintf(ctxt, "\n");
}
@end


@implementation GSPrintOperation

- (id)initWithView:(NSView *)aView
	 printInfo:(NSPrintInfo *)aPrintInfo
{
  NSMutableData *data = [NSMutableData data];
    
  self = [self initWithView: aView
	       insideRect: [aView bounds]
	       toData: data
	       printInfo: aPrintInfo];
  _showPanels = YES;

  return self;
}

- (NSGraphicsContext*)createContext
{
  NSMutableDictionary *info;
  if (_context)
    return _context;

  info = [_printInfo dictionary];
  if (_pathSet == NO)
    {
      NSString *output = [info objectForKey: NSPrintSavePath];
      if (output)
	{
	  ASSIGN(_path, output);
	  _pathSet = YES;
	}
    }

  [info setObject: _path forKey: @"NSOutputFile"];
  [info setObject: NSGraphicsContextPSFormat
	   forKey: NSGraphicsContextRepresentationFormatAttributeName];
  _context = RETAIN([NSGraphicsContext graphicsContextWithAttributes: info]);

  return _context;
}

- (BOOL) _deliverSpooledResult
{
  int copies;
  NSDictionary *dict;
  NSTask *task;
  NSString *name, *status;
  NSMutableArray *args;
  name = [[_printInfo printer] name];
  status = [NSString stringWithFormat: @"Spooling to printer %@.", name];
  [_printPanel _setStatusStringValue: status];

  dict = [_printInfo dictionary];
  args = [NSMutableArray array];
  copies = [[dict objectForKey: NSPrintCopies] intValue];
  if (copies > 1)
    [args addObject: [NSString stringWithFormat: @"-#%0d", copies]];
  if ([name isEqual: @"Unknown"] == NO)
    {
      [args addObject: @"-P"];
      [args addObject: name];
    }
  [args addObject: _path];

  task = [NSTask new];
  [task setLaunchPath: @"lpr"];
  [task setArguments: args];
  [task launch];
  [task waitUntilExit];
  AUTORELEASE(task);
  return YES;
}

- (BOOL) deliverResult
{
  BOOL success;
  NSString *job;
  
  success = YES;
  job = [_printInfo jobDisposition];
  if ([job isEqual: NSPrintPreviewJob])
    {
      /* Check to see if there is a GNUstep app that can preview PS files.
	 It's not likely at this point, so also check for a standards
	 previewer, like gv.
      */
      NSTask *task;
      NSString *preview;
      NSWorkspace *ws = [NSWorkspace sharedWorkspace];
      [_printPanel _setStatusStringValue: @"Opening in previewer..."];
      preview = [ws getBestAppInRole: @"Viewer" forExtension: @"ps"];
      if (preview)
	{
	  [ws openFile: _path withApplication: preview];
	}
      else
	{
	  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	  preview = [def objectForKey: @"NSPreviewApp"];
	  if (preview == nil || [preview length] == 0)
	    preview = @"gv";
	  task = [NSTask new];
	  [task setLaunchPath: preview];
	  [task setArguments: [NSArray arrayWithObject: _path]];
	  [task launch];
	  AUTORELEASE(task);
	}
    }
  else if ([job isEqual: NSPrintSpoolJob])
    {
      success = [self _deliverSpooledResult];
    }
  else if ([job isEqual: NSPrintFaxJob])
    {
    }

  /* We can't remove the temp file because the previewer might still be
     using it, perhaps the printer is also?
  if (!_pathSet)
    [[NSFileManager defaultManager] removeFileAtPath: _path
				    handler: nil];
  */
  return success;
}

@end

@implementation GSEPSPrintOperation

- (id)initEPSOperationWithView:(NSView *)aView
		    insideRect:(NSRect)rect
			toData:(NSMutableData *)data
		     printInfo:(NSPrintInfo *)aPrintInfo
{
  self = [self initWithView: aView
	       insideRect: rect
	       toData: data
	       printInfo: aPrintInfo];
  _pathSet = YES; /* Use the default temp path */
  return self;
}

- (id) initEPSOperationWithView:(NSView *)aView	
		     insideRect:(NSRect)rect
			 toPath:(NSString *)path
		      printInfo:(NSPrintInfo *)aPrintInfo
{
  NSMutableData *data = [NSMutableData data];
  
  self = [self initEPSOperationWithView: aView	
	       insideRect: rect
	       toData: data
	       printInfo: aPrintInfo];

  ASSIGN(_path, path);
  _pathSet = YES;

  return self;
}

- (void) _print
{
  /* Save this for the view to look at. Seems like there should
     be a better way to pass it to beginDocument */
  [[_printInfo dictionary] setObject: [NSValue valueWithRect: _rect]
			      forKey: @"NSPrintSheetBounds"];
  [_view beginDocument];
  [_view beginPageInRect: _rect atPlacement: NSMakePoint(0,0)];
  [_view displayRectIgnoringOpacity: _rect];
  [_view endDocument];
}

- (BOOL)isEPSOperation
{
  return YES;
}

- (BOOL)deliverResult
{
  if (_data != nil && _path != nil)
    {
      NSString	*eps;

      eps = [NSString stringWithContentsOfFile: _path];
      [_data setData: [eps dataUsingEncoding:NSASCIIStringEncoding]];
    }

  return YES;
}

- (NSGraphicsContext*)createContext
{
  NSMutableDictionary *info;

  if (_context)
    return _context;

  info = [_printInfo dictionary];

  [info setObject: _path forKey: @"NSOutputFile"];
  [info setObject: NSGraphicsContextPSFormat
	   forKey: NSGraphicsContextRepresentationFormatAttributeName];
  _context = RETAIN([NSGraphicsContext graphicsContextWithAttributes: info]);
  return _context;
}

@end

@implementation GSPDFPrintOperation

- (id) initPDFOperationWithView:(NSView *)aView 
		     insideRect:(NSRect)rect 
			 toData:(NSMutableData *)data 
		      printInfo:(NSPrintInfo*)aPrintInfo
{
  self = [self initWithView: aView
	       insideRect: rect
	       toData: data
	       printInfo: aPrintInfo];
  _pathSet = YES; /* Use the default temp path */
  return self;
}

- (id) initPDFOperationWithView:(NSView *)aView 
		     insideRect:(NSRect)rect 
			 toPath:(NSString *)path 
		      printInfo:(NSPrintInfo*)aPrintInfo
{
  NSMutableData *data = [NSMutableData data];

  self = [self initPDFOperationWithView: aView	
	       insideRect: rect
	       toData: data
	       printInfo: aPrintInfo];

  ASSIGN(_path, path);
  _pathSet = YES;

  return self;
}

- (NSGraphicsContext*)createContext
{
  // FIXME
  return nil;
}

- (void) _print
{
  [_view displayRectIgnoringOpacity: _rect];
}

- (BOOL)deliverResult
{
  if (_data != nil && _path != nil && [_data length])
    return [_data writeToFile: _path atomically: NO];
  // FIXME Until we can create PDF we shoud convert the file with GhostScript
  
  return YES;
}

@end
