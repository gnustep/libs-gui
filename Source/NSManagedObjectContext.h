/** <title>NSManagedObjectContext</title>
   
   <abstract>
   This class is the context object for the controller classes.
   It contains information which is used by those classes to maintain
   the internal state.
   </abstract>

   Copyright (C) 2007 Free Software Foundation, Inc.

   Author: Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2007
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

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

#include <Foundation/NSObject.h>

@class NSMergePolicy;

@interface NSManagedObjectContext : NSObject <NSCoding>
{
  NSMergePolicy *_mergePolicy;
  BOOL _propagatesDeleted;
  int _fetchTimestamp;
  BOOL _retainsRegisteredObjects;
}
@end
