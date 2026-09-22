# Native Interface Format (NIF)

NIF is a text representation of a native GNUstep interface object graph. It is an
XML property list rather than an XML dialect: standard property-list tools can
read it, and its nested object definitions keep related UI objects together in
source control.  The format is intentionally not compatible with Apple's XIB.

## Document structure

The root dictionary contains:

- `format`: the string `NIF`.
- `version`: currently the integer `1`.
- `objects`: object definitions. Definitions may be nested in property values.
- `topLevelObjects`: references identifying the objects returned to the caller.
- `connections`: optional outlet and action connection dictionaries.

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
  <key>format</key><string>NIF</string>
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
    </dict>
  </array>
  <key>topLevelObjects</key>
  <array><dict><key>$ref</key><string>window</string></dict></array>
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
</plist>
```

Property values can be strings, numbers, booleans, data, dates, arrays, literal
dictionaries, references, nested definitions, or typed values. Typed values
use `$type` and `$value`; version 1 supports `rect`, `point`, `size`, `range`,
and `selector`. Properties are applied with key-value coding, so their names
are the object's normal Cocoa property names.

Connections have `kind` (`outlet` or `action`), `source`, `destination`, and
`label`. After properties and connections are established, the loader sends
`awakeFromNib` to each defined object in document order.

NIF files use the `.nif` extension and load through `NSBundle` and `NSNib` in
the same way as `.gorm`, `.nib`, and `.xib` resources.

## Writing NIF

`GSNifSerialization` produces NIF XML from a live object graph. The caller
supplies the KVC properties that constitute the archive representation of each
class. Requiring an explicit property list avoids accidentally serializing
private framework state and keeps generated files stable as implementations
change.

```objc
NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:
  [NSArray arrayWithObjects: @"title", @"contentView", nil], @"NSWindow",
  [NSArray arrayWithObjects: @"frame", @"subviews", nil], @"NSView",
  [NSArray arrayWithObjects: @"frame", @"title", nil], @"NSButton",
  nil];
NSString *error = nil;
NSData *data = [GSNifSerialization
  dataWithTopLevelObjects: [NSArray arrayWithObject: window]
  propertyKeys: properties
  connections: connections
  errorDescription: &error];
```

The writer embeds an object definition at its first occurrence and emits a
reference thereafter. This preserves shared objects and cycles while retaining
the window/view hierarchy in the XML. Class mappings apply to subclasses when
there is no more-specific entry. Connection endpoints must already occur in
the encoded graph; use the strings `owner` and `application` for the reserved
external endpoints.

NIF output is canonical for source-control use. Schema keys have a fixed
order, other dictionary keys and archived property names are sorted, and
connections are sorted by source, kind, label, and destination. Arrays retain
their input order because they normally express semantic UI order (for example,
the order of subviews or top-level objects). Equivalent graphs therefore do
not acquire noisy XML changes merely because a dictionary or connection list
was assembled in a different order.
