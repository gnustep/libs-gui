/** <title>NSArrayController</title>

   <abstract>Controller class for arrays</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <fredkiefer@gmx.de>
   Date: June 2006

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


#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import "AppKit/NSArrayController.h"

@implementation NSArrayController

- (id) initWithContent: (id)content
{
  if ((self = [super initWithContent: content]) != nil)
    {
      _arrange_objects = [[NSMutableArray alloc] init];
    }

  return self;
}

- (id) init
{
  NSMutableArray *new = [[NSMutableArray alloc] init];

  self = [self initWithContent: new];
  RELEASE(new);
  return self;
}

- (void) addObject: (id)obj
{
  [_content addObject: obj];
  [_arrange_objects addObject: obj];
}

- (void) addObjects: (NSArray*)obj
{
  [_content addObjectsFromArray: obj];
  if ([self selectsInsertedObjects])
    {
      [_arrange_objects addObjectsFromArray: obj];
    }
}

- (void) removeObject: (id)obj
{
  [_content removeObject: obj];
  [_arrange_objects removeObject: obj];
}

- (void) removeObjects: (NSArray*)obj
{
  [_content removeObjectsInArray: obj];
  [_arrange_objects removeObjectsInArray: obj];
}

- (BOOL) canInsert
{
  return YES;
}

- (void) insert: (id)sender
{
  id new = [self newObject];

  [_content addObject: new];
  RELEASE(new);
}

- (BOOL) addSelectedObjects: (NSArray*)obj
{
  // TODO
  return NO;
}

- (BOOL) addSelectionIndexes: (NSIndexSet*)idx
{
  // TODO
  return NO;
}

- (BOOL) setSelectedObjects: (NSArray*)obj
{
  // TODO
  return NO;
}

- (BOOL) setSelectionIndex: (unsigned int)idx
{
  // TODO
  return NO;
}

- (BOOL) setSelectionIndexes: (NSIndexSet*)idx
{
  // TODO
  return NO;
}

- (BOOL) removeSelectedObjects: (NSArray*)obj
{
  // TODO
  return NO;
}

- (BOOL) removeSelectionIndexes: (NSIndexSet*)idx
{
  // TODO
  return NO;
}

- (void) selectNext: (id)sender
{
  // TODO
  return;
}

- (void) selectPrevious: (id)sender
{
  // TODO
  return;
}

- (NSArray*) selectedObjects
{
  // TODO
  return nil;
}

- (unsigned int) selectionIndex
{
  // TODO
  return -1;
}

- (NSIndexSet*) selectionIndexes
{
  // TODO
  return nil;
}


- (BOOL) canSelectNext
{
  // TODO
  return NO;
}

- (BOOL) canSelectPrevious
{
  // TODO
  return NO;
}

- (BOOL) avoidsEmptySelection
{
  // TODO
  return NO;
}

- (void) setAvoidsEmptySelection: (BOOL)flag
{
  // TODO
  return;
}

- (BOOL) preservesSelection
{
  // TODO
  return NO;
}

- (void) setPreservesSelection: (BOOL)flag
{
  // TODO
  return;
}

- (BOOL) selectsInsertedObjects
{
  // TODO
  return NO;
}

- (void) setSelectsInsertedObjects: (BOOL)flag
{
  // TODO
  return;
}


- (NSArray*) arrangeObjects: (NSArray*)obj
{
  // TODO
  return nil;
}

- (id) arrangedObjects
{
  // TODO
  return nil;
}

- (void) rearrangeObjects
{
  // TODO
  return;
}

- (void) setSortDescriptors: (NSArray*)desc
{
  // TODO
  return;
}

- (NSArray*) sortDescriptors
{
  // TODO
  return nil;
}


- (void) insertObject: (id)obj 
atArrangedObjectIndex: (unsigned int)idx
{
  // TODO
  return;
}

- (void) insertObjects: (NSArray*)obj 
atArrangedObjectIndexes: (NSIndexSet*)idx
{
  // TODO
  return;
}

- (void) removeObjectAtArrangedObjectIndex: (unsigned int)idx
{
  // TODO
  return;
}

- (void) removeObjectsAtArrangedObjectIndexes: (NSIndexSet*)idx
{
  // TODO
  return;
}

@end
