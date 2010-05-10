/** <title>GSFusedSilica</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
   Date: Sep 2002
   
   This file is part of the GNUStep

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#include "GSFusedSilicaContext.h"
#include "AppKit/NSAffineTransform.h"
#include <Foundation/NSDictionary.h>

/* Managing Graphics Contexts */

CGContextRef CGBitmapContextCreate(
  void *data,
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bytesPerRow,
  CGColorSpaceRef colorspace,
  CGImageAlphaInfo alphaInfo
)
{
  return NULL;
}

/*
CGContextRef CGPDFContextCreate(
  CGDataConsumerRef consumer,
  const CGRect *mediaBox,
  CFDictionaryRef auxiliaryInfo
);

CGContextRef CGPDFContextCreateWithURL(
  CFURLRef url,
  const CGRect *mediaBox,
  CFDictionaryRef auxiliaryInfo
);
*/

CGContextRef CGContextRetain(CGContextRef ctx)
{
  return [(NSGraphicsContext *)ctx retain];
}

void CGContextRelease(CGContextRef ctx)
{
  [(NSGraphicsContext *)ctx release];
}

void CGContextFlush(CGContextRef ctx)
{
  [(NSGraphicsContext *)ctx flushGraphics];
}

void CGContextSynchronize(CGContextRef ctx)
{
}

/* Defining Pages */

void CGContextBeginPage(CGContextRef ctx, const CGRect *mediaBox)
{
}

void CGContextEndPage(CGContextRef ctx)
{
}

/* Transforming the Coordinate Space of the Page */

void CGContextScaleCTM(CGContextRef ctx, float sx, float sy)
{
  NSAffineTransform *trans = [NSAffineTransform transform];
  [trans scaleXBy: sx yBy: sy];
  [(NSGraphicsContext *)ctx GSConcatCTM: trans];
}

void CGContextTranslateCTM(CGContextRef ctx, float tx, float ty)
{
  NSAffineTransform *trans = [NSAffineTransform transform];
  [trans translateXBy: tx yBy: ty];
  [(NSGraphicsContext *)ctx GSConcatCTM: trans];
}

void CGContextRotateCTM(CGContextRef ctx, float angle)
{
  NSAffineTransform *trans = [NSAffineTransform transform];
  [trans rotateByDegrees: angle];
  [(NSGraphicsContext *)ctx GSConcatCTM: trans];
}

void CGContextConcatCTM(CGContextRef ctx, CGAffineTransform transform)
{
#if 0
  NSAffineTransform *trans = [NSAffineTransform transform];
  [trans setTransformStruct: (NSAffineTransformStruct) transform];
  [(NSGraphicsContext *)ctx GSConcatCTM: trans];
#endif
}

CGAffineTransform CGContextGetCTM(CGContextRef ctx)
{
  //NSAffineTransform *trans = [(NSGraphicsContext *)ctx GSCurrentCTM];
  return CGAffineTransformIdentity;
}

/* Saving and Restoring the Graphics State */

void CGContextSaveGState(CGContextRef ctx)
{
  [(NSGraphicsContext *)ctx DPSgsave];
}

void CGContextRestoreGState(CGContextRef ctx)
{
  [(NSGraphicsContext *)ctx DPSgrestore];
}

/* Setting Graphics State Attributes */

void CGContextSetShouldAntialias(CGContextRef ctx, int shouldAntialias)
{
  [(NSGraphicsContext *)ctx setShouldAntialias: shouldAntialias];
}

void CGContextSetLineWidth(CGContextRef ctx, float width)
{
  [(NSGraphicsContext *)ctx DPSsetlinewidth: width];
}

void CGContextSetLineJoin(CGContextRef ctx, CGLineJoin join)
{
  [(NSGraphicsContext *)ctx DPSsetlinejoin: join];
}

void CGContextSetMiterLimit(CGContextRef ctx, float limit)
{
  [(NSGraphicsContext *)ctx DPSsetmiterlimit: limit];
}

void CGContextSetLineCap(CGContextRef ctx, CGLineCap cap)
{
  [(NSGraphicsContext *)ctx DPSsetlinecap: cap];
}

void CGContextSetLineDash(CGContextRef ctx, float phase, const float *lengths, size_t count)
{
  [(NSGraphicsContext *)ctx DPSsetdash: lengths : count : phase];
}

