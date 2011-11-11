/**
 * Collection of font descriptors
 */
@interface CTFontCollection : NSObject
{
  NSArray *_descriptors;
}

- (id)initWithAvailableFontsWithOptions: (NSDictionary*)opts;
- (id)initWithFontDescriptors: (NSArray*)descriptors options: (NSDictionary*)opts;

- (CTFontCollection*)collectionByAddingFontDescriptors: (NSArray*)descriptors
                                               options: (NSDictionary*)opts;
- (NSArray*)fontDescriptors;
- (NSArray*)fontDescriptorsSortedWithCallback: (CTFontCollectionSortDescriptorsCallback)cb
                                         info: (void*)info;

@end

@implementation CTFontCollection

- (id)initWithAvailableFonts
{

  FcPattern *pat = FcPatternCreate();

  // Request all of the attributes we are interested in
  FcObjectSet *os = FcObjectSetBuild(
		FC_FILE,
    FC_FAMILY,
    FC_FULLNAME,
    FC_STYLE,
    FC_SLANT,
    FC_WEIGHT,
    FC_WIDTH,
    FC_SPACING,
    FC_SIZE,
    FC_MATRIX,
    FC_CHARSET,
    FC_LANG,
    FC_VERTICAL_LAYOUT,
    FC_OUTLINE,
    NULL);

  FcFontSet *fs = FcFontList(NULL, pat, os);
  FcPatternDestroy(pat);
  FcObjectSetDestroy(os);


}

- (id)initWithFontDescriptors: (NSArray*)descriptors options: (NSDictionary*)opts
{
  self = [super init];
  if (nil == self)
  {
    return nil;
  }

  if ([[opts objectForKey: kCTFontCollectionRemoveDuplicatesOption] boolValue])
  {
    // FIXME: relies on CTFontDescriptors behaving properly in sets (-hash/-isEqual:)
    _descriptors = [[[NSSet setWithArray: descriptors] allObjects] retain];
  }
  else
  {
    _descriptors = [descriptors copy];
  }
  return self;
}
- (CTFontCollection*)collectionByAddingFontDescriptors: (NSArray*)descriptors
                                               options: (NSDictionary*)opts
{
  NSArray *newDescriptors = [_descriptors arrayByAddingObjectsFromArray: descriptors];
  CTFontCollection *collection = [[CTFontCollection alloc] initWithFontDescriptors: newDescriptors
                                                                           options: opts];
  return [collection autorelease];
}
- (NSArray*)fontDescriptors
{
  return _descriptors;
}
- (NSArray*)fontDescriptorsSortedWithCallback: (CTFontCollectionSortDescriptorsCallback)cb
                                         info: (void*)info
{
  return [_descriptors sortedArrayUsingFunction: cb context: info];
}

@end
