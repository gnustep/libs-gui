/* NSDataAsset loads a named data asset from a bundle, from either an Apple
   .dataset directory or a plain named resource, and returns nil when the asset
   is not found.  AppKit returns nil for a missing asset (checked on a macOS
   runner); the loading itself is exercised against a temporary bundle built
   here. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSData.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSString.h>

#include <AppKit/NSDataAsset.h>

static NSData *
bytes(NSString *s)
{
  return [s dataUsingEncoding: NSUTF8StringEncoding];
}

/* Build a bundle with a Blob.dataset directory and a Plain.json resource,
   returning its path. */
static NSString *
buildBundle(void)
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *root = [NSTemporaryDirectory()
    stringByAppendingPathComponent: @"NSDataAssetTest.bundle"];
  NSString *res = [root stringByAppendingPathComponent: @"Resources"];
  NSString *dataset = [res stringByAppendingPathComponent: @"Blob.dataset"];

  [fm removeItemAtPath: root error: NULL];
  [fm createDirectoryAtPath: dataset
    withIntermediateDirectories: YES
                 attributes: nil
                      error: NULL];

  [bytes(@"{\"info\":{\"version\":1,\"author\":\"test\"},"
         @"\"data\":[{\"idiom\":\"universal\",\"filename\":\"payload.bin\"}]}")
    writeToFile: [dataset stringByAppendingPathComponent: @"Contents.json"]
     atomically: YES];
  [bytes(@"hello dataset")
    writeToFile: [dataset stringByAppendingPathComponent: @"payload.bin"]
     atomically: YES];
  [bytes(@"{\"k\":1}")
    writeToFile: [res stringByAppendingPathComponent: @"Plain.json"]
     atomically: YES];

  return root;
}

int
main()
{
  NSString *root;
  NSBundle *bundle;
  NSDataAsset *a;

  START_SET("NSDataAsset loading")

  root = buildBundle();
  bundle = [NSBundle bundleWithPath: root];
  PASS(bundle != nil, "built a temporary bundle to load from");

  a = AUTORELEASE([[NSDataAsset alloc] initWithName: @"Blob" bundle: bundle]);
  PASS(a != nil, "an asset packaged as a .dataset loads");
  PASS([[a data] isEqualToData: bytes(@"hello dataset")],
       "the .dataset payload is the asset data");
  PASS([[a name] isEqualToString: @"Blob"], "the asset keeps its name");

  a = AUTORELEASE([[NSDataAsset alloc] initWithName: @"Plain" bundle: bundle]);
  PASS(a != nil, "an asset stored as a plain resource loads");
  PASS([[a data] isEqualToData: bytes(@"{\"k\":1}")],
       "the plain resource is the asset data");
  PASS([[a typeIdentifier] isEqualToString: @"public.json"],
       "the type identifier is derived from the resource extension");

  a = AUTORELEASE([[NSDataAsset alloc] initWithName: @"Missing" bundle: bundle]);
  PASS(a == nil, "a missing asset returns nil");

  a = AUTORELEASE([[NSDataAsset alloc] initWithName: @"NoSuchAsset"]);
  PASS(a == nil, "a missing asset in the main bundle returns nil");

  [[NSFileManager defaultManager] removeItemAtPath: root error: NULL];

  END_SET("NSDataAsset loading")

  return 0;
}
