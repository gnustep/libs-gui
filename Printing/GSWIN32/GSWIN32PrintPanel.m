/** <title>GSWIN32PrintPanel</title>

   <abstract>Standard panel for querying user about printing.</abstract>

   Copyright (C) 2001,2004 Free Software Foundation, Inc.

   Written By: Adam Fedor <fedor@gnu.org>
   Date: Oct 2001
   Modified for Printing Backend Support
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

#import "GSWIN32PrintPanel.h"
#import "GSWIN32Printer.h"

@implementation GSWIN32PrintPanel
//
// Class methods
//
+ (id) allocWithZone: (NSZone*)zone
{
  return NSAllocateObject(self, 0, zone);
}

- (NSInteger) runModalWithPrintInfo: (NSPrintInfo *)printInfo
{
   int                   retVal;
   PRINTDLG              printDlg;
   int                   windowNumber = [[[NSApplication sharedApplication] mainWindow] windowNumber];
   
   printDlg.lStructSize = sizeof(PRINTDLG);
   printDlg.hwndOwner = (HWND)windowNumber;
   printDlg.hDevMode = NULL;
   printDlg.hDevNames = NULL;
   printDlg.Flags = PD_RETURNDC | PD_USEDEVMODECOPIESANDCOLLATE;
   printDlg.hDC = NULL;
   printDlg.lCustData = 0; 
   printDlg.lpfnPrintHook = NULL; 
   printDlg.lpfnSetupHook = NULL; 
   printDlg.lpPrintTemplateName = NULL; 
   printDlg.lpSetupTemplateName = NULL; 
   printDlg.hPrintTemplate = NULL; 
   printDlg.hSetupTemplate = NULL; 

   printDlg.nFromPage = 0; //0xFFFF;
   printDlg.nToPage = 0; //0xFFFF;
   printDlg.nMinPage = 1;
   printDlg.nMaxPage = 0xFFFF;
   printDlg.nCopies = 1; 
   printDlg.hInstance = NULL; 
   
   retVal = PrintDlg(&printDlg);
   if(retVal==0)
     {
       return NSCancelButton;
     }
   else 
     {
       DEVNAMES   *pDevNames = (DEVNAMES *)GlobalLock(printDlg.hDevNames);
       LPCTSTR     szDevice = NULL;
       NSString   *printerName = nil;
       NSPrinter  *printer = nil;

       szDevice = (LPCTSTR)pDevNames + pDevNames->wDeviceOffset;
       printerName = [NSString stringWithCString:(const char *)szDevice];
       NSLog(@"Printer Name = %@",printerName);

       printer = [NSPrinter printerWithName:printerName];
       if(printer != nil)
	 {
	   [printInfo setPrinter:printer];
	 }
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
