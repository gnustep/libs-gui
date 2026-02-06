/*
   NSDocument.h

   The abstract document class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Carl Lindberg <Carl.Lindberg@hbo.com>
   Date: 1999
   Modifications: Fred Kiefer <fredkiefer@gmx.de>
   Date: Dec 2006
   Added MacOS 10.4 methods.

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_NSDocument
#define _GNUstep_H_NSDocument
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>
#import <AppKit/NSNibDeclarations.h>
#import <AppKit/NSUserInterfaceValidation.h>


/* Foundation classes */
@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSData;
@class NSDate;
@class NSDictionary;
@class NSError;
@class NSFileManager;
@class NSURL;
@class NSUndoManager;

/* AppKit classes */
@class NSWindow;
@class NSView;
@class NSSavePanel;
@class NSMenuItem;
@class NSPageLayout;
@class NSPrintInfo;
@class NSPrintOperation;
@class NSPopUpButton;
@class NSFileWrapper;
@class NSDocumentController;
@class NSWindowController;


typedef enum _NSDocumentChangeType {
    NSChangeDone 	= 0,
    NSChangeUndone 	= 1,
    NSChangeCleared 	= 2,
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
    NSChangeReadOtherContents = 3,
    NSChangeAutosaved   = 4
#endif
} NSDocumentChangeType;

typedef enum _NSSaveOperationType {
    NSSaveOperation		= 0,
    NSSaveAsOperation		= 1,
    NSSaveToOperation		= 2,
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
    NSAutosaveOperation		= 3
#endif
} NSSaveOperationType;

APPKIT_EXPORT_CLASS
/**
 * NSDocument is the abstract base class for document-based applications in
 * the AppKit framework. This class provides a comprehensive foundation for
 * managing individual documents within a multi-document application
 * architecture. NSDocument handles the complete document lifecycle including
 * creation, loading, saving, printing, and closing operations. The class
 * integrates seamlessly with NSDocumentController for application-level
 * document management and NSWindowController for document presentation and
 * user interaction. Key responsibilities include file I/O operations, change
 * tracking with undo support, window management, print operations, and user
 * interface validation. NSDocument supports various file formats, automatic
 * and manual save operations, error handling, and delegate-based callbacks
 * for asynchronous operations. Subclasses must override specific methods to
 * provide document-specific functionality while leveraging the extensive
 * infrastructure provided by the base class.
 */
@interface NSDocument : NSObject
{
  @private
    NSWindow		*_window;		// Outlet for the single window case
    NSMutableArray 	*_window_controllers;	// WindowControllers for this document
    NSURL		*_file_url;		// Save location as URL
    NSString		*_file_name;		// Save location
    NSString 		*_file_type;		// file/document type
    NSDate 		*_file_modification_date;// file modification date
    NSString		*_last_component_file_name; // file name last component
    NSURL		*_autosaved_file_url;	// Autosave location as URL
    NSPrintInfo 	*_print_info;		// print info record
    id			_printOp_delegate;	// delegate and selector called
    SEL			_printOp_didRunSelector;//   after modal print operation
    NSView 		*_save_panel_accessory;	// outlet for the accessory save-panel view
    NSPopUpButton	*_spa_button;     	// outlet for "the File Format:" button in the save panel.
    NSString            *_save_type;             // the currently selected extension.
    NSUndoManager 	*_undo_manager;		// Undo manager for this document
    long		_change_count;		// number of time the document has been changed
    long		_autosave_change_count;	// number of time the document has been changed since the last autosave
    int			_document_index;	// Untitled index
    struct __docFlags {
        unsigned int in_close:1;
        unsigned int has_undo_manager:1;
        unsigned int permanently_modified:1;
        unsigned int autosave_permanently_modified:1;
        unsigned int RESERVED:28;
    } _doc_flags;
    void 		*_reserved1;
}

/**
 * Returns an array of file types that this document class can read and open.
 * The returned array contains type identifier strings that correspond to
 * file formats supported for document loading operations. These types are
 * typically UTI strings or file extensions that define the readable formats
 * for this document class. The document controller uses this information to
 * determine which document classes can handle specific file types during
 * open operations. Subclasses should override this method to specify their
 * supported input formats, enabling proper document type resolution and
 * automatic document class selection based on file characteristics.
 */
