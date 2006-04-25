/* NSBitmapImageRep+JPEG.m

   Methods for reading jpeg images

   Copyright (C) 2003 Free Software Foundation, Inc.
   
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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
   */ 

#include "config.h"
#include "NSBitmapImageRep+JPEG.h"

#if HAVE_LIBJPEG

#include <Foundation/NSString.h>
#include <Foundation/NSData.h>
#include <Foundation/NSException.h>
#include "AppKit/NSGraphics.h"

#include <jerror.h>
#if defined(__MINGW32__)
/* Hack so that INT32 is not redefined in jmorecfg.h. MingW defines this
   as well in basetsd.h */
#ifndef XMD_H
#define XMD_H
#endif
#endif
#include <jpeglib.h>

#include <setjmp.h>


/* -----------------------------------------------------------
   The following functions are for interacting with the
   jpeg library 
   ----------------------------------------------------------- */

/* A custom error manager for the jpeg library
 * that 'inherits' from libjpeg's standard
 * error manager.  */
struct gs_jpeg_error_mgr
{
  struct jpeg_error_mgr parent;
   
  /* marks where to return after an error (instead of
     simply exiting) */
  jmp_buf  setjmpBuffer;

  /* a pointer to the last error message, nil if  no
     error occured. if present, string is autoreleased.  */
  NSString *error;
};
typedef struct gs_jpeg_error_mgr *gs_jpeg_error_mgr_ptr;


/* Print the last jpeg library error and returns
 * the control to the caller of the libary.
 * libjpegs default error handling would exit
 * after printing the error.  */
static void gs_jpeg_error_exit(j_common_ptr cinfo)
{
  gs_jpeg_error_mgr_ptr myerr = (gs_jpeg_error_mgr_ptr)cinfo->err;
  (*cinfo->err->output_message)(cinfo);
   
  /* jump back to the caller of the library */
  longjmp(myerr->setjmpBuffer, 1);
}


/* Save the error message in error.  */
static void gs_jpeg_output_message(j_common_ptr cinfo)
{
  char msgBuffer[JMSG_LENGTH_MAX];

  gs_jpeg_error_mgr_ptr myerr = (gs_jpeg_error_mgr_ptr)cinfo->err;

  (*cinfo->err->format_message)(cinfo, msgBuffer);
  myerr->error = [NSString stringWithCString: msgBuffer];
}


/* Initialize our error manager */
static void gs_jpeg_error_mgr_init(gs_jpeg_error_mgr_ptr errMgr)
{
  errMgr->error = nil;
}



/* ------------------------------------------------------------------*/

/* A custom data source manager that allows the jpeg library
 * to read it's data from memory. It 'inherits' from the
 * default jpeg source manager.  */
typedef struct
{
  struct jpeg_source_mgr parent;

  /* the data to be passed to the library functions */
  const unsigned char *data;
  unsigned int length;
} gs_jpeg_source_mgr;

typedef gs_jpeg_source_mgr *gs_jpeg_source_ptr;


static void gs_init_source(j_decompress_ptr cinfo)
{
  /* nothing to do here (so far) */
}


static boolean gs_fill_input_buffer(j_decompress_ptr cinfo)
{
  gs_jpeg_source_ptr src = (gs_jpeg_source_ptr)cinfo->src;

  /* we make all data available at once */
  if (src->length == 0)
    {
      ERREXIT(cinfo, JERR_INPUT_EMPTY);
    }

  src->parent.next_input_byte = src->data;
  src->parent.bytes_in_buffer = src->length;

  return TRUE;
}


static void gs_skip_input_data(j_decompress_ptr cinfo, long numBytes)
{
  gs_jpeg_source_ptr src = (gs_jpeg_source_ptr)cinfo->src;

  if (numBytes > 0)
    {
      src->parent.next_input_byte += numBytes;
      src->parent.bytes_in_buffer -= numBytes;
    }
}


