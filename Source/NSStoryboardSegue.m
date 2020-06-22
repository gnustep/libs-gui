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

+ (instancetype)segueWithIdentifier: (NSStoryboardSegueIdentifier)identifier 
                             source: (id)sourceController 
                        destination: (id)destinationController 
                     performHandler: (GSStoryboardSeguePerformHandler)performHandler
{
  NSStoryboardSegue *segue = [[NSStoryboardSegue alloc] initWithIdentifier: identifier
                                                                    source: sourceController
                                                               destination: destinationController];
  AUTORELEASE(segue);
  CALL_BLOCK_NO_ARGS(performHandler);
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

- (void)perform
{
  // TBD...
}

@end

