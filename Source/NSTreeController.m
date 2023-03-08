 /*
   NSTreeController.m

   The tree controller class.

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author:  Gregory Casamento <greg.casamento@gmail.com>
   Date: 2012

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

#import <Foundation/NSArchiver.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSIndexPath.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/NSString.h>
#import <Foundation/NSSortDescriptor.h>

#import "AppKit/NSKeyValueBinding.h"
#import "AppKit/NSTreeController.h"
#import "AppKit/NSTreeNode.h"

#import "GSBindingHelpers.h"
#import "GSFastEnumeration.h"

@implementation NSTreeController

+ (void) initialize
{
  if (self == [NSTreeController class])
    {
      [self exposeBinding: NSContentArrayBinding];
      [self setKeys: [NSArray arrayWithObjects: NSContentBinding, NSContentObjectBinding, nil]
	    triggerChangeNotificationsForDependentKey: @"arrangedObjects"];
    }
}

- (id) initWithContent: (id)content
{
  NSLog(@"Content = %@", content);
  if ((self = [super initWithContent: content]) != nil)
    {
      _childrenKeyPath = nil;
      _countKeyPath = nil;
      _leafKeyPath = nil;
      _sortDescriptors = nil;
      _selection_index_paths = [[NSMutableArray alloc] init];

      _canInsert = YES;
      _canInsertChild = YES;
      _canAddChild = YES;
    }

  return self;
}

- (id) init
{
  NSMutableArray *array = [[NSMutableArray alloc] init];

  self = [self initWithContent: array];
  RELEASE(array);
  return self;
}

- (void) dealloc
{
  RELEASE(_childrenKeyPath);
  RELEASE(_countKeyPath);
  RELEASE(_leafKeyPath);
  RELEASE(_sortDescriptors);
  RELEASE(_arranged_objects);
  [super dealloc];
}

- (BOOL) addSelectionIndexPaths: (NSArray *)indexPaths
{
  // FIXME
  return NO;
}

- (BOOL) alwaysUsesMultipleValuesMarker
{
  return _alwaysUsesMultipleValuesMarker;
}

- (BOOL) avoidsEmptySelection
{
  return _avoidsEmptySelection;
}

- (BOOL) canAddChild
{
  return _canAddChild;
}

- (BOOL) canInsert
{
  return _canInsert;
}

- (BOOL) canInsertChild
{
  return _canInsertChild;
}

- (BOOL) preservesSelection
{
  return _preservesSelection;
}

- (BOOL) selectsInsertedObjects
{
  return _selectsInsertedObjects;
}

- (BOOL) setSelectionIndexPath: (NSIndexPath *)indexPath
{
  BOOL f = [self commitEditing];

  if (YES == f)
    {
      [_selection_index_paths addObject: indexPath];
    }
  
  return f;
}

- (BOOL) setSelectionIndexPaths: (NSArray *)indexPaths
{
  BOOL f = [self commitEditing];

  if (YES == f)
    {
      NSMutableArray *mutable_index_paths = [NSMutableArray arrayWithArray: indexPaths];
      ASSIGN(_selection_index_paths, mutable_index_paths);
    }
  
  return f;
}

- (NSArray*) arrangeObjects: (NSArray*)obj
{
  NSArray *temp = obj;
  return [temp sortedArrayUsingDescriptors: _sortDescriptors];
}

- (id) arrangedObjects
{
  if (_arranged_objects == nil)
    {
      [self rearrangeObjects];
    }
  return _arranged_objects;
}

- (void) rearrangeObjects
{
  [self willChangeValueForKey: @"arrangedObjects"];
  DESTROY(_arranged_objects);
  _arranged_objects = [[GSObservableArray alloc]
			  initWithArray: [self arrangeObjects: _content]];
  [self didChangeValueForKey: @"arrangedObjects"];
}

- (NSArray *) selectedObjects
{
  // FIXME
  return [super selectedObjects];
}

- (NSIndexPath*) selectionIndexPath
{
  // FIXME
  return nil;
}

- (NSArray*) selectionIndexPaths
{
  // FIXME
  return nil;
}

- (NSArray*) sortDescriptors
{
  return _sortDescriptors;
}

- (NSString*) childrenKeyPath
{
  return _childrenKeyPath;
}

- (NSString*) countKeyPath
{
  return _countKeyPath;;
}

- (NSString*) leafKeyPath
{
  return _leafKeyPath;
}

- (void) add: (id)sender
{
  if ([self canAddChild])
    {
      id new = [self newObject];

      [self addChild: new];
      RELEASE(new);
    }
}

- (void) addChild: (id)obj
{
  GSKeyValueBinding *theBinding;

  [self setContent: obj];
  theBinding = [GSKeyValueBinding getBinding: NSContentObjectBinding
				   forObject: self];
  if (theBinding != nil)
    [theBinding reverseSetValueFor: @"content"];
}

- (void) remove: (id)sender
{
  if ([self canRemove])
    {
      [self removeObject: [self content]];
    }
}

- (void) insertChild: (id)sender
{
  // FIXME
}

- (void) insertObject: (id)object atArrangedObjectIndexPath: (NSIndexPath*)indexPath
{
  // FIXME
}

- (void) insertObjects: (NSArray*)objects atArrangedObjectIndexPaths: (NSArray*)indexPaths
{
  // FIXME
}

- (void) insert: (id)sender
{
  // FIXME
}

- (void) removeObjectAtArrangedObjectIndexPath: (NSIndexPath*)indexPath
{
  // FIXME
}

- (void) removeObjectsAtArrangedObjectIndexPaths: (NSArray*)indexPaths
{
  // FIXME
}

- (void) removeSelectionIndexPaths: (NSArray*)indexPaths
{
  // FIXME
}

- (void) setAlwaysUsesMultipleValuesMarker: (BOOL)flag
{
  _alwaysUsesMultipleValuesMarker = flag;
}

- (void) setAvoidsEmptySelection: (BOOL)flag
{
  _avoidsEmptySelection = flag;
}

- (void) setChildrenKeyPath: (NSString*)path
{
  ASSIGN(_childrenKeyPath, path);
}

- (void) setContent: (id)content
{
  // FIXME
  NSLog(@"in setContent... %@", content);
  [super setContent: content];
  [self rearrangeObjects];
}

- (void) setCountKeyPath: (NSString*)path
{
  ASSIGN(_countKeyPath, path);
}

- (void) setLeafKeyPath: (NSString*)key
{
  ASSIGN(_leafKeyPath, key);
}

- (void) setPreservesSelection: (BOOL)flag
{
  _preservesSelection = flag;
}

- (void) setSelectsInsertedObjects: (BOOL)flag
{
  _selectsInsertedObjects = flag;
}

- (void) setSortDescriptors: (NSArray*)descriptors
{
  ASSIGN(_sortDescriptors, descriptors);
}

- (NSString*) childrenKeyPathForNode: (NSTreeNode*)node
{
  // FIXME
  return nil;
}

- (NSString*) countKeyPathForNode: (NSTreeNode*)node
{
  // FIXME
  return nil;
}

- (NSString*) leafKeyPathForNode: (NSTreeNode*)node
{
  // FIXME
  return nil;
}

- (void) moveNode: (NSTreeNode*)node toIndexPath: (NSIndexPath*)indexPath
{
  // FIXME
}

- (void) moveNodes: (NSArray*)nodes toIndexPath: (NSIndexPath*)startingIndexPath
{
  // FIXME
}

- (NSArray*) selectedNodes
{
  // FIXME
  return nil;
}


- (void) bind: (NSString *)binding
     toObject: (id)anObject
  withKeyPath: (NSString *)keyPath
      options: (NSDictionary *)options
{
  if ([binding isEqual: NSContentArrayBinding])
    {
      GSKeyValueBinding *kvb;

      [self unbind: binding];
      kvb = [[GSKeyValueBinding alloc] initWithBinding: @"content"
					      withName: binding
					      toObject: anObject
					   withKeyPath: keyPath
					       options: options
					    fromObject: self];
      // The binding will be retained in the binding table
      RELEASE(kvb);
    }
  else
    {
      [super bind: binding
	 toObject: anObject
      withKeyPath: keyPath
	  options: options];
    }
}

- (id) initWithCoder: (NSCoder*)coder
{
  self = [super initWithCoder: coder];

  if (self != nil)
    {
      if ([coder allowsKeyedCoding])
	{
	  // These names do not stick to convention.  Usually it would be
	  // NS* or NSTreeController* so they must be overriden in
	  // GSXib5KeyedUnarchver.
	  if ([coder containsValueForKey: @"NSTreeContentChildrenKey"])
	    {
	      [self setChildrenKeyPath:
		      [coder decodeObjectForKey: @"NSTreeContentChildrenKey"]];
	    }
	  if ([coder containsValueForKey: @"NSTreeContentCountKey"])
	    {
	      [self setChildrenKeyPath:
		      [coder decodeObjectForKey: @"NSTreeContentCountKey"]];
	    }
	  if ([coder containsValueForKey: @"NSTreeContentLeafKey"])
	    {
	      [self setChildrenKeyPath:
		      [coder decodeObjectForKey: @"NSTreeContentLeafKey"]];
	    }

	  // Since we don't inherit from NSArrayController these are decoded here
	  // as well.
	  if ([coder containsValueForKey: @"NSAvoidsEmptySelection"])
	    {
	      [self setAvoidsEmptySelection:
		    [coder decodeBoolForKey: @"NSAvoidsEmptySelection"]];
	    }
	  if ([coder containsValueForKey: @"NSPreservesSelection"])
	    {
	      [self setPreservesSelection:
		      [coder decodeBoolForKey: @"NSPreservesSelection"]];
	    }
	  if ([coder containsValueForKey: @"NSSelectsInsertedObjects"])
	    {
	      [self setSelectsInsertedObjects:
		      [coder decodeBoolForKey: @"NSSelectsInsertedObjects"]];
	    }
	}
    }
  else
    {
      id obj = nil;
      BOOL f = NO;

      obj = [coder decodeObject];
      [self setChildrenKeyPath: obj];
      obj = [coder decodeObject];
      [self setCountKeyPath: obj];
      obj = [coder decodeObject];
      [self setLeafKeyPath: obj];

      [coder decodeValueOfObjCType: @encode(BOOL)
				at: &f];
      [self setAvoidsEmptySelection: f];
      [coder decodeValueOfObjCType: @encode(BOOL)
				at: &f];
      [self setPreservesSelection: f];
      [coder decodeValueOfObjCType: @encode(BOOL)
				at: &f];
      [self setSelectsInsertedObjects: f];
    }

  return self;
}

- (void) encodeWithCoder: (NSCoder*)coder
{
  [super encodeWithCoder: coder];

  if ([coder allowsKeyedCoding])
    {
      [coder encodeObject: _childrenKeyPath
		   forKey: @"NSTreeContentChildrenKey"];
      [coder encodeObject:  _countKeyPath
		   forKey: @"NSTreeContentCountKey"];
      [coder encodeObject: _leafKeyPath
		   forKey: @"NSTreeContentLeafKey"];


      [coder encodeBool: _avoidsEmptySelection
		 forKey: @"NSAvoidsEmptySelection"];
      [coder encodeBool: _preservesSelection
		 forKey: @"NSPreservesSelection"];
      [coder encodeBool: _selectsInsertedObjects
		 forKey: @"NSSelectsInsertedObjects"];
    }
  else
    {
      id obj = nil;
      BOOL f = NO;

      obj = [self childrenKeyPath];
      [coder encodeObject: obj];
      obj = [self countKeyPath];
      [coder encodeObject: obj];
      obj = [self leafKeyPath];
      [coder encodeObject: obj];

      f = [self avoidsEmptySelection];
      [coder encodeValueOfObjCType: @encode(BOOL)
				at: &f];
      f = [self preservesSelection];
      [coder encodeValueOfObjCType: @encode(BOOL)
				at: &f];
      f = [self selectsInsertedObjects];
      [coder encodeValueOfObjCType: @encode(BOOL)
				at: &f];
    }
}

- (id) copyWithZone: (NSZone*)zone
{
  NSData *data = [NSArchiver archivedDataWithRootObject: self];
  id result = [NSUnarchiver unarchiveObjectWithData: data];
  return result;
}

@end
