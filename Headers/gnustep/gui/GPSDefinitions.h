/* GPSDefinitions - definitions for GNUstep drawing

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Adam Fedor <fedor@gnu.org>
   Date: Nov 1998
   
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
   If not, write to the Free Software Foundation, Inc.,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef _GPSDefinitions_h_INCLUDE
#define _GPSDefinitions_h_INCLUDE

//
// Backing Store Types
//
typedef enum _NSBackingStoreType {
  NSBackingStoreRetained,
  NSBackingStoreNonretained,
  NSBackingStoreBuffered
} NSBackingStoreType;

//
// Compositing operators
//
typedef enum _NSCompositingOperation {
  NSCompositeClear,
  NSCompositeCopy,
  NSCompositeSourceOver,
  NSCompositeSourceIn,
  NSCompositeSourceOut,
  NSCompositeSourceAtop,
  NSCompositeDataOver,
  NSCompositeDataIn,
  NSCompositeDataOut,
  NSCompositeDataAtop,
  NSCompositeXOR,
  NSCompositePlusDarker,
  NSCompositeHighlight,
  NSCompositePlusLighter
} NSCompositingOperation;

//
// Window ordering
//
typedef enum _NSWindowOrderingMode {
  NSWindowAbove,
  NSWindowBelow,
  NSWindowOut
} NSWindowOrderingMode;

//
// NSDPSContextNotification
// Circular dependency between protocol and class
//
@class NSDPSContext;
@protocol NSDPSContextNotification

//
// Synchronizing Application and Display Postscript Server Execution
//
- (void)contextFinishedExecuting:(NSDPSContext *)context;

@end

extern NSString *DPSPostscriptErrorException;
extern NSString *DPSNameTooLongException;
extern NSString *DPSResultTagCheckException;
extern NSString *DPSResultTypeCheckException;
extern NSString *DPSInvalidContextException;
extern NSString *DPSSelectException;
extern NSString *DPSConnectionClosedException;
extern NSString *DPSReadException;
extern NSString *DPSWriteException;
extern NSString *DPSInvalidFDException;
extern NSString *DPSInvalidTEException;
extern NSString *DPSInvalidPortException;
extern NSString *DPSOutOfMemoryException;
extern NSString *DPSCantConnectException;

#endif /* _GPSDefinitions_h_INCLUDE */
