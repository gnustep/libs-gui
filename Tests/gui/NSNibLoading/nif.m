#import "ObjectTesting.h"

#import <Foundation/Foundation.h>
#import <AppKit/NSNib.h>
#import <GNUstepGUI/GSModelLoaderFactory.h>
#import "../../../Headers/Additions/GNUstepGUI/GSNifSerialization.h"

/* Keep a non-tagged constant-string section with older ELF Objective-C
 * linkers; all literals in this small test can otherwise be optimized into
 * tagged strings while the runtime module still references section bounds. */
static NSString *NifTestLinkerString __attribute__((used)) = @"NIF loader test fixture";

@interface NifTestNode : NSObject
{
  NSString *_name;
  NifTestNode *_child;
  NifTestNode *_peer;
  BOOL _awakened;
}
- (NSString *) name;
- (void) setName: (NSString *)value;
- (NifTestNode *) child;
- (void) setChild: (NifTestNode *)value;
- (NifTestNode *) peer;
- (void) setPeer: (NifTestNode *)value;
- (BOOL) awakened;
@end

@implementation NifTestNode
- (void) dealloc
{
  [_name release];
  [_child release];
  [_peer release];
  [super dealloc];
}
- (NSString *) name { return _name; }
- (void) setName: (NSString *)value { ASSIGN(_name, value); }
- (NifTestNode *) child { return _child; }
- (void) setChild: (NifTestNode *)value { ASSIGN(_child, value); }
- (NifTestNode *) peer { return _peer; }
- (void) setPeer: (NifTestNode *)value { ASSIGN(_peer, value); }
- (void) awakeFromNib { _awakened = YES; }
- (BOOL) awakened { return _awakened; }
@end

@interface NifTestOwner : NSObject
{
  NifTestNode *_node;
}
- (NifTestNode *) node;
- (void) setNode: (NifTestNode *)value;
@end

@implementation NifTestOwner
- (void) dealloc { [_node release]; [super dealloc]; }
- (NifTestNode *) node { return _node; }
- (void) setNode: (NifTestNode *)value { ASSIGN(_node, value); }
@end

