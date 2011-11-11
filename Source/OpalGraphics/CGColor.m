/** <title>CGColor</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: BALATON Zoltan <balaton@eik.bme.hu>
   Date: 2006

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#include "CoreGraphics/CGContext.h"
#include "CoreGraphics/CGColor.h"

#import "CGColor-private.h"
#import "CGColorSpace-private.h"
#import "OPImageConversion.h"

const CFStringRef kCGColorWhite = @"kCGColorWhite";
const CFStringRef kCGColorBlack = @"kCGColorBlack";
const CFStringRef kCGColorClear = @"kCGColorClear";

static CGColorRef _whiteColor;
static CGColorRef _blackColor;
static CGColorRef _clearColor;


@implementation CGColor

- (id) initWithColorSpace: (CGColorSpaceRef)cs components: (const CGFloat*)components
{
  self = [super init];
  if (nil == self) return nil;

  size_t nc, i;
  nc = CGColorSpaceGetNumberOfComponents(cs);
  NSLog(@"Create color with %d comps", nc);
  self->comps = malloc((nc+1)*sizeof(CGFloat));
  if (NULL == self->comps) {
    NSLog(@"malloc failed");
    [self release];
    return nil;
  }
  self->cspace = CGColorSpaceRetain(cs);
  self->pattern = nil;
  for (i=0; i<=nc; i++)
    self->comps[i] = components[i];    
  return self;  
}

- (void) dealloc
{
  CGColorSpaceRelease(self->cspace);
  CGPatternRelease(self->pattern);
  free(self->comps);
  [super dealloc];    
}

- (BOOL) isEqual: (id)other
{
  if (![other isKindOfClass: [CGColor class]]) return NO;
  CGColor *otherColor = (CGColor *)other;
  
  int nc = CGColorSpaceGetNumberOfComponents(self->cspace);

  if (![self->cspace isEqual: otherColor->cspace]) return NO;
  if (![self->pattern isEqual: otherColor->pattern]) return NO;
  
  for (int i = 0; i <= nc; i++) {
    if (self->comps[i] != otherColor->comps[i])
      return NO;
  }
  return YES;
}

- (CGColor*) transformToColorSpace: (CGColorSpaceRef)destSpace withRenderingIntent: (CGColorRenderingIntent)intent
{
  CGColorSpaceRef sourceSpace = CGColorGetColorSpace(self);

  // FIXME: this is ugly because CGColor uses CGFloats, but OPColorTransform only accepts
  // 32-bit float components.

  float originalComps[CGColorSpaceGetNumberOfComponents(sourceSpace) + 1];
  float tranformedComps[CGColorSpaceGetNumberOfComponents(destSpace) + 1];

  for (size_t i=0; i < CGColorSpaceGetNumberOfComponents(sourceSpace) + 1; i++)
  {
    originalComps[i] = comps[i];
  }

  OPImageFormat sourceFormat;
  sourceFormat.compFormat = kOPComponentFormatFloat32bpc;
  sourceFormat.colorComponents = CGColorSpaceGetNumberOfComponents(sourceSpace);
  sourceFormat.hasAlpha = true;
  sourceFormat.isAlphaPremultiplied = false;
  sourceFormat.isAlphaLast = true;

  OPImageFormat destFormat;
  destFormat.compFormat = kOPComponentFormatFloat32bpc;
  destFormat.colorComponents = CGColorSpaceGetNumberOfComponents(destSpace);
  destFormat.hasAlpha = true;
  destFormat.isAlphaPremultiplied = false;
  destFormat.isAlphaLast = true;

  id<OPColorTransform> xform = [sourceSpace colorTransformTo: destSpace
                                             sourceFormat: sourceFormat
                                        destinationFormat: destFormat
                                          renderingIntent: intent
                                               pixelCount: 1];

  [xform transformPixelData: (const unsigned char *)originalComps
                     output: (unsigned char *)tranformedComps];
  
  CGFloat cgfloatTransformedComps[CGColorSpaceGetNumberOfComponents(destSpace) + 1];
  for (size_t i=0; i < CGColorSpaceGetNumberOfComponents(destSpace) + 1; i++)
  {
    cgfloatTransformedComps[i] = tranformedComps[i];
  }
 // FIXME: release xform?

  return [[[CGColor alloc] initWithColorSpace: destSpace components: cgfloatTransformedComps] autorelease];
}

@end


CGColorRef CGColorCreate(CGColorSpaceRef colorspace, const CGFloat components[])
{
  CGColor *clr = [[CGColor alloc] initWithColorSpace: colorspace components: components];
  return clr;
}

CFTypeID CGColorGetTypeID()
{
  return (CFTypeID)[CGColor class];   
}

CGColorRef CGColorRetain(CGColorRef clr)
{
  return [clr retain];
}

void CGColorRelease(CGColorRef clr)
{
  [clr release];
}

CGColorRef CGColorCreateCopy(CGColorRef clr)
{
  return CGColorCreate(clr->cspace, clr->comps);
}

CGColorRef CGColorCreateCopyWithAlpha(CGColorRef clr, CGFloat alpha)
{
  CGColorRef newclr;

  newclr = CGColorCreate(clr->cspace, clr->comps);
  if (!newclr) return nil;

  newclr->comps[CGColorSpaceGetNumberOfComponents(newclr->cspace)] = alpha;
  return newclr;
}

CGColorRef CGColorCreateGenericCMYK(
  CGFloat cyan,
  CGFloat magenta,
  CGFloat yellow,
  CGFloat black,
  CGFloat alpha)
{
  CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceCMYK();
  const CGFloat components[] = {cyan, magenta, yellow, black, alpha};
  CGColorRef clr = CGColorCreate(colorspace, components);
  CGColorSpaceRelease(colorspace);
  return clr;
}

CGColorRef CGColorCreateGenericGray(CGFloat gray, CGFloat alpha)
{
  CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
  const CGFloat components[] = {gray, alpha};
  CGColorRef clr = CGColorCreate(colorspace, components);
  CGColorSpaceRelease(colorspace);
  return clr;
}

CGColorRef CGColorCreateGenericRGB(
  CGFloat red,
  CGFloat green,
  CGFloat blue,
  CGFloat alpha)
{
  CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
  const CGFloat components[] = {red, green, blue, alpha};
  CGColorRef clr = CGColorCreate(colorspace, components);
  CGColorSpaceRelease(colorspace);
  return clr;
}

CGColorRef CGColorCreateWithPattern(
  CGColorSpaceRef colorspace,
  CGPatternRef pattern,
  const CGFloat components[])
{
  CGColorRef clr = CGColorCreate(colorspace, components);
  clr->pattern = CGPatternRetain(pattern);
  return clr;
}

bool CGColorEqualToColor(CGColorRef color1, CGColorRef color2)
{
  return [color1 isEqual: color2];
}

CGFloat CGColorGetAlpha(CGColorRef clr)
{
  int alphaIndex = CGColorSpaceGetNumberOfComponents(clr->cspace);
  return clr->comps[alphaIndex];
}

CGColorSpaceRef CGColorGetColorSpace(CGColorRef clr)
{
  return clr->cspace;
}

const CGFloat *CGColorGetComponents(CGColorRef clr)
{
  return clr->comps;
}

CGColorRef CGColorGetConstantColor(CFStringRef name)
{
  if ([name isEqual: kCGColorWhite])
  {
    if (nil == _whiteColor)
    {
      _whiteColor = CGColorCreateGenericGray(1, 1);
    }
    return  _whiteColor;
  }
  else if ([name isEqual: kCGColorBlack])
  {
    if (nil == _blackColor)
    {
      _blackColor = CGColorCreateGenericGray(0, 1);
    }
    return _blackColor;
  }
  else if ([name isEqual: kCGColorClear])
  {
    if (nil == _clearColor)
    {
      _clearColor = CGColorCreateGenericGray(0, 0);
    }
    return _clearColor;
  }
  return nil;
}

size_t CGColorGetNumberOfComponents(CGColorRef clr)
{
  return CGColorSpaceGetNumberOfComponents(clr->cspace);
}

CGPatternRef CGColorGetPattern(CGColorRef clr)
{
  return clr->pattern;
}

CGColorRef OPColorGetTransformedToSpace(CGColorRef clr, CGColorSpaceRef space, CGColorRenderingIntent intent)
{
  return [clr transformToColorSpace: space withRenderingIntent: intent];
}
