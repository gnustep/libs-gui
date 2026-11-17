/* Private print-panel UI. Copyright (C) 2026 Free Software Foundation, Inc.
   Author: Gregory Casamento <greg.casamento@gmail.com>
   Distributed under the GNU Lesser General Public License, version 2 or later. */
#import <Foundation/Foundation.h>
#import "AppKit/AppKit.h"
#import "GNUstepGUI/GSPDFPrintOperation.h"
#import "GSPrintPanelAccessory.h"
#import "GSGuiPrivate.h"

@interface NSPrintPanel (GSAccessoryPrivate)

- (void) _updateFromPrintInfo: (NSPrintInfo *)printInfo;
- (void) _finalWritePrintInfo: (NSPrintInfo *)printInfo;

@end

@interface NSPrintOperation (GSPreviewPrivate)

- (NSRect) _printingRect;

@end

/* Rendering a preview must not order out the operation's shared print panel. */
@interface GSPrintPanelPDFOperation : GSPDFPrintOperation

@end

@implementation GSPrintPanelPDFOperation

- (void) cleanUpOperation
{
  _currentPage = 0;
  if ([NSPrintOperation currentOperation] == self)
    [NSPrintOperation setCurrentOperation: nil];
}

@end

static char previewObservation;

@interface GSPrintPreviewImageView : NSImageView

@end

@implementation GSPrintPreviewImageView

- (void) drawRect: (NSRect)dirtyRect
{
  NSSize size = [[self image] size];
  NSRect bounds = [self bounds];

  if (size.width > 0 && size.height > 0)
    {
      CGFloat factor = MIN(NSWidth(bounds) / size.width, NSHeight(bounds) / size.height);
      NSRect sheet = NSMakeRect(NSMidX(bounds) - size.width * factor / 2,
        NSMidY(bounds) - size.height * factor / 2, size.width * factor, size.height * factor);
      [[NSColor whiteColor] set];
      NSRectFill(sheet);
    }
  [super drawRect: dirtyRect];
}

@end

static NSTextField *
GSPrintLabel(NSView *parent, NSString *text, NSRect frame)
{
  NSTextField *label = AUTORELEASE([[NSTextField alloc] initWithFrame: frame]);

  [label setEditable: NO];
  [label setSelectable: NO];
  [label setBordered: NO];
  [label setBezeled: NO];
  [label setDrawsBackground: NO];
  [label setStringValue: text];
  [parent addSubview: label];
  return label;
}

@implementation GSPrintPanelAccessory

- (id) initWithPanel: (NSPrintPanel *)owner
{
  self = [super initWithFrame: NSZeroRect];
  if (self != nil)
    {
      panel = owner;
      baseSize = [[panel contentView] frame].size;
      observations = [[NSMutableArray alloc] init];
      scroll = [[NSScrollView alloc] initWithFrame: NSMakeRect(0, 0, 330, baseSize.height)];
      [scroll setHasVerticalScroller: YES];
      [scroll setBorderType: NSNoBorder];
      [self addSubview: scroll];
    }
  return self;
}

- (NSInteger) tag
{
  return GSPrintPanelAccessoryTag;
}

- (void) invalidate
{
  NSEnumerator *enumerator = [observations objectEnumerator];
  NSDictionary *entry;

  [NSObject cancelPreviousPerformRequestsWithTarget: self];
  while ((entry = [enumerator nextObject]) != nil)
    [[entry objectForKey: @"controller"] removeObserver: self
        forKeyPath: [entry objectForKey: @"path"]];
  [observations removeAllObjects];
}

- (void) dealloc
{
  [self invalidate];
  RELEASE(observations);
  RELEASE(scroll);
  RELEASE(info);
  RELEASE(pdf);
  DEALLOC;
}

- (void) detach
{
  NSEnumerator *enumerator = [[panel accessoryControllers] objectEnumerator];
  NSViewController *controller;

  [self invalidate];
  while ((controller = [enumerator nextObject]) != nil)
    [controller setRepresentedObject: nil];
  panel = nil;
  DESTROY(info);
}

