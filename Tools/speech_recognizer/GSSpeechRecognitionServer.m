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
  if (nil == (self = [super init])) { return nil; }
  engine = [GSSpeechRecognitionEngine defaultSpeechRecognitionEngine];
  if (nil == engine)
    {
      [self release];
      return nil;
    }
  return self;
}

- (id)newRecognizer
{
  return [[GSSpeechRecognizer new] autorelease];
}
@end
