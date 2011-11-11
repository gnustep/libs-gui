/** <title>CGContext</title>

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

#ifndef OPAL_CGContext_h
#define OPAL_CGContext_h

/* Data Types */

#ifdef __OBJC__
@class CGContext;
typedef CGContext* CGContextRef;
#else
typedef struct CGContext* CGContextRef;
#endif

#include <CoreGraphics/CGAffineTransform.h>
#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGBitmapContext.h>
#include <CoreGraphics/CGColor.h>
#include <CoreGraphics/CGFont.h>
#include <CoreGraphics/CGImage.h>
#include <CoreGraphics/CGPath.h>
#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGPDFDocument.h>
#include <CoreGraphics/CGPDFPage.h>
#include <CoreGraphics/CGGradient.h>
#include <CoreGraphics/CGShading.h>

/* Constants */

typedef enum CGBlendMode {
  kCGBlendModeNormal = 0,
  kCGBlendModeMultiply = 1,
  kCGBlendModeScreen = 2,
  kCGBlendModeOverlay = 3,
  kCGBlendModeDarken = 4,
  kCGBlendModeLighten = 5,
  kCGBlendModeColorDodge = 6,
  kCGBlendModeColorBurn = 7,
  kCGBlendModeSoftLight = 8,
  kCGBlendModeHardLight = 9,
  kCGBlendModeDifference = 10,
  kCGBlendModeExclusion = 11,
  kCGBlendModeHue = 12,
  kCGBlendModeSaturation = 13,
  kCGBlendModeColor = 14,
  kCGBlendModeLuminosity = 15,
  kCGBlendModeClear = 16,
  kCGBlendModeCopy = 17,
  kCGBlendModeSourceIn = 18,
  kCGBlendModeSourceOut = 19,
  kCGBlendModeSourceAtop = 20,
  kCGBlendModeDestinationOver = 21,
  kCGBlendModeDestinationIn = 22,
  kCGBlendModeDestinationOut = 23,
  kCGBlendModeDestinationAtop = 24,
  kCGBlendModeXOR = 25,
  kCGBlendModePlusDarker = 26,
  kCGBlendModePlusLighter = 27
} CGBlendMode;

typedef enum CGInterpolationQuality {
  kCGInterpolationDefault = 0,
  kCGInterpolationNone = 1,
  kCGInterpolationLow = 2,
  kCGInterpolationMedium = 4,
  kCGInterpolationHigh = 3
} CGInterpolationQuality;

typedef enum CGLineCap {
  kCGLineCapButt = 0,
  kCGLineCapRound = 1,
  kCGLineCapSquare = 2
} CGLineCap;

typedef enum CGLineJoin {
  kCGLineJoinMiter = 0,
  kCGLineJoinRound = 1,
  kCGLineJoinBevel = 2
} CGLineJoin;

typedef enum CGPathDrawingMode {
  kCGPathFill = 0,
  kCGPathEOFill = 1,
  kCGPathStroke = 2,
  kCGPathFillStroke = 3,
  kCGPathEOFillStroke = 4
} CGPathDrawingMode;

typedef enum CGTextDrawingMode {
  kCGTextFill = 0,
  kCGTextStroke = 1,
  kCGTextFillStroke = 2,
  kCGTextInvisible = 3,
  kCGTextFillClip = 4,
  kCGTextStrokeClip = 5,
  kCGTextFillStrokeClip = 6,
  kCGTextClip = 7
} CGTextDrawingMode;

typedef enum CGTextEncoding {
  kCGEncodingFontSpecific = 0,
  kCGEncodingMacRoman = 1
} CGTextEncoding;

/* Functions */

/* Managing Graphics Contexts */

CFTypeID CGContextGetTypeID();

CGContextRef CGContextRetain(CGContextRef ctx);

void CGContextRelease(CGContextRef ctx);

void CGContextFlush(CGContextRef ctx);

void CGContextSynchronize(CGContextRef ctx);

/* Defining Pages */

void CGContextBeginPage(CGContextRef ctx, const CGRect *mediaBox);

void CGContextEndPage(CGContextRef ctx);

