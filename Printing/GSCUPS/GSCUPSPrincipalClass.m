/* 
   GSCUPSPrincipalClass.m

   Principal class for the GSCUPS Bundle

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Chad Hardin <cehardin@mac.com>
   Date: October 2004
   
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

#include <Foundation/NSDebug.h>
#include "GSCUPSPrincipalClass.h"
#include "GSCUPSPageLayout.h"
#include "GSCUPSPrintInfo.h"
#include "GSCUPSPrintOperation.h"
#include "GSCUPSPrintPanel.h"
#include "GSCUPSPrinter.h"


@implementation GSCUPSPrincipalClass
//
// Class methods
//
+(Class) pageLayoutClass
{
  NSDebugMLLog(@"GSPrinting", @"");
  return [GSCUPSPageLayout class];
}

+(Class) printInfoClass
{
  NSDebugMLLog(@"GSPrinting", @"");
  return [GSCUPSPrintInfo class];
}

+(Class) printOperationClass
{
  NSDebugMLLog(@"GSPrinting", @"");
  return [GSCUPSPrintOperation class];
}


+(Class) printPanelClass
{
  NSDebugMLLog(@"GSPrinting", @"");
  return [GSCUPSPrintPanel class];
}


+(Class) printerClass
{
  NSDebugMLLog(@"GSPrinting", @"");
  return [GSCUPSPrinter class];
}


+(Class) gsPrintOperationClass
{
  NSDebugMLLog(@"GSPrinting", @"");
  return [GSCUPSPrintOperation class];
}



@end
