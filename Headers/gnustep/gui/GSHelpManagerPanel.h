#import <AppKit/AppKit.h>

@interface GSHelpManagerPanel: NSPanel
{
   id textView;
}

+sharedHelpManagerPanel;
-init;
-(void)setHelpText: (NSAttributedString*)helpText;
@end