/* Transforming the Coordinate Space of the Page */

void CGContextScaleCTM(CGContextRef ctx, CGFloat sx, CGFloat sy);

void CGContextTranslateCTM(CGContextRef ctx, CGFloat tx, CGFloat ty);

void CGContextRotateCTM(CGContextRef ctx, CGFloat angle);

void CGContextConcatCTM(CGContextRef ctx, CGAffineTransform transform);

CGAffineTransform CGContextGetCTM(CGContextRef ctx);

/* Saving and Restoring the Graphics State */

void CGContextSaveGState(CGContextRef ctx);

void CGContextRestoreGState(CGContextRef ctx);

/* Setting Graphics State Attributes */

void CGContextSetShouldAntialias(CGContextRef ctx, int shouldAntialias);

void CGContextSetLineWidth(CGContextRef ctx, CGFloat width);

void CGContextSetLineJoin(CGContextRef ctx, CGLineJoin join);

void CGContextSetMiterLimit(CGContextRef ctx, CGFloat limit);

void CGContextSetLineCap(CGContextRef ctx, CGLineCap cap);

void CGContextSetLineDash(
  CGContextRef ctx,
  CGFloat phase,
  const CGFloat lengths[],
  size_t count
);

void CGContextSetFlatness(CGContextRef ctx, CGFloat flatness);

CGInterpolationQuality CGContextGetInterpolationQuality(CGContextRef ctx);

void CGContextSetInterpolationQuality(
  CGContextRef ctx,
  CGInterpolationQuality quality
);

void CGContextSetPatternPhase (CGContextRef ctx, CGSize phase);

void CGContextSetFillPattern(
  CGContextRef ctx,
  CGPatternRef pattern,
  const CGFloat components[]
);

void CGContextSetStrokePattern(
  CGContextRef ctx,
  CGPatternRef pattern,
  const CGFloat components[]
);

void CGContextSetShouldSmoothFonts(CGContextRef ctx, int shouldSmoothFonts);

void CGContextSetAllowsFontSmoothing(CGContextRef ctx, bool allowsFontSmoothing);

void CGContextSetBlendMode(CGContextRef ctx, CGBlendMode mode);

void CGContextSetAllowsAntialiasing(CGContextRef ctx, int allowsAntialiasing);

void CGContextSetShouldSubpixelPositionFonts(
  CGContextRef ctx,
  bool shouldSubpixelPositionFonts
);

void CGContextSetAllowsFontSubpixelPositioning(
  CGContextRef ctx,
  bool allowsFontSubpixelPositioning
);

void CGContextSetShouldSubpixelQuantizeFonts(
  CGContextRef ctx,
  bool shouldSubpixelQuantizeFonts
);

void CGContextSetAllowsFontSubpixelQuantization(
  CGContextRef ctx,
  bool allowsFontSubpixelQuantization
);

void CGContextSetShadow(
  CGContextRef ctx,
  CGSize offset,
  CGFloat radius
);

void CGContextSetShadowWithColor(
  CGContextRef ctx,
  CGSize offset,
  CGFloat radius,
  CGColorRef color
);

/* Constructing Paths */

void CGContextBeginPath(CGContextRef ctx);

void CGContextClosePath(CGContextRef ctx);

void CGContextMoveToPoint(CGContextRef ctx, CGFloat x, CGFloat y);

void CGContextAddLineToPoint(CGContextRef ctx, CGFloat x, CGFloat y);

void CGContextAddLines(CGContextRef ctx, const CGPoint points[], size_t count);

void CGContextAddCurveToPoint(
  CGContextRef ctx,
  CGFloat cp1x,
  CGFloat cp1y,
  CGFloat cp2x,
  CGFloat cp2y,
  CGFloat x,
  CGFloat y
);

void CGContextAddQuadCurveToPoint(
  CGContextRef ctx,
  CGFloat cpx,
  CGFloat cpy,
  CGFloat x,
  CGFloat y
);

void CGContextAddRect(CGContextRef ctx, CGRect rect);

void CGContextAddRects(CGContextRef ctx, const CGRect rects[], size_t count);

