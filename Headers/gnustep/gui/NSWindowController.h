
#import <Foundation/Foundation.h>
#import <AppKit/NSNibDeclarations.h>

@class NSWindow, NSDocument, NSArray;

@interface NSWindowController : NSObject <NSCoding>
{
  @private
    NSWindow            *_window;
    NSString            *_windowNibName;
    NSString            *_windowFrameAutosaveName;
    NSDocument          *_document;
    NSArray             *_topLevelObjects;
    id                  _owner;
    struct ___wcFlags {
        unsigned int shouldCloseDocument:1;
        unsigned int shouldCascade:1;
        unsigned int nibIsLoaded:1;
        unsigned int RESERVED:29;
    } _wcFlags;
    void                *_reserved1;
    void                *_reserved2;
}

- (id)initWithWindowNibName:(NSString *)windowNibName;  // self is the owner
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner;
- (id)initWithWindow:(NSWindow *)window;

- (NSString *)windowNibName;
- (id)owner;
- (void)setDocument:(NSDocument *)document;
- (id)document;
- (void)setWindowFrameAutosaveName:(NSString *)name;
- (NSString *)windowFrameAutosaveName;
- (void)setShouldCloseDocument:(BOOL)flag;
- (BOOL)shouldCloseDocument;
- (void)setShouldCascadeWindows:(BOOL)flag;
- (BOOL)shouldCascadeWindows;
- (void)close;
- (NSWindow *)window;
- (IBAction)showWindow:(id)sender;
- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName;
- (BOOL)isWindowLoaded;
- (void)windowDidLoad;
- (void)windowWillLoad;
- (void)loadWindow;

@end

