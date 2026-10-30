/** <title>GSOpenStepNibReader</title>

   <abstract>This set of functions and classes allows the reading of
   nib files from OPENSTEP.</abstract>

   This set of functions / classes allows GNUstep to read OPENSTEP
   nib files so that applications can be directly ported or so that
   IB/Gorm can translate those files directly.

   Copyright <copy>(C) 2026 Free Software Foundation, Inc.</copy>

   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: August 2026

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
   Free Software Foundation, 31 Milk Street, # 960789, Boston,
   MA 02196, USA
*/

/* Private binary OPENSTEP nib adapter.  LGPL-2.0-or-later. */
#ifndef GS_OPENSTEP_NIB_READER_H
#define GS_OPENSTEP_NIB_READER_H

#import <Foundation/NSObject.h>

@class NSData;
@class NSKeyedUnarchiver;

/* Neither function instantiates application objects.  The second returns an
 * autoreleased keyed archive, or raises NSInvalidUnarchiveOperationException
 * with the offending class/version/offset.  There is no XML input path. */
BOOL GSOpenStepNibIsTypedStream(NSData *data);

NSData *GSOpenStepNibKeyedData(NSData *data);

/* Apply fields whose existing keyed representation loses precision. */
void GSOpenStepNibFinishDecoding(NSKeyedUnarchiver *coder);

#endif
