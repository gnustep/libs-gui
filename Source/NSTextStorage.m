/** <title>NSTextStorage</title>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 1999
  
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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <Foundation/Foundation.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSLayoutManager.h>

@implementation NSTextStorage

@class	GSTextStorage;

static	Class	abstract;
static	Class	concrete;

static NSNotificationCenter *nc = nil;

+ (void) initialize
{
  if (self == [NSTextStorage class])
    {
      abstract = self;
      concrete = [GSTextStorage class];
      nc = [NSNotificationCenter defaultCenter];
    }
}

+ (id) allocWithZone: (NSZone*)zone
{
  if (self == abstract)
    return NSAllocateObject(concrete, 0, zone);
  else
    return NSAllocateObject(self, 0, zone);
}

- (void) dealloc
{
  RELEASE (_layoutManagers);
  if (_delegate != nil)
    {
      [nc removeObserver: _delegate  name: nil  object: self];
      _delegate = nil;
    }
  [super dealloc];
}

/*
 *	The designated intialiser
 */
- (id) initWithString: (NSString*)aString
           attributes: (NSDictionary*)attributes
{
  _layoutManagers = [[NSMutableArray alloc] initWithCapacity: 2];
  return self;
}

/*
 * Return a string
 */

- (NSString*) string
{
  [self subclassResponsibility: _cmd];
  return nil;
}

/*
 *	Managing NSLayoutManagers
 */
- (void) addLayoutManager: (NSLayoutManager*)obj
{
  if ([_layoutManagers indexOfObjectIdenticalTo: obj] == NSNotFound)
    {
      [_layoutManagers addObject: obj];
      [obj setTextStorage: self];
    }
}

- (void) removeLayoutManager: (NSLayoutManager*)obj
{
  [_layoutManagers removeObjectIdenticalTo: obj];
}

- (NSArray*) layoutManagers
{
  return _layoutManagers;
}

- (void) beginEditing
{
  _editCount++;
}

- (void) endEditing
{
  if (_editCount == 0)
    {
      [NSException raise: NSGenericException
		   format: @"endEditing without corresponding beginEditing"];
    }
  if (--_editCount == 0)
    {
      [self processEditing];
    }
}

/*
 *	If there are no outstanding beginEditing calls, this method calls
 *	processEditing to cause post-editing stuff to happen. This method
 *	has to be called by the primitives after changes are made.
 *	The range argument to edited:... is the range in the original string
 *	(before the edit).
 */
- (void) edited: (unsigned)mask range: (NSRange)old changeInLength: (int)delta
{

  NSDebugLLog(@"NSText", @"edited:range:changeInLength: called");

  /*
   * Add in any new flags for this edit.
   */
  _editedMask |= mask;

  /*
   * Extend edited range to encompass the latest edit.
   */
  if (_editedRange.length == 0)
    {
      _editedRange = old;		// First edit.
    }
  else
    {
      _editedRange = NSUnionRange (_editedRange, old);
    }

  /*
   * If the number of characters has been increased or decreased -
   * adjust the delta accordingly.
   */
  if ((mask & NSTextStorageEditedCharacters) && delta)
    {
      if (delta < 0)
	{
	  NSAssert (old.length >= -delta, NSInvalidArgumentException);
	}
      _editedRange.length += delta; 
      _editedDelta += delta;
    }

  if (_editCount == 0)
    [self processEditing];
}

/*
 *	This is called from edited:range:changeInLength: or endEditing.
 *	This method sends out NSTextStorageWillProcessEditing, then fixes
 *	the attributes, then sends out NSTextStorageDidProcessEditing,
 *	and finally notifies the layout managers of change with the
 *	textStorage:edited:range:changeInLength:invalidatedRange: method.
 */
- (void) processEditing
{
  NSRange	r;
  int i;
  unsigned length;

  NSDebugLLog(@"NSText", @"processEditing called in NSTextStorage.");

  /*
   * The _editCount gets decreased later again, so that changes by the
   * delegate or by ourselves when we fix attributes dont trigger a
   * new processEditing */
  _editCount++;
  [nc postNotificationName: NSTextStorageWillProcessEditingNotification
		    object: self];

  /* Very important: we save the current _editedRange */
  r = _editedRange;
  length = [self length];
  // Multiple adds at the end might give a too long result
  if (NSMaxRange(r) > length)
    {
      r.length = length - r.location;
    }
  
  /* The following call will potentially fix attributes.  These changes 
     are done through NSTextStorage methods, which records the changes 
     by calling edited:range:changeInLength: - which modifies editedRange.
     
     As a consequence, if any attribute has been fixed, r !=
     editedRange after this call.  This is why we saved r in the first
     place. */
  [self invalidateAttributesInRange: r];

  [nc postNotificationName: NSTextStorageDidProcessEditingNotification
                    object: self];
  _editCount--;

  /*
   * Calls textStorage:edited:range:changeInLength:invalidatedRange: for
   * every layoutManager.
   */

  for (i = 0; i < [_layoutManagers count]; i++)
    {
      NSLayoutManager *lManager = [_layoutManagers objectAtIndex: i];

      [lManager textStorage: self  edited: _editedMask  range: r
		changeInLength: _editedDelta  invalidatedRange: _editedRange];
    }

  /*
   * edited values reset to be used again in the next pass.
   */

  _editedRange = NSMakeRange (0, 0);
  _editedDelta = 0;
  _editedMask = 0;
}

/*
 *	These methods return information about the editing status.
 *	Especially useful when there are outstanding beginEditing calls or
 *	during processEditing... editedRange.location will be NSNotFound if
 *	nothing has been edited.
 */       
- (unsigned) editedMask
{
  return _editedMask;
}

- (NSRange) editedRange
{
  return _editedRange;
}

- (int) changeInLength
{
  return _editedDelta;
}

/*
 *	Set/get the delegate
 */
- (void) setDelegate: (id)anObject
{
  if (_delegate)
    [nc removeObserver: _delegate  name: nil  object: self];
  _delegate = anObject;

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(textStorage##notif_name:)]) \
    [nc addObserver: _delegate \
	   selector: @selector(textStorage##notif_name:) \
	       name: NSTextStorage##notif_name##Notification object: self]

  SET_DELEGATE_NOTIFICATION(DidProcessEditing);
  SET_DELEGATE_NOTIFICATION(WillProcessEditing);
}

- (id) delegate
{
  return _delegate;
}

- (void) ensureAttributesAreFixedInRange: (NSRange)range
{
  // Do nothing as the default is not lazy fixing, so all is done already
}

- (BOOL) fixesAttributesLazily
{
  return NO;
}

- (void) invalidateAttributesInRange: (NSRange)range
{
  [self fixAttributesInRange: range];
}

@end