void CGContextSetFlatness(CGContextRef ctx, float flatness)
{
  [(NSGraphicsContext *)ctx DPSsetflat: flatness];
}

/* Constructing Paths */

void CGContextBeginPath(CGContextRef ctx)
{
  [(NSGraphicsContext *)ctx DPSnewpath];
}

void CGContextMoveToPoint(CGContextRef ctx, float x, float y)
{
  [(NSGraphicsContext *)ctx DPSmoveto: x : y];
}

void CGContextAddLineToPoint(CGContextRef ctx, float x, float y)
{
  [(NSGraphicsContext *)ctx DPSlineto: x : y];
}

void CGContextAddLines(CGContextRef ctx, const CGPoint *points, size_t count)
{
  // FIXME
}

void CGContextAddCurveToPoint(
  CGContextRef ctx,
  float cp1x,
  float cp1y,
  float cp2x,
  float cp2y,
  float x,
  float y
)
{
  [(NSGraphicsContext *)ctx DPScurveto: cp1x : cp1y : cp2x : cp2y : x : y];
}

void CGContextAddQuadCurveToPoint(
  CGContextRef ctx,
  float cpx,
  float cpy,
  float x,
  float y
)
{
  // FIXME
}

void CGContextAddRect(CGContextRef ctx, CGRect rect)
{
  // FIXME
}

void CGContextAddRects(CGContextRef ctx, const CGRect *rects, size_t count)
{
  // FIXME
}

void CGContextAddArc(
  CGContextRef ctx,
  float x,
  float y,
  float radius,
  float startAngle,
  float endAngle,
  int clockwise
)
{
  // FIXME: clockwise...
  [(NSGraphicsContext *)ctx DPSarc: x : y : radius : startAngle : endAngle];
}

void CGContextAddArcToPoint(
  CGContextRef ctx,
  float x1,
  float y1,
  float x2,
  float y2,
  float radius
)
{
  [(NSGraphicsContext *)ctx DPSarct: x1 : y1 : x2 : y2 : radius];
}

void CGContextClosePath(CGContextRef ctx)
{
  [(NSGraphicsContext *)ctx DPSclosepath];
}

/* Painting Paths */

void CGContextDrawPath(CGContextRef ctx, CGPathDrawingMode mode)
{
  //FIXME
}

void CGContextStrokePath(CGContextRef ctx)
{
  [(NSGraphicsContext *)ctx DPSstroke];
}

void CGContextFillPath(CGContextRef ctx)
{
  [(NSGraphicsContext *)ctx DPSfill];
}

void CGContextEOFillPath(CGContextRef ctx)
{
  [(NSGraphicsContext *)ctx DPSeofill];
}

void CGContextStrokeRect(CGContextRef ctx, CGRect rect)
{
  [(NSGraphicsContext *)ctx DPSrectstroke: rect.origin.x : rect.origin.y
   : rect.size.width : rect.size.height];
}

void CGContextStrokeRectWithWidth(CGContextRef ctx, CGRect rect, float width)
{
  //FIXME
}

void CGContextFillRect(CGContextRef ctx, CGRect rect)
{
  [(NSGraphicsContext *)ctx DPSrectfill: rect.origin.x : rect.origin.y
   : rect.size.width : rect.size.height];
}

void CGContextFillRects(CGContextRef ctx, const CGRect *rects, size_t count)
{
  [(NSGraphicsContext *)ctx GSRectFillList: (NSRect *)rects : count];
}

void CGContextClearRect(CGContextRef c, CGRect rect)
{
  //FIXME
}

/* Obtaining Path Information */

int CGContextIsPathEmpty(CGContextRef ctx)
{
  return 0;
}

CGPoint CGContextGetPathCurrentPoint(CGContextRef ctx)
{
  CGPoint p;
  [(NSGraphicsContext *)ctx DPScurrentpoint: &p.x : &p.y];
  return p;
}

CGRect CGContextGetPathBoundingBox(CGContextRef ctx)
{
  return CGRectZero;
}

/* Clipping Paths */

void CGContextClip(CGContextRef ctx)
{
  [(NSGraphicsContext *)ctx DPSclip];
}

void CGContextEOClip(CGContextRef ctx)
{
  [(NSGraphicsContext *)ctx DPSeoclip];
}

