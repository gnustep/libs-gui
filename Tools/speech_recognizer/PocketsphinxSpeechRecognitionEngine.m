#import "GSSpeechRecognitionEngine.h"
#include <pocketsphinx/pocketsphinx.h>

/**
 * Implementation of a speech engine using pocketsphinx.  This should be the default
 * for resource-constrained platforms.
 */
@interface PocketsphinxSpeechEngine : GSSpeechRecognitionEngine
{
}
@end

@implementation PocketsphinxSpeechEngine
+ (void)initialize
{
}

- (id)init
{
  if (nil == (self = [super init])) { return nil; }
  return self;
}
@end

@implementation GSSpeechRecognitionEngine (Pocketsphinx)
+ (GSSpeechRecognitionEngine*)defaultSpeechRecognitionEngine
{
  return [[[PocketsphinxSpeechRecognitionEngine alloc] init] autorelease];
}
@end
