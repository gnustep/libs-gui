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

#ifndef _GSFusedSilica_h_INCLUDE
#define _GSFusedSilica_h_INCLUDE

#include <unistd.h>

/* ------------------------------------------------------------------------
 * Data Types
 * ------------------------------------------------------------------------*/

typedef struct CGAffineTransform
{
  float a;
  float b;
  float c;
  float d;
  float tx;
  float ty;
} CGAffineTransform;

typedef struct CGPoint
{
  float x;
  float y;
} CGPoint;

typedef struct CGSize
{
  float width;
  float height;
} CGSize;

typedef struct CGRect
{
  CGPoint origin;
  CGSize size;
} CGRect;

typedef void * CGColorSpaceRef;

typedef void * CGContextRef;

typedef void * CGFontRef;

typedef /*UInt16*/ unsigned int CGGlyph;

typedef void * CGImageRef;

typedef void * CGPatternRef;

typedef void * CGPDFDocumentRef;

typedef void * CGDataConsumerRef;

/* ------------------------------------------------------------------------
 * Constants
 * ---------------------------------------------------------------------- */

static const CGAffineTransform CGAffineTransformIdentity = {1,0,0,1,0,0};

typedef enum CGColorRenderingIntent
{
  kCGRenderingIntentDefault = 0,
  kCGRenderingIntentAbsoluteColorimetric = 1,
  kCGRenderingIntentRelativeColorimetric = 2,
  kCGRenderingIntentPerceptual = 3,
  kCGRenderingIntentSaturation = 4
} CGColorRenderingIntent;

typedef enum CGImageAlphaInfo
{
  kCGImageAlphaNone = 0,
  kCGImageAlphaPremultipliedLast = 1,
  kCGImageAlphaPremultipliedFirst = 2,
  kCGImageAlphaLast = 3,
  kCGImageAlphaFirst = 4,
  kCGImageAlphaNoneSkipLast = 5,
  kCGImageAlphaNoneSkipFirst = 6
} CGImageAlphaInfo;

typedef enum CGInterpolationQuality
{
  kCGInterpolationDefault = 0,
  kCGInterpolationNone = 1,
  kCGInterpolationLow = 2,
  kCGInterpolationHigh = 3
} CGInterpolationQuality;

typedef enum CGLineCap
{
  kCGLineCapButt = 0,
  kCGLineCapRound = 1,
  kCGLineCapSquare = 2
} CGLineCap;

typedef enum CGLineJoin
{
  kCGLineJoinMiter = 0,
  kCGLineJoinRound = 1,
  kCGLineJoinBevel = 2
} CGLineJoin;

typedef enum CGPathDrawingMode
{
  kCGPathFill = 0,
  kCGPathEOFill = 1,
  kCGPathStroke = 2,
  kCGPathFillStroke = 3,
  kCGPathEOFillStroke = 4
} CGPathDrawingMode;

static const CGPoint CGPointZero = {0,0};

typedef enum CGRectEdge
{
  CGRectMinXEdge = 0,
  CGRectMinYEdge = 1,
  CGRectMaxXEdge = 2,
  CGRectMaxYEdge = 3
} CGRectEdge;

static const CGRect CGRectNull = {{-1,-1},{0,0}};  /*FIXME*/

static const CGSize CGSizeZero = {0,0};

static const CGRect CGRectZero = {{0,0},{0,0}};

typedef enum CGTextDrawingMode
{
  kCGTextFill = 0,
  kCGTextStroke = 1,
  kCGTextFillStroke = 2,
  kCGTextInvisible = 3,
  kCGTextFillClip = 4,
  kCGTextStrokeClip = 5,
  kCGTextFillStrokeClip = 6,
  kCGTextClip = 7
} CGTextDrawingMode;

typedef enum CGTextEncoding
{
  kCGEncodingFontSpecific = 0,
  kCGEncodingMacRoman = 1
} CGTextEncoding;

/* ------------------------------------------------------------------------
 * Callbacks
 * ---------------------------------------------------------------------- */

typedef void(*CGGetBytePointerProcPtr)(void *info);

