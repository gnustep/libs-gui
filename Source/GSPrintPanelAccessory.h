/* Private print-panel UI. Copyright (C) 2026 Free Software Foundation, Inc.
   Author: Gregory Casamento <greg.casamento@gmail.com>
   Distributed under the GNU Lesser General Public License, version 2 or later. */
#ifndef _GNUstep_H_GSPrintPanelAccessory
#define _GNUstep_H_GSPrintPanelAccessory

#import "AppKit/NSView.h"

@class NSPrintPanel, NSPrintInfo, NSScrollView, NSPopUpButton, NSTextField;
@class NSImageView, NSPDFImageRep, NSMutableArray;

enum { GSPrintPanelAccessoryTag = 19470 };

@interface GSPrintPanelAccessory : NSView
{
  NSPrintPanel *panel;
  NSPrintInfo *info;
  NSSize baseSize;
  NSScrollView *scroll;
  NSMutableArray *observations;
  NSPopUpButton *paper;
  NSPopUpButton *orientation;
  NSTextField *scale;
  NSImageView *preview;
  NSTextField *pageLabel;
  NSPDFImageRep *pdf;
  BOOL rendering;
}

- (id) initWithPanel: (NSPrintPanel *)owner;
- (void) updateWithPrintInfo: (NSPrintInfo *)printInfo;
- (void) invalidate;
- (void) detach;
- (void) writePrintInfo: (NSPrintInfo *)printInfo;
- (void) schedulePreview;

@end

#endif