+ (NSArray *)readableTypes;
/**
 * Returns an array of file types that this document class can write and save.
 * The returned array contains type identifier strings that correspond to
 * file formats supported for document saving operations. These types define
 * the available output formats that users can select when saving documents
 * of this class. The document controller and save panels use this information
 * to populate format selection controls and validate save operations.
 * Subclasses should override this method to specify their supported output
 * formats, enabling appropriate save format options and proper file type
 * handling during save operations.
 */
+ (NSArray *)writableTypes;
/**
 * Tests whether the specified type represents a native file format for this
 * document class. Native types are formats that preserve all document
 * information without data loss and represent the primary or preferred
 * storage format for this document type. This method helps distinguish
 * between native formats and export/import formats that may not preserve
 * complete document fidelity. The document controller uses this information
 * for save operation behavior, determining when to prompt users about
 * potential data loss or format limitations. Subclasses should override
 * this method to identify their native file formats accurately.
 */
+ (BOOL)isNativeType:(NSString *)type;

/*" Initialization "*/
/**
 * Initializes a new empty document instance with default settings. This
 * designated initializer creates a new document without loading content from
 * any file source, suitable for creating blank documents that users will
 * populate with content. The initialization process establishes default
 * document state, creates necessary internal structures, and prepares the
 * document for content editing and user interaction. Subclasses should
 * override this method to perform document-specific initialization while
 * ensuring proper super class initialization. This method is typically used
 * when creating new documents through menu actions or programmatic document
 * creation workflows.
 */
- (id)init;
/**
 * Initializes a new document instance by loading content from the specified
 * file path with the given file type. The fileName parameter specifies the
 * complete path to the source file, while fileType identifies the format
 * for proper content interpretation and loading. This initialization method
 * handles file reading, content parsing, and document state setup in a
 * single operation. The document's file location and type properties are
 * automatically configured based on the provided parameters. Subclasses
 * typically override this method to implement format-specific loading logic
 * while leveraging the base class infrastructure for standard document
 * management operations.
 */
- (id)initWithContentsOfFile:(NSString *)fileName ofType:(NSString *)fileType;
/**
 * Initializes a new document instance by loading content from the specified
 * URL with the given file type. The url parameter specifies the source
 * location using URL syntax, supporting both local file URLs and potentially
 * remote resources depending on implementation. The fileType parameter
 * identifies the content format for proper interpretation during loading.
 * This method provides URL-based initialization with automatic content
 * loading and document configuration. Modern document implementations should
 * prefer URL-based methods for enhanced flexibility and network resource
 * support. Subclasses override this method to implement format-specific
 * URL-based loading while maintaining standard document lifecycle behavior.
 */
- (id)initWithContentsOfURL:(NSURL *)url ofType:(NSString *)fileType;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
- (id)initForURL:(NSURL *)forUrl
withContentsOfURL:(NSURL *)url
          ofType:(NSString *)type
           error:(NSError **)error;
- (id)initWithContentsOfURL:(NSURL *)url
                     ofType:(NSString *)type
                      error:(NSError **)error;
- (id)initWithType:(NSString *)type
             error:(NSError **)error;
#endif

/*" Window management "*/
/**
 * Returns an array of window controllers currently associated with this
 * document. Window controllers manage the presentation and user interface
 * aspects of the document, with each controller typically corresponding to
 * a document window. This method provides access to all window controllers
 * for document-wide operations, window enumeration, or controller-specific
 * customization. The returned array contains NSWindowController instances
 * that handle window lifecycle, user interface updates, and user interaction
 * coordination. Multiple window controllers enable complex document
 * presentations with multiple views or specialized interface panels.
 */
- (NSArray *)windowControllers;
/**
 * Adds the specified window controller to this document's controller
 * collection. The windowController parameter represents an NSWindowController
 * instance that will manage document presentation and user interface
 * coordination. This method establishes the bidirectional relationship
 * between the document and its window controller, enabling proper document
 * lifecycle management and user interface synchronization. The document
 * retains the window controller and configures it for document-specific
 * operations. Multiple window controllers can be added to support complex
 * document presentations with specialized interface components.
 */
- (void)addWindowController:(NSWindowController *)windowController;
#if OS_API_VERSION(GS_API_MACOSX, MAC_OS_X_VERSION_10_4)
- (BOOL)shouldCloseWindowController:(NSWindowController *)windowController;
#endif
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (void)shouldCloseWindowController:(NSWindowController *)windowController
			   delegate:(id)delegate
		shouldCloseSelector:(SEL)callback
			contextInfo:(void *)contextInfo;
#endif
- (void)showWindows;
- (void)removeWindowController:(NSWindowController *)windowController;
- (void)setWindow:(NSWindow *)aWindow;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)
- (NSWindow *)windowForSheet;
#endif

