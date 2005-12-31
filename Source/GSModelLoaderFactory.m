/** <title>GSModelLoaderFactory</title>

   <abstract>Model loader framework</abstract>

   Copyright (C) 1997, 1999 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2005
   
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

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GNUstepGUI/GSModelLoaderFactory.h"

static NSMutableDictionary *_modelMap = nil;

@implementation GSModelLoaderFactory
+ (void) initialize
{
  // load these, since we know about them.
  [GSModelLoaderFactory registerModelLoaderClass: @"GSGormLoader" forType: @"gorm"];
  [GSModelLoaderFactory registerModelLoaderClass: @"GSGModelLoader" forType: @"gmodel"];
}

+ (void) registerModelLoaderClass: (NSString *)aClass forType: (NSString *)type
{
  if(_modelMap == nil)
    {
      _modelMap = [[NSMutableDictionary alloc] initWithCapacity: 5];
    }

  [_modelMap setObject: aClass forKey: type];
}

+ (NSString *)classForType: (NSString *)type
{
  return [_modelMap objectForKey: type];
}

+ (NSString *) supportedModelFileAtPath: (NSString *)modelPath
{
  NSEnumerator *ken = [_modelMap keyEnumerator];
  NSString *type = nil;
  NSString *result = nil;
  NSFileManager	*mgr = [NSFileManager defaultManager];
  NSString *ext = [modelPath pathExtension];

  if([ext isEqual: @""])
    {
      while((type = [ken nextObject]) != nil && result == NO)
	{
	  NSString *path = [modelPath stringByAppendingPathExtension: type];
	  if([mgr isReadableFileAtPath: path])
	    {
	      result = path;
	    }
	}
    }
  else
    {
      if([_modelMap objectForKey: ext] != nil)
	{
	  result = modelPath;
	} 
    }
  
  return result;
}

+ (id<GSModelLoader>)modelLoaderForFileType: (NSString *)type
{
  NSString *className = [GSModelLoaderFactory classForType: type];
  Class aClass = NSClassFromString(className);
  id<GSModelLoader> loader = nil;

  if(aClass != nil)
    {
      // it is up to the class which uses the loader to release it.
      loader = [[aClass alloc] init];
    }
  else
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"Unable to find model loader class '%@'", className];
    }

  return loader;
}

+ (id<GSModelLoader>)modelLoaderForFileName: (NSString *)modelPath
{
  NSString *path = [GSModelLoaderFactory supportedModelFileAtPath: modelPath];
  id<GSModelLoader> result = nil;

  if(path != nil)
    {
      NSString *ext = [path pathExtension];
      result = [self modelLoaderForFileType: ext];
    }
  
  return result;  
}
@end
