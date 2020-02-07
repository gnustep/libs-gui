#import "GSSpeechRecognitionServer.h"
#import "GSSpeechRecognitionEngine.h"
#import "GSSpeechRecognizer.h"
#import <Foundation/Foundation.h>

static GSSpeechRecognitionServer *sharedInstance;

@implementation GSSpeechRecognitionServer

+ (void)initialize
{
  sharedInstance = [self new];
}

+ (void)start
{
  NSConnection *connection = [NSConnection defaultConnection];
  [connection setRootObject: sharedInstance];
  if (NO == [connection registerName: @"GSSpeechRecognitionServer"])
    {
      return;
    }
  [[NSRunLoop currentRunLoop] run];
}

+ (id)sharedServer
{
  return sharedInstance;
}

- (id)init
{
  if (nil == (self = [super init]))
    {
      return nil;
    }
  
  _engine = [GSSpeechRecognitionEngine defaultSpeechRecognitionEngine];

  if (nil == _engine)
    {
      [self release];
      return nil;
    }
  else
    {
      NSLog(@"Got engine %@", _engine);
    }
  
  return self;
}

- (id)newRecognizer
{
  GSSpeechRecognizer *r = [[GSSpeechRecognizer alloc] init];
  RETAIN(r);
  return r;
}

- (void) startListening
{
  [_engine startListening];
}

- (void) stopListening
{
  [_engine stopListening];
}

@end
