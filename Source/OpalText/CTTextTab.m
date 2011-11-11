/** <title>CTTextTab</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Aug 2010

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#include <CoreText/CTTextTab.h>

/* Constants */

const CFStringRef kCTTabColumnTerminatorsAttributeName = @"kCTTabColumnTerminatorsAttributeName";

/* Classes */

/**
 * Tab
 */
@interface CTTextTab : NSObject
{
  CTTextAlignment _alignment;
  double _location;
  NSDictionary *_options;
}

- (id)initWithAlignment: (CTTextAlignment)alignment
               location: (double)location
                options: (NSDictionary*)options;
- (CTTextAlignment)alignment;
- (double)location;
- (NSDictionary*)options;
@end

@implementation CTTextTab

- (id)initWithAlignment: (CTTextAlignment)alignment
               location: (double)location
                options: (NSDictionary*)options
{
  self = [super init];
  if (nil == self)
  {
    return nil;
  }

  return self;
}
- (CTTextAlignment)alignment
{
  return _alignment;
}
- (double)location
{
  return _location;
}
- (NSDictionary*)options
{
  return _options;
}

@end


/* Functions */

CTTextTabRef CTTextTabCreate(
	CTTextAlignment alignment,
	double location,
	CFDictionaryRef options)
{
  return [[CTTextTab alloc] initWithAlignment: alignment
                                     location: location
                                      options: options];
}
CTTextAlignment CTTextTabGetAlignment(CTTextTabRef tab)
{
  return [tab alignment];
}
double CTTextTabGetLocation(CTTextTabRef tab)
{
  return [tab location];
}
CFDictionaryRef CTTextTabGetOptions(CTTextTabRef tab)
{
  return [tab options];
}

CFTypeID CTTextTabGetTypeID()
{
  return (CFTypeID)[CTTextTab class];
}
