/* NSBitmapImageRep+GIF.m

   Methods for reading GIF images

   Copyright (C) 2003, 2004 Free Software Foundation, Inc.
   
   Written by:  Stefan Kleine Stegemann <stefan@wms-network.de>
   Date: Nov 2003

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
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
   */ 

#include "config.h"
#include "NSBitmapImageRep+GIF.h"

#if HAVE_LIBUNGIF || HAVE_LIBGIF

/*
gif_lib.h (4.1.0b1, possibly other versions) uses Object as the name of an
argument to a function. This causes a conflict with Object declared by the
objective-c headers.
*/
#define Object GS_GifLib_Object
#include <gif_lib.h>
#undef Object

#include <Foundation/NSString.h>
#include <Foundation/NSData.h>
#include <Foundation/NSException.h>
#include "AppKit/NSGraphics.h"


/* -----------------------------------------------------------
   The following types and functions are for interacting with
   the gif library.
   ----------------------------------------------------------- */

/* settings for reading interlaced images */
static int InterlaceOffset[] = { 0, 4, 2, 1 };
static int InterlaceJumps[]  = { 8, 8, 4, 2 };

/* Holds the information for the input function.  */
typedef struct gs_gif_input_src
{
  const void *data;
  unsigned    length;
  unsigned    pos;
} gs_gif_input_src;

/* Provides data for the gif library.  */
static int gs_gif_input(GifFileType *file, GifByteType *buffer, int len)
{
  /* according the the libungif sources, this functions has
     to act like fread. */
  int bytesRead;
  gs_gif_input_src *src = (gs_gif_input_src *)file->UserData;

  if (src->pos < src->length)
    {
      if ((src->pos + len) > src->length)
	{
	  bytesRead = (src->length - src->pos);
	}
      else
	{
	  bytesRead = len;
	}

      /* We have to copy the data here, looking at
         the libungif source makes this clear.  */
      memcpy(buffer, src->data + src->pos, bytesRead);
      src->pos = src->pos + bytesRead;
    }
  else
    {
      bytesRead = 0;
    }

  return bytesRead;
}


/* Initialze a new input source to be used with
   gs_gif_input. The passed structure has to be
   allocated outside this function. */
static void gs_gif_init_input_source(gs_gif_input_src *src, NSData *data)
{
  src->data   = [data bytes];
  src->length = [data length];
  src->pos    = 0;
}


/* -----------------------------------------------------------
   The gif loading part of NSBitmapImageRep
   ----------------------------------------------------------- */

@implementation NSBitmapImageRep (GIFReading)

/* Return YES if this looks like a GIF. */
+ (BOOL) _bitmapIsGIF: (NSData *)imageData
{
  struct gs_gif_input_src src;
  GifFileType*            file;

  if (!imageData || ![imageData length])
    {
      return NO;
    }

  gs_gif_init_input_source(&src, imageData);
  file = DGifOpen(&src, gs_gif_input);
  if (file == NULL)
    {
      /* we do not use giferror here because it doesn't
         seem to be thread-safe (the error code is a global
         variable, so we might get the wrong error here.  */
      return NO;
    }

  DGifCloseFile(file);
  return YES;
}


#define SET_ERROR_MSG(msg) \
   if (errorMsg != NULL) \
     {\
       *errorMsg = msg; \
     }\
   NSLog(msg);

#define GIF_CREATE_ERROR(msg) \
   SET_ERROR_MSG(msg); \
   if (file != NULL) \
     {\
       DGifCloseFile(file); \
     }\
   if (imgBuffer != NULL) \
     {\
       NSZoneFree([self zone], imgBuffer); \
     }\
   RELEASE(self); \
   return nil;

#define CALL_CHECKED(f, where) \
   gifrc = f; \
   if (gifrc != GIF_OK) \
     {\
       NSString* msg = [NSString stringWithFormat: @"reading gif failed (%@)", \
						   where]; \
       GIF_CREATE_ERROR(msg);\
     }

