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

#import <AppKit/NSObjectController.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_3,GS_API_LATEST)

@class NSArray;
@class NSMutableArray;
@class NSIndexSet;
@class NSPredicate;

/*
 *  Class: NSArrayController
 *  Description: Controller class for managing and interacting with array-based content in a GUI.
 *
 *  This controller maintains a content array and provides sorting, filtering, and selection capabilities.
 *  It also supports rearranging of objects based on the sort descriptors and predicates set.
 *
 *  Instance Variables:
 *    _arranged_objects - Holds the sorted and filtered version of the content.
 *    _selection_indexes - Tracks the indexes of currently selected objects.
 *    _sort_descriptors - An array of NSSortDescriptor used to order the arranged objects.
 *    _filter_predicate - An NSPredicate used to filter the arranged objects.
 *    _acflags - Structure containing internal configuration flags.
 *      - always_uses_multiple_values_marker: Enables the multiple values marker.
 *      - automatically_rearranges_objects: Enables automatic rearrangement when content changes.
 *      - avoids_empty_selection: Ensures a selection always exists.
 *      - clears_filter_predicate_on_insertion: Clears filter predicate during insertions.
 *      - preserves_selection: Maintains the selection when rearranging.
 *      - selects_inserted_objects: Automatically selects newly inserted objects.
 *
 *  Inherits From:
 *    NSObjectController - Provides basic content handling and KVO integration for bound objects.
 */

APPKIT_EXPORT_CLASS
@interface NSArrayController : NSObjectController
{
  NSArray *_arranged_objects;
  NSIndexSet *_selection_indexes;
  NSArray *_sort_descriptors;
  NSPredicate *_filter_predicate;
  struct GSArrayControllerFlagsType {
    unsigned always_uses_multiple_values_marker: 1;
    unsigned automatically_rearranges_objects: 1;
    unsigned avoids_empty_selection: 1;
    unsigned clears_filter_predicate_on_insertion: 1;
    unsigned preserves_selection: 1;
    unsigned selects_inserted_objects: 1;
  } _acflags;
}

// MARK: - Modification

/**
 *  Adds a single object to the content array.
 *  The object will be inserted into the arranged objects.
 */
- (void) addObject: (id)obj;

/**
 *  Adds multiple objects to the content array.
 *  Each object will be inserted into the arranged objects.
 */
- (void) addObjects: (NSArray*)obj;

/**
 *  Removes a single object from the content array.
 */
- (void) removeObject: (id)obj;

/**
 *  Removes multiple objects from the content array.
 */
- (void) removeObjects: (NSArray*)obj;

/**
 *  Returns whether inserting objects is currently allowed.
 */
- (BOOL) canInsert;

/**
 *  Triggers the insertion operation from a sender.
 */
- (void) insert: (id)sender;

// MARK: - Selection

/**
 *  Adds given objects to the current selection.
 *  Returns whether the operation was successful.
 */
- (BOOL) addSelectedObjects: (NSArray*)obj;

/**
 *  Adds index positions to the current selection.
 *  Returns whether the operation was successful.
 */
- (BOOL) addSelectionIndexes: (NSIndexSet*)idx;

/**
 *  Replaces the current selection with the given objects.
 *  Returns whether the operation was successful.
 */
- (BOOL) setSelectedObjects: (NSArray*)obj;

/**
 *  Sets the selection to a specific index.
 *  Returns whether the operation was successful.
 */
- (BOOL) setSelectionIndex: (NSUInteger)idx;

/**
 *  Sets the selection to the specified indexes.
 *  Returns whether the operation was successful.
 */
- (BOOL) setSelectionIndexes: (NSIndexSet*)idx;

/**
 *  Removes the specified objects from the current selection.
 *  Returns whether the operation was successful.
 */
- (BOOL) removeSelectedObjects: (NSArray*)obj;

/**
 *  Removes the specified index positions from the current selection.
 *  Returns whether the operation was successful.
 */