void CGContextClipToRect(CGContextRef ctx, CGRect rect)
{
  [(NSGraphicsContext *)ctx DPSrectclip: rect.origin.x : rect.origin.y
   : rect.size.width : rect.size.height];
}

void CGContextClipToRects(CGContextRef ctx, const CGRect *rects, size_t count)
{
  [(NSGraphicsContext *)ctx GSRectClipList: (NSRect *)rects : count];
}

/* Setting the Color Space */
CGColorSpaceRef CGColorSpaceCreateDeviceGray(void)
{
  return [NSGraphicsContext CGColorSpaceCreateDeviceGray];
}

CGColorSpaceRef CGColorSpaceCreateDeviceRGB(void)
{
  return [NSGraphicsContext CGColorSpaceCreateDeviceRGB];
}

CGColorSpaceRef CGColorSpaceCreateDeviceCMYK(void)
{
  return [NSGraphicsContext CGColorSpaceCreateDeviceCMYK];
}

CGColorSpaceRef CGColorSpaceCreateCalibratedGray(
  const float *whitePoint,
  const float *blackPoint,
  float gamma
)
{
  return [NSGraphicsContext CGColorSpaceCreateCalibratedGray: whitePoint
			       : blackPoint
			       : gamma];
}

CGColorSpaceRef CGColorSpaceCreateCalibratedRGB(
  const float *whitePoint,
  const float *blackPoint,
  const float *gamma,
  const float *matrix
)
{
  return [NSGraphicsContext CGColorSpaceCreateCalibratedRGB: whitePoint
			       : blackPoint
			       : gamma
			       : matrix];
}

CGColorSpaceRef CGColorSpaceCreateLab(
  const float *whitePoint,
  const float *blackPoint,
  const float *range
)
{
  return [NSGraphicsContext CGColorSpaceCreateLab: whitePoint
			       : blackPoint
			       : range];
}

CGColorSpaceRef CGColorSpaceCreateICCBased(
  size_t nComponents,
  const float *range,
  CGDataProviderRef profile,
  CGColorSpaceRef alternateSpace
)
{
  return [NSGraphicsContext CGColorSpaceCreateICCBased: nComponents
			       : range
			       : profile
			       : alternateSpace];
}

CGColorSpaceRef CGColorSpaceCreateIndexed(
  CGColorSpaceRef baseSpace,
  size_t lastIndex,
  const /*UInt8*/ unsigned short int *colorTable
)
{
  return [NSGraphicsContext CGColorSpaceCreateIndexed: baseSpace
			       : lastIndex
			       : colorTable];
}

size_t CGColorSpaceGetNumberOfComponents(CGColorSpaceRef cs)
{
  return [NSGraphicsContext CGColorSpaceGetNumberOfComponents: cs];
}

CGColorSpaceRef CGColorSpaceRetain(CGColorSpaceRef cs)
{
  return [NSGraphicsContext CGColorSpaceRetain: cs];
}

void CGColorSpaceRelease(CGColorSpaceRef cs)
{
  [NSGraphicsContext CGColorSpaceRelease: cs];
}

void CGContextSetFillColorSpace(CGContextRef ctx, CGColorSpaceRef colorspace)
{
  [(NSGraphicsContext *)ctx GSSetFillColorspace: colorspace];
}

void CGContextSetStrokeColorSpace(CGContextRef ctx, CGColorSpaceRef colorspace)
{
  [(NSGraphicsContext *)ctx GSSetStrokeColorspace: colorspace];
}


void CGContextSetRenderingIntent(CGContextRef c, CGColorRenderingIntent intent)
{
  //FIXME
}


/* Setting Colors */

void CGContextSetFillColor(CGContextRef ctx, const float *value)
{
  [(NSGraphicsContext *)ctx GSSetFillColor: value];
}

void CGContextSetStrokeColor(CGContextRef ctx, const float *value)
{
  [(NSGraphicsContext *)ctx GSSetStrokeColor: value];
}

void CGContextSetGrayFillColor(CGContextRef ctx, float gray, float alpha)
{
  float values[2];
  values[0] = gray;
  values[1] = alpha;
  CGContextSetFillColor(ctx, CGColorSpaceCreateDeviceGray());
  return CGContextSetFillColor(ctx, values);
}

