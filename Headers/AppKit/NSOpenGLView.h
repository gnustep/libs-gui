/* 	-*-ObjC-*- */
/** 
   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Frederic De Jaeger
   Date: Nov 2002
   
   This file is part of the GNU Objective C User interface library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.
   */

#ifndef _NSOpenGLView_h
#define _NSOpenGLView_h
#import <GNUstepBase/GSVersionMacros.h>

#include <AppKit/NSView.h>

@class NSOpenGLContext;
@class NSOpenGLPixelFormat;

@interface NSOpenGLView : NSView
{
  NSOpenGLContext 	*glcontext;
  NSOpenGLPixelFormat	*pixel_format;
  BOOL			attached;
}
+ (NSOpenGLPixelFormat*)defaultPixelFormat;
- (void)clearGLContext;
- (void)setOpenGLContext:(NSOpenGLContext*)context;
- (NSOpenGLContext*)openGLContext;
- (id)initWithFrame:(NSRect)frameRect 
pixelFormat:(NSOpenGLPixelFormat*)format;
- (void) dealloc;
- (NSOpenGLPixelFormat*)pixelFormat;
- (void)setPixelFormat:(NSOpenGLPixelFormat*)pixelFormat;
- (void) reshape;
- (void) update;
@end
#endif
