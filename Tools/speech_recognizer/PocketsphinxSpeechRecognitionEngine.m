#import "GSSpeechRecognitionEngine.h"

#include <sphinxbase/err.h>
#include <sphinxbase/ad.h>
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
  char const *uttid;
  int16 buf[512];
  int rv;
  int32 score;
  NSThread *_listeningThread;
  id<NSSpeechRecognizerDelegate> _delegate;
}
@end

@implementation PocketsphinxSpeechRecognitionEngine

+ (void)initialize
{
}

- (id)init
{
  if ((self = [super init]) != nil)
    {
      config = cmd_ln_init(NULL, ps_args(), TRUE,
                           "-hmm", MODELDIR "/en-us/en-us",
                           "-lm", MODELDIR "/en-us/en-us.lm.bin",
                           "-dict", MODELDIR "/en-us/cmudict-en-us.dict",
                           NULL);
      ps = ps_init(config);
      _listeningThread = nil;
    }
  return self;
}

- (void) _recognizedWord: (NSString *)word
{
  
}

/*
 * Main utterance processing loop:
 *     for (;;) {
 *        start utterance and wait for speech to process
 *        decoding till end-of-utterance silence will be detected
 *        print utterance result;
 *     }
 */
- (void) recognize
{
  ad_rec_t *ad;
  int16 adbuf[2048];
  uint8 utt_started, in_speech;
  int32 k;
  char const *hyp;
  
  if ((ad = ad_open_dev(cmd_ln_str_r(config, "-adcdev"),
                        (int) cmd_ln_float32_r(config,
                                               "-samprate"))) == NULL)
    E_FATAL("Failed to open audio device\n");
  if (ad_start_rec(ad) < 0)
    E_FATAL("Failed to start recording\n");
  
  if (ps_start_utt(ps) < 0)
    E_FATAL("Failed to start utterance\n");
  utt_started = FALSE;
  E_INFO("Ready....\n");
  
  for (;;) {
    if ((k = ad_read(ad, adbuf, 2048)) < 0)
      E_FATAL("Failed to read audio\n");
    ps_process_raw(ps, adbuf, k, FALSE, FALSE);
    in_speech = ps_get_in_speech(ps);
    if (in_speech && !utt_started) {
      utt_started = TRUE;
      E_INFO("Listening...\n");
    }
    if (!in_speech && utt_started) {
      /* speech -> silence transition, time to start new utterance  */
      ps_end_utt(ps);
      hyp = ps_get_hyp(ps, NULL );
      if (hyp != NULL) {
        NSString *recognizedString = [NSString stringWithCString: hyp
                                                        encoding: NSUTF8StringEncoding];
        [self performSelectorOnMainThread: @selector(_recognizedWord:)
                               withObject: recognizedString
                            waitUntilDone: NO];
        printf("%s\n", hyp);
        fflush(stdout);
      }
      
      if (ps_start_utt(ps) < 0)
        E_FATAL("Failed to start utterance\n");
      utt_started = FALSE;
      E_INFO("Ready....\n");
    }
    [NSThread sleepForTimeInterval: 0.01];
  }
  ad_close(ad);
}

- (void) _startProcessing
{
}

- (void) startListening
{
  [NSThread detachNewThreadSelector: @selector(recognize)
                           toTarget: self
                         withObject: nil];
}

- (void) stopListening
{
}

@end

@implementation GSSpeechRecognitionEngine (Pocketsphinx)

+ (GSSpeechRecognitionEngine*)defaultSpeechRecognitionEngine
{
  return AUTORELEASE([[PocketsphinxSpeechRecognitionEngine alloc] init]);
}

@end