- (void) updateWithPrintInfo: (NSPrintInfo *)printInfo
{
  NSPrintPanelOptions options = [panel options];
  NSView *document;
  NSArray *controllers = [panel accessoryControllers];
  NSEnumerator *enumerator;
  NSViewController *controller;
  CGFloat y = 12;
  CGFloat width = 310;
  BOOL setup = (options & NSPrintPanelShowsPageSetupAccessory) != 0;
  BOOL extra;
  BOOL autoresizes;

  if (panel == nil)
    return;
  [self invalidate];
  if (info != printInfo || !(options & NSPrintPanelShowsPreview))
    DESTROY(pdf);
  ASSIGN(info, printInfo);
  paper = nil;
  orientation = nil;
  scale = nil;
  preview = nil;
  pageLabel = nil;
  document = AUTORELEASE([[NSView alloc] initWithFrame: NSZeroRect]);
  [scroll setDocumentView: document];

  /* The preview occupies the bottom of the scrolling accessory area. */
  if (options & NSPrintPanelShowsPreview)
    {
      NSButton *button;
      preview = AUTORELEASE([[GSPrintPreviewImageView alloc]
        initWithFrame: NSMakeRect(8, y + 30, width - 16, 230)]);
      [preview setImageScaling: NSImageScaleProportionallyUpOrDown];
      [document addSubview: preview];
      pageLabel = GSPrintLabel(document, _(@"Preview"),
                              NSMakeRect(65, y, 180, 24));
      button = AUTORELEASE([[NSButton alloc] initWithFrame: NSMakeRect(8, y, 50, 24)]);
      [button setTitle: @"<"];
      [button setTarget: self];
      [button setAction: @selector(previousPage:)];
      [document addSubview: button];
      button = AUTORELEASE([[NSButton alloc] initWithFrame: NSMakeRect(252, y, 50, 24)]);
      [button setTitle: @">"];
      [button setTarget: self];
      [button setAction: @selector(nextPage:)];
      [document addSubview: button];
      y += 275;
    }

  if ([controllers count] > 0 || [panel accessoryView] != nil)
    {
      NSTabView *tabs = AUTORELEASE([[NSTabView alloc]
        initWithFrame: NSMakeRect(0, 0, width, 120)]);
      CGFloat height = 0;
      enumerator = [controllers objectEnumerator];
      while ((controller = [enumerator nextObject]) != nil)
        {
          NSView *view;
          NSView *page;
          NSTabViewItem *item;
          NSArray *summary = nil;
          NSEnumerator *items;
          NSDictionary *description;
          CGFloat bottom = 8;

          [controller setRepresentedObject: info];
          view = [controller view];
          page = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, width - 20, 100)]);
          if ([controller respondsToSelector: @selector(localizedSummaryItems)])
            summary = [(id)controller localizedSummaryItems];
          items = [summary objectEnumerator];
          while ((description = [items nextObject]) != nil)
            {
              NSString *name = [description objectForKey: NSPrintPanelAccessorySummaryItemNameKey];
              NSString *value = [description objectForKey: NSPrintPanelAccessorySummaryItemDescriptionKey];
              GSPrintLabel(page, [NSString stringWithFormat: @"%@: %@",
                name ? name : @"", value ? value : @""],
                NSMakeRect(8, bottom, width - 32, 22));
              bottom += 22;
            }
          [view setFrameOrigin: NSMakePoint(8, bottom)];
          [page addSubview: view];
          height = MAX(height, bottom + [view frame].size.height + 40);
          item = AUTORELEASE([[NSTabViewItem alloc] initWithIdentifier: controller]);
          [item setLabel: [controller title] ? [controller title] : _(@"Options")];
          [item setView: page];
          [tabs addTabViewItem: item];

          if (info != nil && [controller respondsToSelector:
                @selector(keyPathsForValuesAffectingPreview)])
            {
              NSEnumerator *paths = [[(id)controller keyPathsForValuesAffectingPreview] objectEnumerator];
              NSString *path;

              while ((path = [paths nextObject]) != nil)
                {
                  [controller addObserver: self forKeyPath: path options: 0
                                  context: &previewObservation];
                  [observations addObject: [NSDictionary dictionaryWithObjectsAndKeys:
                    controller, @"controller", path, @"path", nil]];
                }
            }
        }
      if ([panel accessoryView] != nil)
        {
          NSTabViewItem *item = AUTORELEASE([[NSTabViewItem alloc] initWithIdentifier: @"legacy"]);
          NSView *view = [panel accessoryView];
          NSView *page = AUTORELEASE([[NSView alloc]
            initWithFrame: NSMakeRect(0, 0, width - 20, [view frame].size.height + 16)]);

          height = MAX(height, [view frame].size.height + 40);
          [view setFrameOrigin: NSMakePoint(8, 8)];
          [page addSubview: view];
          [item setLabel: _(@"Options")];
          [item setView: page];
          [tabs addTabViewItem: item];
        }
      [tabs setFrame: NSMakeRect(0, y, width, height)];
      [document addSubview: tabs];
      y += height + 12;
    }

  if (setup || (options & (NSPrintPanelShowsPaperSize | NSPrintPanelShowsOrientation)))
    {
      NSBox *box = AUTORELEASE([[NSBox alloc] initWithFrame: NSMakeRect(0, y, width, setup ? 135 : 105)]);
      NSView *content = [box contentView];
      CGFloat row = 8;

      [box setTitle: setup ? _(@"Page Setup") : _(@"Paper")];
      if (setup)
        {
          GSPrintLabel(content, _(@"Scale (%)"), NSMakeRect(8, row, 105, 24));
          scale = AUTORELEASE([[NSTextField alloc] initWithFrame: NSMakeRect(120, row, 150, 24)]);
          [scale setDoubleValue: 100 * MAX(0.1, [[[info dictionary] objectForKey: NSPrintScalingFactor] doubleValue])];
          if ([[info dictionary] objectForKey: NSPrintScalingFactor] == nil)
            [scale setDoubleValue: 100];
          [scale setTarget: self];
          [scale setAction: @selector(settingsChanged:)];
          [content addSubview: scale];
          row += 30;
        }
      if (setup || (options & NSPrintPanelShowsOrientation))
        {
          GSPrintLabel(content, _(@"Orientation"), NSMakeRect(8, row, 105, 24));
          orientation = AUTORELEASE([[NSPopUpButton alloc] initWithFrame: NSMakeRect(120, row, 150, 24)]);
          [orientation addItemsWithTitles: [NSArray arrayWithObjects: _(@"Portrait"), _(@"Landscape"), nil]];
          [orientation selectItemAtIndex: [info orientation]];
          [orientation setTarget: self];
          [orientation setAction: @selector(settingsChanged:)];
          [content addSubview: orientation];
          row += 30;
        }
      if (setup || (options & NSPrintPanelShowsPaperSize))
        {
          NSArray *names = [[info printer] stringListForKey: @"PageSize" inTable: @"PPD"];
          GSPrintLabel(content, _(@"Paper Size"), NSMakeRect(8, row, 105, 24));
          paper = AUTORELEASE([[NSPopUpButton alloc] initWithFrame: NSMakeRect(120, row, 150, 24)]);
          [paper addItemsWithTitles: names];
          if ([info paperName] != nil && [paper indexOfItemWithTitle: [info paperName]] < 0)
            [paper addItemWithTitle: [info paperName]];
          if ([info paperName] != nil)
            [paper selectItemWithTitle: [info paperName]];
          [paper setTarget: self];
          [paper setAction: @selector(settingsChanged:)];
          [content addSubview: paper];
        }
      [document addSubview: box];
      y += [box frame].size.height + 12;
    }
  extra = y > 12;
  [document setFrame: NSMakeRect(0, 0, width, MAX(y, baseSize.height))];
  [self setFrame: NSMakeRect(baseSize.width + 8, 0, width + 20, baseSize.height)];
  [scroll setFrame: [self bounds]];
  [self setHidden: !extra];
  autoresizes = [[panel contentView] autoresizesSubviews];
  [[panel contentView] setAutoresizesSubviews: NO];
  [panel setContentSize: NSMakeSize(baseSize.width + (extra ? width + 28 : 0), baseSize.height)];
  [[panel contentView] setAutoresizesSubviews: autoresizes];
  if (extra)
    [document scrollPoint: NSMakePoint(0, MAX(0, y - baseSize.height))];
  [self schedulePreview];
}