typedef size_t(*CGGetBytesDirectProcPtr)(
  void *info,
  void *buffer,
  size_t offset,
  size_t count
);

typedef size_t(*CGGetBytesProcPtr)(void *info, void *buffer, size_t count);

typedef size_t(*CGPutBytesProcPtr)(
  void *info,
  const void *buffer,
  size_t count
);

typedef void(*CGSkipBytesProcPtr)(void *info, size_t count);

typedef void(*CGReleaseByteProcPtr)(void *info, const void *pointer);

typedef void(*CGReleaseConsumerProcPtr)(void *info);

typedef void(*CGReleaseDataProcPtr)(
  void *info,
  const void *data,
  size_t size
);

typedef void(*CGReleaseProviderProcPtr)(void *info);

typedef void(*CGRewindProcPtr)(void *info);

typedef struct CGDataConsumerCallbacks
{
  CGPutBytesProcPtr putBytes;
  CGReleaseConsumerProcPtr releaseConsumer;
} CGDataConsumerCallbacks;

typedef void * CGDataProviderRef;

typedef struct CGDataProviderCallbacks
{
  CGGetBytesProcPtr getBytes; 
  CGSkipBytesProcPtr skipBytes; 
  CGRewindProcPtr rewind; 
  CGReleaseProviderProcPtr releaseProvider;
} CGDataProviderCallbacks;

typedef struct CGDataProviderDirectAccessCallbacks
{
  CGGetBytePointerProcPtr getBytePointer; 
  CGReleaseByteProcPtr releaseBytePointer; 
  CGGetBytesDirectProcPtr getBytes; 
  CGReleaseProviderProcPtr releaseProvider;
} CGDataProviderDirectAccessCallbacks;

/* ------------------------------------------------------------------------
 * Functions
 * ---------------------------------------------------------------------- */

/* Managing Graphics Contexts */

CGContextRef CGBitmapContextCreate(
  void *data,
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bytesPerRow,
  CGColorSpaceRef colorspace,
  CGImageAlphaInfo alphaInfo
);

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

CGContextRef CGContextRetain(CGContextRef ctx);

void CGContextRelease(CGContextRef ctx);

void CGContextFlush(CGContextRef ctx);

void CGContextSynchronize(CGContextRef ctx);

/* Defining Pages */

void CGContextBeginPage(CGContextRef ctx, const CGRect *mediaBox);

void CGContextEndPage(CGContextRef ctx);

/* Transforming the Coordinate Space of the Page */

void CGContextScaleCTM(CGContextRef ctx, float sx, float sy);

void CGContextTranslateCTM(CGContextRef ctx, float tx, float ty);

void CGContextRotateCTM(CGContextRef ctx, float angle);

void CGContextConcatCTM(CGContextRef ctx, CGAffineTransform transform);

CGAffineTransform CGContextGetCTM(CGContextRef ctx);

/* Saving and Restoring the Graphics State */

void CGContextSaveGState(CGContextRef ctx);

void CGContextRestoreGState(CGContextRef ctx);

/* Setting Graphics State Attributes */

void CGContextSetShouldAntialias(CGContextRef ctx, int shouldAntialias);

void CGContextSetLineWidth(CGContextRef ctx, float width);

void CGContextSetLineJoin(CGContextRef ctx, CGLineJoin join);

void CGContextSetMiterLimit(CGContextRef ctx, float limit);

void CGContextSetLineCap(CGContextRef ctx, CGLineCap cap);

void CGContextSetLineDash(CGContextRef ctx, float phase, const float *lengths, size_t count);

void CGContextSetFlatness(CGContextRef ctx, float flatness);

/* Constructing Paths */

void CGContextBeginPath(CGContextRef ctx);

void CGContextMoveToPoint(CGContextRef ctx, float x, float y);

void CGContextAddLineToPoint(CGContextRef ctx, float x, float y);

void CGContextAddLines(CGContextRef ctx, const CGPoint *points, size_t count);

void CGContextAddCurveToPoint(
  CGContextRef ctx,
  float cp1x,
  float cp1y,
  float cp2x,
  float cp2y,
  float x,
  float y
);

