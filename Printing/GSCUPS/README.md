# CUPS capabilities

With CUPS 1.7 or newer, `GSCUPSPrinter` queries destination information as well
as reading the legacy PPD. It exposes advertised media sizes and margins,
resolution, duplex, color modes, paper sources, and collation using the existing
`NSPrinter` table API. Missing or malformed attributes leave the corresponding
PPD capability intact. Older CUPS builds use the PPD path alone.

The existing page-layout and print panels consume the media, resolution, and
paper-source tables. Applications can select duplex and color through
`NSPrintJobFeatures`, using the references in those tables; for example,
`Duplex/DuplexNoTumble` and `ColorModel/Gray`. This change does not add new panel
controls. IPP defaults are exposed as `DefaultPageSize`, `DefaultResolution`,
`DefaultDuplex`, and the other corresponding default keys.

The backend translates selected features into `media`, `printer-resolution`,
`sides`, `print-color-mode`, `media-source`, and `multiple-document-handling`
options. It refreshes destination information before submission and checks
advertised supported values and CUPS option conflicts. Invalid selections fail
with a status message rather than silently selecting a different value. When a
refresh fails, the discovery snapshot remains usable and normal CUPS submission
reports transport failures. Vendor PPD options remain available. Layout already
performed by GNUstep is not forwarded for a second application by CUPS.

Discovery connects to the CUPS destination with a five-second connection limit
and a five-second HTTP I/O timeout. Queue destinations use the scheduler's
capabilities, including its document conversion support. Jobs continue through
`cupsPrintFile`, preserving CUPS filtering; this is not direct raw submission to
a physical driverless device.

Media variants sharing the same dimensions use one AppKit paper name, preferring
the default variant's margins. The panel does not separately expose borderless
or tray-specific margin variants. Resolution display uses dpi while submission
preserves the destination's original resolution units.

## Tests

From `Tests`, run `gnustep-tests gui/GSCUPS` with the usual uninstalled GUI build
environment. The test uses real IPP attribute objects and controlled transport,
covering translation, margins, default values, conflicts, unsupported options,
PPD fallback, absent attributes, and connection failures. No printer is needed.
`cups-config` supplies the CUPS build flags. Alternatively, set
`GSCUPS_TEST_LIBS` and `ADDITIONAL_INCLUDE_DIRS` for unpacked development files.
Without CUPS development support the test explicitly skips.

For an optional integration check, start an isolated simulator:

```
ippeveprinter -p 18631 -n localhost -r off -2 -s 20,10 \
  -f application/pdf,application/postscript 'GNUstep IPP Test'
```

Then run the test with `GSCUPS_TEST_URI=ipp://localhost:18631/ipp/print`.
It performs real destination discovery and capability validation against the
simulator; job submission remains intercepted. It does not create a system
printer queue or send physical print jobs.