- (void) settingsChanged: (id)sender
{
  if (info == nil)
    return;
  [self writePrintInfo: info];
  [panel _updateFromPrintInfo: info];
}

- (void) writePrintInfo: (NSPrintInfo *)printInfo
{
  if (paper != nil && [paper titleOfSelectedItem] != nil
      && ![[paper titleOfSelectedItem] isEqual: [printInfo paperName]])
    {
      NSPrintingOrientation saved = [printInfo orientation];
      [printInfo setPaperName: [paper titleOfSelectedItem]];
      [printInfo setOrientation: saved];
    }
  if (orientation != nil)
    [printInfo setOrientation: [orientation indexOfSelectedItem]];
  if (scale != nil)
    [[printInfo dictionary] setObject: [NSNumber numberWithDouble:
      MIN(10, MAX(0.1, [scale doubleValue] / 100))] forKey: NSPrintScalingFactor];
}

- (void) observeValueForKeyPath: (NSString *)path ofObject: (id)object
                        change: (NSDictionary *)change context: (void *)context
{
  if (context == &previewObservation)
    [self performSelectorOnMainThread: @selector(accessoryChanged:)
                           withObject: nil waitUntilDone: NO];
  else
    [super observeValueForKeyPath: path ofObject: object change: change context: context];
}