/* Read a gif image. Assume it is from a gif file. */
- (id) _initBitmapFromGIF: (NSData *)imageData
	     errorMessage: (NSString **)errorMsg
{
  struct gs_gif_input_src src;
  GifFileType            *file = NULL;
  GifRecordType           recordType;
  GifByteType            *extension;
  GifPixelType           *imgBuffer = NULL;
  GifPixelType           *imgBufferPos;  /* a position inside imgBuffer */
  unsigned char          *rgbBuffer; /* image convertet to rgb */
  unsigned                rgbBufferPos;
  unsigned                rgbBufferSize;
  ColorMapObject         *colorMap;
  GifColorType           *color;
  unsigned                pixelSize, rowSize;
  int                     extCode;
  int                     gifrc; /* required by CALL_CHECKED */
  int                     i, j;  /* counters */
  int                     imgHeight = 0, imgWidth = 0, imgRow = 0, imgCol = 0;

  /* open the image */
  gs_gif_init_input_source(&src, imageData);
  file = DGifOpen(&src, gs_gif_input);
  if (file == NULL)
    {
      /* we do not use giferror here because it doesn't
         seem to be thread-safe (the error code is a global
         variable, so we might get the wrong error here.  */
      GIF_CREATE_ERROR(@"unable to open gif from data");
      /* Not reached. */
    }


  /* allocate a buffer for the decoded image */
  pixelSize = sizeof(GifPixelType);
  rowSize   = file->SWidth * pixelSize;
  imgBuffer = NSZoneMalloc([self zone], file->SHeight * rowSize);
  if (imgBuffer == NULL)
    {
      GIF_CREATE_ERROR(@"could not allocate input buffer");
      /* Not reached. */
    }


  /* set the background color */
  memset(imgBuffer, file->SBackGroundColor, file->SHeight * rowSize);


  /* read the image */
  do
    {
      CALL_CHECKED(DGifGetRecordType(file, &recordType), @"GetRecordType");
      switch (recordType)
	{
	  case IMAGE_DESC_RECORD_TYPE:
	    {
	      CALL_CHECKED(DGifGetImageDesc(file), @"GetImageDesc");
	     
	      imgWidth  = file->Image.Width;
	      imgHeight = file->Image.Height;
	      imgRow    = file->Image.Top;
	      imgCol    = file->Image.Left;

	      if ((file->Image.Left + file->Image.Width > file->SWidth)
		  || (file->Image.Top + file->Image.Height > file->SHeight))
		{
		   GIF_CREATE_ERROR(@"image does not fit into screen dimensions");
		}

	      if (file->Image.Interlace)
		{
		  for (i = 0; i < 4; i++)
		    {
		      for (j = imgRow + InterlaceOffset[i]; j < imgRow + imgHeight;
			   j = j + InterlaceJumps[i])
			{
			  imgBufferPos =
			    imgBuffer + (j * rowSize) + (imgCol * pixelSize);
			  CALL_CHECKED(DGifGetLine(file, imgBufferPos, imgWidth),
				       @"GetLine(Interlaced)");
			}      
		    }
		}
	      else
		{
		  for (i = 0; i < imgHeight; i++)
		    {
		      imgBufferPos =
			imgBuffer + ((imgRow++) * rowSize) + (imgCol * pixelSize);
		      CALL_CHECKED(DGifGetLine(file, imgBufferPos, imgWidth),
				   @"GetLine(Non-Interlaced)");
		    }
		}

	      break;
	    }

	  case EXTENSION_RECORD_TYPE:
	    {
	      /* ignore extensions */
	      CALL_CHECKED(DGifGetExtension(file, &extCode, &extension), @"GetExtension");
	      while (extension != NULL)
		{
		  CALL_CHECKED(DGifGetExtensionNext(file, &extension), @"GetExtensionNext");
		}
	      break;
	    }

	  case TERMINATE_RECORD_TYPE:
	  default:
	    {
	      break;
	    }
	}
    } while (recordType != TERMINATE_RECORD_TYPE);


  /* convert the image to rgb */
  rgbBufferSize = file->SHeight * (file->SWidth * sizeof(unsigned char) * 3);
  rgbBuffer = NSZoneMalloc([self zone],  rgbBufferSize);
  if (rgbBuffer == NULL)
    {
      GIF_CREATE_ERROR(@"could not allocate image buffer");
      /* Not reached. */
    }

  colorMap = (file->Image.ColorMap ? file->Image.ColorMap : file->SColorMap);
  rgbBufferPos = 0;

  for (i = 0; i < file->SHeight; i++)
    {
      imgBufferPos = imgBuffer + (i * rowSize);
      for (j = 0; j < file->SWidth; j++)
	{
	  color = &colorMap->Colors[*(imgBufferPos + (j * pixelSize))];
	  rgbBuffer[rgbBufferPos++] = color->Red;
	  rgbBuffer[rgbBufferPos++] = color->Green;
	  rgbBuffer[rgbBufferPos++] = color->Blue;
	}
    }

  NSZoneFree([self zone], imgBuffer);


  /* initialize self */
  [self initWithBitmapDataPlanes: &rgbBuffer
	pixelsWide: file->SWidth
	pixelsHigh: file->SHeight
	bitsPerSample: 8
	samplesPerPixel: 3
	hasAlpha: NO
	isPlanar: NO
	colorSpaceName: NSCalibratedRGBColorSpace
	bytesPerRow: file->SWidth * 3
	bitsPerPixel: 8 * 3];

  _imageData = [[NSData alloc] initWithBytesNoCopy: rgbBuffer
			       length: rgbBufferSize];
   

  /* don't forget to close the gif */
  DGifCloseFile(file);

  return self;
}

@end

#else /* !HAVE_LIBUNGIF || !HAVE_LIBGIF */

@implementation NSBitmapImageRep (GIFReading)
+ (BOOL) _bitmapIsGIF: (NSData *)imageData
{
  return NO;
}
- (id) _initBitmapFromGIF: (NSData *)imageData
	     errorMessage: (NSString **)errorMsg
{
  RELEASE(self);
  return nil;
}
@end

#endif /* !HAVE_LIBUNGIF || !HAVE_LIBGIF */

