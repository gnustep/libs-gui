
#import "NSDocumentController.h"

@interface NSDocumentController (Private)
- (NSArray *)_editorAndViewerTypesForClass:(Class)documentClass;
- (NSArray *)_editorTypesForClass:(Class)fp12;
- (NSArray *)_exportableTypesForClass:(Class)documentClass;
- (void)_removeDocument:(NSDocument *)document;
@end


#import "NSDocument.h"

@interface NSDocument (Private)
- (void)_removeWindowController:(NSWindowController *)controller;
- (NSWindow *)_transferWindowOwnership;
@end


#import "NSWindowController.h"

@interface NSWindowController (Private)
- (void)_windowDidLoad;
- (void)_synchronizeWindowTitleWithDocumentName;
- (void)setWindow:(NSWindow *)window;
@end