void CGContextAddQuadCurveToPoint(
  CGContextRef ctx,
  float cpx,
  float cpy,
  float x,
  float y
);

void CGContextAddRect(CGContextRef ctx, CGRect rect);

void CGContextAddRects(CGContextRef ctx, const CGRect *rects, size_t count);

void CGContextAddArc(
  CGContextRef ctx,
  float x,
  float y,
  float radius,
  float startAngle,
  float endAngle,
  int clockwise
);

void CGContextAddArcToPoint(
  CGContextRef ctx,
  float x1,
  float y1,
  float x2,
  float y2,
  float radius
);

void CGContextClosePath(CGContextRef ctx);

/* Painting Paths */

void CGContextDrawPath(CGContextRef ctx, CGPathDrawingMode mode);

void CGContextStrokePath(CGContextRef ctx);

void CGContextFillPath(CGContextRef ctx);

void CGContextEOFillPath(CGContextRef ctx);

void CGContextStrokeRect(CGContextRef ctx, CGRect rect);

void CGContextStrokeRectWithWidth(CGContextRef ctx, CGRect rect, float width);

void CGContextFillRect(CGContextRef ctx, CGRect rect);

void CGContextFillRects(CGContextRef ctx, const CGRect *rects, size_t count);

void CGContextClearRect(CGContextRef c, CGRect rect);

/* Obtaining Path Information */

int CGContextIsPathEmpty(CGContextRef ctx);

CGPoint CGContextGetPathCurrentPoint(CGContextRef ctx);

CGRect CGContextGetPathBoundingBox(CGContextRef ctx);

/* Clipping Paths */

void CGContextClip(CGContextRef ctx);

void CGContextEOClip(CGContextRef ctx);

void CGContextClipToRect(CGContextRef ctx, CGRect rect);

void CGContextClipToRects(CGContextRef ctx, const CGRect *rects, size_t count);

/* Setting the Color Space */

CGColorSpaceRef CGColorSpaceCreateDeviceGray(void);

CGColorSpaceRef CGColorSpaceCreateDeviceRGB(void);

CGColorSpaceRef CGColorSpaceCreateDeviceCMYK(void);

CGColorSpaceRef CGColorSpaceCreateCalibratedGray(
  const float *whitePoint,
  const float *blackPoint,
  float gamma
);

CGColorSpaceRef CGColorSpaceCreateCalibratedRGB(
  const float *whitePoint,
  const float *blackPoint,
  const float *gamma,
  const float *matrix
);

CGColorSpaceRef CGColorSpaceCreateLab(
  const float *whitePoint,
  const float *blackPoint,
  const float *range
);

CGColorSpaceRef CGColorSpaceCreateICCBased(
  size_t nComponents,
  const float *range,
  CGDataProviderRef profile,
  CGColorSpaceRef alternateSpace
);

CGColorSpaceRef CGColorSpaceCreateIndexed(
  CGColorSpaceRef baseSpace,
  size_t lastIndex,
  const /*UInt8*/ unsigned short int *colorTable
);

size_t CGColorSpaceGetNumberOfComponents(CGColorSpaceRef cs);

CGColorSpaceRef CGColorSpaceRetain(CGColorSpaceRef cs);

void CGColorSpaceRelease(CGColorSpaceRef cs);

void CGContextSetFillColorSpace(CGContextRef ctx, CGColorSpaceRef colorspace);

void CGContextSetStrokeColorSpace(CGContextRef ctx, CGColorSpaceRef colorspace);

void CGContextSetRenderingIntent(CGContextRef c, CGColorRenderingIntent intent);

/* Setting Colors */

void CGContextSetFillColor(CGContextRef ctx, const float *value);

void CGContextSetStrokeColor(CGContextRef ctx, const float *value);

void CGContextSetGrayFillColor(CGContextRef ctx, float gray, float alpha);

void CGContextSetGrayStrokeColor(CGContextRef ctx, float gray, float alpha);

void CGContextSetRGBFillColor(
    CGContextRef ctx,
    float r,
    float g,
    float b,
    float alpha
);

void CGContextSetRGBStrokeColor(
  CGContextRef ctx,
  float r,
  float g,
  float b,
  float alpha
);

