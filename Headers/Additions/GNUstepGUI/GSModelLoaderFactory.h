/** <title>NSBundleAdditions</title>

   <abstract>Implementation of NSBundle Additions</abstract>

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

#ifndef _GNUstep_H_GSModelLoaderFactory
#define _GNUstep_H_GSModelLoaderFactory

#include <Foundation/Foundation.h>

@protocol GSModelLoader
- (BOOL) loadModelFile: (NSString *)fileName
     externalNameTable: (NSDictionary *)context
              withZone: (NSZone *)zone;
@end

@interface GSModelLoaderFactory : NSObject
+ (void) registerModelLoaderClass: (NSString *)aClass forType: (NSString *)type;
+ (NSString *)classForType: (NSString *)type;
+ (NSString *) supportedModelFileAtPath: (NSString *)modelPath;
+ (id<GSModelLoader>)modelLoaderForFileType: (NSString *)type;
+ (id<GSModelLoader>)modelLoaderForFileName: (NSString *)modelPath;
@end

#endif
