#import "GSSpeechRecognitionEngine.h"
#include <pocketsphinx/pocketsphinx.h>

/**
 * Implementation of a speech engine using pocketsphinx.  This should be the default
 * for resource-constrained platforms.
 */

#define MODELDIR "/share/pocketsphinx/model"

@interface PocketsphinxSpeechRecognitionEngine : GSSpeechRecognitionEngine
{
  ps_decoder_t *ps;
  cmd_ln_t *config;
  FILE *fh;
  char const *hyp, *uttid;
  int16 buf[512];
  int rv;
  int32 score;
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
  rv = ps_start_utt(ps);
}

- (void) stopListening
{
  rv = ps_end_utt(ps);
}

@end

@implementation GSSpeechRecognitionEngine (Pocketsphinx)

+ (GSSpeechRecognitionEngine*)defaultSpeechRecognitionEngine
{
  return [[[PocketsphinxSpeechRecognitionEngine alloc] init] autorelease];
}

@end