int main(void)
{
  NSData *data = [NSData dataWithContentsOfFile: @"Test.nif"];
  GSModelLoader *loader = [GSModelLoaderFactory modelLoaderForData: data];
  NSMutableArray *topLevel = [NSMutableArray array];
  NifTestOwner *owner = [[NifTestOwner alloc] init];
  NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:
    owner, NSNibOwner, topLevel, NSNibTopLevelObjects, nil];
  BOOL loaded;
  NifTestNode *root;
  NifTestNode *child;
  NSData *encoded;
  NSData *canonicalA;
  NSData *canonicalB;
  NSString *encodedString;
  NSString *error = nil;

  START_SET("NIF loading and writing")
  PASS(data != nil, "the NIF fixture can be read")
  PASS([[loader class] type] != nil && [[[loader class] type] isEqual: @"nif"],
       "the model loader factory recognizes NIF data")

  loaded = [loader loadModelData: data externalNameTable: context withZone: NULL];
  PASS(loaded, "the NIF document loads")
  PASS([topLevel count] == 1, "one top-level object is returned")

  root = [topLevel objectAtIndex: 0];
  child = [root child];
  PASS([[root name] isEqual: @"root"] && [[child name] isEqual: @"child"],
       "nested definitions and properties are decoded")
  PASS([child peer] == root, "references preserve identity and allow cycles")
  PASS([owner node] == root, "outlet connections to the owner are established")
  PASS([root awakened] && [child awakened], "awakeFromNib is sent after connections")

  encoded = [GSNifSerialization
    dataWithTopLevelObjects: [NSArray arrayWithObject: root]
    propertyKeys: [NSDictionary dictionaryWithObject:
      [NSArray arrayWithObjects: @"name", @"child", @"peer", nil]
      forKey: @"NifTestNode"]
    connections: [NSArray arrayWithObject:
      [NSDictionary dictionaryWithObjectsAndKeys:
        @"outlet", @"kind", @"owner", @"source", root, @"destination",
        @"node", @"label", nil]]
    errorDescription: &error];
  PASS(encoded != nil && error == nil, "the framework produces NIF data")
  encodedString = [[[NSString alloc] initWithData: encoded
                                          encoding: NSUTF8StringEncoding] autorelease];
  PASS([encodedString rangeOfString: @"<string>NIF</string>"].location != NSNotFound,
       "produced data is readable XML and identifies itself as NIF")
  {
    NSPropertyListFormat plistFormat;
    NSDictionary *writtenDocument = [NSPropertyListSerialization
      propertyListFromData: encoded
          mutabilityOption: NSPropertyListImmutable
                    format: &plistFormat
          errorDescription: NULL];
    NSDictionary *writtenRoot = [[writtenDocument objectForKey: @"objects"]
      objectAtIndex: 0];
    PASS([writtenDocument objectForKey: @"connections"] == nil
         && [[writtenRoot objectForKey: @"connections"] count] == 1,
         "connections are written beside their participating object")
  }

  {
    NSDictionary *firstConnection = [NSDictionary dictionaryWithObjectsAndKeys:
      @"outlet", @"kind", @"owner", @"source", root, @"destination",
      @"zOutlet", @"label", nil];
    NSMutableDictionary *secondConnection = [NSMutableDictionary dictionary];
    [secondConnection setObject: @"aOutlet" forKey: @"label"];
    [secondConnection setObject: root forKey: @"destination"];
    [secondConnection setObject: @"owner" forKey: @"source"];
    [secondConnection setObject: @"outlet" forKey: @"kind"];
    canonicalA = [GSNifSerialization
      dataWithTopLevelObjects: [NSArray arrayWithObject: root]
      propertyKeys: [NSDictionary dictionaryWithObject:
        [NSArray arrayWithObjects: @"peer", @"name", @"child", nil]
        forKey: @"NifTestNode"]
      connections: [NSArray arrayWithObjects: firstConnection, secondConnection, nil]
      errorDescription: NULL];
    canonicalB = [GSNifSerialization
      dataWithTopLevelObjects: [NSArray arrayWithObject: root]
      propertyKeys: [NSDictionary dictionaryWithObject:
        [NSArray arrayWithObjects: @"child", @"name", @"peer", nil]
        forKey: @"NifTestNode"]
      connections: [NSArray arrayWithObjects: secondConnection, firstConnection, nil]
      errorDescription: NULL];
    PASS([canonicalA isEqual: canonicalB],
         "property, dictionary, and connection insertion order does not change NIF output")
  }

  if (encoded != nil)
    {
      NSMutableArray *roundTripObjects = [NSMutableArray array];
      NifTestOwner *roundTripOwner = [[NifTestOwner alloc] init];
      NSDictionary *roundTripContext = [NSDictionary dictionaryWithObjectsAndKeys:
        roundTripOwner, NSNibOwner,
        roundTripObjects, NSNibTopLevelObjects, nil];
      GSModelLoader *roundTripLoader =
        [GSModelLoaderFactory modelLoaderForData: encoded];
      BOOL roundTripLoaded = [roundTripLoader loadModelData: encoded
                                         externalNameTable: roundTripContext
                                                  withZone: NULL];
      NifTestNode *roundTripRoot = [roundTripObjects count] != 0
        ? [roundTripObjects objectAtIndex: 0] : nil;
      PASS(roundTripLoaded && [[roundTripRoot child] peer] == roundTripRoot,
           "produced NIF reloads with hierarchy and cycles intact")
      PASS([roundTripOwner node] == roundTripRoot,
           "produced NIF preserves connections")
      [roundTripOwner release];
    }

  [error release];
  [owner release];
  END_SET("NIF loading and writing")
  return 0;
}
