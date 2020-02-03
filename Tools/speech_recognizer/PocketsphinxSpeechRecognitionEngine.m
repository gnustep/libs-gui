#import "GSSpeechRecognitionEngine.h"
#include <pocketsphinx/pocketsphinx.h>

/**
 * Implementation of a speech engine using pocketsphinx.  This should be the default
 * for resource-constrained platforms.
 */

#define MODELDIR "/share/pocketsphinx/model"

/* 
    ps_decoder_t *ps = NULL;
    cmd_ln_t *config = NULL;

    config = cmd_ln_init(NULL, ps_args(), TRUE,
		         "-hmm", MODELDIR "/en-us/en-us",
	                 "-lm", MODELDIR "/en-us/en-us.lm.bin",
	                 "-dict", MODELDIR "/en-us/cmudict-en-us.dict",
	                 NULL);

 */
@interface PocketsphinxSpeechRecognitionEngine : GSSpeechRecognitionEngine
{
  ps_decoder_t *ps;
  cmd_ln_t *config;
}
@end

@implementation PocketsphinxSpeechRecognitionEngine

+ (void)initialize
{
}

- (id)init
{
  if (nil != (self = [super init]))
    {
      config = cmd_ln_init(NULL, ps_args(), TRUE,
                           "-hmm", MODELDIR "/en-us/en-us",
                           "-lm", MODELDIR "/en-us/en-us.lm.bin",
                           "-dict", MODELDIR "/en-us/cmudict-en-us.dict",
                           NULL);
      ps = ps_init(config);
    }
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
