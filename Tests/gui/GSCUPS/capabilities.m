/* Real IPP attributes with controlled CUPS transport. No physical jobs are
   submitted. GSCUPS_TEST_URI optionally exercises discovery against a local
   IPP simulator; only the final spool submission remains intercepted. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#ifdef TEST_CUPS_IPP
#undef __BLOCKS__
#include <cups/cups.h>
#include <cups/ppd.h>
#include <cups/pwg.h>

#if CUPS_VERSION_MAJOR > 1 || (CUPS_VERSION_MAJOR == 1 && CUPS_VERSION_MINOR >= 7)
#define TEST_DESTINATIONS 1

static ipp_t *attributes;
static BOOL missingDestination, connectionFailure, queryFailure;
static BOOL mediaMissing, rejectOption, conflict, mediaVariant;
static BOOL requireCombinedOptions;
static int closed, freed, submitted;
static char token;
static const char *liveURI;
static NSDictionary *submittedOptions;

static cups_dest_t *
TestGetNamedDest(http_t *http, const char *name, const char *instance)
{
  cups_dest_t *dest = NULL;

  if (missingDestination)
    return NULL;
  if (liveURI != NULL)
    return cupsGetDestWithURI(name, liveURI);
  cupsAddDest(name, instance, 0, &dest);
  return dest;
}

static http_t *
TestConnect(cups_dest_t *dest, unsigned flags, int msec, int *cancel,
            char *resource, size_t length, cups_dest_cb_t cb, void *data)
{
  if (liveURI != NULL)
    return cupsConnectDest(dest, flags, msec, cancel, resource, length, cb, data);
  return connectionFailure ? NULL : (http_t *)&token;
}

static void
TestTimeout(http_t *http, double timeout, http_timeout_cb_t cb, void *data)
{
  if (liveURI != NULL)
    httpSetTimeout(http, timeout, cb, data);
}

static void
TestClose(http_t *http)
{
  closed++;
  if (liveURI != NULL)
    httpClose(http);
}

static cups_dinfo_t *
TestCopyInfo(http_t *http, cups_dest_t *dest)
{
  if (liveURI != NULL)
    return cupsCopyDestInfo(http, dest);
  return queryFailure ? NULL : (cups_dinfo_t *)&token;
}

static void
TestFreeInfo(cups_dinfo_t *info)
{
  freed++;
  if (liveURI != NULL)
    cupsFreeDestInfo(info);
}

static ipp_attribute_t *
TestSupported(http_t *http, cups_dest_t *dest, cups_dinfo_t *info, const char *option)
{
  char name[128];

  if (liveURI != NULL)
    return cupsFindDestSupported(http, dest, info, option);
  snprintf(name, sizeof(name), "%s-supported", option);
  return ippFindAttribute(attributes, name, IPP_TAG_ZERO);
}

static ipp_attribute_t *
TestDefault(http_t *http, cups_dest_t *dest, cups_dinfo_t *info, const char *option)
{
  char name[128];

  if (liveURI != NULL)
    return cupsFindDestDefault(http, dest, info, option);
  snprintf(name, sizeof(name), "%s-default", option);
  return ippFindAttribute(attributes, name, IPP_TAG_ZERO);
}

static int
TestMedia(http_t *http, cups_dest_t *dest, cups_dinfo_t *info, int n,
          unsigned flags, cups_size_t *size)
{
  if (liveURI != NULL)
    return cupsGetDestMediaByIndex(http, dest, info, n, flags, size);
  if (mediaMissing)
    return 0;
  memset(size, 0, sizeof(*size));
  strcpy(size->media, n == 0 ? "iso_a4_210x297mm" : "na_letter_8.5x11in");
  if (mediaVariant && n == 1)
    strcpy(size->media, "na_letter_8.5x11in_main_1");
  size->width = n == 0 ? 21000 : 21590;
  size->length = n == 0 ? 29700 : 27940;
  size->bottom = 1270;
  size->left = 635;
  size->right = 635;
  size->top = 1270;
  return 1;
}

static int
TestMediaDefault(http_t *http, cups_dest_t *dest, cups_dinfo_t *info,
                 unsigned flags, cups_size_t *size)
{
  if (liveURI != NULL)
    return cupsGetDestMediaDefault(http, dest, info, flags, size);
  return TestMedia(http, dest, info, 1, flags, size);
}

static int
TestMediaCount(http_t *http, cups_dest_t *dest, cups_dinfo_t *info, unsigned flags)
{
  if (liveURI != NULL)
    return cupsGetDestMediaCount(http, dest, info, flags);
  return mediaMissing ? 0 : 2;
}

static int
TestSupportedValue(http_t *http, cups_dest_t *dest, cups_dinfo_t *info,
                   const char *option, const char *value)
{
  if (liveURI != NULL)
    return cupsCheckDestSupported(http, dest, info, option, value);
  return !rejectOption;
}

static int
TestConflicts(http_t *http, cups_dest_t *dest, cups_dinfo_t *info, int count,
              cups_option_t *options, const char *option, const char *value,
              int *nc, cups_option_t **co, int *nr, cups_option_t **resolved)
{
  if (liveURI != NULL)
    return cupsCopyDestConflicts(http, dest, info, count, options, option, value,
                                nc, co, nr, resolved);
  if (requireCombinedOptions)
    return cupsGetOption("sides", count, options) == NULL
      || cupsGetOption("media", count, options) == NULL;
  return conflict;
}

static const char *
TestPPD(const char *name)
{
  return NULL;
}

#define GSCUPSPrinter CapabilityPrinter
#define GSCUPSDummyPrinterName CapabilityDummyName
#define cupsGetPPD TestPPD
#define cupsGetNamedDest TestGetNamedDest
#define cupsConnectDest TestConnect
#define httpSetTimeout TestTimeout
#define httpClose TestClose
#define cupsCopyDestInfo TestCopyInfo
#define cupsFreeDestInfo TestFreeInfo
#define cupsFindDestSupported TestSupported
#define cupsFindDestDefault TestDefault
#define cupsGetDestMediaDefault TestMediaDefault
#define cupsGetDestMediaCount TestMediaCount
#define cupsGetDestMediaByIndex TestMedia
#define cupsCheckDestSupported TestSupportedValue
#define cupsCopyDestConflicts TestConflicts
#include "../../../Printing/GSCUPS/GSCUPSPrinter.m"
#undef cupsCopyDestConflicts
#undef cupsCheckDestSupported
#undef cupsGetDestMediaByIndex
#undef cupsGetDestMediaCount
#undef cupsGetDestMediaDefault
#undef cupsFindDestDefault
#undef cupsFindDestSupported
#undef cupsFreeDestInfo
#undef cupsCopyDestInfo
#undef httpClose
#undef httpSetTimeout
#undef cupsConnectDest
#undef cupsGetNamedDest
#undef cupsGetPPD
#undef GSCUPSDummyPrinterName
#undef GSCUPSPrinter

static int
TestSubmit(const char *name, const char *path, const char *title,
           int count, cups_option_t *options)
{
  NSMutableDictionary *values = [NSMutableDictionary dictionary];
  int i;

  submitted++;
  for (i = 0; i < count; i++)
    [values setObject: [NSString stringWithUTF8String: options[i].value]
              forKey: [NSString stringWithUTF8String: options[i].name]];
  ASSIGNCOPY(submittedOptions, values);
  return 123;
}

#define GSCUPSPrintOperation CapabilityOperation
#define cupsPrintFile TestSubmit
#include "../../../Printing/GSCUPS/GSCUPSPrintOperation.m"
#undef cupsPrintFile
#undef GSCUPSPrintOperation

@interface CapabilityJob : CapabilityOperation

- (id) initWithPrinter: (NSPrinter *)printer features: (NSDictionary *)features;

@end

@implementation CapabilityJob

- (id) initWithPrinter: (NSPrinter *)printer features: (NSDictionary *)features
{
  self = [super init];
  if (self != nil)
    {
      _print_info = [[NSPrintInfo alloc] initWithDictionary:
        [NSDictionary dictionaryWithObjectsAndKeys: printer, NSPrintPrinter,
          features, NSPrintJobFeatures, @"Letter", NSPrintPaperName, nil]];
      ASSIGNCOPY(_path, @"/unused/test.ps");
    }
  return self;
}

- (NSPrintPanel *) printPanel
{
  return nil;
}

@end

static CapabilityPrinter *
Printer(void)
{
  return AUTORELEASE([[CapabilityPrinter alloc] initWithName: @"Test"
    withType: @"Test" withHost: @"localhost" withNote: @"Test"]);
}

static void
AddKeywords(const char *option, int count, const char **values, const char *def)
{
  char name[128];

  snprintf(name, sizeof(name), "%s-supported", option);
  ippAddStrings(attributes, IPP_TAG_PRINTER, IPP_TAG_KEYWORD, name, count, NULL, values);
  snprintf(name, sizeof(name), "%s-default", option);
  ippAddString(attributes, IPP_TAG_PRINTER, IPP_TAG_KEYWORD, name, NULL, def);
}

#endif
#endif

int
main(void)
{
  CREATE_AUTORELEASE_POOL(pool);
  START_SET("CUPS IPP capabilities")
#ifdef TEST_DESTINATIONS
  CapabilityPrinter *printer;
  NSDictionary *result;
  NSString *error = nil;
  NSSize size;
  NSRect rect;
  const char *sides[] = { "one-sided", "two-sided-long-edge", "two-sided-short-edge" };
  const char *colors[] = { "monochrome", "color" };
  const char *media[] = { "iso_a4_210x297mm", "na_letter_8.5x11in" };
  const char *sources[] = { "main", "manual" };
  const char *collation[] = { "separate-documents-collated-copies", "separate-documents-uncollated-copies" };
  int resolutions[] = { 300, 600 };
  NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:
    @"Letter", @"PageSize", @"DuplexNoTumble", @"Duplex", @"RGB", @"ColorModel",
    @"600dpi", @"Resolution", @"main", @"InputSlot", @"True", @"Collate", @"2", @"copies", nil];

  attributes = ippNew();
  AddKeywords("media", 2, media, media[1]);
  AddKeywords("sides", 3, sides, sides[1]);
  AddKeywords("print-color-mode", 2, colors, colors[0]);
  AddKeywords("media-source", 2, sources, sources[0]);
  AddKeywords("multiple-document-handling", 2, collation, collation[0]);
  ippAddResolutions(attributes, IPP_TAG_PRINTER, "printer-resolution-supported", 2,
                    IPP_RES_PER_INCH, resolutions, resolutions);
  ippAddResolution(attributes, IPP_TAG_PRINTER, "printer-resolution-default", IPP_RES_PER_INCH, 600, 600);
  mediaVariant = YES;
  printer = Printer();
  PASS([printer _loadIPPCapabilities], "discovery succeeds without a PPD");
  PASS(closed == 1 && freed == 1, "discovery releases its connection and destination info");
  PASS([[printer stringListForKey: @"PageSize" inTable: @"PPD"] count] == 2,
       "media variants are deduplicated using AppKit paper names");
  PASS([[printer stringForKey: @"DefaultPageSize" inTable: @"PPD"] isEqual: @"Letter"],
       "IPP default media is exposed to print info");
  size = [printer pageSizeForPaper: @"Letter"];
  rect = [printer imageRectForPaper: @"Letter"];
  PASS(fabs(size.width - 612) < 0.001 && fabs(size.height - 792) < 0.001,
       "IPP hundredths of millimeters convert to PostScript points");
  PASS(fabs(rect.origin.x - 18) < 0.001 && fabs(rect.origin.y - 36) < 0.001
       && fabs(rect.size.width - 576) < 0.001 && fabs(rect.size.height - 720) < 0.001,
       "imageable area includes the advertised margins");
  PASS([printer isColor], "color support is exposed through NSPrinter");
  PASS([[printer stringForKey: @"DefaultResolution" inTable: @"PPD"] isEqual: @"600dpi"],
       "resolution default reaches the existing resolution control");
  PASS([[printer stringForKey: @"DefaultDuplex" inTable: @"PPD"] isEqual: @"DuplexNoTumble"],
       "IPP duplex defaults use legacy feature references");
  result = [printer _cupsTranslateOptions: options error: &error];
  PASS([[result objectForKey: @"media"] isEqual: @"na_letter_8.5x11in"], "media keys with tray/margin suffixes map to supported IPP size names");
  PASS([[result objectForKey: @"sides"] isEqual: @"two-sided-long-edge"], "duplex maps back to IPP");
  PASS([[result objectForKey: @"print-color-mode"] isEqual: @"color"], "color maps back to IPP");
  PASS([[result objectForKey: @"printer-resolution"] isEqual: @"600x600dpi"], "resolution maps back to IPP");
  PASS([[result objectForKey: @"media-source"] isEqual: @"main"], "paper source maps back to IPP");
  PASS([[result objectForKey: @"multiple-document-handling"] isEqual: @"separate-documents-collated-copies"],
       "collation maps back to IPP");
  PASS([[result objectForKey: @"copies"] isEqual: @"2"] && [result objectForKey: @"PageSize"] == nil,
       "translation preserves copies without duplicating legacy media options");
  [options setObject: @"Unsupported" forKey: @"Duplex"];
  PASS([printer _cupsTranslateOptions: options error: &error] == nil && [error length] > 0,
       "an unsupported explicit choice fails with a reason");
  [options setObject: @"DuplexNoTumble" forKey: @"Duplex"];
  rejectOption = YES;
  PASS([printer _cupsTranslateOptions: options error: &error] == nil,
       "submission rechecks currently supported destination values");
  rejectOption = NO;
  conflict = YES;
  PASS([printer _cupsTranslateOptions: options error: &error] == nil,
       "conflicting job options are rejected");
  conflict = NO;
  requireCombinedOptions = YES;
  PASS([printer _cupsTranslateOptions: options error: &error] != nil,
       "conflict checking uses all explicit settings rather than intermediate defaults");
  requireCombinedOptions = NO;
  {
    NSMutableDictionary *features = [NSMutableDictionary dictionaryWithObjectsAndKeys:
      @"Duplex/DuplexTumble", @"Duplex", @"ColorModel/Gray", @"ColorModel", nil];
    CapabilityJob *job = [[CapabilityJob alloc] initWithPrinter: printer features: features];
    PASS([job _deliverSpooledResult], "operation submits translated IPP options");
    PASS([[submittedOptions objectForKey: @"sides"] isEqual: @"two-sided-short-edge"]
         && [[submittedOptions objectForKey: @"print-color-mode"] isEqual: @"monochrome"],
         "submission uses the selected duplex and color features");
    [features setObject: @"Duplex/invalid" forKey: @"Duplex"];
    [[[job printInfo] dictionary] setObject: features forKey: NSPrintJobFeatures];
    PASS(![job _deliverSpooledResult] && submitted == 1,
         "unsupported choices prevent transport submission, rather than being dropped");
    RELEASE(job);
  }
  connectionFailure = YES;
  PASS(![Printer() _loadIPPCapabilities], "connection failure leaves legacy capabilities usable");
  PASS([printer _cupsTranslateOptions: options error: &error] != nil,
       "refresh failure retains the previously discovered mapping");
  connectionFailure = NO;
  missingDestination = YES;
  PASS(![Printer() _loadIPPCapabilities], "a missing destination is handled");
  missingDestination = NO;
  queryFailure = YES;
  PASS(![Printer() _loadIPPCapabilities], "an unsuccessful IPP query is handled");
  queryFailure = NO;
  ippDelete(attributes);
  attributes = ippNew();
  mediaMissing = YES;
  printer = Printer();
  PASS(![printer _loadIPPCapabilities], "absent capabilities do not invent printer support");
  PASS([[printer _cupsTranslateOptions: options error: &error] isEqual: options],
       "destinations without IPP capabilities keep legacy options");
  {
    int cm[] = { 118, 236 }, y[] = { 118, 118 };
    ippAddResolutions(attributes, IPP_TAG_PRINTER, "printer-resolution-supported", 2, IPP_RES_PER_CM, cm, y);
    ippAddResolution(attributes, IPP_TAG_PRINTER, "printer-resolution-default", IPP_RES_PER_CM, 236, 118);
    PASS([printer _loadIPPCapabilities], "resolution-only destinations are supported");
    PASS([[printer stringForKey: @"DefaultResolution" inTable: @"PPD"] isEqual: @"599x300dpi"],
         "non-square dpcm resolution converts to display dpi");
    result = [printer _cupsTranslateOptions:
      [NSDictionary dictionaryWithObject: @"599x300dpi" forKey: @"Resolution"] error: &error];
    PASS([[result objectForKey: @"printer-resolution"] isEqual: @"236x118dpcm"],
         "submission preserves the exact original resolution units");
  }
  ippDelete(attributes);
  attributes = ippNew();
  printer = Printer();
  {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:
      [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension: @"ppd"]];
    NSString *ppd = @"*PPD-Adobe: \"4.3\"\n"
      @"*DefaultResolution: 1200dpi\n"
      @"*Resolution 1200dpi: \"\"\n"
      @"*DefaultPageSize: Letter\n"
      @"*PageSize Letter: \"\"\n"
      @"*PaperDimension Letter: \"612 792\"\n"
      @"*VendorFeature Staple: \"\"\n";
    [ppd writeToFile: path atomically: YES];
    PASS([printer parsePPDAtPath: path], "legacy PPD fixture is parsed");
    [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
    ippAddInteger(attributes, IPP_TAG_PRINTER, IPP_TAG_INTEGER, "printer-resolution-supported", 42);
    AddKeywords("sides", 3, sides, sides[0]);
    PASS([printer _loadIPPCapabilities], "partial IPP discovery augments a legacy PPD");
    PASS([[printer stringForKey: @"DefaultResolution" inTable: @"PPD"] isEqual: @"1200dpi"],
         "malformed IPP resolution retains the PPD default");
    PASS([[printer stringListForKey: @"VendorFeature" inTable: @"PPD"] containsObject: @"Staple"],
         "IPP discovery retains vendor-specific PPD features");
    PASS([[printer stringForKey: @"DefaultPageSize" inTable: @"PPD"] isEqual: @"Letter"],
         "missing IPP media retains PPD paper settings");
  }
  ippDelete(attributes);
  liveURI = getenv("GSCUPS_TEST_URI");
  if (liveURI != NULL)
    {
      printer = (CapabilityPrinter *)[CapabilityPrinter printerWithName: @"Simulator"];
      PASS([[printer stringListForKey: @"PageSize" inTable: @"PPD"] count] > 0,
           "live IPP simulator supplies media without a PPD");
      PASS([printer _cupsSupportsIPPOption: @"Resolution"], "live IPP simulator supplies resolution");
      result = [printer _cupsTranslateOptions: [NSDictionary dictionaryWithObjectsAndKeys:
        [printer stringForKey: @"DefaultPageSize" inTable: @"PPD"], @"PageSize",
        [printer stringForKey: @"DefaultResolution" inTable: @"PPD"], @"Resolution", nil] error: &error];
      PASS(result != nil, "live CUPS capability checking accepts simulator defaults");
      NSLog(@"Simulator defaults: %@ (%@)", result, error);
      result = [printer _cupsTranslateOptions: [NSDictionary dictionaryWithObjectsAndKeys:
        @"DuplexNoTumble", @"Duplex", @"RGB", @"ColorModel", @"2", @"copies", nil] error: &error];
      PASS(result != nil, "live CUPS accepts supported duplex, color, and copies");
      result = [printer _cupsTranslateOptions:
        [NSDictionary dictionaryWithObject: @"99999999" forKey: @"copies"] error: &error];
      PASS(result == nil, "live CUPS rejects a copy count outside the destination range");
    }
  DESTROY(submittedOptions);
#else
  SKIP("CUPS 1.7+ development files are required (cups-config or GSCUPS_TEST_LIBS)");
#endif
  END_SET("CUPS IPP capabilities")
  RELEASE(pool);
  return 0;
}