void CGContextSetCMYKFillColor(
  CGContextRef ctx,
  float c,
  float m,
  float y,
  float k,
  float alpha
);

void CGContextSetCMYKStrokeColor(
  CGContextRef ctx,
  float c,
  float m,
  float y,
  float k,
  float alpha
);

void CGContextSetAlpha(CGContextRef ctx, float alpha);

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
);

CGImageRef CGImageMaskCreate(
  size_t width,
  size_t height,
  size_t bitsPerComponent,
  size_t bitsPerPixel,
  size_t bytesPerRow,
  CGDataProviderRef provider,
  const float *decode,
  int shouldInterpolate
);

CGImageRef CGImageRetain(CGImageRef image);

void CGImageRelease(CGImageRef image);

int CGImageIsMask(CGImageRef image);

size_t CGImageGetWidth(CGImageRef image);

size_t CGImageGetHeight(CGImageRef image);

size_t CGImageGetBitsPerComponent(CGImageRef image);

size_t CGImageGetBitsPerPixel(CGImageRef image);

size_t CGImageGetBytesPerRow(CGImageRef image);

CGColorSpaceRef CGImageGetColorSpace(CGImageRef image);

CGImageAlphaInfo CGImageGetAlphaInfo(CGImageRef image);

CGDataProviderRef CGImageGetDataProvider(CGImageRef image);

const float *CGImageGetDecode(CGImageRef image);

int CGImageGetShouldInterpolate(CGImageRef image);

CGColorRenderingIntent CGImageGetRenderingIntent(CGImageRef image);

void CGContextDrawImage(CGContextRef ctx, CGRect rect, CGImageRef image);

/* Drawing PDF Documents */

CGPDFDocumentRef CGPDFDocumentCreateWithProvider(CGDataProviderRef provider);

/* CGPDFDocumentRef CGPDFDocumentCreateWithURL(CFURLRef url); */

CGPDFDocumentRef CGPDFDocumentRetain(CGPDFDocumentRef document);

void CGPDFDocumentRelease(CGPDFDocumentRef document);

int CGPDFDocumentGetNumberOfPages(CGPDFDocumentRef document);

CGRect CGPDFDocumentGetMediaBox(CGPDFDocumentRef document, int page);

CGRect CGPDFDocumentGetCropBox(CGPDFDocumentRef document, int page);

CGRect CGPDFDocumentGetBleedBox(CGPDFDocumentRef document, int page);

CGRect CGPDFDocumentGetTrimBox(CGPDFDocumentRef document, int page);

CGRect CGPDFDocumentGetArtBox(CGPDFDocumentRef document, int page);

int CGPDFDocumentGetRotationAngle(CGPDFDocumentRef document, int page);

void CGContextDrawPDFDocument(
  CGContextRef ctx,
  CGRect rect,
  CGPDFDocumentRef document,
  int page
);

/* Drawing Text */

CGFontRef CGFontCreateWithPlatformFont(void *platformFontReference);

void CGContextSelectFont(
  CGContextRef ctx,
  const char *name,
  float size,
  CGTextEncoding textEncoding
);

void CGContextSetFont(CGContextRef ctx, CGFontRef font);

void CGContextSetFontSize(CGContextRef ctx, float size);

CGFontRef CGFontRetain(CGFontRef font);

void CGFontRelease(CGFontRef font);

void CGContextSetCharacterSpacing(CGContextRef ctx, float spacing);

void CGContextSetTextDrawingMode(CGContextRef ctx, CGTextDrawingMode mode);

void CGContextSetTextPosition(CGContextRef ctx, float x, float y);

CGPoint CGContextGetTextPosition(CGContextRef ctx);

void CGContextSetTextMatrix(CGContextRef ctx, CGAffineTransform transform);

CGAffineTransform CGContextGetTextMatrix(CGContextRef ctx);

void CGContextShowText(CGContextRef ctx, const char *cstring, size_t length);

void CGContextShowGlyphs(CGContextRef ctx, const CGGlyph *g, size_t count);

void CGContextShowTextAtPoint(
  CGContextRef ctx,
  float x,
  float y,
  const char *cstring,
  size_t length
);

