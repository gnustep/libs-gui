#import <Foundation/Foundation.h>

@interface GSSpeechRecognitionServer
+ (void)start;
@end

int main(void)
{
	[NSAutoreleasePool new];
	[GSSpeechRecognitonServer start];
	return 0;
}
