#import <AppKit/AppKit.h>
#include <unistd.h>
#include <getopt.h>

@interface SpeechDelegate : NSObject @end
@implementation SpeechDelegate
- (void)speechSynthesizer: (NSSpeechSynthesizer*)sender 
        didFinishSpeaking: (BOOL)success
{
	exit((int)success);
}
@end
int main(int argc, char **argv)
{
	[NSAutoreleasePool new];
	NSMutableString *words = [NSMutableString string];
	NSString *outFile = nil;
	NSString *voice = nil;
	NSString *inFile = nil;

	int ch;
	while ((ch = getopt(argc, argv, "o:v:f:")) != -1)
	{
		switch (ch)
		{
			case 'o':
				outFile = [NSString stringWithUTF8String: optarg];
				break;
			case 'f':
				inFile = [NSString stringWithUTF8String: optarg];
				break;
			case 'v':
				voice = [NSString stringWithUTF8String: optarg];
				break;
		}
	}
	int i;
	for (i=optind ; i<argc ; i++)
	{
		[words appendString: [NSString stringWithUTF8String: argv[i]]];
		[words appendString: @" "];
	}

	NSSpeechSynthesizer *say = [[NSSpeechSynthesizer alloc] initWithVoice: voice];
	if (nil != inFile)
	{
		[words release];
		NSData *file = [NSData dataWithContentsOfFile: inFile];
		words = [NSString stringWithCString: [file bytes]];
	}

	// Don't interrupt other apps.
	while ([NSSpeechSynthesizer isAnyApplicationSpeaking])
	{
		[NSThread sleepForTimeInterval: 0.1];
	}
	[say setDelegate: [SpeechDelegate new]];
	[say startSpeakingString: words];
	[[NSRunLoop currentRunLoop] run];
	// Not reached.
	return 0;
}
