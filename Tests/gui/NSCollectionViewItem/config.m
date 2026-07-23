/* Coverage for NSCollectionViewItem: the selection flag, the text field and
   image view outlets, the represented object and the collection view of an item
   that is not in a collection.  Every assertion here matches AppKit (verified on
   a macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCollectionView.h>
#include <AppKit/NSCollectionViewItem.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSImageView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSCollectionViewItem *item;
  NSTextField *tf;
  NSImageView *iv;

  START_SET("NSCollectionViewItem config")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  item = AUTORELEASE([[NSCollectionViewItem alloc] init]);

  PASS([item isSelected] == NO, "default isSelected is NO");
  PASS([item textField] == nil, "default textField is nil");
  PASS([item imageView] == nil, "default imageView is nil");
  PASS([item representedObject] == nil, "default representedObject is nil");
  PASS([item collectionView] == nil,
       "an item not in a collection has no collectionView");

  [item setSelected: YES];
  PASS([item isSelected] == YES, "setSelected: YES round-trips");
  [item setSelected: NO];
  PASS([item isSelected] == NO, "setSelected: NO round-trips");

  tf = AUTORELEASE([[NSTextField alloc]
    initWithFrame: NSMakeRect(0, 0, 100, 20)]);
  [item setTextField: tf];
  PASS([item textField] == tf, "textField round-trips");

  iv = AUTORELEASE([[NSImageView alloc]
    initWithFrame: NSMakeRect(0, 0, 100, 100)]);
  [item setImageView: iv];
  PASS([item imageView] == iv, "imageView round-trips");

  [item setRepresentedObject: @"represented"];
  PASS([[item representedObject] isEqual: @"represented"],
       "representedObject round-trips");

  END_SET("NSCollectionViewItem config")

  DESTROY(arp);
  return 0;
}
