/* 
   NSTextStorage.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
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
#include <Foundation/NSGAttributedString.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSLayoutManager.h>

@implementation NSTextStorage

@class	GSTextStorage;

static	Class	abstract;
static	Class	concrete;

+ (void) initialize
{
  if (self == [NSTextStorage class])
    {
      abstract = self;
      concrete = [GSTextStorage class];
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
  RELEASE(layoutManagers);
  [super dealloc];
}

/*
 *	The designated intialiser
 */
- (id) initWithString: (NSString*)aString
           attributes: (NSDictionary*)attributes
{
  layoutManagers = [[NSMutableArray alloc] initWithCapacity: 2];
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

- (void) replaceCharactersInRange: (NSRange)aRange
	     withAttributedString: (NSAttributedString *)attributedString  
{
  [super replaceCharactersInRange: aRange
	     withAttributedString: attributedString];

  [self edited: NSTextStorageEditedCharacters | NSTextStorageEditedAttributes
	 range: aRange
changeInLength: [attributedString length] - aRange.length];
}

/*
 *	Managing NSLayoutManagers
 */
- (void) addLayoutManager: (NSLayoutManager*)obj
{
  if ([layoutManagers indexOfObjectIdenticalTo: obj] == NSNotFound)
    [layoutManagers addObject: obj];
}

- (void) removeLayoutManager: (NSLayoutManager*)obj
{
  [layoutManagers removeObjectIdenticalTo: obj];
}

- (NSArray*) layoutManagers
{
  return layoutManagers;
}

- (void) beginEditing
{
  editCount++;
}

- (void) endEditing
{
  if (editCount == 0)
    [NSException raise: NSGenericException
		format: @"endEditing without corresponding beginEditing"];
  if (--editCount == 0)
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

  NSLog(@"edited:range:changeInLength: called");

  /*
   * Add in any new flags for this edit.
   */
  editedMask |= mask;

  /*
   * Extend edited range to encompass the latest edit.
   */
  if (editedRange.length == 0)
    {
      editedRange = old;		// First edit.
    }
  else
    {
      if (editedRange.location > old.location)
	editedRange.location = old.location;
      if (NSMaxRange(editedRange) < NSMaxRange(old))
	editedRange.length = NSMaxRange(old) - editedRange.location;
    }

  /*
   * If the number of characters has been increased or decreased -
   * adjust the delta accordingly.
   */
  if ((mask & NSTextStorageEditedCharacters) && delta)
    {
      if (delta < 0)
	{
	  // FIXME: this was > not >=, is that going to be a problem?
	  NSAssert(old.length >= -delta, NSInvalidArgumentException);
	}
      editedDelta += delta;
    }

  if (editCount == 0)
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

  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

  NSLog(@"processEditing called in NSTextStorage.");

  [nc postNotificationName: NSTextStorageWillProcessEditingNotification
		    object: self];

  r = editedRange;
  r.length += editedDelta;
  [self fixAttributesInRange: r];

  [nc postNotificationName: NSTextStorageDidProcessEditingNotification
                    object: self];

  /*
   * Calls textStorage:edited:range:changeInLength:invalidatedRange: for
   * every layoutManager.
   *
   * FIXME, Michael: are the ranges used correct?
   */

  for (i=0;i<[layoutManagers count];i++)
    {
      NSLayoutManager *lManager = [layoutManagers objectAtIndex:i];

      [lManager textStorage:self edited:editedMask range:editedRange
	changeInLength:editedDelta invalidatedRange:r];
    }

  /*
   * edited values reset to be used again in the next pass.
   */

  editedRange = NSMakeRange(0, 0);
  editedDelta = 0;
  editedMask = 0;
}

/*
 *	These methods return information about the editing status.
 *	Especially useful when there are outstanding beginEditing calls or
 *	during processEditing... editedRange.location will be NSNotFound if
 *	nothing has been edited.
 */       
- (unsigned) editedMask
{
  return editedMask;
}

- (NSRange) editedRange
{
  return editedRange;
}

- (int) changeInLength
{
  return editedDelta;
}

/*
 *	Set/get the delegate
 */
- (void) setDelegate: (id)anObject
{
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

  if (delegate)
    [nc removeObserver: delegate name: nil object: self];
  delegate = anObject;

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([delegate respondsToSelector: @selector(textStorage##notif_name:)]) \
    [nc addObserver: delegate \
	   selector: @selector(textStorage##notif_name:) \
	       name: NSTextStorage##notif_name##Notification object: self]

  SET_DELEGATE_NOTIFICATION(DidProcessEditing);
  SET_DELEGATE_NOTIFICATION(WillProcessEditing);
}

- (id) delegate
{
  return delegate;
}

@end


/*
 *	Notifications
 */

NSString *NSTextStorageWillProcessEditingNotification =
  @"NSTextStorageWillProcessEditingNotification";
NSString *NSTextStorageDidProcessEditingNotification =
  @"NSTextStorageDidProcessEditingNotification";

