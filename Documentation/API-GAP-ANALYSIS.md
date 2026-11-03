# GNUstep GUI API Gap Analysis

**Audit date:** 2026-07-21  
**Repository examined:** `libs-gui`, revision `gui-0_32_0` (`4c1687d2b`)  
**Cocoa reference:** the locally installed Xcode 26.3 (`17C529`) macOS SDK,
`AppKit.framework/Versions/C/Headers`.

## Scope and method

This is a source-level API audit of the public AppKit headers in
`Headers/AppKit` and the corresponding implementations in `Source`.  A class
is considered present when this repository declares its public Objective-C
interface.  A method is considered missing when the implementation explicitly
reports that it is unimplemented, or when it belongs to an Apple AppKit feature
family for which the required public GNUstep interfaces are absent.

This deliberately does not claim binary, rendering, accessibility, or
behavioural equivalence.  The exact availability of declarations also depends
on GNUstep's `OS_API_VERSION` compile-time target.  Apple SDK declarations are
not a promise that a feature is usable on every macOS deployment target.

## Executive assessment

GNUstep GUI has a **very strong OpenStep-era surface** and exposes much of the
pre-TextKit-2 Cocoa/AppKit API.  The remaining OpenStep class gap is limited to
three obsolete compatibility classes.  Its largest divergence from current
macOS is architectural rather than cosmetic: modern collection data sources,
the TextKit 2 stack, file-provider promises, window tabs, haptics, scripting,
and the macOS 26 glass/writing-tools APIs are absent.  Several declared legacy
or Cocoa methods are also known stubs or incomplete implementations.

## OpenStep baseline

### Missing classes

| OpenStep class | Status in this tree | Assessment |
| --- | --- | --- |
| `NSCStringText` | No header or implementation | Missing.  A NEXTSTEP compatibility text class; not relevant to new code. |
| `NSCoderAdditions` | No header or implementation | Missing.  A NEXTSTEP compatibility category/API. |
| `NSMenuCell` | No header or implementation | Missing.  Superseded by `NSMenuItem` / `NSMenuItemCell`. |
| `NSHelpPanel` | Present: `Headers/AppKit/NSHelpPanel.h`, `Source/NSHelpPanel.m` | Present now, despite the old compliance page listing it as replaced. |

The in-tree OpenStep compliance document is dated 2005 and calls its result a
“best guess.”  It should therefore be treated as historical evidence, not the
current result.  In particular, it lists several methods as missing which now
have declarations and implementations, including `-preventWindowOrdering`,
`-setFloatingPointFormat:left:right:`, `-setValidateSize:`, the
`-noteDocumentSaved...` methods, `-setAccessoryView:`, `-toggleRuler:`,
`-isRulerVisible`, and `-resizeFlags`.

### OpenStep methods still missing or non-functional

| API | Evidence | Impact |
| --- | --- | --- |
| `NSReadPixel` | `Source/Functions.m` logs “not implemented” and returns `nil`. | Cannot read a pixel through the classic drawing API. |
| `NSCopyBitmapFromGState` | `Source/Functions.m` logs “not implemented”. | Legacy graphics-state bitmap copy is unavailable. |
| Classic text drawing functions | Historical compliance document lists “all text functions”; this audit did not re-certify every legacy C text routine. | Requires targeted verification for applications depending on DPS/OpenStep text functions. |

The classes declared as OpenStep-conforming in
`Documentation/General/OpenStepCompliance.gsdoc` remain a useful positive
baseline, but this repository has no current, automated OpenStep conformance
suite.  Before advertising strict OpenStep compatibility, refresh that ledger
and add executable tests for the three function-level gaps above.

## Current macOS / Cocoa comparison

### Public classes missing from the current AppKit surface

The list below is limited to AppKit-owned public classes whose absence is
material.  Types such as `CIImage`, `NSFileManager`, and `NSManagedObjectContext`
are not counted as missing AppKit classes: they belong to Core Image,
Foundation, and Core Data respectively.

| Feature family | Missing AppKit classes / primary public APIs |
| --- | --- |
| **TextKit 2** | `NSTextContentManager`, `NSTextContentStorage`, `NSTextElement`, `NSTextParagraph`, `NSTextLayoutManager`, `NSTextLayoutFragment`, `NSTextLineFragment`, `NSTextRange`, `NSTextSelection`, `NSTextSelectionNavigation`, `NSTextViewportLayoutController`, `NSTextInsertionIndicator`, `NSTextAttachmentViewProvider`, `NSTextPreview`, `NSTextListElement`. |
| **Modern collections** | `NSCollectionViewDiffableDataSource`, `NSDiffableDataSourceSnapshot`, `NSTableViewDiffableDataSource`, and the compositional-layout types `NSCollectionLayout{Item,Group,Section,Size,Dimension,...}`.  GNUstep does declare `NSCollectionViewCompositionalLayout`, but not its required Apple layout model. |
| **Dragging and promised files** | `NSDraggingItem`, `NSDraggingSession`, `NSDraggingImageComponent`, `NSFilePromiseProvider`, `NSFilePromiseReceiver`, and the related `NSItemProvider` integration. |
| **Window and toolbar integration** | `NSWindowTab`, `NSWindowTabGroup`, `NSSearchToolbarItem`, `NSTrackingSeparatorToolbarItem`, `NSSplitViewItemAccessoryViewController`, `NSViewLayoutRegion`. |
| **Feedback and input** | `NSHapticFeedbackManager`, `NSPressureConfiguration`, `NSAlignmentFeedbackFilter`, and `NSAdaptiveImageGlyph`. |
| **Scripting and workspace evolution** | Apple AppKit scripting headers (`NSApplicationScripting`, `NSDocumentScripting`, `NSTextStorageScripting`, `NSWindowScripting`) plus `NSWorkspaceOpenConfiguration` and `NSWorkspaceAuthorization`. |
| **Recent macOS 26 UI** | `NSGlassEffectView`, `NSGlassEffectContainerView`, `NSTintConfiguration`, `NSComboButton`, `NSItemBadge`, `NSMenuItemBadge`, `NSBackgroundExtensionView`, and the `NSWritingToolsCoordinator` family. |

