/* 
   TypesandConstants.h

   All of the Type and Constant definitions for Display Postscript

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: September, 1995
   
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

#ifndef _GNUstep_H_DPSTypes
#define _GNUstep_H_DPSTypes

@class NSString;

// These are already defined in the DPSclient headers
#if 0
#ifndef HAVE_DPS_DPSCLIENT_H
typedef void *DPSProgramEncoding;
typedef void *DPSNameEncoding;
typedef void *DPSTextProc;
typedef void *DPSErrorProc;
typedef void DPSBinObjSeqRec;
typedef unsigned int DPSDefinedType;
#endif /* HAVE_DPS_DPSCLIENT_H */
#endif

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

#endif // _GNUstep_H_DPSTypes
