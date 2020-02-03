#import "GSSpeechRecognitionEngine.h"
#include <pocketsphinx/pocketsphinx.h>

/**
 * Implementation of a speech engine using pocketsphinx.  This should be the default
 * for resource-constrained platforms.
 */
@interface PocketsphinxSpeechRecognitionEngine : GSSpeechRecognitionEngine
{
}
@end

@implementation PocketsphinxSpeechRecognitionEngine
+ (void)initialize
{
}

- (id)init
{
  if (nil == (self = [super init])) { return nil; }
  return self;
}

- (void) startListening
{
}

- (void) stopListening
{
}

@end

@implementation GSSpeechRecognitionEngine (Pocketsphinx)
+ (GSSpeechRecognitionEngine*)defaultSpeechRecognitionEngine
{
  return [[[PocketsphinxSpeechRecognitionEngine alloc] init] autorelease];
}
@end
