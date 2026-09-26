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
external object (`owner`, `application`, or `firstResponder`), it is stored
with its destination.

An object definition has `$id`, `$class`, and an optional `properties`
dictionary. New definitions normally have `$coding` set to `keyed`; their
properties are the values emitted by the class's `encodeWithCoder:` method.
`$classVersions` records the keyed-coding versions used during decoding.
`$codingClass` records an archive replacement class, such as
`NSWindowTemplate`, without changing the object's public `$class` or identity.
`$superclass` records the concrete design-time superclass used
when an application-specific class is unavailable to an interface editor. The
loader creates every object first and applies properties in a
second pass, so forward references and cycles are valid. A reference is a
dictionary containing `$ref`; the reserved ids `owner`, `application`, and
`firstResponder` refer to the nib owner, `NSApp`, and a nil action target.

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
`selector`, and `color`. Colors preserve named catalog colors or calibrated
RGBA components. Keyed definitions are reconstructed with `initWithCoder:`;
their property names are archive keys and need not be KVC-compliant. Definitions
without `$coding` are version-1 legacy objects and continue to apply their
properties with key-value coding.

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
uses each object's keyed `NSCoding` implementation. A NIX-specific `NSCoder`
records `encodeObject:forKey:`, keyed scalar and geometry calls, conditional
objects, and class versions into the normal NIX properties dictionary. The
inverse coder presents those values to `initWithCoder:`. Consequently AppKit's
existing archive contract decides which state is persistent; NIX does not
guess from accessor names or require archive keys to be KVC properties.

The surrounding version-1 representation is unchanged: first occurrences are
nested definitions, later occurrences are `$ref` dictionaries, and connections
remain object-local. Existing NIX files without a `$coding` marker retain their
legacy KVC decoding behavior. `NSWindow` follows AppKit's normal keyed archive
replacement rule and records `NSWindowTemplate` as its `$codingClass` while
remaining an `NSWindow` definition.

The optional key/value metadata is a compatibility path for custom classes
that do not implement keyed `NSCoding`. Each mapping key is the property name
written to NIX and its value is the KVC key used to read the live object.
Mappings accumulate through the inheritance chain. A non-coding object without
an explicit mapping is rejected rather than having arbitrary accessors guessed
or silently omitted.

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

Passing an empty metadata dictionary selects keyed coding for objects that
support it. The full API also accepts an `excludedKeys` dictionary for the
explicit KVC compatibility path; exclusions accumulate through inheritance.
Keyed definitions are not filtered because their class's `encodeWithCoder:`
implementation is authoritative.

The writer embeds an object definition at its first occurrence and emits a
reference thereafter. This preserves shared objects and cycles while retaining
the window/view hierarchy in the XML. Class mappings apply to subclasses when
there is no more-specific entry. Connection endpoints must already occur in
the encoded graph; use the strings `owner`, `application`, and
`firstResponder` for the reserved external endpoints.

NIX output is canonical for source-control use. Schema keys have a fixed
order, other dictionary keys and archived property names are sorted, and
connections are sorted by source, kind, label, and destination. Arrays retain
their input order because they normally express semantic UI order (for example,
the order of subviews or top-level objects). Equivalent graphs therefore do
not acquire noisy XML changes merely because a dictionary or connection list
was assembled in a different order.

## Persistent object identity

Object IDs are independent of traversal and hierarchy position. The loader
associates each archived ID with its instantiated object, and later writes of
that object preserve the same ID. A design tool may assign a meaningful ID
with `+[GSNixSerialization setIdentifier:forObject:]` or pass an identity-keyed
`NSMapTable` to the full serialization method. Caller-supplied IDs take
precedence over loader-preserved IDs. Objects without either receive a UUID
once, which is then retained as their serialization identity.

The reserved IDs `owner`, `application`, and `firstResponder`, empty IDs, and
duplicate IDs are rejected. IDs are never derived from array position or object contents, so
inserting, deleting, or reordering a view does not rename unaffected objects
or rewrite their connections.

## Editing custom classes in Gorm

When `+[NSClassSwapper isInInterfaceBuilder]` is true, an unavailable `$class`
is represented by an instance of its recorded `$superclass`. The placeholder
retains the intended class name, persistent ID, properties it cannot apply,
and object-local connections. Writing the document restores that metadata
rather than substituting the placeholder's runtime class.

For known classes, editor mode honors the existing `+allocSubstitute` design
tool hook. This lets interface editors instantiate their editable window,
menu, and control subclasses while the NIX document continues to name the
runtime AppKit classes.

An editor may also pass a runtime-class-name to substitute-class-name
dictionary under `GSNixClassSubstitutions` in the loader's external name
table. This is the authoritative mechanism for palette-provided replacement
classes; `+allocSubstitute` remains the fallback for classes not in the map.

Editor mode does not establish outlets or actions and does not send
`awakeFromNib`; those operations remain application-runtime behavior. Outside
editor mode, a missing custom class is still an error so applications cannot
silently run with an unintended superclass.
