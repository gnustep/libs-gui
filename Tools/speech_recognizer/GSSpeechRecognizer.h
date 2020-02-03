#import "GSSpeechRecognitionServer.h"
#import <AppKit/NSSpeechRecognizer.h>


@interface GSSpeechRecognizer : NSSpeechRecognizer {
	NSString *currentVoice;
	id delegate;
}
- (id)init;
- (id)delegate;
- (void)setDelegate: (id)aDelegate;
@end