void CGContextSetGrayStrokeColor(CGContextRef ctx, float gray, float alpha)
{
  float values[2];
  values[0] = gray;
  values[1] = alpha;
  CGContextSetStrokeColor(ctx, CGColorSpaceCreateDeviceGray());
  return CGContextSetStrokeColor(ctx, values);
}

void CGContextSetRGBFillColor(
    CGContextRef ctx,
    float r,
    float g,
    float b,
    float alpha
)
{
  float values[4];
  values[0] = r; values[1] = g; values[2] = b;
  values[3] = alpha;
  CGContextSetFillColor(ctx, CGColorSpaceCreateDeviceRGB());
  return CGContextSetFillColor(ctx, values);
}

void CGContextSetRGBStrokeColor(
  CGContextRef ctx,
  float r,
  float g,
  float b,
  float alpha
)
{
  float values[4];
  values[0] = r; values[1] = g; values[2] = b;
  values[3] = alpha;
  CGContextSetStrokeColor(ctx, CGColorSpaceCreateDeviceRGB());
  return CGContextSetStrokeColor(ctx, values);
}

void CGContextSetCMYKFillColor(
  CGContextRef ctx,
  float c,
  float m,
  float y,
  float k,
  float alpha
)
{
  float values[5];
  values[0] = c; values[1] = m; values[2] = y; values[3] = k;
  values[4] = alpha;
  CGContextSetFillColor(ctx, CGColorSpaceCreateDeviceCMYK());
  return CGContextSetFillColor(ctx, values);
}

void CGContextSetCMYKStrokeColor(
  CGContextRef ctx,
  float c,
  float m,
  float y,
  float k,
  float alpha
)
{
  float values[5];
  values[0] = c; values[1] = m; values[2] = y; values[3] = k;
  values[4] = alpha;
  CGContextSetStrokeColor(ctx, CGColorSpaceCreateDeviceCMYK());
  return CGContextSetStrokeColor(ctx, values);
}

void CGContextSetAlpha(CGContextRef ctx, float alpha)
{
  [(NSGraphicsContext *)ctx DPSsetalpha: alpha];
}

/* Drawing Images */

CGImageRef CGImageCreate(
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bitsPerPixel,
  size_t bytesPerRow,
  CGColorSpaceRef colorspace,
  CGImageAlphaInfo alphaInfo,
  CGDataProviderRef provider,
  const float *decode,
  int shouldInterpolate,
  CGColorRenderingIntent intent
)
{
  return NULL;
}

CGImageRef CGImageMaskCreate(
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bitsPerPixel,
  size_t bytesPerRow,
  CGDataProviderRef provider,
  const float *decode,
  int shouldInterpolate
)
{
  return NULL;
}

CGImageRef CGImageRetain(CGImageRef image)
{
  return NULL;
}

void CGImageRelease(CGImageRef image)
{
}

int CGImageIsMask(CGImageRef image)
{
  return 0;
}

size_t CGImageGetWidth(CGImageRef image)
{
  return 0;
}

size_t CGImageGetHeight(CGImageRef image)
{
  return 0;
}

size_t CGImageGetBitsPerComponent(CGImageRef image)
{
  return 0;
}

size_t CGImageGetBitsPerPixel(CGImageRef image)
{
  return 0;
}

size_t CGImageGetBytesPerRow(CGImageRef image)
{
  return 0;
}

CGColorSpaceRef CGImageGetColorSpace(CGImageRef image)
{
  return NULL;
}

CGImageAlphaInfo CGImageGetAlphaInfo(CGImageRef image)
{
  return 0;
}

CGDataProviderRef CGImageGetDataProvider(CGImageRef image)
{
  return NULL;
}

const float *CGImageGetDecode(CGImageRef image)
{
  return NULL;
}

int CGImageGetShouldInterpolate(CGImageRef image)
{
  return 0;
}

CGColorRenderingIntent CGImageGetRenderingIntent(CGImageRef image)
{
  return 0;
}

void CGContextDrawImage(CGContextRef ctx, CGRect rect, CGImageRef image)
{
}

/* Drawing PDF Documents */

CGPDFDocumentRef CGPDFDocumentCreateWithProvider(CGDataProviderRef provider)
{
  return NULL;
}

/* CGPDFDocumentRef CGPDFDocumentCreateWithURL(CFURLRef url) */

CGPDFDocumentRef CGPDFDocumentRetain(CGPDFDocumentRef document)
{
  return NULL;
}

