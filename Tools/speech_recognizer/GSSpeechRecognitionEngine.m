#import "GSSpeechRecognitionEngine.h"

/**
 * Dummy implementation of a speech engine.  Doesn't do anything.
 */
@implementation GSSpeechRecognitionEngine

+ (GSSpeechRecognitionEngine*) defaultSpeechEngine
{
  return AUTORELEASE([[self alloc] init]);
} 

- (void) startListening
{
}

- (void) stopListening
{
}

- (void) recognize
{
}

@end