/*" Window controller creation "*/
- (void)makeWindowControllers;  // Manual creation
- (NSString *)windowNibName;    // Automatic creation (Document will be the nib owner)

/*" Window loading notifications "*/
// Only called if the document is the owner of the nib
- (void)windowControllerWillLoadNib:(NSWindowController *)windowController;
- (void)windowControllerDidLoadNib:(NSWindowController *)windowController;

/*" Edited flag "*/
/**
 * Returns whether this document has unsaved changes that require saving.
 * The document maintains an internal change count that tracks modifications
 * since the last save operation, and this method reports the current edited
 * state based on that count. The edited state affects user interface
 * elements like window titles, close confirmations, and save menu items.
 * Document controllers and window managers use this information to provide
 * appropriate user feedback and prevent accidental data loss. The method
 * returns YES when the document contains unsaved changes and NO when all
 * changes have been saved or the document is in its original state.
 */
- (BOOL)isDocumentEdited;
/**
 * Updates the document's change tracking state based on the specified change
 * type. The change parameter indicates whether a modification was made,
 * undone, or cleared, allowing the document to maintain accurate change
 * counts and edited status. NSChangeDone increments the change count for
 * new modifications, NSChangeUndone decrements for undo operations, and
 * NSChangeCleared resets the count after save operations. This method
 * automatically updates user interface elements and triggers appropriate
 * notifications to maintain consistent document state representation.
 * Proper change tracking enables undo support, save prompts, and accurate
 * document status reporting.
 */
- (void)updateChangeCount:(NSDocumentChangeType)change;

/*" Display Name (window title) "*/
- (NSString *)displayName;

/*" Backup file "*/
- (BOOL)keepBackupFile;

/*" Closing "*/
- (void)close;
#if OS_API_VERSION(GS_API_MACOSX, MAC_OS_X_VERSION_10_4)
- (BOOL)canCloseDocument;
#endif
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (void)canCloseDocumentWithDelegate:(id)delegate
		 shouldCloseSelector:(SEL)shouldCloseSelector
			 contextInfo:(void *)contextInfo;
#endif

/*" Type and location "*/
- (NSString *)fileName;
- (void)setFileName:(NSString *)fileName;
- (NSString *)fileType;
- (void)setFileType:(NSString *)type;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
- (NSURL *)fileURL;
- (void)setFileURL:(NSURL *)url;
- (NSDate *)fileModificationDate;
- (void)setFileModificationDate: (NSDate *)date;
- (NSString *)lastComponentOfFileName;
- (void)setLastComponentOfFileName:(NSString *)str;
#endif

/*" Read/Write/Revert "*/

- (NSData *)dataRepresentationOfType:(NSString *)type;
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type;

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)type;
- (BOOL)loadFileWrapperRepresentation:(NSFileWrapper *)wrapper
			       ofType:(NSString *)type;

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type;
- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type;
- (BOOL)revertToSavedFromFile:(NSString *)fileName ofType:(NSString *)type;

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)type;
- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)type;
- (BOOL)revertToSavedFromURL:(NSURL *)url ofType:(NSString *)type;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
- (NSData *)dataOfType:(NSString *)type
                 error:(NSError **)error;
- (NSFileWrapper *)fileWrapperOfType:(NSString *)type
                               error:(NSError **)error;
- (BOOL)readFromData:(NSData *)data
              ofType:(NSString *)type
               error:(NSError **)error;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)wrapper
                     ofType:(NSString *)type
                      error:(NSError **)error;
- (BOOL)readFromURL:(NSURL *)url
             ofType:(NSString *)type
              error:(NSError **)error;
- (BOOL)revertToContentsOfURL:(NSURL *)url
                       ofType:(NSString *)type
                        error:(NSError **)error;
- (BOOL)writeSafelyToURL:(NSURL *)url
                  ofType:(NSString *)type
        forSaveOperation:(NSSaveOperationType)op
                   error:(NSError **)error;
- (BOOL)writeToURL:(NSURL *)url
            ofType:(NSString *)type
             error:(NSError **)error;
- (BOOL)writeToURL:(NSURL *)url
            ofType:(NSString *)type
  forSaveOperation:(NSSaveOperationType)op
originalContentsURL:(NSURL *)orig
             error:(NSError **)error;
#endif