void CGPDFDocumentRelease(CGPDFDocumentRef document)
{
}

int CGPDFDocumentGetNumberOfPages(CGPDFDocumentRef document)
{
  return 0;
}

CGRect CGPDFDocumentGetMediaBox(CGPDFDocumentRef document, int page)
{
  return CGRectMake(0, 0, 0, 0);
}

CGRect CGPDFDocumentGetCropBox(CGPDFDocumentRef document, int page)
{
  return CGRectMake(0, 0, 0, 0);
}

CGRect CGPDFDocumentGetBleedBox(CGPDFDocumentRef document, int page)
{
  return CGRectMake(0, 0, 0, 0);
}

CGRect CGPDFDocumentGetTrimBox(CGPDFDocumentRef document, int page)
{
  return CGRectMake(0, 0, 0, 0);
}

CGRect CGPDFDocumentGetArtBox(CGPDFDocumentRef document, int page)
{
  return CGRectMake(0, 0, 0, 0);
}

int CGPDFDocumentGetRotationAngle(CGPDFDocumentRef document, int page)
{
  return 0;
}

void CGContextDrawPDFDocument(
  CGContextRef ctx,
  CGRect rect,
  CGPDFDocumentRef document,
  int page
)
{
}

/* Drawing Text */

CGFontRef CGFontCreateWithPlatformFont(void *platformFontReference)
{
  return NULL;
}

void CGContextSelectFont(
  CGContextRef ctx,
  const char *name,
  float size,
  CGTextEncoding textEncoding
)
{
}

void CGContextSetFont(CGContextRef ctx, CGFontRef font)
{
  [(NSGraphicsContext *)ctx GSSetFont: font];
}

void CGContextSetFontSize(CGContextRef ctx, float size)
{
}

CGFontRef CGFontRetain(CGFontRef font)
{
  return [NSGraphicsContext CGFontRetain: font];
}

void CGFontRelease(CGFontRef font)
{
  [NSGraphicsContext CGFontRelease: font];
}

void CGContextSetCharacterSpacing(CGContextRef ctx, float spacing)
{
}

void CGContextSetTextDrawingMode(CGContextRef ctx, CGTextDrawingMode mode)
{
}

void CGContextSetTextPosition(CGContextRef ctx, float x, float y)
{
}

CGPoint CGContextGetTextPosition(CGContextRef ctx)
{
  //return [(NSGraphicsContext *)ctx GSGetTextPosition];
  return CGPointZero;
}

void CGContextSetTextMatrix(CGContextRef ctx, CGAffineTransform transform)
{
}

CGAffineTransform CGContextGetTextMatrix(CGContextRef ctx)
{
  //return [(NSGraphicsContext *)ctx GSGetTextCTM] transformStruct];
  return CGAffineTransformIdentity;
}

void CGContextShowText(CGContextRef ctx, const char *cstring, size_t length)
{
}

void CGContextShowGlyphs(CGContextRef ctx, const CGGlyph *g, size_t count)
{
}

void CGContextShowTextAtPoint(
  CGContextRef ctx,
  float x,
  float y,
  const char *cstring,
  size_t length
)
{
}

void CGContextShowGlyphsAtPoint(
  CGContextRef ctx,
  float x,
  float y,
  const CGGlyph *g,
  size_t count
)
{
}

/* Passing Data */

CGDataConsumerRef CGDataConsumerCreate(
  void *info,
  const CGDataConsumerCallbacks *callbacks
)
{
  return NULL;
}

/* CGDataConsumerRef CGDataConsumerCreateWithURL(CFURLRef url) */

CGDataConsumerRef CGDataConsumerRetain(CGDataConsumerRef consumer)
{
  return NULL;
}

void CGDataConsumerRelease(CGDataConsumerRef consumer)
{
}

CGDataProviderRef CGDataProviderCreate(
  void *info,
  const CGDataProviderCallbacks *callbacks
)
{
  return NULL;
}

CGDataProviderRef CGDataProviderCreateDirectAccess(
  void *info,
  size_t size,
  const CGDataProviderDirectAccessCallbacks *callbacks
)
{
  return NULL;
}

CGDataProviderRef CGDataProviderCreateWithData(
  void *info,
  const void *data,
  size_t size,
  int releaseData
)
{
  return NULL;
}