### Missing methods implied by those absent families

Because the owning classes are absent, their selectors are unavailable too.
Important examples include:

| Area | Examples unavailable in GNUstep GUI |
| --- | --- |
| TextKit 2 | `-textLayoutManager`, `-textContentManager`, `-enumerateTextLayoutFragmentsFromLocation:options:usingBlock:`, `-ensureLayoutForRange:`, `-textSelections`, `-setTextSelections:`. |
| Diffable data sources | `-applySnapshot:animatingDifferences:`, `-snapshot`, and `-applySnapshot:toSection:animatingDifferences:`. |
| File promises | `-initWithFileType:delegate:`, `-writePromiseToURL:completionHandler:`, and `-receivePromisedFilesAtDestination:options:operationQueue:reader:`. |
| Window tabs | `-tabGroup`, `-addTabbedWindow:ordered:`, and `-selectNextTab:`. |
| Haptics | `-performFeedbackPattern:performanceTime:`. |
| Writing tools | coordinator/delegate APIs for the system writing-tools experience. |

These are feature-level comparisons, not a raw selector diff.  A raw diff is
misleading because AppKit headers contain private support classes, categories,
and cross-framework forward declarations; it also reports inherited methods
many times.  The absent class families above are the actionable method gap.

### Declared API that is visibly incomplete

The following deficiencies are directly evidenced by implementation comments
or runtime “not implemented” diagnostics and affect Cocoa compatibility even
where a public header is present.

| Class / API | Missing or incomplete method(s) | Evidence and consequence |
| --- | --- | --- |
| `NSToolbarItemGroup` | Most of the class beyond `-subitems` / `-setSubitems:` | `Source/NSToolbarItemGroup.m` explicitly says most implementation is missing. |
| `NSTableView` | `-indicatorImageInTableColumn:` and `-setIndicatorImage:inTableColumn:` | Both log “not implemented” in `Source/NSTableView.m`. |
| `NSMovie` / `NSMovieView` | QuickTime-backed movie support | `Source/NSMovie.m` contains FIXME paths returning `nil`; this API is legacy on Apple as well, but GNUstep's declared surface is not feature-complete. |
| `NSTextTable` / `NSTextBlock` | Table/block layout and drawing fidelity | `Source/NSTextTable.m` contains multiple FIXME implementations; use only after application-specific testing. |
| `NSCollectionView` | Alternating colors, item animation, multi-selection, and portions of drag/drop | Explicit TODOs in `Source/NSCollectionView.m`. |
| `NSPasteboardItem` | Modern item-provider/UTI interoperability | Source notes it is limited until pasteboard support is extended; no modern Uniform Type Identifier / item-provider bridge is present. |
| `NSBitmapImageRep` | BMP and JPEG 2000 representation paths | Runtime “not yet implemented” diagnostics in `Source/NSBitmapImageRep.m`. |
| `NSSetFocusRingStyle` | Focus-ring placement | `Source/Functions.m` logs “not implemented.” |

## Compatibility conclusion and priorities

For a portable application targeting the traditional GNUstep desktop model,
the classic application/window/view/control/menu/text/pasteboard APIs are the
appropriate compatibility target.  For source compatibility with contemporary
macOS applications, use availability guards and avoid assuming that a GNUstep
declaration implies matching behaviour.

Recommended implementation order:

1. Replace the stale OpenStep compliance page with a generated, test-backed
   audit; implement `NSReadPixel`, `NSCopyBitmapFromGState`, and focus-ring
   support if strict legacy compatibility is a goal.
2. Complete declared-but-stubbed APIs, starting with `NSToolbarItemGroup`,
   `NSTableView` indicator images, `NSCollectionView`, and pasteboard items.
3. Add the modern file-promise/dragging and diffable-data-source families.
4. Choose a TextKit 2 strategy.  It is the largest modern Cocoa source-
   compatibility gap and cannot be closed by adding isolated selectors.
5. Treat macOS 26 glass and writing-tools APIs as a separate platform-
   integration project after the foundational gaps above.

## Evidence locations

- Historical OpenStep ledger: `Documentation/General/OpenStepCompliance.gsdoc`.
- Public GNUstep AppKit umbrella: `Headers/AppKit/AppKit.h`.
- Legacy graphics stubs: `Source/Functions.m`.
- Incomplete toolbar group: `Source/NSToolbarItemGroup.m`.
- Incomplete table-view indicator methods: `Source/NSTableView.m`.
- Current Cocoa reference used: Xcode 26.3 macOS SDK AppKit headers at
  `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/AppKit.framework/Versions/C/Headers`.