/*" Save panel "*/
- (BOOL)shouldRunSavePanelWithAccessoryView;
#if OS_API_VERSION(GS_API_MACOSX, MAC_OS_X_VERSION_10_4)
- (NSString *)fileNameFromRunningSavePanelForSaveOperation:(NSSaveOperationType)saveOperation;
- (NSInteger)runModalSavePanel:(NSSavePanel *)savePanel withAccessoryView:(NSView *)accessoryView;
#endif
- (NSString *)fileTypeFromLastRunSavePanel;
- (NSDictionary *)fileAttributesToWriteToFile: (NSString *)fullDocumentPath
				       ofType: (NSString *)docType
				saveOperation: (NSSaveOperationType)saveOperationType;
- (BOOL)writeToFile:(NSString *)fileName
	     ofType:(NSString *)type
       originalFile:(NSString *)origFileName
      saveOperation:(NSSaveOperationType)saveOp;
- (BOOL)writeWithBackupToFile:(NSString *)fileName
		       ofType:(NSString *)fileType
		saveOperation:(NSSaveOperationType)saveOp;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
- (NSArray *)writableTypesForSaveOperation:(NSSaveOperationType)op;
- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)url
                                      ofType:(NSString *)type
                            forSaveOperation:(NSSaveOperationType)op
                         originalContentsURL:(NSURL *)original
                                       error:(NSError **)error;
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_1, GS_API_LATEST)
- (BOOL)fileNameExtensionWasHiddenInLastRunSavePanel;
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
- (NSString *)fileNameExtensionForType:(NSString *)typeName
                         saveOperation:(NSSaveOperationType)saveOperation;
#endif

/*" Printing "*/
- (NSPrintInfo *)printInfo;
- (void)setPrintInfo:(NSPrintInfo *)printInfo;
- (BOOL)shouldChangePrintInfo:(NSPrintInfo *)newPrintInfo;
- (IBAction)runPageLayout:(id)sender;
- (NSInteger)runModalPageLayoutWithPrintInfo:(NSPrintInfo *)printInfo;
- (IBAction)printDocument:(id)sender;
- (void)printShowingPrintPanel:(BOOL)flag;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
- (BOOL)preparePageLayout:(NSPageLayout *)pageLayout;
- (void)runModalPageLayoutWithPrintInfo:(NSPrintInfo *)info
                               delegate:(id)delegate
                         didRunSelector:(SEL)sel
                            contextInfo:(void *)context;
- (void)printDocumentWithSettings:(NSDictionary *)settings
                   showPrintPanel:(BOOL)flag
                         delegate:(id)delegate
                 didPrintSelector:(SEL)sel
                      contextInfo:(void *)context;
- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)settings
                                           error:(NSError **)error;
- (void)runModalPrintOperation:(NSPrintOperation *)op
                      delegate:(id)delegate
                didRunSelector:(SEL)sel
                   contextInfo:(void *)context;
#endif

/*" IB Actions "*/
/**
 * Performs a save operation for the current document, preserving changes to
 * the existing file location. This action method is typically connected to
 * Save menu items or toolbar buttons and initiates the standard document
 * save process. If the document has an established file location, the save
 * operation writes changes directly to that location. For new documents
 * without a file location, this method automatically presents a save panel
 * to allow the user to specify a save location and file name. The method
 * handles all aspects of the save process including user interface updates,
 * error handling, and change count management. Successful saves reset the
 * document's edited status and update the modification date.
 */
- (IBAction)saveDocument:(id)sender;
/**
 * Performs a save-as operation, allowing the user to specify a new save
 * location and potentially change the file format. This action method
 * presents a save panel regardless of whether the document has an existing
 * file location, enabling users to create copies or save in different
 * formats. The save-as operation preserves the original file while creating
 * a new file at the specified location. After successful completion, the
 * document's file location is updated to the new location, making it the
 * target for subsequent save operations. This method supports workflow
 * flexibility and file management by enabling document duplication and
 * format conversion capabilities.
 */
- (IBAction)saveDocumentAs:(id)sender;
/**
 * Performs a save-to operation, creating a copy of the document at a
 * specified location without changing the current document's file location.
 * Unlike save-as, this operation preserves the original document's location
 * as the target for future save operations while creating an independent
 * copy at the new location. This action is useful for creating backups,
 * exporting to different locations, or generating copies for distribution
 * without affecting the primary document workflow. The save-to operation
 * maintains the current document's edited status and file associations
 * while ensuring the copy reflects the current document content.
 */
