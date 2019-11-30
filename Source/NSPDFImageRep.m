/* Implementation of class NSPDFImageRep
   Copyright (C) 2019 Free Software Foundation, Inc.
   
   By: Gregory Casamento <greg.casamento@gmail.com>
   Date: Fri Nov 15 04:24:27 EST 2019

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.
*/

#include <AppKit/NSPDFImageRep.h>
#include <Foundation/NSString.h>
#include <Foundation/NSData.h>

@implementation NSPDFImageRep

+ (BOOL) canInitWithData: (NSData *)imageData
{
  NSData *header = [imageData subdataWithRange: NSMakeRange(0,4)];
  NSString *str = [[NSString alloc] initWithData: header encoding: NSUTF8StringEncoding];
  AUTORELEASE(str);
  return [str isEqualToString: @"%PDF"] &&
    [super canInitWithData: imageData];
}

+ (instancetype) imageRepWithData: (NSData *)imageData
{
  return AUTORELEASE([[self alloc] initWithData: imageData]);
}

- (instancetype) initWithData: (NSData *)imageData
{
  self = [super init];
  if(self != nil)
    {
#if HAVE_IMAGEMAGICK
  
#endif
    }
  return self;
}

- (NSRect) bounds
{
  return _bounds;
}

- (void) setBounds: (NSRect)bounds
{
  _bounds = bounds;
}

- (NSInteger) currentPage
{
  return _currentPage;
}

- (void) setCurrentPage: (NSInteger)currentPage
{
  _currentPage = currentPage;
}

- (NSInteger) pageCount
{
  return _pageCount;
}

- (NSData *) PDFRepresentation
{
  return _pdfRepresentation;
}

@end

