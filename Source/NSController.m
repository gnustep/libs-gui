/** <title>NSController</title>

   <abstract>abstract base class for controllers</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <fredkiefer@gmx.de>
   Date: June 2006

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#include <Foundation/NSArray.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSKeyedArchiver.h>
#include <AppKit/NSController.h>

@implementation NSController

- (id) init
{
  if((self = [super init]) != nil)
    {
      _editors = [[NSMutableArray alloc] init];
      _declared_keys = [[NSMutableArray alloc] init];
    }
  
  return self;
}

- (void) dealloc
{
  RELEASE(_editors);
  RELEASE(_declared_keys);
  [super dealloc];
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{ 
  // TODO
}

- (id) initWithCoder: (NSCoder *)aDecoder
{ 
  if((self = [super init]) != nil)
    {
      if([aDecoder allowsKeyedCoding])
	{
	  ASSIGN(_declared_keys,[aDecoder decodeObjectForKey: @"NSDeclaredKeys"]);
	}
      else
	{
	  ASSIGN(_declared_keys,[aDecoder decodeObject]);
	}
    }
  return self; 
}

- (BOOL) isEditing
{
  return [_editors count] > 0;
}

- (BOOL) commitEditing
{
  unsigned c = [_editors count];
  unsigned i;

  for (i = 0; i < c; i++)
    {
      if (![[_editors objectAtIndex: i] commitEditing])
        {
	  return NO;
	}
    }

  return YES;
}

- (void) discardEditing
{
  [_editors makeObjectsPerformSelector: @selector(discardEditing)];
}

- (void) objectDidBeginEditing: (id)editor
{
  [_editors addObject: editor];
}

- (void) objectDidEndEditing: (id)editor
{
  [_editors removeObject: editor];
}

@end
