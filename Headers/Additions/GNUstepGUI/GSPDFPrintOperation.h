/** <title>GSPDFPrintOperation</title>

   <abstract>Controls generation of PDF print output.</abstract>

   Copyright (C) 1996,2004 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: November 2000
   Updated to new specification
   Author: Adam Fedor <fedor@gnu.org>
   Date: Oct 2001
   Modified for Printing Backend Support
   Author: Chad Hardin <cehardin@mac.com>
   Date: June 2004

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

#ifndef _GNUstep_H_GSPDFPrintOperation
#define _GNUstep_H_GSPDFPrintOperation

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>
#include "AppKit/NSPrintOperation.h"

@class NSString;

@class NSView;
@class NSPrintInfo;

// subclass for PDF output
@interface GSPDFPrintOperation: NSPrintOperation
{
}

- (id) initWithView:(NSView *)aView	
		     insideRect:(NSRect)rect
			       toPath:(NSString *)path
		      printInfo:(NSPrintInfo *)aPrintInfo;
@end


#endif // _GNUstep_H_GSPDFPrintOperation

