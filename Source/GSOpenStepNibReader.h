/* Private binary OPENSTEP nib adapter.  LGPL-2.0-or-later. */
#ifndef GS_OPENSTEP_NIB_READER_H
#define GS_OPENSTEP_NIB_READER_H

#import <Foundation/NSObject.h>
@class NSData;
@class NSKeyedUnarchiver;

/* Neither function instantiates application objects.  The second returns an
 * autoreleased keyed archive, or raises NSInvalidUnarchiveOperationException
 * with the offending class/version/offset.  There is no XML input path. */
BOOL GSOpenStepNibIsTypedStream(NSData *data);
NSData *GSOpenStepNibKeyedData(NSData *data);
/* Apply fields whose existing keyed representation loses precision. */
void GSOpenStepNibFinishDecoding(NSKeyedUnarchiver *coder);

#endif