- (void) accessoryChanged: (id)sender
{
  [self updateWithPrintInfo: info];
}

- (void) schedulePreview
{
  if (panel == nil)
    return;
  if (![NSThread isMainThread])
    {
      [self performSelectorOnMainThread: _cmd withObject: nil waitUntilDone: NO];
      return;
    }
  [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(refreshPreview) object: nil];
  if (preview != nil && info != nil && !rendering)
    [self performSelector: @selector(refreshPreview) withObject: nil afterDelay: 0
                 inModes: [NSArray arrayWithObjects: NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil]];
}

- (void) showPage
{
  NSImage *image;

  if (pdf == nil || [pdf pageCount] == 0)
    {
      [preview setImage: nil];
      [pageLabel setStringValue: _(@"Preview unavailable")];
      return;
    }
  image = AUTORELEASE([[NSImage alloc] initWithSize: [pdf size]]);
  [image addRepresentation: pdf];
  [preview setImage: image];
  [pageLabel setStringValue: [NSString stringWithFormat: _(@"Page %ld of %ld"),
    (long)[pdf currentPage] + 1, (long)[pdf pageCount]]];
}

- (void) previousPage: (id)sender
{
  [pdf setCurrentPage: MAX(0, [pdf currentPage] - 1)];
  [self showPage];
}

- (void) nextPage: (id)sender
{
  [pdf setCurrentPage: MIN([pdf pageCount] - 1, [pdf currentPage] + 1)];
  [self showPage];
}

- (void) refreshPreview
{
  NSPrintOperation *current = RETAIN([NSPrintOperation currentOperation]);
  NSPrintOperation *operation = nil;
  NSString *path;
  NSInteger page = [pdf currentPage];

  if (panel == nil || [current view] == nil || rendering
      || [current printInfo] != info)
    {
      RELEASE(current);
      return;
    }
  rendering = YES;
  path = [NSTemporaryDirectory() stringByAppendingPathComponent:
    [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension: @"pdf"]];
  DESTROY(pdf);
  NS_DURING
    {
      [NSPrintOperation setCurrentOperation: nil];
      operation = [[GSPrintPanelPDFOperation alloc] initWithView: [current view]
        insideRect: [current _printingRect] toPath: path printInfo: info];
      if ([operation runOperation])
        pdf = [[NSPDFImageRep alloc] initWithData: [NSData dataWithContentsOfFile: path]];
    }
  NS_HANDLER
    {
      NSLog(@"Could not generate print preview: %@", localException);
    }
  NS_ENDHANDLER
  [NSPrintOperation setCurrentOperation: current];
  RELEASE(operation);
  RELEASE(current);
  [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
  rendering = NO;
  [pdf setCurrentPage: page];
  [self showPage];
}

@end