static void gs_term_source(j_decompress_ptr cinfo)
{
  /* nothing to do here */
}


/* Prepare a decompression object for input from memory. The
 * caller is responsible for providing and releasing the
 * data. After decompression is done, gs_jpeg_memory_src_destroy
 * has to be called.  */
static void gs_jpeg_memory_src_create(j_decompress_ptr cinfo, NSData *data)
{
  gs_jpeg_source_ptr src;
  
  cinfo->src = (struct jpeg_source_mgr *)malloc(sizeof(gs_jpeg_source_mgr));
  src = (gs_jpeg_source_ptr)cinfo->src;

  src = (gs_jpeg_source_ptr) cinfo->src;
  src->parent.init_source = gs_init_source;
  src->parent.fill_input_buffer = gs_fill_input_buffer;
  src->parent.skip_input_data = gs_skip_input_data;
  src->parent.resync_to_restart = jpeg_resync_to_restart; /* use default */
  src->parent.term_source = gs_term_source;
  src->parent.bytes_in_buffer = 0; /* forces fill_input_buffer on first read */
  src->parent.next_input_byte = NULL; /* until buffer loaded */

  src->data = (const unsigned char *)[data bytes];
  src->length = [data length];
}


/* Destroy the source manager of the jpeg decompression object.  */
static void gs_jpeg_memory_src_destroy(j_decompress_ptr cinfo)
{
  gs_jpeg_source_ptr src = (gs_jpeg_source_ptr)cinfo->src;
   
  free(src); // does not free the data
  cinfo->src = NULL;
}


/* -----------------------------------------------------------
   The jpeg loading part of NSBitmapImageRep
   ----------------------------------------------------------- */

@implementation NSBitmapImageRep (JPEGReading)


/* Return YES if this looks like a JPEG. */
+ (BOOL) _bitmapIsJPEG: (NSData *)imageData
{
  struct jpeg_decompress_struct  cinfo;
  struct gs_jpeg_error_mgr  jerrMgr;

  /* Be sure imageData contains data */
  if (![imageData length])
    {
      return NO;
    }

  /* Establish the our custom error handler */
  gs_jpeg_error_mgr_init(&jerrMgr);
  cinfo.err = jpeg_std_error(&jerrMgr.parent);
  jerrMgr.parent.error_exit = gs_jpeg_error_exit;
  jerrMgr.parent.output_message = gs_jpeg_output_message;

  // establish return context for error handling
  if (setjmp(jerrMgr.setjmpBuffer))
    {
      gs_jpeg_memory_src_destroy(&cinfo);
      jpeg_destroy_decompress(&cinfo);
      return NO;
    }

  /* read the header to see if we have a jpeg */
  jpeg_create_decompress(&cinfo);

  /* Establish our own data source manager */
  gs_jpeg_memory_src_create(&cinfo, imageData);

  jpeg_read_header(&cinfo, TRUE);
  gs_jpeg_memory_src_destroy(&cinfo);
  jpeg_destroy_decompress(&cinfo);

  return YES;
}


