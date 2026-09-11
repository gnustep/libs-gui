#!/usr/bin/env python3
"""Generate small, original binary typedstream fixtures; no XML dependency.

The writer intentionally emits literal classes and type strings.  Object
back-references still share the class/object numbering space, including cycles.
Run from this directory to regenerate the checked-in fixtures.
"""
from pathlib import Path
import struct


class Obj:
    def __init__(self, classes, groups=()):
        self.classes = classes + [("NSObject", 0)]
        self.groups = list(groups)


def string(s):
    return Obj([("NSString", 1)], [("+", [s.encode("ascii")])])


def array(items):
    return Obj([("NSMutableArray", 0), ("NSArray", 0)],
               [("i", [len(items)])] + [("@", [o]) for o in items])


class Writer:
    def __init__(self, endian, version):
        self.order = endian
        self.data = bytearray([version, 11])
        self.data += b"streamtyped" if endian == "<" else b"typedstream"
        self.slots = 0
        self.objects = {}
        self.integer(1000)

    def integer(self, n):
        if -110 <= n <= 127:
            self.data.append(n & 255)
        elif -32768 <= n <= 32767:
            self.data += b"\x81" + struct.pack(self.order + "h", n)
        else:
            self.data += b"\x82" + struct.pack(self.order + "I", n & 0xffffffff)

    def text(self, b):
        self.integer(len(b))
        self.data += b

    def shared(self, s):
        if s is None:
            self.data.append(0x85)
        else:
            self.data.append(0x84)
            self.text(s.encode("ascii"))

    def object(self, o):
        if o is None:
            self.data.append(0x85)
            return
        if id(o) in self.objects:
            self.integer(self.objects[id(o)] - 110)
            return
        self.objects[id(o)] = self.slots
        self.slots += 1
        self.data.append(0x84)
        for name, version in o.classes:
            self.data.append(0x84)
            self.slots += 1
            self.shared(name)
            self.integer(version)
        self.data.append(0x85)
        for encoding, values in o.groups:
            self.group(encoding, values)
        self.data.append(0x86)

    def group(self, encoding, values):
        self.shared(encoding)
        assert len(encoding) == len(values)
        for typ, value in zip(encoding, values):
            if typ == "@":
                self.object(value)
            elif typ == "+":
                self.text(value)
            elif typ == ":":
                self.shared(value)
            elif typ in "cC":
                self.data.append(value & 255)
            elif typ in "iIsS":
                self.integer(value)
            elif typ == "f":
                self.data += b"\x83" + struct.pack(self.order + "f", value)
            else:
                raise ValueError(typ)


def document(views=False, bad_version=False):
    owner = Obj([("NSCustomObject", 41)], [("@@", [string("NSObject"), None])])
    custom = Obj([("NSCustomObject", 41)],
                 [("@@", [string("OpenStepTestObject"), None])])
    objects = [(custom, owner)]
    connections = [Obj([("NSIBOutletConnector", 0), ("NSIBConnector", 17)],
                       [("@@@", [owner, custom, string("object")])])]
    if views:
        cell = Obj([("NSButtonCell", 57), ("NSActionCell", 17), ("NSCell", 60)],
                   [("ii", [0x0401fe00, 0x08000000]),
                    ("@@@@", [string("Run"), None, None, None]),
                    ("i:", [17, None]), ("@", [None]), ("@", [None]),
                    ("ssIi@@@@@", [200, 25, 0, 0x86824000,
                                    string(""), string(""), None, None, None])])
        button = Obj([("NSButton", 0), ("NSControl", 41), ("NSView", 41),
                      ("NSResponder", 0)])
        view = Obj([("NSView", 41), ("NSResponder", 0)])
        button.groups = [("@", [view]), ("i", [0]),
                         ("@@@@ffffffff", [array([]), None, None, None,
                          12.5, 18.25, 90, 24, 0, 0, 90, 24]),
                         ("@", [view]), ("@", [None]), ("@", [None]),
                         ("@", [None]), ("icc@", [23, 0, 0, cell])]
        cell.groups[4] = ("@", [button])  # cyclic control-view reference
        view.groups = [("@", [None]), ("i", [0]),
                       ("@@@@ffffffff", [array([button]), None, None, None,
                        0, 0, 240, 100, 0, 0, 240, 100]),
                       ("@", [None]), ("@", [None]), ("@", [None]), ("@", [None])]
        window = Obj([("NSWindowTemplate", 41)],
                     [("iiffffi@@@@@c", [3, 2, 100, 100, 240, 100, 0x40000000,
                       string("OPENSTEP fixture"), string("NSWindow"),
                       string("View"), view, None, 1]),
                      ("ffff", [0, 0, 1024, 768]), ("c", [0])])
        objects += [(window, owner), (view, window), (button, view)]
        for target, label in [(window, "window"), (button, "button"), (button, "alias")]:
            connections.append(Obj([("NSIBOutletConnector", 0), ("NSIBConnector", 17)],
                                   [("@@@", [owner, target, string(label)])]))
        connections.append(Obj([("NSIBControlConnector", 0), ("NSIBConnector", 17)],
                               [("@@@", [cell, owner, string("run:")])]))
    names = [(owner, string("File's Owner"))]
    ids = [(owner, 1)] + [(obj, i + 2) for i, (obj, _) in enumerate(objects)]
    return Obj([("NSIBObjectData", 999 if bad_version else 24)],
               [("@", [owner]), ("i", [len(objects)])]
               + [("@@", pair) for pair in objects]
               + [("i", [len(names)])] + [("@@", pair) for pair in names]
               + [("@", [Obj([("NSMutableSet", 0), ("NSSet", 0)], [("I", [0])])]),
                  ("@", [array(connections)]), ("@", [None]), ("i", [len(ids)])]
               + [("@i", pair) for pair in ids] + [("i", [100]), ("i", [0])])


if __name__ == "__main__":
    out = Path(__file__).parent / "OpenStepFixtures"
    out.mkdir(exist_ok=True)
    for version in (3, 4):
        for order, suffix in (("<", "le"), (">", "be")):
            for views in (False, True):
                writer = Writer(order, version)
                writer.group("@", [document(views)])
                name = f"{'window' if views else 'objects'}-v{version}-{suffix}.nib"
                (out / name).write_bytes(writer.data)
    writer = Writer("<", 4)
    writer.group("@", [document(bad_version=True)])
    (out / "unsupported-version.nib").write_bytes(writer.data)
