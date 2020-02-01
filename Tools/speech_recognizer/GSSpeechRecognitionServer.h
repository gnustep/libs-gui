#import <Foundation/Foundation.h> 
@class GSSpeechRecognitionEngine;
/**
 * GSSpeechRecognitionServer handles all of the engine-agnostic operations.  Currently,
 * there aren't any, but when the on-screen text interface is added it should
 * go in here.
 */
@interface GSSpeechRecognitionServer : NSObject {
	GSSpeechRecognitionEngine *engine;
}
/**
 * Returns a shared instance of the speech server.
 */
+ (id)sharedServer;
@end
