/** <title>NSNibAXAttributeConnector</title>

   <abstract>
   </abstract>

   Copyright (C) 2007 Free Software Foundation, Inc.

   Author: Gregory John Casamento
   Date: 2007

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
   License along with this library;
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/ 

#import <GNUstepGUI/GSNibCompatibility.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>

@implementation NSNibBindingConnector
- (NSString *) binding
{
  return _binding;
}

- (NSString *) keyPath
{
  return _keyPath;
}

- (NSDictionary *) options
{
  return _options;
}

- (void) setBinding: (NSString *)binding
{
  ASSIGN(_binding, binding);
}

- (void) setKeyPath: (NSString *)keyPath
{
  ASSIGN(_keyPath, keyPath);
}

- (void) setOptions: (NSDictionary *)options
{
  ASSIGN(_options, options);
}
@end
