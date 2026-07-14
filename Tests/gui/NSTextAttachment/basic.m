/* Coverage for NSTextAttachment: the default attachment cell, the file
 * wrapper round-trip, and the attachment cell round-trip with its back
 * reference to the attachment.  Setting a file wrapper reaches the file
 * icon, so the set uses the backend and is skipped when it is unavailable.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSTextAttachment.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSData *data = [@"hello" dataUsingEncoding: NSUTF8StringEncoding];
  NSFileWrapper *fw = AUTORELEASE([[NSFileWrapper alloc]
    initRegularFileWithContents: data]);

  START_SET("NSTextAttachment")

  NS_DURING
  {
    [NSApplication sharedApplication];
  }
  NS_HANDLER
  {
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  }
  NS_ENDHANDLER

  {
    NSTextAttachment *a = AUTORELEASE([[NSTextAttachment alloc]
      initWithFileWrapper: nil]);

    pass([a fileWrapper] == nil, "an attachment with no wrapper has none");
    pass([(id)[a attachmentCell] isKindOfClass: [NSTextAttachmentCell class]],
         "an attachment has a text attachment cell by default");
  }

  {
    NSTextAttachment *a = AUTORELEASE([[NSTextAttachment alloc]
      initWithFileWrapper: fw]);

    pass([a fileWrapper] == fw, "initWithFileWrapper: stores the wrapper");
    pass([(id)[a attachmentCell] isKindOfClass: [NSTextAttachmentCell class]],
         "an attachment from a wrapper still has a cell");
  }

  {
    NSTextAttachment *a = AUTORELEASE([[NSTextAttachment alloc] init]);

    [a setFileWrapper: fw];
    pass([a fileWrapper] == fw, "setFileWrapper: round trips");
  }

  {
    NSTextAttachment *a = AUTORELEASE([[NSTextAttachment alloc] init]);
    NSTextAttachmentCell *cell = AUTORELEASE([[NSTextAttachmentCell alloc] init]);

    [a setAttachmentCell: cell];
    pass([a attachmentCell] == cell, "setAttachmentCell: round trips");
    pass([cell attachment] == a,
         "setAttachmentCell: points the cell back at the attachment");
  }

  END_SET("NSTextAttachment")

  DESTROY(arp);
  return 0;
}
