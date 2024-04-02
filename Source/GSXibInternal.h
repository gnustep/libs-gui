/** -*- mode: ObjC -*-
  <title>GSXibInternal</title>

   <abstract>On macOS when a XIB is compiled it is broken into several
   different NIB files representing different aspects of the data in
   the XIB.  This file is intended to implement a class which will allow
   parts of the XIB which would be broken off into separate parts to be
   loaded later on.</abstract>
   
   Copyright (C) 2024 Free Software Foundation, Inc.
   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: Mar 2024

   This file is part of the GNU Objective C User Interface library.

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

#ifndef _GNUSTEP_H_GSXIBINTERNAL
#define _GNUSTEP_H_GSXIBINTERNAL

#import <Foundation/NSObject.h>
#import "GSXib5KeyedUnarchiver.h"

@interface GSXibInternal : NSObject
@end

#endif // _GNUSTEP_H_GSXIBINTERNAL
