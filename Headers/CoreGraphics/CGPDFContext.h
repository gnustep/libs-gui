/** <title>CGPDFContext</title>

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

#ifndef OPAL_CGPDFContext_h
#define OPAL_CGPDFContext_h

#include <CoreGraphics/CGBase.h>
#include <CoreGraphics/CGContext.h>
#include <CoreGraphics/CGDataConsumer.h>

/* Constants */

extern const CFStringRef kCGPDFContextAuthor;
extern const CFStringRef kCGPDFContextCreator;
extern const CFStringRef kCGPDFContextTitle;
extern const CFStringRef kCGPDFContextOwnerPassword;
extern const CFStringRef kCGPDFContextUserPassword;
extern const CFStringRef kCGPDFContextAllowsPrinting;
extern const CFStringRef kCGPDFContextAllowsCopying;
extern const CFStringRef kCGPDFContextOutputIntent;
extern const CFStringRef kCGPDFContextOutputIntents;
extern const CFStringRef kCGPDFContextSubject;
extern const CFStringRef kCGPDFContextKeywords;
extern const CFStringRef kCGPDFContextEncryptionKeyLength;

extern const CFStringRef kCGPDFContextMediaBox;
extern const CFStringRef kCGPDFContextCropBox;
extern const CFStringRef kCGPDFContextBleedBox;
extern const CFStringRef kCGPDFContextTrimBox;
extern const CFStringRef kCGPDFContextArtBox;

extern const CFStringRef kCGPDFXOutputIntentSubtype;
extern const CFStringRef kCGPDFXOutputConditionIdentifier;
extern const CFStringRef kCGPDFXOutputCondition;
extern const CFStringRef kCGPDFXRegistryName;
extern const CFStringRef kCGPDFXInfo;
extern const CFStringRef kCGPDFXDestinationOutputProfile;

/* Functions */

void CGPDFContextAddDestinationAtPoint(
  CGContextRef ctx,
  CFStringRef name,
  CGPoint point
);

void CGPDFContextBeginPage(CGContextRef ctx, CFDictionaryRef pageInfo);

void CGPDFContextClose(CGContextRef ctx);

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

void CGPDFContextEndPage(CGContextRef ctx);

void CGPDFContextSetDestinationForRect(
  CGContextRef ctx,
  CFStringRef name,
  CGRect rect
);

void CGPDFContextSetURLForRect(CGContextRef ctx, CFURLRef url, CGRect rect);

#endif /* OPAL_CGPDFContext_h */
