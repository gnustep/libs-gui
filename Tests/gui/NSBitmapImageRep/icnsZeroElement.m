#import "ObjectTesting.h"
#import <Foundation/NSData.h>
#import <Foundation/NSAutoreleasePool.h>
#import <AppKit/NSBitmapImageRep.h>

/* zeroSizeElementICNS : 32 bytes - icns family with a zero-size il32 element */
static const unsigned char zeroSizeElementICNS[] = {
0x69,0x63,0x6e,0x73,0x00,0x00,0x00,0x20,0x69,0x6c,0x33,0x32,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

};


/*
 * Regression test for an infinite loop when reading an ICNS file that
 * contains an element with a size field of zero.
 *
 * Both _initBitmapFromICNS: and _imageRepsWithICNSData: walked the icon
 * family with `dataOffset += element.elementSize'.  A zero element size
 * never advanced dataOffset, so a crafted file hung the reader.  The
 * fixture below is an "icns" family whose single il32 element has a size
 * field of zero, followed by padding so the walk loop is entered.
 */
int main()
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  NSData            *data;
  NSBitmapImageRep  *rep;
  NSArray           *reps;

  data = [NSData dataWithBytes: zeroSizeElementICNS
                        length: sizeof(zeroSizeElementICNS)];

  rep = [[NSBitmapImageRep alloc] initWithData: data];
  PASS(rep == nil,
    "an ICNS file with a zero-size element does not hang -initWithData:");
  [rep release];

  reps = [NSBitmapImageRep imageRepsWithData: data];
  PASS(reps != nil,
    "an ICNS file with a zero-size element does not hang +imageRepsWithData:");

  [arp release];
  return 0;
}
