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

#ifndef _GNUstep_H_NSArrayController
#define _GNUstep_H_NSArrayController

#include <AppKit/NSObjectController.h>

#if OS_API_VERSION(100300,GS_API_LATEST)

@class NSArray;
@class NSIndexSet;

@interface NSArrayController : NSObjectController
{
  NSMutableArray *_arrange_objects;
  NSArray *_sort_descriptors;
  NSIndexSet *_selection_indexes;
  BOOL _avoids_empty_Selection;
  BOOL _preserves_selection;
}

- (void) addObjects: (NSArray*)obj;
- (void) removeObjects: (NSArray*)obj;
- (BOOL) canInsert;
- (void) insert: (id)sender;

- (BOOL) addSelectedObjects: (NSArray*)obj;
- (BOOL) addSelectionIndexes: (NSIndexSet*)idx;
- (BOOL) setSelectedObjects: (NSArray*)obj;
- (BOOL) setSelectionIndex: (unsigned int)idx;
- (BOOL) setSelectionIndexes: (NSIndexSet*)idx;
- (BOOL) removeSelectedObjects: (NSArray*)obj;
- (BOOL) removeSelectionIndexes: (NSIndexSet*)idx;
- (void) selectNext: (id)sender;
- (void) selectPrevious: (id)sender;
- (NSArray*) selectedObjects;
- (unsigned int) selectionIndex;
- (NSIndexSet*) selectionIndexes;

- (BOOL) canSelectNext;
- (BOOL) canSelectPrevious;
- (BOOL) avoidsEmptySelection;
- (void) setAvoidsEmptySelection: (BOOL)flag;
- (BOOL) preservesSelection;
- (void) setPreservesSelection: (BOOL)flag;
- (BOOL) selectsInsertedObjects;
- (void) setSelectsInsertedObjects: (BOOL)flag;

- (NSArray*) arrangeObjects: (NSArray*)obj;
- (id) arrangedObjects;
- (void) rearrangeObjects;
- (void) setSortDescriptors: (NSArray*)desc;
- (NSArray*) sortDescriptors;

- (void) insertObject: (id)obj 
atArrangedObjectIndex: (unsigned int)idx;
- (void) insertObjects: (NSArray*)obj 
atArrangedObjectIndexes: (NSIndexSet*)idx;
- (void) removeObjectAtArrangedObjectIndex: (unsigned int)idx;
- (void) removeObjectsAtArrangedObjectIndexes: (NSIndexSet*)idx;

@end

#endif // OS_API_VERSION

#endif // _GNUstep_H_NSArrayController
