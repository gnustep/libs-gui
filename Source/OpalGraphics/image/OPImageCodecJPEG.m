/* NSBitmapImageRep+JPEG.m

   Methods for reading jpeg images

   Copyright (C) 2010 Free Software Foundation, Inc.

   Written by:  Eric Wasylishen <ewasylishen@gmail.com>
   Date: July 2010   
   Written by:  Stefan Kleine Stegemann <stefan@wms-network.de>
   Date: Nov 2003
   
   This file is part of the GNUstep GUI Library.

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

// Opal Includes

#import <Foundation/NSValue.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>

#import "CGImageSource-private.h"
#import "CGImageDestination-private.h"
#import "CGDataProvider-private.h"
#import "CGDataConsumer-private.h"

#include <jerror.h>
#if defined(__MINGW32__)
/* Hack so that INT32 is not redefined in jmorecfg.h. MingW defines this
   as well in basetsd.h */
#ifndef XMD_H
#define XMD_H
#endif
/* And another so that boolean is not redefined in jmorecfg.h. */
#ifndef HAVE_BOOLEAN
#define HAVE_BOOLEAN
/* This MUST match the jpeg definition of boolean */
typedef int jpeg_boolean;
#define boolean jpeg_boolean
#endif
#endif // __MINGW32__

#include <jpeglib.h>






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

  /* a pointer to the last error message, nil if  no
     error occured. if present, string is autoreleased.  */
  NSString *message;
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
  [NSException raise: @"JPEGException" format: @"%@", myerr->message];
}

/* Save the error message in error.  */
static void gs_jpeg_output_message(j_common_ptr cinfo)
{
  char msgBuffer[JMSG_LENGTH_MAX];

  gs_jpeg_error_mgr_ptr myerr = (gs_jpeg_error_mgr_ptr)cinfo->err;

  (*cinfo->err->format_message)(cinfo, msgBuffer);
  myerr->message = [NSString stringWithCString: msgBuffer];
  NSLog(@"Message %@", myerr->message);
  // FIXME: Do something with warnings?
}

/* Initialize our error manager */
static void gs_jpeg_error_mgr_create(j_common_ptr cinfo, gs_jpeg_error_mgr_ptr errMgr)
{
  cinfo->err = jpeg_std_error(&errMgr->parent);
  errMgr->parent.error_exit = gs_jpeg_error_exit;
  errMgr->parent.output_message = gs_jpeg_output_message;
  errMgr->message = nil;
}

/* ------------------------------------------------------------------*/

#define OPAL_BUFFER_SIZE 8192

/* A custom data source manager that allows the jpeg library
 * to read it's data from memory. It 'inherits' from the
 * default jpeg source manager.  */
typedef struct
{
  struct jpeg_source_mgr parent;
  CGDataProviderRef dp;
  void *buffer;
} gs_jpeg_source_mgr;

typedef gs_jpeg_source_mgr *gs_jpeg_source_ptr;


static void gs_init_source(j_decompress_ptr cinfo)
{
   /* nothing to do here */
}

static boolean gs_fill_input_buffer(j_decompress_ptr cinfo)
{
  gs_jpeg_source_ptr src = (gs_jpeg_source_ptr)cinfo->src;

  src->parent.bytes_in_buffer = OPDataProviderGetBytes(src->dp, src->buffer, OPAL_BUFFER_SIZE);
  src->parent.next_input_byte = src->buffer;
  
  if (src->parent.bytes_in_buffer == 0)
  {
    ERREXIT(cinfo, JERR_INPUT_EMPTY);
  }

  return TRUE;
}

static void gs_skip_input_data(j_decompress_ptr cinfo, long numBytes)
{
  gs_jpeg_source_ptr src = (gs_jpeg_source_ptr)cinfo->src;
  OPDataProviderSkipForward(src->dp, numBytes);
}

static void gs_term_source(j_decompress_ptr cinfo)
{
  /* nothing to do here */
}