/* CGDataProviderRef CGDataProviderCreateWithURL(CFURLRef url) */

CGDataProviderRef CGDataProviderRetain(CGDataProviderRef provider)
{
  return NULL;
}

void CGDataProviderRelease(CGDataProviderRef provider)
{
}

/* Modifying Geometric Forms */

CGPoint CGPointMake(float x, float y)
{
  return CGPointZero;
}

CGSize CGSizeMake(float width, float height)
{
  return CGSizeZero;
}

CGRect CGRectMake(
  float x,
  float y,
  float width,
  float height
)
{
  return CGRectZero;
}

CGRect CGRectStandardize(CGRect rect)
{
  return CGRectZero;
}

CGRect CGRectInset(CGRect rect, float dx, float dy)
{
  return CGRectZero;
}

CGRect CGRectOffset(CGRect rect, float dx, float dy)
{
  return CGRectZero;
}

CGRect CGRectIntegral(CGRect rect)
{
  return CGRectZero;
}

CGRect CGRectUnion(CGRect r1, CGRect r2)
{
  return CGRectZero;
}

CGRect CGRectIntersection(CGRect r1, CGRect r2)
{
  return CGRectZero;
}

void CGRectDivide(
  CGRect rect,
  CGRect *slice,
  CGRect *remainder,
  float amount,
  CGRectEdge edge
)
{
}

/* Accessing Geometric Attributes */

float CGRectGetMinX(CGRect rect)
{
  return 0;
}

float CGRectGetMidX(CGRect rect)
{
  return 0;
}

float CGRectGetMaxX(CGRect rect)
{
  return 0;
}

float CGRectGetMinY(CGRect rect)
{
  return 0;
}

float CGRectGetMidY(CGRect rect)
{
  return 0;
}

float CGRectGetMaxY(CGRect rect)
{
  return 0;
}

float CGRectGetWidth(CGRect rect)
{
  return 0;
}

float CGRectGetHeight(CGRect rect)
{
  return 0;
}

int CGRectIsNull(CGRect rect)
{
  return 0;
}

int CGRectIsEmpty(CGRect rect)
{
  return 0;
}

int CGRectIntersectsRect(CGRect rect1, CGRect rect2)
{
  return 0;
}

int CGRectContainsRect(CGRect rect1, CGRect rect2)
{
  return 0;
}

int CGRectContainsPoint(CGRect rect, CGPoint point)
{
  return 0;
}

int CGRectEqualToRect(CGRect rect1, CGRect rect2)
{
  return 0;
}

int CGSizeEqualToSize(CGSize size1, CGSize size2)
{
  return 0;
}

int CGPointEqualToPoint(CGPoint point1, CGPoint point2)
{
  return 0;
}

/* Affine Transform Utility Functions */

CGAffineTransform CGAffineTransformMake(
  float a,
  float b,
  float c,
  float d,
  float tx,
  float ty
)
{
  return CGAffineTransformIdentity;
}

CGAffineTransform CGAffineTransformMakeTranslation(float tx, float ty)
{
  return CGAffineTransformIdentity;
}

CGAffineTransform CGAffineTransformMakeScale(float sx, float sy)
{
  return CGAffineTransformIdentity;
}

CGAffineTransform CGAffineTransformMakeRotation(float angle)
{
  return CGAffineTransformIdentity;
}

CGAffineTransform CGAffineTransformTranslate(
  CGAffineTransform t,
  float tx,
  float ty
)
{
  return CGAffineTransformIdentity;
}

CGAffineTransform CGAffineTransformScale(
  CGAffineTransform t,
  float sx,
  float sy
)
{
  return CGAffineTransformIdentity;
}

CGAffineTransform CGAffineTransformRotate(CGAffineTransform t, float angle)
{
  return CGAffineTransformIdentity;
}

CGAffineTransform CGAffineTransformInvert(CGAffineTransform t)
{
  return CGAffineTransformIdentity;
}

CGAffineTransform CGAffineTransformConcat(
  CGAffineTransform t1,
  CGAffineTransform t2
)
{
  return CGAffineTransformIdentity;
}

CGPoint CGPointApplyAffineTransform(CGPoint point, CGAffineTransform t)
{
  return point;
}

CGSize CGSizeApplyAffineTransform(CGSize size, CGAffineTransform t)
{
  return size;
}
