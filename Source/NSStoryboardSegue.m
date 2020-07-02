/* Implementation of class NSStoryboardSegue
   Copyright (C) 2019 Free Software Foundation, Inc.
   
   By: Gregory Casamento
   Date: Mon Jan 20 15:57:31 EST 2020

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/NSString.h>
#import "AppKit/NSStoryboardSegue.h"

@implementation NSStoryboardSegue

- (id) sourceController
{
  return _sourceController;
}

- (id) destinationController
{
  return _destinationController;
}

- (NSStoryboardSegueIdentifier)identifier
{
  return _identifier;
}

- (void) _setHandler: (GSStoryboardSeguePerformHandler)handler
{
  ASSIGN(_handler, handler);
}

+ (instancetype)segueWithIdentifier: (NSStoryboardSegueIdentifier)identifier 
                             source: (id)sourceController 
                        destination: (id)destinationController 
                     performHandler: (GSStoryboardSeguePerformHandler)performHandler
{
  NSStoryboardSegue *segue = [[NSStoryboardSegue alloc] initWithIdentifier: identifier
                                                                    source: sourceController
                                                               destination: destinationController];
  AUTORELEASE(segue);
  [segue _setHandler: performHandler];

  return segue;
}

- (instancetype)initWithIdentifier: (NSStoryboardSegueIdentifier)identifier 
                            source: (id)sourceController 
                       destination: (id)destinationController
{
  self = [super init];
  if (self != nil)
    {
      ASSIGN(_sourceController, sourceController);
      ASSIGN(_destinationController, destinationController);
      ASSIGN(_identifier, identifier);
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_sourceController);
  RELEASE(_destinationController);
  RELEASE(_identifier);
  RELEASE(_kind);
  RELEASE(_relationship);
  RELEASE(_handler);
  [super dealloc];
}

- (void)perform
{
  if ([_kind isEqualToString: @"relationship"])
    {
    }
  else if ([_kind isEqualToString: @"modal"])
    {
    }
  else if ([_kind isEqualToString: @"show"])
    {
    }
  
  // Perform segue based on it's kind...
  CALL_BLOCK_NO_ARGS(_handler);
}

@end