/* Prepare a decompression object for input from memory. The
 * caller is responsible for providing and releasing the
 * data. After decompression is done, gs_jpeg_memory_src_destroy
 * has to be called.  */
static void gs_jpeg_memory_src_create(j_decompress_ptr cinfo, CGDataProviderRef dp)
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

  src->dp = CGDataProviderRetain(dp);
  src->buffer = malloc(OPAL_BUFFER_SIZE);
}


/* Destroy the source manager of the jpeg decompression object.  */
static void gs_jpeg_memory_src_destroy(j_decompress_ptr cinfo)
{
  gs_jpeg_source_ptr src = (gs_jpeg_source_ptr)cinfo->src;
  
  CGDataProviderRelease(src->dp); 
  free(src->buffer);
  
  free(src);
  cinfo->src = NULL;
}

/* ------------------------------------------------------------------*/

/*
 * A custom destination manager.
 */

typedef struct
{
  struct jpeg_destination_mgr pub; // public fields
  CGDataConsumerRef dc;
  void *buffer;
} gs_jpeg_destination_mgr;
typedef gs_jpeg_destination_mgr * gs_jpeg_dest_ptr;

/*
        Initialize destination.  This is called by jpeg_start_compress()
        before any data is actually written.  It must initialize
        next_output_byte and free_in_buffer.  free_in_buffer must be
        initialized to a positive value.
*/

static void gs_init_destination (j_compress_ptr cinfo)
{
  gs_jpeg_dest_ptr dest = (gs_jpeg_dest_ptr) cinfo->dest;
  
  dest->pub.next_output_byte = dest->buffer;
  dest->pub.free_in_buffer = OPAL_BUFFER_SIZE;
}

/*
        This is called whenever the buffer has filled (free_in_buffer
        reaches zero).  In typical applications, it should write out the
        *entire* buffer (use the saved start address and buffer length;
        ignore the current state of next_output_byte and free_in_buffer).
        Then reset the pointer & count to the start of the buffer, and
        return TRUE indicating that the buffer has been dumped.
        free_in_buffer must be set to a positive value when TRUE is
        returned.  A FALSE return should only be used when I/O suspension is
        desired (this operating mode is discussed in the next section).
*/

static boolean gs_empty_output_buffer (j_compress_ptr cinfo)
{
  gs_jpeg_dest_ptr dest = (gs_jpeg_dest_ptr) cinfo->dest;

  OPDataConsumerPutBytes(dest->dc, dest->buffer, OPAL_BUFFER_SIZE);

  dest->pub.next_output_byte = dest->buffer;
  dest->pub.free_in_buffer = OPAL_BUFFER_SIZE;

  return TRUE;
}

/*
        Terminate destination --- called by jpeg_finish_compress() after all
        data has been written.  In most applications, this must flush any
        data remaining in the buffer.  Use either next_output_byte or
        free_in_buffer to determine how much data is in the buffer.
*/

static void gs_term_destination (j_compress_ptr cinfo)
{
  gs_jpeg_dest_ptr dest = (gs_jpeg_dest_ptr) cinfo->dest;
  
  OPDataConsumerPutBytes(dest->dc, dest->buffer, OPAL_BUFFER_SIZE - dest->pub.free_in_buffer);
}

static void gs_jpeg_CGDataConsumer_dest_create (j_compress_ptr cinfo, CGDataConsumerRef dc)
{
  gs_jpeg_dest_ptr dest;

  cinfo->dest = (struct jpeg_destination_mgr*)
    malloc (sizeof (gs_jpeg_destination_mgr));

  dest = (gs_jpeg_dest_ptr) cinfo->dest;

  dest->pub.init_destination = gs_init_destination;
  dest->pub.empty_output_buffer = gs_empty_output_buffer;
  dest->pub.term_destination = gs_term_destination;
  
  dest->dc = CGDataConsumerRetain(dc);
  dest->buffer = malloc(OPAL_BUFFER_SIZE);
}

