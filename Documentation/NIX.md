# Native Interface XML (NIX)

NIX is a text representation of a native GNUstep interface object graph. It is an
XML property list rather than an XML dialect: standard property-list tools can
read it, and its nested object definitions keep related UI objects together in
source control.  The format is intentionally not compatible with Apple's XIB.

## Document structure

The root dictionary contains:

- `format`: the string `NIX`.
- `version`: currently the integer `1`.
- `objects`: object definitions. Definitions may be nested in property values.
- `topLevelObjects`: references identifying the objects returned to the caller.

Object definitions may contain a `connections` array immediately after their
properties. A connection is stored with its source object. If its source is an
external object (`owner` or `application`), it is stored with its destination.

An object definition has `$id`, `$class`, and an optional `properties`
dictionary. The loader creates every object first and applies properties in a
second pass, so forward references and cycles are valid. A reference is a
dictionary containing `$ref`; the reserved ids `owner` and `application` refer
to the nib owner and `NSApp`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>format</key><string>NIX</string>
  <key>version</key><integer>1</integer>
  <key>objects</key>
  <array>
    <dict>
      <key>$id</key><string>window</string>
      <key>$class</key><string>NSWindow</string>
      <key>properties</key>
      <dict>
        <key>title</key><string>Hello</string>
        <key>contentView</key>
        <dict>
          <key>$id</key><string>content</string>
          <key>$class</key><string>NSView</string>
          <key>properties</key>
          <dict>
            <key>frame</key>
            <dict><key>$type</key><string>rect</string>
                  <key>$value</key><string>{0, 0, 480, 320}</string></dict>
          </dict>
        </dict>
      </dict>
      <key>connections</key>
      <array>
        <dict>
          <key>kind</key><string>outlet</string>
          <key>source</key><dict><key>$ref</key><string>owner</string></dict>
          <key>destination</key><dict><key>$ref</key><string>window</string></dict>
          <key>label</key><string>window</string>
        </dict>
      </array>
    </dict>
  </array>
  <key>topLevelObjects</key>
  <array><dict><key>$ref</key><string>window</string></dict></array>
</dict>
</plist>
```

Property values can be strings, numbers, booleans, data, dates, arrays, literal
dictionaries, references, nested definitions, or typed values. Typed values
use `$type` and `$value`; version 1 supports `rect`, `point`, `size`, `range`,
and `selector`. Properties are applied with key-value coding, so their names
are the object's normal Cocoa property names.

Connections have `kind` (`outlet` or `action`), `source`, `destination`, and
`label`. Keeping them beside the participating object makes changes to a view
and its wiring appear in the same area of a diff. After all properties and
connections are established, the loader sends `awakeFromNib` to each defined
object in document order. The loader also accepts the earlier document-level
`connections` array for compatibility, but the writer never produces it.

NIX files use the `.nix` extension and load through `NSBundle` and `NSNib` in
the same way as `.gorm`, `.nib`, and `.xib` resources.

## Writing NIX

`GSNixSerialization` produces NIX XML from a live object graph. By default it
examines the methods declared by every class in the inheritance chain and
matches `setFoo:` with a `foo` or `isFoo` getter. These pre-`@property` KVC
pairs make ordinary GNUstep widgets and application-specific classes
self-describing without relying on Objective-C property metadata.

The optional key/value metadata is for classes with special persistence
semantics. Each mapping key is the property name written to NIX and its value
is the KVC key used to read the live object. An explicit mapping replaces
inference for the methods declared by that class, while inherited classes are
handled independently. Unsupported values cause serialization to fail rather
than silently dropping state.

```objc
NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:
  [NSDictionary dictionaryWithObjectsAndKeys:
    @"title", @"title", @"contentView", @"contentView", nil], @"NSWindow",
  [NSDictionary dictionaryWithObjectsAndKeys:
    @"frame", @"frame", @"subviews", @"subviews", nil], @"NSView",
  [NSDictionary dictionaryWithObjectsAndKeys:
    @"frame", @"frame", @"title", @"title", nil], @"NSButton",
  nil];
NSString *error = nil;
NSData *data = [GSNixSerialization
  dataWithTopLevelObjects: [NSArray arrayWithObject: window]
  keyValuePairs: properties
  connections: connections
  errorDescription: &error];
```

Passing an empty metadata dictionary enables inference for every class. The
full API also accepts an `excludedKeys` dictionary mapping class names to
arrays of transient inferred keys. Exclusions accumulate through inheritance.
NIX always excludes common graph back-references and runtime collaborators:
`superview`, `window`, `nextResponder`, `undoManager`, `delegate`,
`dataSource`, `target`, editors, first-responder state, graphics contexts, and
live-resize state. Keys beginning with `needs` are also excluded because they
represent pending display, layout, or constraint work rather than persistent
model state. An explicit key/value mapping can opt a built-in exclusion back
in when that name has persistent meaning for a particular class. Entries in
`excludedKeys` remain authoritative and cannot be opted back in accidentally.
A class with other transient state should list it explicitly rather than
allowing it into the archive.

The writer embeds an object definition at its first occurrence and emits a
reference thereafter. This preserves shared objects and cycles while retaining
the window/view hierarchy in the XML. Class mappings apply to subclasses when
there is no more-specific entry. Connection endpoints must already occur in
the encoded graph; use the strings `owner` and `application` for the reserved
external endpoints.

NIX output is canonical for source-control use. Schema keys have a fixed
order, other dictionary keys and archived property names are sorted, and
connections are sorted by source, kind, label, and destination. Arrays retain
their input order because they normally express semantic UI order (for example,
the order of subviews or top-level objects). Equivalent graphs therefore do
not acquire noisy XML changes merely because a dictionary or connection list
was assembled in a different order.
