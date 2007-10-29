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

#include "NSManagedObjectContext.h"
#include <Foundation/NSArchiver.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>

@interface NSMergePolicy : NSObject <NSCoding>
{
  int _typeCode;
}
@end

@implementation NSMergePolicy
- (id) initWithCoder: (NSCoder *)coder
{
  if ((self = [super init]) != nil)
    {
      if ([coder allowsKeyedCoding])
	{
//	  NSLog(@"merge policy: In keyed coder... %@",[coder keyMap]);
	  _typeCode = [coder decodeIntForKey: @"NSTypeCode"];
	}
      else
	{
	}
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
    }
  else
    {
    }
}
@end

@implementation NSManagedObjectContext
- (id) initWithCoder: (NSCoder *)coder
{
  if ((self = [super init]) != nil)
    {
      if ([coder allowsKeyedCoding])
	{
//	  NSLog(@"managed object: In keyed coder... %@",[coder keyMap]);
	  _mergePolicy = RETAIN([coder decodeObjectForKey: 
					 @"NSMergePolicy"]);
	  _propagatesDeleted = [coder decodeBoolForKey: 
					@"NSPropagatesDeleted"];
	  _fetchTimestamp = [coder decodeIntForKey: 
				     @"NSFetchTimestamp"];
	  _retainsRegisteredObjects = [coder decodeBoolForKey:
					       @"NSRetainsRegisteredObjects"];
	}
      else
	{
	}
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
    }
  else
    {
    }
}
@end