static void gs_jpeg_memory_dest_destroy (j_compress_ptr cinfo)
{
  gs_jpeg_dest_ptr dest = (gs_jpeg_dest_ptr) cinfo->dest;

  CGDataConsumerRelease(dest->dc);
  free (dest->buffer);

  free (dest);
  cinfo->dest = NULL;
}



/* -----------------------------------------------------------
   The jpeg loading part of NSBitmapImageRep
   ----------------------------------------------------------- */

@interface CGImageSourceJPEG : CGImageSource
{
  CGDataProviderRef dp;
}

@end

@implementation CGImageSourceJPEG

+ (void)load
{
  [CGImageSource registerSourceClass: self];
}

+ (NSArray *)typeIdentifiers
{
  return [NSArray arrayWithObject: @"public.jpeg"]; 
}

- (id)initWithProvider: (CGDataProviderRef)provider
{
  self = [super init];
  
  dp = CGDataProviderRetain(provider);
  OPDataProviderRewind(dp);

  struct jpeg_decompress_struct  cinfo;
  struct gs_jpeg_error_mgr  jerrMgr;

  memset((void*)&cinfo, 0, sizeof(struct jpeg_decompress_struct));

  gs_jpeg_error_mgr_create((j_common_ptr)&cinfo, &jerrMgr);

  /* read the header to see if we have a jpeg */
  jpeg_create_decompress(&cinfo);

  /* Establish our own data source manager */
  gs_jpeg_memory_src_create(&cinfo, dp);

  NS_DURING
  {
    jpeg_read_header(&cinfo, TRUE);
  }
  NS_HANDLER
  {
    gs_jpeg_memory_src_destroy(&cinfo);
    jpeg_destroy_decompress(&cinfo);
    [self release];
    NS_VALUERETURN(nil, id);
  }
  NS_ENDHANDLER
  
  gs_jpeg_memory_src_destroy(&cinfo);
  jpeg_destroy_decompress(&cinfo);

  return self;
}

- (void)dealloc
{
  CGDataProviderRelease(dp);
  [super dealloc];
}
  
- (NSDictionary*)propertiesWithOptions: (NSDictionary*)opts
{
  return [NSDictionary dictionary];
}

- (NSDictionary*)propertiesWithOptions: (NSDictionary*)opts atIndex: (size_t)index
{
  return [NSDictionary dictionary];  
}

- (size_t)count
{
  return 1; //FIXME
}