void CGContextAddArc(
  CGContextRef ctx,
  CGFloat x,
  CGFloat y,
  CGFloat radius,
  CGFloat startAngle,
  CGFloat endAngle,
  int clockwise
);

void CGContextAddArcToPoint(
  CGContextRef ctx,
  CGFloat x1,
  CGFloat y1,
  CGFloat x2,
  CGFloat y2,
  CGFloat radius
);

void CGContextAddPath(CGContextRef ctx, CGPathRef path);

void CGContextAddEllipseInRect(CGContextRef ctx, CGRect rect);

/* Creating Stroked Paths */

void CGContextReplacePathWithStrokedPath(CGContextRef ctx);

/* Painting Paths */

void CGContextStrokePath(CGContextRef ctx);

void CGContextFillPath(CGContextRef ctx);

void CGContextEOFillPath(CGContextRef ctx);

void CGContextDrawPath(CGContextRef ctx, CGPathDrawingMode mode);

void CGContextStrokeRect(CGContextRef ctx, CGRect rect);

void CGContextStrokeRectWithWidth(CGContextRef ctx, CGRect rect, CGFloat width);

void CGContextFillRect(CGContextRef ctx, CGRect rect);

void CGContextFillRects(CGContextRef ctx, const CGRect rects[], size_t count);

void CGContextClearRect(CGContextRef ctx, CGRect rect);

void CGContextFillEllipseInRect(CGContextRef ctx, CGRect rect);

void CGContextStrokeEllipseInRect(CGContextRef ctx, CGRect rect);

void CGContextStrokeLineSegments(
  CGContextRef ctx,
  const CGPoint points[],
  size_t count
);

/* Obtaining Path Information */

bool CGContextIsPathEmpty(CGContextRef ctx);

CGPoint CGContextGetPathCurrentPoint(CGContextRef ctx);

CGRect CGContextGetPathBoundingBox(CGContextRef ctx);

CGPathRef CGContextCopyPath(CGContextRef context);

/* Clipping Paths */

void CGContextClip(CGContextRef ctx);

void CGContextEOClip(CGContextRef ctx);

void CGContextClipToRect(CGContextRef ctx, CGRect rect);

void CGContextClipToRects(CGContextRef ctx, const CGRect rects[], size_t count);

void CGContextClipToMask(CGContextRef ctx, CGRect rect, CGImageRef mask);

CGRect CGContextGetClipBoundingBox(CGContextRef ctx);

/* Setting the Color Space and Colors */

void CGContextSetFillColorWithColor(CGContextRef ctx, CGColorRef color);

void CGContextSetStrokeColorWithColor(CGContextRef ctx, CGColorRef color);

void CGContextSetAlpha(CGContextRef ctx, CGFloat alpha);

void CGContextSetFillColorSpace(CGContextRef ctx, CGColorSpaceRef colorspace);

void CGContextSetStrokeColorSpace(CGContextRef ctx, CGColorSpaceRef colorspace);

void CGContextSetFillColor(CGContextRef ctx, const CGFloat components[]);

void CGContextSetStrokeColor(CGContextRef ctx, const CGFloat components[]);

void CGContextSetGrayFillColor(CGContextRef ctx, CGFloat gray, CGFloat alpha);

void CGContextSetGrayStrokeColor(CGContextRef ctx, CGFloat gray, CGFloat alpha);

void CGContextSetRGBFillColor(
  CGContextRef ctx,
  CGFloat r,
  CGFloat g,
  CGFloat b,
  CGFloat alpha
);

void CGContextSetRGBStrokeColor(
  CGContextRef ctx,
  CGFloat r,
  CGFloat g,
  CGFloat b,
  CGFloat alpha
);

void CGContextSetCMYKFillColor(
  CGContextRef ctx,
  CGFloat c,
  CGFloat m,
  CGFloat y,
  CGFloat k,
  CGFloat alpha
);

void CGContextSetCMYKStrokeColor(
  CGContextRef ctx,
  CGFloat c,
  CGFloat m,
  CGFloat y,
  CGFloat k,
  CGFloat alpha
);

void CGContextSetRenderingIntent(CGContextRef ctx, CGColorRenderingIntent intent);