/* Read the jpeg image. Assume it is from a jpeg file and imageData is not
nil. */
- (id) _initBitmapFromJPEG: (NSData *)imageData
	      errorMessage: (NSString **)errorMsg
{
  struct jpeg_decompress_struct  cinfo;
  struct gs_jpeg_error_mgr  jerrMgr;
  JDIMENSION sclcount, samplesPerRow, i, j, rowSize;
  JSAMPARRAY sclbuffer = NULL;
  unsigned char *imgbuffer = NULL;

  if (!(self = [super init]))
    return nil;

  /* Establish the our custom error handler */
  gs_jpeg_error_mgr_init(&jerrMgr);
  cinfo.err = jpeg_std_error(&jerrMgr.parent);
  jerrMgr.parent.error_exit = gs_jpeg_error_exit;
  jerrMgr.parent.output_message = gs_jpeg_output_message;

  // establish return context for error handling
  if (setjmp(jerrMgr.setjmpBuffer))
    {
      /* assign the description of possible occured error to errorMsg */
      if (errorMsg)
	*errorMsg = (jerrMgr.error ? jerrMgr.error : nil);
      gs_jpeg_memory_src_destroy(&cinfo);
      jpeg_destroy_decompress(&cinfo);
      if (imgbuffer)
        {
          free(imgbuffer);
        }
      RELEASE(self);
      return nil;
    }

  /* jpeg-decompression */

  jpeg_create_decompress(&cinfo);

  /* Establish our own data source manager */
  gs_jpeg_memory_src_create(&cinfo, imageData);

  jpeg_read_header(&cinfo, TRUE);

  /* we use RGB as target color space */
  cinfo.out_color_space = JCS_RGB;

  /* decompress */
  jpeg_start_decompress(&cinfo);

  /* process the decompressed  data */
  samplesPerRow = cinfo.output_width * cinfo.output_components;
  rowSize = samplesPerRow * sizeof(unsigned char);
  NSAssert(sizeof(JSAMPLE) == sizeof(unsigned char),
    @"unexpected sample size");

  sclbuffer = cinfo.mem->alloc_sarray((j_common_ptr)&cinfo,
                                      JPOOL_IMAGE,
                                      samplesPerRow,
                                      cinfo.rec_outbuf_height);
  /* sclbuffer is freed when cinfo is destroyed */

  imgbuffer = NSZoneMalloc([self zone], cinfo.output_height * rowSize);
  if (!imgbuffer)
    {
      NSLog(@"NSBitmapImageRep+JPEG: failed to allocated image buffer");
      RELEASE(self);
      return nil;
    }

  i = 0;
  while (cinfo.output_scanline < cinfo.output_height)
    {
      sclcount = jpeg_read_scanlines(&cinfo, sclbuffer, cinfo.rec_outbuf_height);
      for (j = 0; j < sclcount; j++)
       {
         // copy a row to the image buffer
         memcpy((imgbuffer + (i * rowSize)),
                *(sclbuffer + (j * rowSize)),
                rowSize);
         i++;
       }
    }

  /* done */
  jpeg_finish_decompress(&cinfo);

  gs_jpeg_memory_src_destroy(&cinfo);
  jpeg_destroy_decompress(&cinfo);

  if (jerrMgr.parent.num_warnings)
    {
      NSLog(@"NSBitmapImageRep+JPEG: %d warnings during jpeg decompression, image may be corrupted",
            jerrMgr.parent.num_warnings);
    }

  // create the imagerep
  //BITS_IN_JSAMPLE is defined by libjpeg
  [self initWithBitmapDataPlanes: &imgbuffer
		      pixelsWide: cinfo.output_width
		      pixelsHigh: cinfo.output_height
		   bitsPerSample: BITS_IN_JSAMPLE
		 samplesPerPixel: cinfo.output_components
			hasAlpha: (cinfo.output_components == 3 ? NO : YES)
			isPlanar: NO
		  colorSpaceName: NSCalibratedRGBColorSpace
		     bytesPerRow: rowSize
		    bitsPerPixel: BITS_IN_JSAMPLE * cinfo.output_components];

  _imageData = [[NSData alloc]
    initWithBytesNoCopy: imgbuffer
		 length: (rowSize * cinfo.output_height)];

  return self;
}

@end

#else /* !HAVE_LIBJPEG */

@implementation NSBitmapImageRep (JPEGReading)
+ (BOOL) _bitmapIsJPEG: (NSData *)imageData
{
  return NO;
}
- (id) _initBitmapFromJPEG: (NSData *)imageData
	      errorMessage: (NSString **)errorMsg
{
  RELEASE(self);
  return nil;
}
@end

#endif /* !HAVE_LIBJPEG */