- (CGImageRef)createImageAtIndex: (size_t)index options: (NSDictionary*)opts
{
  struct jpeg_decompress_struct  cinfo;
  struct gs_jpeg_error_mgr  jerrMgr;
  CGImageRef img = NULL;;
  
  if (!(self = [super init]))
    return NULL;

  memset((void*)&cinfo, 0, sizeof(struct jpeg_decompress_struct));
  gs_jpeg_error_mgr_create((j_common_ptr)&cinfo, &jerrMgr);
  
  NS_DURING
  {
    /* jpeg-decompression */
    JDIMENSION sclcount, i, j;
    JSAMPARRAY sclbuffer = NULL;
    unsigned char *imgbuffer = NULL;
    BOOL isProgressive;
  
    jpeg_create_decompress(&cinfo);
  
    /* Establish our own data source manager */
    OPDataProviderRewind(dp);
    gs_jpeg_memory_src_create(&cinfo, dp);
  
    jpeg_read_header(&cinfo, TRUE);
  
    /* we use RGB as target color space; others are not yet supported */
    cinfo.out_color_space = JCS_RGB;
  
    /* decompress */
    jpeg_start_decompress(&cinfo);
  
    /* process the decompressed  data */
    const JDIMENSION samplesPerRow = cinfo.output_width * cinfo.output_components;
    const JDIMENSION rowSize = samplesPerRow * sizeof(unsigned char);
    NSAssert(sizeof(JSAMPLE) == sizeof(unsigned char),
      @"unexpected sample size");
  
    sclbuffer = cinfo.mem->alloc_sarray((j_common_ptr)&cinfo,
                                        JPOOL_IMAGE,
                                        samplesPerRow,
                                        cinfo.rec_outbuf_height);
    /* sclbuffer is freed when cinfo is destroyed */
  
    imgbuffer = malloc(cinfo.output_height * rowSize);
    if (!imgbuffer)
      {
        NSLog(@"NSBitmapImageRep+JPEG: failed to allocated image buffer");
        return NULL;
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
  
    isProgressive = cinfo.progressive_mode;

    /* done */
    jpeg_finish_decompress(&cinfo);

    // Create the CGImage

    NSData *imgData = [[NSData alloc] initWithBytesNoCopy:imgbuffer length:cinfo.output_height * rowSize freeWhenDone:YES];
    CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData((CFDataRef)imgData);
    [imgData release];
    
    CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    
    img = CGImageCreate(
      cinfo.output_width,
      cinfo.output_height,
      BITS_IN_JSAMPLE,
      cinfo.output_components * BITS_IN_JSAMPLE,
      rowSize,
      cs,
      kCGBitmapByteOrderDefault | kCGImageAlphaNone,
      imgDataProvider,
      NULL,
      true,
      kCGRenderingIntentDefault);

    CGColorSpaceRelease(cs);
    CGDataProviderRelease(imgDataProvider);
  } 
  NS_HANDLER
  {
    gs_jpeg_memory_src_destroy(&cinfo);
    jpeg_destroy_decompress(&cinfo);
    NS_VALUERETURN(NULL, CGImageRef);
  }
  NS_ENDHANDLER

  gs_jpeg_memory_src_destroy(&cinfo);
  jpeg_destroy_decompress(&cinfo);

  
  if (jerrMgr.parent.num_warnings)
    {
      NSLog(@"NSBitmapImageRep+JPEG: %ld warnings during jpeg decompression, "
        @"image may be corrupted", jerrMgr.parent.num_warnings);
    }
  
  return img;
}

- (CGImageRef)createThumbnailAtIndex: (size_t)index options: (NSDictionary*)opts
{
  return NULL;
}

- (CGImageSourceStatus)status
{
  return kCGImageStatusComplete;
}

- (CGImageSourceStatus)statusAtIndex: (size_t)index
{
  return kCGImageStatusComplete;
}

- (NSString*)type
{
  return @"public.jpeg";
}

- (void)updateDataProvider: (CGDataProviderRef)provider finalUpdate: (bool)finalUpdate
{
  ;
}

@end





@interface CGImageDestinationJPEG : CGImageDestination
{
  CGDataConsumerRef dc;
  CFDictionaryRef props;
  CGImageRef img;
}
@end

@implementation CGImageDestinationJPEG

+ (void)load
{
  [CGImageDestination registerDestinationClass: self];
}

+ (NSArray *)typeIdentifiers
{
  return [NSArray arrayWithObject: @"public.jpeg"];
}

- (id) initWithDataConsumer: (CGDataConsumerRef)consumer
                       type: (CFStringRef)type
                      count: (size_t)count
                    options: (CFDictionaryRef)options
{
  self = [super init];
  
  if (![(NSString*)type isEqual: @"public.jpeg"] || count != 1)
  {
    [self release];
    return nil;
  }
  
  dc = [consumer retain];
  
  return self;
}

- (void)dealloc
{
  CGDataConsumerRelease(dc);
  [props release];
  CGImageRelease(img);
  [super dealloc];    
}

- (void) setProperties: (CFDictionaryRef)properties
{
  ASSIGN(props, properties);
}

- (void) addImage: (CGImageRef)image properties: (CFDictionaryRef)properties
{
  img = CGImageRetain(image);
  ASSIGN(props, properties);
}

- (bool) finalize
{
  struct jpeg_compress_struct	cinfo;
  struct gs_jpeg_error_mgr jerrMgr;

  memset((void*)&cinfo, 0, sizeof(struct jpeg_compress_struct));
  gs_jpeg_error_mgr_create((j_common_ptr)&cinfo, &jerrMgr);
  
  NS_DURING
  {
    // initialize libjpeg for compression
  
    jpeg_create_compress(&cinfo);
  
    // specify the destination for the compressed data.. 
  
    gs_jpeg_CGDataConsumer_dest_create(&cinfo, dc);
  
    int quality = 90;    
    const int row_stride = CGImageGetBytesPerRow(img);
      
    // set parameters
  
    cinfo.image_width  = CGImageGetWidth(img);
    cinfo.image_height = CGImageGetHeight(img);
    
    cinfo.input_components = CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(img));
    
    switch (CGColorSpaceGetModel(CGImageGetColorSpace(img)))
    {
      case kCGColorSpaceModelMonochrome:
        cinfo.in_color_space = JCS_GRAYSCALE;
        break;
      case kCGColorSpaceModelCMYK:
        cinfo.in_color_space = JCS_CMYK;
        break;
      case kCGColorSpaceModelRGB:
        cinfo.in_color_space = JCS_RGB;
        break;
      case kCGColorSpaceModelUnknown:
        cinfo.in_color_space = JCS_UNKNOWN;
        NSLog(@"JPEG image rep: Using unknown color space with unpredictable results");
        break;
      default:
        NSLog(@"JPEG image rep: Unknown color space");
        return false;
    }
    
    jpeg_set_defaults (&cinfo);
  
    // set quality
    
    NSNumber *qualityNumber = [(NSDictionary*)props objectForKey: (NSString*)kCGImageDestinationLossyCompressionQuality];
    if (qualityNumber != nil)
    {
      quality = (int) (((1-[qualityNumber floatValue]) / 255.0) * 100.0);
    }
  
    // set progressive mode
    NSNumber *progressiveNumber = [(NSDictionary*)props objectForKey: @"NSImageProgressive"];
    if (progressiveNumber != nil)
    {
      cinfo.progressive_mode = [progressiveNumber boolValue];
    }
  
    // compress the image
  
    jpeg_set_quality (&cinfo, quality, TRUE);
    jpeg_start_compress (&cinfo, TRUE);
  
    /*
    if (isRGB && [self hasAlpha])	// strip alpha channel before encoding
    {
      unsigned char * RGB, * pRGB, * pRGBA;
      unsigned int iRGB, iRGBA;
      OBJC_MALLOC(RGB, unsigned char, 3*width);
      while (cinfo.next_scanline < cinfo.image_height)
      {
        iRGBA = cinfo.next_scanline * row_stride;
        pRGBA = &imageSource[iRGBA];
        pRGB = RGB;
        for (iRGB = 0; iRGB < 3*width; iRGB += 3)
        {
          memcpy(pRGB, pRGBA, 3);
          pRGB +=3;
          pRGBA +=4;
        }
        row_pointer[0] = RGB;
        jpeg_write_scanlines (&cinfo, row_pointer, 1);
      }
      OBJC_FREE(RGB);
    }
    else	// no alpha channel
    {

    }*/

    unsigned char *rowdata = malloc(row_stride);
    JSAMPROW row_pointer[1] = {rowdata};
    CGDataProviderRef dp = CGImageGetDataProvider(img);
    OPDataProviderRewind(dp);
    while (cinfo.next_scanline < cinfo.image_height)
    {
      // FIXME: strip alpha
      OPDataProviderGetBytes(dp, rowdata, row_stride);
      jpeg_write_scanlines(&cinfo, row_pointer, 1);
    }
    free(rowdata);
  
    jpeg_finish_compress(&cinfo);
  
    gs_jpeg_memory_dest_destroy (&cinfo);
  
    jpeg_destroy_compress(&cinfo);
  }
  NS_HANDLER
  {
      gs_jpeg_memory_dest_destroy(&cinfo);
      jpeg_destroy_compress(&cinfo);
      NS_VALUERETURN(false, bool);
  }
  NS_ENDHANDLER
  
  return true;
}

@end