/* Drawing Images */

void CGContextDrawImage(CGContextRef ctx, CGRect rect, CGImageRef image);

void CGContextDrawTiledImage(CGContextRef ctx, CGRect rect, CGImageRef image);

/* Drawing PDF Documents */

void CGContextDrawPDFDocument(
  CGContextRef ctx,
  CGRect rect,
  CGPDFDocumentRef document,
  int page
);

void CGContextDrawPDFPage(CGContextRef ctx, CGPDFPageRef page);

/* Drawing Gradients */

void CGContextDrawLinearGradient(
  CGContextRef ctx,
  CGGradientRef gradient,
  CGPoint startPoint,
  CGPoint endPoint,
  CGGradientDrawingOptions options
);

void CGContextDrawRadialGradient(
  CGContextRef ctx,
  CGGradientRef gradient,
  CGPoint startCenter,
  CGFloat startRadius,
  CGPoint endCenter,
  CGFloat endRadius,
  CGGradientDrawingOptions options
);

void CGContextDrawShading(
  CGContextRef ctx,
  CGShadingRef shading
);

/* Drawing Text */

void CGContextSetFont(CGContextRef ctx, CGFontRef font);

void CGContextSetFontSize(CGContextRef ctx, CGFloat size);

void CGContextSelectFont(
  CGContextRef ctx,
  const char *name,
  CGFloat size,
  CGTextEncoding textEncoding
);

void CGContextSetCharacterSpacing(CGContextRef ctx, CGFloat spacing);

void CGContextSetTextDrawingMode(CGContextRef ctx, CGTextDrawingMode mode);

void CGContextSetTextPosition(CGContextRef ctx, CGFloat x, CGFloat y);

CGPoint CGContextGetTextPosition(CGContextRef ctx);

void CGContextSetTextMatrix(CGContextRef ctx, CGAffineTransform transform);

CGAffineTransform CGContextGetTextMatrix(CGContextRef ctx);

void CGContextShowText(CGContextRef ctx, const char *cstring, size_t length);

void CGContextShowTextAtPoint(
  CGContextRef ctx,
  CGFloat x,
  CGFloat y,
  const char *cstring,
  size_t length
);

void CGContextShowGlyphs(CGContextRef ctx, const CGGlyph *g, size_t count);

void CGContextShowGlyphsAtPoint(
  CGContextRef ctx,
  CGFloat x,
  CGFloat y,
  const CGGlyph *g,
  size_t count
);

void CGContextShowGlyphsAtPositions(
  CGContextRef context,
  const CGGlyph glyphs[],
  const CGPoint positions[],
  size_t count
);

void CGContextShowGlyphsWithAdvances (
  CGContextRef c,
  const CGGlyph glyphs[],
  const CGSize advances[],
  size_t count
);

/* Transparency Layers */

void CGContextBeginTransparencyLayer(
  CGContextRef ctx,
  CFDictionaryRef auxiliaryInfo
);

void CGContextBeginTransparencyLayerWithRect(
  CGContextRef ctx,
  CGRect rect,
  CFDictionaryRef auxiliaryInfo
);

void CGContextEndTransparencyLayer(CGContextRef ctx);

/* User to Device Transformation */

CGAffineTransform CGContextGetUserSpaceToDeviceSpaceTransform(CGContextRef ctx);

CGPoint CGContextConvertPointToDeviceSpace(CGContextRef ctx, CGPoint point);

CGPoint CGContextConvertPointToUserSpace(CGContextRef ctx, CGPoint point);

CGSize CGContextConvertSizeToDeviceSpace(CGContextRef ctx, CGSize size);

CGSize CGContextConvertSizeToUserSpace(CGContextRef ctx, CGSize size);

CGRect CGContextConvertRectToDeviceSpace(CGContextRef ctx, CGRect rect);

CGRect CGContextConvertRectToUserSpace(CGContextRef ctx, CGRect rect);

/* Opal Extensions */

// FIXME: Move extensions to a separate header?

void OpalContextSetScaleFactor(CGContextRef ctx, CGFloat scale);

#endif /* OPAL_CGContext_h */

