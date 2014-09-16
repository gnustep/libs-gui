/** <title>GSWIN32PageLayout</title>

   <abstract></abstract>

   Copyright (C) 2004 Free Software Foundation, Inc.
   Author: Chad Hardin <cehardin@mac.com>
   Date: June 2004
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#import <Foundation/NSDebug.h>
#import <Foundation/NSValue.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSPrinter.h>
#import <AppKit/NSApplication.h>

#import "GSWIN32Printer.h"
#import "GSWIN32PageLayout.h"

#define PTS2INCHES(n) ((n / 72.0f) * 1000.0f)
#define INCHES2PTS(n) ((n / 1000.0f) * 72.0f)

@implementation GSWIN32PageLayout
//
// Class methods
//
+ (void)initialize
{
  if (self == [GSWIN32PageLayout class])
    {
      // Initial version
      [self setVersion:1];
    }
}


+ (id) allocWithZone: (NSZone*)zone
{
  return NSAllocateObject(self, 0, zone);
}

- (NSInteger)runModalWithPrintInfo:(NSPrintInfo *)printInfo
{
  PAGESETUPDLG pgSetup;
  int windowNumber = 
    [[[NSApplication sharedApplication] mainWindow] windowNumber];

  pgSetup.lStructSize = sizeof(PAGESETUPDLG);
  pgSetup.Flags = PSD_INTHOUSANDTHSOFINCHES;
  pgSetup.hwndOwner = (HWND)windowNumber;
  pgSetup.hDevNames = NULL;
  pgSetup.hDevMode = NULL;
  pgSetup.rtMargin.top  =  PTS2INCHES([printInfo topMargin]);
  pgSetup.rtMargin.bottom  =  PTS2INCHES([printInfo bottomMargin]);
  pgSetup.rtMargin.right  =  PTS2INCHES([printInfo rightMargin]);
  pgSetup.rtMargin.left  =  PTS2INCHES([printInfo leftMargin]);
  pgSetup.ptPaperSize.x  =  PTS2INCHES([printInfo paperSize].width);
  pgSetup.ptPaperSize.y  =  PTS2INCHES([printInfo paperSize].height);
  
  int retVal = PageSetupDlg(&pgSetup);
  if (retVal == 0) 
    {
      return NSCancelButton;
    }
  else 
    {
      NSSize size = NSMakeSize(INCHES2PTS(pgSetup.ptPaperSize.x),
			       INCHES2PTS(pgSetup.ptPaperSize.y));
      [printInfo setPaperSize: size];    
      [printInfo setTopMargin: INCHES2PTS(pgSetup.rtMargin.top)];
      [printInfo setBottomMargin: INCHES2PTS(pgSetup.rtMargin.bottom)];
      [printInfo setRightMargin: INCHES2PTS(pgSetup.rtMargin.right)];
      [printInfo setLeftMargin: INCHES2PTS(pgSetup.rtMargin.left)];
    }
  return NSOKButton;
}

- (void) beginSheetWithPrintInfo: (NSPrintInfo *)printInfo 
		  modalForWindow: (NSWindow *)docWindow 
			delegate: (id)delegate 
		  didEndSelector: (SEL)didEndSelector 
		     contextInfo: (void *)contextInfo
{
  [self runModalWithPrintInfo: printInfo];
}
@end