- (IBAction)saveDocumentTo:(id)sender;
/**
 * Reverts the document to its last saved state, discarding all unsaved
 * changes since the last save operation. This action method presents user
 * confirmation when appropriate and then reloads the document content from
 * its file source. The revert operation restores the document to its
 * previously saved state, resetting the change count and edited status.
 * This method provides a mechanism for abandoning unwanted changes and
 * returning to known good document state. The revert process includes
 * user interface updates and proper window controller coordination to
 * maintain consistent document presentation after content restoration.
 */
- (IBAction)revertDocumentToSaved:(id)sender;

/*" Menus "*/
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;

/*" Undo "*/
/**
 * Returns the undo manager instance associated with this document. The undo
 * manager coordinates undo and redo operations for document modifications,
 * maintaining a history of changes that can be reversed or reapplied. Each
 * document typically maintains its own undo manager to provide isolated
 * undo functionality that doesn't interfere with other documents. The
 * returned undo manager integrates with the document's change tracking
 * system to provide accurate change counts and edited status updates.
 * Applications can customize undo behavior by configuring the undo manager
 * or providing custom undo implementations through the standard NSUndoManager
 * interface.
 */
- (NSUndoManager *)undoManager;
/**
 * Sets the undo manager instance for this document. The undoManager parameter
 * specifies the NSUndoManager instance that will handle undo and redo
 * operations for this document. Setting a custom undo manager allows
 * applications to provide specialized undo behavior, shared undo management
 * across multiple documents, or enhanced undo functionality beyond the
 * standard implementation. The document integrates the provided undo manager
 * with its change tracking and user interface validation systems. Setting
 * nil removes undo support from the document, which may be appropriate for
 * certain document types or application configurations.
 */
- (void)setUndoManager:(NSUndoManager *)undoManager;
/**
 * Returns whether this document has an active undo manager available for
 * undo and redo operations. This method indicates the document's undo
 * capability without requiring access to the actual undo manager instance.
 * Documents with undo managers can track and reverse changes, while those
 * without undo managers operate in a linear modification mode without
 * change reversal capabilities. User interface elements like Undo menu
 * items use this information to determine their availability and enabled
 * state. Applications can use this method to conditionally enable undo-
 * dependent features and provide appropriate user feedback about available
 * functionality.
 */
- (BOOL)hasUndoManager;
/**
 * Configures whether this document should maintain an undo manager for
 * change tracking and reversal operations. The flag parameter determines
 * whether the document creates and maintains an undo manager instance.
 * When YES, the document provides full undo and redo functionality with
 * change history tracking. When NO, the document operates without undo
 * support, which may improve performance for large documents or specialized
 * applications where undo functionality is not required. This setting
 * affects user interface validation, change count management, and the
 * availability of undo-related menu items and toolbar buttons.
 */
- (void)setHasUndoManager:(BOOL)flag;

/* NEW delegate operations*/
- (void)saveToFile:(NSString *)fileName
     saveOperation:(NSSaveOperationType)saveOperation
	  delegate:(id)delegate
   didSaveSelector:(SEL)didSaveSelector
       contextInfo:(void *)contextInfo;
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel;
- (void)saveDocumentWithDelegate:(id)delegate
		 didSaveSelector:(SEL)didSaveSelector
		     contextInfo:(void *)contextInfo;
- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation
				 delegate:(id)delegate
			  didSaveSelector:(SEL)didSaveSelector
			      contextInfo:(void *)contextInfo;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
- (BOOL)saveToURL:(NSURL *)url
           ofType:(NSString *)type
 forSaveOperation:(NSSaveOperationType)op
            error:(NSError **)error;
- (void)saveToURL:(NSURL *)url
           ofType:(NSString *)type
 forSaveOperation:(NSSaveOperationType)op
         delegate:(id)delegate
  didSaveSelector:(SEL)didSaveSelector
      contextInfo:(void *)contextInfo;

/* Autosaving */
- (NSURL *)autosavedContentsFileURL;
- (void)setAutosavedContentsFileURL:(NSURL *)url;
- (void)autosaveDocumentWithDelegate:(id)delegate
                 didAutosaveSelector:(SEL)didAutosaveSelector
                         contextInfo:(void *)context;
- (NSString *)autosavingFileType;
- (BOOL)hasUnautosavedChanges;


- (BOOL)presentError:(NSError *)error;
- (void)presentError:(NSError *)error
      modalForWindow:(NSWindow *)window
            delegate:(id)delegate
  didPresentSelector:(SEL)sel
         contextInfo:(void *)context;
- (NSError *)willPresentError:(NSError *)error;
#endif
@end

#endif // _GNUstep_H_NSDocument
