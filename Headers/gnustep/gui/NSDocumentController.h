
#import <Foundation/Foundation.h>
#import <AppKit/NSNibDeclarations.h>

@class NSArray, NSMutableArray;
@class NSURL;
@class NSMenuItem, NSOpenPanel, NSWindow;
@class NSDocument;

@interface NSDocumentController : NSObject
{
  @private
    NSMutableArray 	*_documents;
    struct __controllerFlags {
        unsigned int shouldCreateUI:1;
        unsigned int RESERVED:31;
    } _controllerFlags;
    NSArray		*_types;		// from info.plist with key NSTypes
    void 		*_reserved1;
    void 		*_reserved2;
}

+ (id)sharedDocumentController;

/*" document creation "*/
// doesn't create the windowControllers
- (id)makeUntitledDocumentOfType:(NSString *)type;
- (id)makeDocumentWithContentsOfFile:(NSString *)fileName ofType:(NSString *)type;
// creates window controllers
- (id)openUntitledDocumentOfType:(NSString*)type display:(BOOL)display;
- (id)openDocumentWithContentsOfFile:(NSString *)fileName display:(BOOL)display;

#if NS_URL
//- (id)makeDocumentWithContentsOfURL:(NSURL *)url ofType:(NSString *)type;
//- (id)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)display;
#endif

/*" With or without UI "*/
- (BOOL)shouldCreateUI;
- (void)setShouldCreateUI:(BOOL)flag;

/*" Actions "*/
- (IBAction)saveAllDocuments:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)newDocument:(id)sender;

/*" Open panel "*/
#if NS_URL
//- (NSArray *)URLsFromRunningOpenPanel;
#endif
- (NSArray *)fileNamesFromRunningOpenPanel;
- (int)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)openableFileExtensions;

/*" Document management "*/
- (BOOL)closeAllDocuments;
- (BOOL)reviewUnsavedDocumentsWithAlertTitle:(NSString *)title cancellable:(BOOL)cancellable;
- (NSArray *)documents;
- (BOOL)hasEditedDocuments;
- (id)currentDocument;
- (NSString *)currentDirectory;
- (id)documentForWindow:(NSWindow *)window;
- (id)documentForFileName:(NSString *)fileName;

/*" Menu validation "*/
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

/*" Types and extensions "*/
- (NSString *)displayNameForType:(NSString *)type;
- (NSString *)typeFromFileExtension:(NSString *)fileExtension;
- (NSArray *)fileExtensionsFromType:(NSString *)type;
- (Class)documentClassForType:(NSString *)type;

@end

