/* Coverage for NSCollectionViewItem: the selection flag, the highlight state,
   the text field and image view outlets, the represented object and the
   collection view of an item that is not in a collection.  Every assertion here
   matches AppKit (verified on a macOS runner). */
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
  PASS([item highlightState] == NSCollectionViewItemHighlightNone,
       "default highlightState is None");
  PASS([item textField] == nil, "default textField is nil");
  PASS([item imageView] == nil, "default imageView is nil");
  PASS([item representedObject] == nil, "default representedObject is nil");
  PASS([item collectionView] == nil,
       "an item not in a collection has no collectionView");

  [item setSelected: YES];
  PASS([item isSelected] == YES, "setSelected: YES round-trips");
  [item setSelected: NO];
  PASS([item isSelected] == NO, "setSelected: NO round-trips");

  [item setHighlightState: NSCollectionViewItemHighlightForSelection];
  PASS([item highlightState] == NSCollectionViewItemHighlightForSelection,
       "setHighlightState: round-trips");
  PASS([item isSelected] == NO,
       "setting the highlight state does not change the selection");
  [item setHighlightState: NSCollectionViewItemHighlightAsDropTarget];
  PASS([item highlightState] == NSCollectionViewItemHighlightAsDropTarget,
       "the drop-target highlight state round-trips");
  [item setSelected: YES];
  PASS([item highlightState] == NSCollectionViewItemHighlightAsDropTarget,
       "selecting the item does not change the highlight state");
  [item setSelected: NO];
  [item setHighlightState: NSCollectionViewItemHighlightNone];

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

  return 0;
}