void CGContextShowGlyphsAtPoint(
  CGContextRef ctx,
  float x,
  float y,
  const CGGlyph *g,
  size_t count
);

/* Passing Data */

CGDataConsumerRef CGDataConsumerCreate(
  void *info,
  const CGDataConsumerCallbacks *callbacks
);

/* CGDataConsumerRef CGDataConsumerCreateWithURL(CFURLRef url); */

CGDataConsumerRef CGDataConsumerRetain(CGDataConsumerRef consumer);

void CGDataConsumerRelease(CGDataConsumerRef consumer);

CGDataProviderRef CGDataProviderCreate(
  void *info,
  const CGDataProviderCallbacks *callbacks
);

CGDataProviderRef CGDataProviderCreateDirectAccess(
  void *info,
  size_t size,
  const CGDataProviderDirectAccessCallbacks *callbacks
);

CGDataProviderRef CGDataProviderCreateWithData(
  void *info,
  const void *data,
  size_t size,
  int releaseData
);

/* CGDataProviderRef CGDataProviderCreateWithURL(CFURLRef url); */

CGDataProviderRef CGDataProviderRetain(CGDataProviderRef provider);

void CGDataProviderRelease(CGDataProviderRef provider);

/* Modifying Geometric Forms */

CGPoint CGPointMake(float x, float y);

CGSize CGSizeMake(float width, float height);

CGRect CGRectMake(
  float x,
  float y,
  float width,
  float height
);

CGRect CGRectStandardize(CGRect rect);

CGRect CGRectInset(CGRect rect, float dx, float dy);

CGRect CGRectOffset(CGRect rect, float dx, float dy);

CGRect CGRectIntegral(CGRect rect);

CGRect CGRectUnion(CGRect r1, CGRect r2);

CGRect CGRectIntersection(CGRect r1, CGRect r2);

void CGRectDivide(
  CGRect rect,
  CGRect *slice,
  CGRect *remainder,
  float amount,
  CGRectEdge edge
);

/* Accessing Geometric Attributes */

float CGRectGetMinX(CGRect rect);

float CGRectGetMidX(CGRect rect);

float CGRectGetMaxX(CGRect rect);

float CGRectGetMinY(CGRect rect);

float CGRectGetMidY(CGRect rect);

float CGRectGetMaxY(CGRect rect);

float CGRectGetWidth(CGRect rect);

float CGRectGetHeight(CGRect rect);

int CGRectIsNull(CGRect rect);

int CGRectIsEmpty(CGRect rect);

int CGRectIntersectsRect(CGRect rect1, CGRect rect2);

int CGRectContainsRect(CGRect rect1, CGRect rect2);

int CGRectContainsPoint(CGRect rect, CGPoint point);

int CGRectEqualToRect(CGRect rect1, CGRect rect2);

int CGSizeEqualToSize(CGSize size1, CGSize size2);

int CGPointEqualToPoint(CGPoint point1, CGPoint point2);

/* Affine Transform Utility Functions */

CGAffineTransform CGAffineTransformMake(
  float a,
  float b,
  float c,
  float d,
  float tx,
  float ty
);

CGAffineTransform CGAffineTransformMakeTranslation(float tx, float ty);

CGAffineTransform CGAffineTransformMakeScale(float sx, float sy);

CGAffineTransform CGAffineTransformMakeRotation(float angle);

CGAffineTransform CGAffineTransformTranslate(
  CGAffineTransform t,
  float tx,
  float ty
);

CGAffineTransform CGAffineTransformScale(
  CGAffineTransform t,
  float sx,
  float sy
);

CGAffineTransform CGAffineTransformRotate(CGAffineTransform t, float angle);

CGAffineTransform CGAffineTransformInvert(CGAffineTransform t);

CGAffineTransform CGAffineTransformConcat(
  CGAffineTransform t1,
  CGAffineTransform t2
);

CGPoint CGPointApplyAffineTransform(CGPoint point, CGAffineTransform t);

CGSize CGSizeApplyAffineTransform(CGSize size, CGAffineTransform t);

#endif
