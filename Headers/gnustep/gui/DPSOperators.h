/* 
   DPSOperators.h

   Display Postscript operators and functions

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: September 1995
   
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

#ifndef _GNUstep_H_DPSOperators
#define _GNUstep_H_DPSOperators

#include "config.h"

// Use the DPSclient library if we have it
#ifdef HAVE_DPS_DPSCLIENT_H

#include <DPS/dpsclient.h>
#include <DPS/psops.h>

#else

typedef void (*DPSTextProc)();
typedef void (*DPSErrorProc)();

typedef enum {
  dps_ascii, dps_binObjSeq, dps_encodedTokens
  } DPSProgramEncoding;
  /* Defines the 3 possible encodings of PostScript language programs. */
     
typedef enum {
  dps_indexed, dps_strings
  } DPSNameEncoding;
  /* Defines the 2 possible encodings for user names in the
     dps_binObjSeq and dps_encodedTokens forms of PostScript language
     programs. */     

typedef enum {
  dps_tBoolean,
  dps_tChar,    dps_tUChar,
  dps_tFloat,   dps_tDouble,
  dps_tShort,   dps_tUShort,
  dps_tInt,     dps_tUInt,
  dps_tLong,    dps_tULong } DPSDefinedType;
  
typedef struct {
    unsigned char attributedType;
    unsigned char tag;
    unsigned short length;
    union {
        int integerVal;
        float realVal;
        int nameVal;    /* offset or index */
        int booleanVal;
        int stringVal;  /* offset */
        int arrayVal;  /* offset */
    } val;
} DPSBinObjRec, *DPSBinObj;

typedef struct {
    unsigned char tokenType;
    unsigned char nTopElements;
    unsigned short length;
    DPSBinObjRec objects[1];
} DPSBinObjSeqRec, *DPSBinObjSeq;

#endif /* HAVE_DPS_DPSCLIENT_H */

#endif /* _GNUstep_H_DPSOperators */
