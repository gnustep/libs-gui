#import <Foundation/Foundation.h>
#import <AppKit/NSSpeechRecognizer.h>

/**
 * GSSpeechRecognitionEngine is an abstract speech server.  One concrete subclass should
 * be implemented for each speech engine.  Currently, only one may be compiled
 * in to the speech server at any given time.  This limitation may be removed
 * in future if pluggable speech engines are considered beneficial.
 */
@interface GSSpeechRecognitionEngine : NSObject

- (void) startListening;
- (void) stopListening;

@end

@interface NSObject (GSSpeechRecognitionEngineDelegate)
@end

@interface GSSpeechRecognitionEngine (Default)
/**
 * Returns a new instance of the default speech engine.
 */
+ (GSSpeechRecognitionEngine*)defaultSpeechRecognitionEngine;
@end
