/** <title>OPColorTransformLCMS</title>

   <abstract>C Interface to graphics drawing library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen <ewasylishen@gmail.com>
   Date: July, 2010

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

#include <lcms.h>

#include "CoreGraphics/CGColorSpace.h"

#import "CGColorSpace-private.h"
#import "OPColorTransformLCMS.h"
#import "OPPremultiplyAlpha.h"

@implementation OPColorTransformLCMS


static int LcmsIntentForCGColorRenderingIntent(CGColorRenderingIntent intent)
{
  switch (intent)
  {
    default:
    case kCGRenderingIntentDefault:
      return INTENT_RELATIVE_COLORIMETRIC; // FIXME: Check a user default
    case kCGRenderingIntentAbsoluteColorimetric:
      return INTENT_ABSOLUTE_COLORIMETRIC;
    case kCGRenderingIntentRelativeColorimetric:
      return INTENT_RELATIVE_COLORIMETRIC;
    case kCGRenderingIntentPerceptual:
      return INTENT_PERCEPTUAL;
    case kCGRenderingIntentSaturation:
      return INTENT_SATURATION;
  }
}

static int LcmsPixelTypeForCGColorSpaceModel(CGColorSpaceModel model)
{
  switch (model)
  {
    case kCGColorSpaceModelMonochrome:
      return PT_GRAY;
    case kCGColorSpaceModelRGB:
      return PT_RGB;
    case kCGColorSpaceModelCMYK:
      return PT_CMYK;
    case kCGColorSpaceModelLab:
      return PT_Lab;
    case kCGColorSpaceModelUnknown:
    case kCGColorSpaceModelDeviceN:
    case kCGColorSpaceModelIndexed:
    case kCGColorSpaceModelPattern:
    default:
      return PT_ANY;
  }
}
 
static DWORD LcmsFormatForOPImageFormat(OPImageFormat opalFormat, CGColorSpaceRef colorSpace)
{    
  DWORD cmsFormat = 0;
  
  switch (opalFormat.compFormat)
  {
    case kOPComponentFormat8bpc:
      cmsFormat |= BYTES_SH(1);
			break;
    case kOPComponentFormat16bpc:
      cmsFormat |= BYTES_SH(2);
			break;
    case kOPComponentFormat32bpc:
      cmsFormat |= BYTES_SH(2); // Convert to 16-bit before passing to LCMS
			break;
    case kOPComponentFormatFloat32bpc:
      cmsFormat |= BYTES_SH(2); // Convert to 16-bit before passing to LCMS
			break;
  }
  
  cmsFormat |= CHANNELS_SH((DWORD)opalFormat.colorComponents);
 
  if (opalFormat.hasAlpha)
  {
    cmsFormat |= EXTRA_SH(1);
  }
  if (!opalFormat.isAlphaLast && opalFormat.hasAlpha)
  {
    cmsFormat |= SWAPFIRST_SH(1);
  }
  
  cmsFormat |= COLORSPACE_SH(
      LcmsPixelTypeForCGColorSpaceModel(
        CGColorSpaceGetModel(colorSpace)
      )
    );

  return cmsFormat;
}

- (id) initWithSourceSpace: (OPColorSpaceLCMS *)aSourceSpace
          destinationSpace: (OPColorSpaceLCMS *)aDestSpace
              sourceFormat: (OPImageFormat)aSourceFormat
         destinationFormat: (OPImageFormat)aDestFormat
           renderingIntent: (CGColorRenderingIntent)anIntent
                pixelCount: (size_t)aPixelCount
{
  self = [super init];
  ASSIGN(source, aSourceSpace);
  ASSIGN(dest, aDestSpace);

  const int lcmsIntent = LcmsIntentForCGColorRenderingIntent(anIntent);
  int lcmsSrcFormat = LcmsFormatForOPImageFormat(aSourceFormat, aSourceSpace);
  int lcmsDstFormat = LcmsFormatForOPImageFormat(aDestFormat, aDestSpace);

  self->xform = cmsCreateTransform(aSourceSpace->profile, lcmsSrcFormat, 
                                   aDestSpace->profile, lcmsDstFormat,
                                   lcmsIntent, 0);
  // FIXME: check for success

  self->renderingIntent = anIntent;
  self->sourceFormat = aSourceFormat;
  self->destFormat = aDestFormat;
  self->pixelCount = aPixelCount;

  if (sourceFormat.compFormat == kOPComponentFormatFloat32bpc
      || sourceFormat.compFormat == kOPComponentFormat32bpc)
  {
    tempBuffer1 = malloc(2 * pixelCount); // Convert to 16-bit
  }
  else if (sourceFormat.isAlphaPremultiplied)
  {
    // FIXME: Don't do unnecessary premul->unpremul->premul conversions
    tempBuffer1 = malloc(OPPixelNumberOfBytes(sourceFormat) * pixelCount);
  }

  if (destFormat.compFormat == kOPComponentFormatFloat32bpc
      || destFormat.compFormat == kOPComponentFormat32bpc) 
  {
    tempBuffer2 = malloc(OPPixelNumberOfBytes(destFormat) * pixelCount);
  }

  return self;
}

- (void) dealloc
{
  cmsDeleteTransform(self->xform);
  [source release];
  [dest release];
  if (tempBuffer1)
  {
    free(tempBuffer1);
  }
  if (tempBuffer2)
  {
    free(tempBuffer2);
  }
  [super dealloc];
}

- (void) transformPixelData: (const unsigned char *)input
                     output: (unsigned char *)output
{
  unsigned char *tempOutput = output;

  const size_t totalComponentsIn = sourceFormat.colorComponents + (sourceFormat.hasAlpha ? 1 : 0);
  const size_t totalComponentsOut = destFormat.colorComponents + (destFormat.hasAlpha ? 1 : 0);

  const bool destIntermediateIs16bpc = (destFormat.compFormat == kOPComponentFormatFloat32bpc
      	|| destFormat.compFormat == kOPComponentFormat32bpc
	      || destFormat.compFormat == kOPComponentFormat16bpc);

	const bool sourceIntermediateIs16bpc = (sourceFormat.compFormat == kOPComponentFormatFloat32bpc
      	|| sourceFormat.compFormat == kOPComponentFormat32bpc
	      || sourceFormat.compFormat == kOPComponentFormat16bpc);

  //NSLog(@"Transform %d pixels %d comps in %d out", pixelCount, totalComponentsIn, totalComponentsOut);

  // Special case for kOPComponentFormatFloat32bpc, which LCMS 1 doesn't support directly
	// Copy to temp input buffer
  if (sourceFormat.compFormat == kOPComponentFormatFloat32bpc)
  {
    for (size_t i=0; i<pixelCount; i++)
    {
      for (size_t j=0; j<totalComponentsIn; j++)
      {
        ((uint16_t*)tempBuffer1)[i*totalComponentsIn + j] = UINT16_MAX * ((float*)input)[i*totalComponentsIn + j];
        //NSLog(@"Input comp: %f => %d", (float)((float*)input)[i*totalComponentsIn + j],(int)((uint16_t*)tempBuffer1)[i*totalComponentsIn + j]);
        if ( (float)((float*)input)[i*totalComponentsIn + j] > 1) 
 {
  NSLog(@"oveflow");
 }
      }
    }
    input = (const unsigned char *)tempBuffer1;
  }
  else if (sourceFormat.compFormat == kOPComponentFormat32bpc)
  {
    for (size_t i=0; i<pixelCount; i++)
    {
      for (size_t j=0; j<totalComponentsIn; j++)
      {
        ((uint16_t*)tempBuffer1)[i*totalComponentsIn + j] = ((uint32_t*)input)[i*totalComponentsIn + j] >> 16;
      }
    }
    input = tempBuffer1;
  }

  // Special case: if outputting kOPComponentFormatFloat32bpc, we get LCMS
  // to convert to uint32, then manually convert that to float
  if (destFormat.compFormat == kOPComponentFormatFloat32bpc
      || destFormat.compFormat == kOPComponentFormat32bpc)
  {
    tempOutput = tempBuffer2;
  }

  // Unpremultiply alpha in input
  if (sourceFormat.isAlphaPremultiplied)
  {
    if (sourceFormat.compFormat == kOPComponentFormatFloat32bpc
        || sourceFormat.compFormat == kOPComponentFormat32bpc)
    {
      OPImageFormat fake = sourceFormat;
      fake.compFormat = kOPComponentFormat16bpc;
      OPPremultiplyAlpha(tempBuffer1, pixelCount, fake, true);
    }
    else
    {
      const size_t numBytes = OPPixelNumberOfBytes(sourceFormat) * pixelCount;
      memmove(tempBuffer1, input, numBytes);
      OPPremultiplyAlpha(tempBuffer1, pixelCount, sourceFormat, true);
      input = tempBuffer1;
    }
  }

  // generate a output alpha channel of alpha=100% if necessary

  if (!sourceFormat.hasAlpha && destFormat.hasAlpha)
	{
		size_t destIntermediateBytesPerComponent = (destIntermediateIs16bpc ? 2 : 1);
		size_t destIntermediateTotalComponentsPerPixel = (destFormat.colorComponents + (destFormat.hasAlpha ? 1 : 0));
		size_t destIntermediateBytesPerRow = pixelCount * destIntermediateTotalComponentsPerPixel * destIntermediateBytesPerComponent;
		memset(tempOutput, 0xff, destIntermediateBytesPerRow);
  }
 
  // get LCMS to do the main conversion of the color channels
    
  cmsDoTransform(xform, (void*)input, tempOutput, pixelCount);
 
  // copy alpha from source to dest if necessary

	if (sourceFormat.hasAlpha && destFormat.hasAlpha)
	{ 
    const size_t sourceAlphaCompIndex = (sourceFormat.isAlphaLast ? sourceFormat.colorComponents : 0);
    const size_t destAlphaCompIndex = (destFormat.isAlphaLast ? destFormat.colorComponents : 0);
    
		if (sourceIntermediateIs16bpc && destIntermediateIs16bpc)  /* 16 bit -> 16 bit */
	    for (size_t i=0; i<pixelCount; i++)
	    {
	     ((uint16_t*)tempOutput)[i*totalComponentsOut + destAlphaCompIndex] = ((uint16_t*)input)[i*totalComponentsIn + sourceAlphaCompIndex];
	    }
	  else if (!sourceIntermediateIs16bpc && destIntermediateIs16bpc)  /* 8 bit -> 16 bit */
	  {
	    for (size_t i=0; i<pixelCount; i++)
	    {
	      ((uint16_t*)tempOutput)[i*totalComponentsOut + destAlphaCompIndex] = ((uint8_t*)input)[i*totalComponentsIn + sourceAlphaCompIndex] << 16;
	    }
	  }
		else if (sourceIntermediateIs16bpc && !destIntermediateIs16bpc)  /* 16 bit -> 8 bit */
	  {
	    for (size_t i=0; i<pixelCount; i++)
	    {
	      ((uint8_t*)tempOutput)[i*totalComponentsOut + destAlphaCompIndex] = ((uint16_t*)input)[i*totalComponentsIn + sourceAlphaCompIndex] >> 16;
	    }
	  }
	  else /* 8 bit -> 8 bit */
	  {
	    for (size_t i=0; i<pixelCount; i++)
	    {
	    	((uint8_t*)tempOutput)[i*totalComponentsOut + destAlphaCompIndex] = ((uint8_t*)input)[i*totalComponentsIn + sourceAlphaCompIndex];
	    }
	  }
	}

  // Premultiply alpha in output buffer if necessary

  if (destFormat.isAlphaPremultiplied)
  {
    OPImageFormat fake = destFormat;
    if (destFormat.compFormat == kOPComponentFormatFloat32bpc
         || destFormat.compFormat == kOPComponentFormat32bpc)
    {  
      fake.compFormat = kOPComponentFormat16bpc;
    }
    OPPremultiplyAlpha(tempOutput, pixelCount, fake, false);
  }

	// If using a 16-bit intermediate output, copy & convert to the real destination format

  if (destFormat.compFormat == kOPComponentFormatFloat32bpc)
  {
    for (size_t i=0; i<pixelCount; i++)
    {
      for (size_t j=0; j<totalComponentsOut; j++)
      {
        ((float*)output)[i*totalComponentsOut + j] = ((uint16_t*)tempBuffer2)[i*totalComponentsOut + j] / ((float)UINT16_MAX);
				//NSLog(@"Output comp: %d => %f", (int)((uint16_t*)tempBuffer2)[i*totalComponentsOut + j], (float)((float*)output)[i*totalComponentsOut + j]);

      }
    }
  }
  else if (destFormat.compFormat == kOPComponentFormat32bpc)
  {
    for (size_t i=0; i<pixelCount; i++)
    { 
      for (size_t j=0; j<totalComponentsOut; j++)
      {
        ((uint32_t*)output)[i*totalComponentsOut + j] = ((uint16_t*)tempBuffer2)[i*totalComponentsOut + j] << 16;
      }
    }
  }
}

@end
