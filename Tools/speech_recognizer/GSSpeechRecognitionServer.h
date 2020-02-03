#import <Foundation/Foundation.h>
#import <AppKit/NSSpeechRecognizer.h>

@class GSSpeechRecognitionEngine;

/**
 * GSSpeechRecognitionServer handles all of the engine-agnostic operations.  Currently,
 * there aren't any, but when the on-screen text interface is added it should
 * go in here.
 */
@interface GSSpeechRecognitionServer : NSObject
{
  GSSpeechRecognitionEngine *_engine;
  id<NSSpeechRecognizerDelegate> _delegate;
}

/**
 * Returns a shared instance of the speech server.
 */
+ (id)sharedServer;

- (void) setDelegate: (id<NSSpeechRecognizerDelegate>) delegate;

- (id<NSSpeechRecognizerDelegate>) delegate;
@end
