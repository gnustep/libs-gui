/* GSKeyBindingAction.m                    -*-objc-*-

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
#include "AppKit/NSInputManager.h"

@implementation GSKeyBindingAction
- (void) performActionWithInputManager: (NSInputManager *)manager
{
  [self subclassResponsibility: _cmd];
}
@end


@implementation GSKeyBindingActionSelector
- (id) initWithSelectorName: (NSString *)sel
{
  _selector = NSSelectorFromString (sel);
  
  if (_selector == NULL)
    {
      DESTROY (self);
      return nil;
    }
  
  return [super init];
}

- (void) performActionWithInputManager: (NSInputManager *)manager
{
  [manager doCommandBySelector: _selector];
}
@end


@implementation GSKeyBindingActionSelectorArray
- (id) initWithSelectorNames: (NSArray *)sels
{
  int i;
  
  _selectorsCount = [sels count];

  _selectors = objc_malloc (sizeof (SEL) * _selectorsCount);

  for (i = 0; i < _selectorsCount; i++)
    {
      NSString *name = [sels objectAtIndex: i];

      _selectors[i] = NSSelectorFromString (name);

      if (_selectors[i] == NULL)
	{
	  /* DESTROY (self) will dealloc the selectors array.  */
	  DESTROY (self);
	  return nil;
	}
    }

  return [super init];
}

- (void) dealloc
{
  objc_free (_selectors);
  [super dealloc];
}

- (void) performActionWithInputManager: (NSInputManager *)manager
{
  int i;

  for (i = 0; i < _selectorsCount; i++)
    {
      [manager doCommandBySelector: _selectors[i]];
    }
}
@end


@implementation GSKeyBindingActionQuoteNextKeyStroke
- (void) performActionWithInputManager: (NSInputManager *)manager
{
  [manager quoteNextKeyStroke];
}
@end