- (BOOL) removeSelectionIndexes: (NSIndexSet*)idx;
/**
 *  Returns whether a next item is available to select.
 */
- (BOOL) canSelectNext;

/**
 *  Returns whether a previous item is available to select.
 */
- (BOOL) canSelectPrevious;

/**
 *  Moves the selection to the next object.
 */
- (void) selectNext: (id)sender;

/**
 *  Moves the selection to the previous object.
 */
- (void) selectPrevious: (id)sender;

/**
 *  Returns an array of currently selected objects.
 */
- (NSArray*) selectedObjects;

/**
 *  Returns the index of the current selection.
 */
- (NSUInteger) selectionIndex;

/**
 *  Returns the current selection as an index set.
 */
- (NSIndexSet*) selectionIndexes;

// MARK: - Selection Behavior

/**
 *  Returns whether empty selection is avoided.
 */
- (BOOL) avoidsEmptySelection;

/**
 *  Sets whether the controller avoids empty selection.
 */
- (void) setAvoidsEmptySelection: (BOOL)flag;

/**
 *  Returns whether the selection is preserved across rearrangements.
 */
- (BOOL) preservesSelection;

/**
 *  Sets whether to preserve the selection across rearrangements.
 */
- (void) setPreservesSelection: (BOOL)flag;

/**
 *  Returns whether newly inserted objects are selected.
 */
- (BOOL) selectsInsertedObjects;

/**
 *  Sets whether newly inserted objects should be selected.
 */
- (void) setSelectsInsertedObjects: (BOOL)flag;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 *  Returns whether multiple values marker is always used.
 */
- (BOOL) alwaysUsesMultipleValuesMarker;

/**
 *  Sets whether the controller should always use the multiple values marker.
 */
- (void) setAlwaysUsesMultipleValuesMarker: (BOOL)flag;

/**
 *  Returns whether the filter predicate is cleared on insertion.
 */
- (BOOL) clearsFilterPredicateOnInsertion;

/**
 *  Sets whether the filter predicate should be cleared when inserting objects.
 */
- (void) setClearsFilterPredicateOnInsertion: (BOOL)flag;
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
/**
 *  Returns whether the controller automatically rearranges its objects.
 */
- (BOOL) automaticallyRearrangesObjects;

/**
 *  Sets whether the controller should automatically rearrange its objects.
 */
- (void) setAutomaticallyRearrangesObjects: (BOOL)flag;
#endif

// MARK: - Arrangement

/**
 *  Returns a newly arranged version of the given objects.
 */
- (NSArray*) arrangeObjects: (NSArray*)obj;

/**
 *  Returns the currently arranged objects.
 */
- (id) arrangedObjects;

/**
 *  Rearranges the content based on current sort descriptors and filters.
 */
- (void) rearrangeObjects;

/**
 *  Sets the sort descriptors used for rearranging objects.
 */
- (void) setSortDescriptors: (NSArray*)desc;

/**
 *  Returns the current sort descriptors.
 */
- (NSArray*) sortDescriptors;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 *  Sets the filter predicate used to filter content.
 */
- (void) setFilterPredicate: (NSPredicate*)filterPredicate;

/**
 *  Returns the current filter predicate.
 */
- (NSPredicate*) filterPredicate;
#endif


/**
 *  Inserts an object at a specific index in the arranged objects.
 */
- (void) insertObject: (id)obj
atArrangedObjectIndex: (NSUInteger)idx;

/**
 *  Inserts multiple objects at the specified indexes in the arranged objects.
 */
- (void) insertObjects: (NSArray*)obj
atArrangedObjectIndexes: (NSIndexSet*)idx;

/**
 *  Removes the object at the specified index from the arranged objects.
 */
- (void) removeObjectAtArrangedObjectIndex: (NSUInteger)idx;

/**
 *  Removes multiple objects at the specified indexes from the arranged objects.
 */
- (void) removeObjectsAtArrangedObjectIndexes: (NSIndexSet*)idx;

@end

#endif // OS_API_VERSION

#endif // _GNUstep_H_NSArrayController
