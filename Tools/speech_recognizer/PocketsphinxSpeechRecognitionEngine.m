#import "GSSpeechRecognitionEngine.h"
#import <Foundation/NSDistributedNotificationCenter.h>

#include <sphinxbase/err.h>
#include <sphinxbase/ad.h>
#include <pocketsphinx/pocketsphinx.h>

/**
 * Implementation of a speech engine using pocketsphinx.  This should be the default
 * for resource-constrained platforms.
 */

#define MODELDIR "/share/pocketsphinx/model"

static const arg_t cont_args_def[] = {
    POCKETSPHINX_OPTIONS,
    /* Argument file. */
    {"-argfile",
     ARG_STRING,
     NULL,
     "Argument file giving extra arguments."},
    {"-adcdev",
     ARG_STRING,
     NULL,
     "Name of audio device to use for input."},
    {"-infile",
     ARG_STRING,
     NULL,
     "Audio file to transcribe."},
    {"-inmic",
     ARG_BOOLEAN,
     "no",
     "Transcribe audio from microphone."},
    {"-time",
     ARG_BOOLEAN,
     "no",
     "Print word times in file transcription."},
    CMDLN_EMPTY_OPTION
};

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
      char *arg[3];
      arg[0] = "";
      arg[1] = "-inmic";
      arg[2] = "yes";

      config = cmd_ln_parse_r(NULL, cont_args_def, 3, arg, TRUE);
      ps_default_search_args(config);
      ps = ps_init(config);
      if (ps == NULL)
        {
          cmd_ln_free_r(config);
          NSLog(@"Could not start server");
          return nil;
        }
      _listeningThread = nil;
    }
  return self;
}

- (void) _recognizedWord: (NSString *)word
{
  [[NSDistributedNotificationCenter defaultCenter]
    postNotificationName: GSSpeechRecognizerDidRecognizeWordNotification
                  object: word
                userInfo: nil];
}

/*
 * NOTE: This code is derived from continuous.c under pocketsphinx 
 *       which is MIT licensed
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
    {
      NSLog(@"Failed to open audio device\n");
    }
  
  if (ad_start_rec(ad) < 0)
    {
      NSLog(@"Failed to start recording\n");
    }
  
  if (ps_start_utt(ps) < 0)
    {
      NSLog(@"Failed to start utterance\n");
    }
  
  utt_started = FALSE;
  NSLog(@"Ready....\n");
  
  for (;;) {
    if ((k = ad_read(ad, adbuf, 2048)) < 0)
      NSLog(@"Failed to read audio\n");
    ps_process_raw(ps, adbuf, k, FALSE, FALSE);
    in_speech = ps_get_in_speech(ps);
    if (in_speech && !utt_started) {
      utt_started = TRUE;
      NSLog(@"Listening...\n");
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
        NSLog(@"Failed to start utterance\n");
      utt_started = FALSE;
      NSLog(@"Ready....\n");
    }
    [NSThread sleepForTimeInterval: 0.01];
  }
  ad_close(ad);
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
