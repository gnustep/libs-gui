#import <AppKit/NSMenuItemCell.h>
#import <AppKit/NSMenuItem.h>

@class NSMenu;

typedef enum {
    NSPopUpNoArrow = 0,
    NSPopUpArrowAtCenter = 1,
    NSPopUpArrowAtBottom = 2,
} NSPopUpArrowPosition;

@interface NSPopUpButtonCell : NSMenuItemCell
{
  NSMenu	*_menu;
  NSMenuItem	*_selectedItem;
  struct __pbcFlags {
      unsigned int pullsDown:1;
      unsigned int preferredEdge:3;
      unsigned int menuIsAttached:1;
      unsigned int usesItemFromMenu:1;
      unsigned int altersStateOfSelectedItem:1;
      unsigned int decoding:1;
      unsigned int arrowPosition:2;
  } _pbcFlags;
}

- (id)initTextCell:(NSString *)stringValue pullsDown:(BOOL)pullDown;

// Overrides behavior of NSCell.  This is the menu for the popup, not a 
// context menu.  PopUpButtonCells do not have context menus.
- (void)setMenu:(NSMenu *)menu;
- (NSMenu *)menu;

// Behavior settings
- (void)setPullsDown:(BOOL)flag;
- (BOOL)pullsDown;

- (void)setAutoenablesItems:(BOOL)flag;
- (BOOL)autoenablesItems;

- (void)setPreferredEdge:(NSRectEdge)edge;
- (NSRectEdge)preferredEdge;

- (void)setUsesItemFromMenu:(BOOL)flag;
- (BOOL)usesItemFromMenu;

- (void)setAltersStateOfSelectedItem:(BOOL)flag;
- (BOOL)altersStateOfSelectedItem;

// Adding and removing items
- (void)addItemWithTitle:(NSString *)title;
- (void)addItemsWithTitles:(NSArray *)itemTitles;
- (void)insertItemWithTitle:(NSString *)title atIndex:(int)index;
        
- (void)removeItemWithTitle:(NSString *)title;
- (void)removeItemAtIndex:(int)index; 
- (void)removeAllItems;
        

// Accessing the items
- (NSArray *)itemArray;
- (int)numberOfItems;
 
- (int)indexOfItem:(id <NSMenuItem>)item;
- (int)indexOfItemWithTitle:(NSString *)title;
- (int)indexOfItemWithTag:(int)tag;
- (int)indexOfItemWithRepresentedObject:(id)obj;
- (int)indexOfItemWithTarget:(id)target andAction:(SEL)actionSelector;

- (id <NSMenuItem>)itemAtIndex:(int)index;
- (id <NSMenuItem>)itemWithTitle:(NSString *)title;
- (id <NSMenuItem>)lastItem;


// Dealing with selection
- (void)selectItem:(id <NSMenuItem>)item;
- (void)selectItemAtIndex:(int)index;
- (void)selectItemWithTitle:(NSString *)title;
- (void)setTitle:(NSString *)aString;

- (id <NSMenuItem>)selectedItem;
- (int)indexOfSelectedItem;
- (void)synchronizeTitleAndSelectedItem;

    
// Title conveniences
- (NSString *)itemTitleAtIndex:(int)index;
- (NSArray *)itemTitles;
- (NSString *)titleOfSelectedItem;

- (void)attachPopUpWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;

- (void)dismissPopUp;
- (void)performClickWithFrame:(NSRect)frame inView:(NSView *)controlView;

// Arrow position for bezel style and borderless popups.
- (NSPopUpArrowPosition)arrowPosition;
- (void)setArrowPosition:(NSPopUpArrowPosition)position;
@end    

/* Notifications */ 
extern const NSString *NSPopUpButtonCellWillPopUpNotification;
