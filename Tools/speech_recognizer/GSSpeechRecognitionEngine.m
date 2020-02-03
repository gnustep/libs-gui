#import "GSSpeechRecognitionEngine.h"

/**
 * Dummy implementation of a speech engine.  Doesn't do anything.
 */
@implementation GSSpeechRecognitionEngine

+ (GSSpeechRecognitionEngine*)defaultSpeechEngine
{
  return [[self new] autorelease];
}

- (void) startListening
{
}

- (void) stopListening
{
}

@end
