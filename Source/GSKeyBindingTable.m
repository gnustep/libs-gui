/* GSKeyBindingTable.m                    -*-objc-*-

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: February 2002

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

#include "GSKeyBindingAction.h"
#include "GSKeyBindingTable.h"
#include <AppKit/NSInputManager.h>
#include <AppKit/NSEvent.h>

@implementation GSKeyBindingTable : NSObject

- (void) loadBindingsFromDictionary: (NSDictionary *)dict
{
  NSEnumerator *e;
  NSString *key;
  
  e = [dict keyEnumerator];
  while ((key = [e nextObject]) != nil)
    {
      [self bindKey: key  toAction: [dict objectForKey: key]];
    }
}

- (void) bindKey: (NSString *)key  toAction: (id)action
{
  unichar character;
  int modifiers;
  GSKeyBindingAction *a = nil;
  GSKeyBindingTable *t = nil;
  int i;
  
  if (![NSInputManager parseKey: key 
		       intoCharacter: &character
		       andModifiers: &modifiers])
    {
      NSLog (@"GSKeyBindingTable - Could not bind key %@", key);
      return;
    }

  /* If it is not a function key, we automatically ignore the Shift
   * modifier.  You shouldn't use it unless you are describing a modification
   * of a function key.  The NSInputManager will ignore Shift modifiers
   * as well for non-function keys.  */
  if (modifiers & NSFunctionKeyMask)
    {
      /* Ignore all other modifiers when storing the keystroke modifiers.  */
      modifiers = modifiers & (NSShiftKeyMask 
			       | NSAlternateKeyMask 
			       | NSControlKeyMask 
			       | NSNumericPadKeyMask);
    }
  else
    {
      modifiers = modifiers & (NSAlternateKeyMask 
			       | NSControlKeyMask 
			       | NSNumericPadKeyMask);
    }


  /* Now build the associated action/table.  */
  if ([action isKindOfClass: [NSString class]])
    {
      /* "" as action means disable the keybinding.  It can be used to
	 override a previous keybinding.  */
      if ([(NSString *)action isEqualToString: @""])
	{
	  a = nil;
	}
      else
	{
	  a = [[GSKeyBindingActionSelector alloc] 
		initWithSelectorName: (NSString *)action];
	  AUTORELEASE (a);
	}
    }
  else if ([action isKindOfClass: [NSArray class]])
    {
      a = [[GSKeyBindingActionSelectorArray alloc]
	    initWithSelectorNames: (NSArray *)action];
      AUTORELEASE (a);
    }
  else if ([action isKindOfClass: [NSDictionary class]])
    {
      t = [[GSKeyBindingTable alloc] init];
      [t loadBindingsFromDictionary: (NSDictionary *)action];
      AUTORELEASE (t);
    }
  else if ([action isKindOfClass: [GSKeyBindingAction class]])
    {
      a = action;
    }

  /* Ok - at this point, we have all the elements ready, we just need
     to insert into the table.  */
    
  /* Check if there are already some bindings for this keystroke.  */
  for (i = 0; i < _bindingsCount; i++)
    {
      if ((_bindings[i].character == character)  
	  &&  (_bindings[i].modifiers == modifiers))
	{
	  /* Replace/override the existing action/table with the new
	     ones.  */
	  ASSIGN (_bindings[i].action, a);
	  ASSIGN (_bindings[i].table, t);
	  return;
	}
    }

  /* Ok - allocate memory for the new binding.  */
  if (_bindingsCount == 0)
    {
      _bindingsCount = 1;
      _bindings = objc_malloc (sizeof (struct _GSKeyBinding));
    }
  else
    {
      _bindingsCount++;
      _bindings = objc_realloc (_bindings, sizeof (struct _GSKeyBinding) 
				* _bindingsCount);
    }
  _bindings[_bindingsCount - 1].character = character;
  _bindings[_bindingsCount - 1].modifiers = modifiers;

  /* Don't use ASSIGN here because that uses the previous value of
     _bindings[_bindingsCount - 1] ... which is undefined.  */
  _bindings[_bindingsCount - 1].action = a;
  RETAIN (a);
  _bindings[_bindingsCount - 1].table = t;
  RETAIN (t);
}

- (BOOL) lookupKeyStroke: (unichar)character
	       modifiers: (int)flags
       returningActionIn: (GSKeyBindingAction **)action
		 tableIn: (GSKeyBindingTable **)table
{
  int i;
  
  for (i = 0; i < _bindingsCount; i++)
    {
      if (_bindings[i].character == character)
	{
	  if (_bindings[i].modifiers == flags)
	    {
	      if (_bindings[i].action == nil  &&  _bindings[i].table == nil)
		{
		  /* Found the keybinding, but it is disabled!  */
		  return NO;
		}
	      else
		{
		  *action = _bindings[i].action;
		  *table = _bindings[i].table;
		  return YES;
		}
	    }
	}
    }
  return NO;
}

- (void) dealloc
{
  int i;

  for (i = 0; i < _bindingsCount; i++)
    {
      RELEASE (_bindings[i].action);
      RELEASE (_bindings[i].table);
    }
  objc_free (_bindings);
  [super dealloc];
}

@end


