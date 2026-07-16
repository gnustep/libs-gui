/* A default NSCollectionViewFlowLayout uses AppKit's default metrics: a line
   and interitem spacing of 10 and a 50x50 item size. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCollectionViewFlowLayout.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSCollectionViewFlowLayout *l;

  START_SET("NSCollectionViewFlowLayout defaultMetrics")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  l = AUTORELEASE([[NSCollectionViewFlowLayout alloc] init]);
  pass([l minimumLineSpacing] == 10.0, "default minimumLineSpacing is 10");
  pass([l minimumInteritemSpacing] == 10.0,
       "default minimumInteritemSpacing is 10");
  pass([l itemSize].width == 50 && [l itemSize].height == 50,
       "default itemSize is 50x50");

  END_SET("NSCollectionViewFlowLayout defaultMetrics")

  DESTROY(arp);
  return 0;
}
