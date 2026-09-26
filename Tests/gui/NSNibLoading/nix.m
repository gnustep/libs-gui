#import "ObjectTesting.h"

#import <Foundation/Foundation.h>
#import <AppKit/NSNib.h>
#import <GNUstepGUI/GSModelLoaderFactory.h>
#import "../../../Headers/Additions/GNUstepGUI/GSNibLoading.h"
#import "../../../Headers/Additions/GNUstepGUI/GSNixSerialization.h"

/* Keep a non-tagged constant-string section with older ELF Objective-C
 * linkers; all literals in this small test can otherwise be optimized into
 * tagged strings while the runtime module still references section bounds. */
static NSString *NixTestLinkerString __attribute__((used)) = @"NIX loader test fixture";

@interface NixTestNode : NSObject
{
  NSString *_name;
  NixTestNode *_child;
  NixTestNode *_peer;
  BOOL _awakened;
  BOOL _needsDisplay;
}
- (NSString *) name;
- (void) setName: (NSString *)value;
- (NSString *) displayName;
- (NixTestNode *) child;
- (void) setChild: (NixTestNode *)value;
- (NixTestNode *) peer;
- (void) setPeer: (NixTestNode *)value;
- (BOOL) awakened;
- (BOOL) needsDisplay;
- (void) setNeedsDisplay: (BOOL)value;
@end

@implementation NixTestNode
- (void) dealloc
{
  [_name release];
  [_child release];
  [_peer release];
  [super dealloc];
}
- (NSString *) name { return _name; }
- (void) setName: (NSString *)value { ASSIGN(_name, value); }
- (NSString *) displayName { return _name; }
- (NixTestNode *) child { return _child; }
- (void) setChild: (NixTestNode *)value { ASSIGN(_child, value); }
- (NixTestNode *) peer { return _peer; }
- (void) setPeer: (NixTestNode *)value { ASSIGN(_peer, value); }
- (void) awakeFromNib { _awakened = YES; }
- (BOOL) awakened { return _awakened; }
- (BOOL) needsDisplay { return _needsDisplay; }
- (void) setNeedsDisplay: (BOOL)value { _needsDisplay = value; }
@end

@interface NixTestDesignNode : NixTestNode
@end

@implementation NixTestDesignNode
@end

@interface NixTestNode (NixTestSubstitution)
+ (id) allocSubstitute;
@end

@implementation NixTestNode (NixTestSubstitution)
+ (id) allocSubstitute
{
  return [NixTestDesignNode alloc];
}
@end

@interface NixTestOwner : NSObject
{
  NixTestNode *_node;
}
- (NixTestNode *) node;
- (void) setNode: (NixTestNode *)value;
@end

@implementation NixTestOwner
- (void) dealloc { [_node release]; [super dealloc]; }
- (NixTestNode *) node { return _node; }
- (void) setNode: (NixTestNode *)value { ASSIGN(_node, value); }
@end

int main(void)
{
  NSData *data = [NSData dataWithContentsOfFile: @"Test.nix"];
  GSModelLoader *loader = [GSModelLoaderFactory modelLoaderForData: data];
  NSMutableArray *topLevel = [NSMutableArray array];
  NixTestOwner *owner = [[NixTestOwner alloc] init];
  NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:
    owner, NSNibOwner, topLevel, NSNibTopLevelObjects, nil];
  BOOL loaded;
  NixTestNode *root;
  NixTestNode *child;
  NSData *encoded;
  NSData *canonicalA;
  NSData *canonicalB;
  NSData *inferred;
  NSData *transientOptIn;
  NSString *encodedString;
  NSString *error = nil;

  START_SET("NIX loading and writing")
  PASS(data != nil, "the NIX fixture can be read")
  PASS([[loader class] type] != nil && [[[loader class] type] isEqual: @"nix"],
       "the model loader factory recognizes NIX data")

  loaded = [loader loadModelData: data externalNameTable: context withZone: NULL];
  PASS(loaded, "the NIX document loads")
  PASS([topLevel count] == 1, "one top-level object is returned")

  root = [topLevel objectAtIndex: 0];
  child = [root child];
  [root setNeedsDisplay: YES];
  PASS([[root name] isEqual: @"root"] && [[child name] isEqual: @"child"],
       "nested definitions and properties are decoded")
  PASS([child peer] == root, "references preserve identity and allow cycles")
  PASS([owner node] == root, "outlet connections to the owner are established")
  PASS([root awakened] && [child awakened], "awakeFromNib is sent after connections")
  PASS([[GSNixSerialization identifierForObject: root] isEqual: @"root"]
       && [[GSNixSerialization identifierForObject: child] isEqual: @"child"],
       "the loader preserves archive identifiers on instantiated objects")

  {
    NSData *customData = [NSData dataWithContentsOfFile: @"Test-Custom.nix"];
    NSMutableArray *customObjects = [NSMutableArray array];
    NixTestOwner *customOwner = [[NixTestOwner alloc] init];
    NSDictionary *customContext = [NSDictionary dictionaryWithObjectsAndKeys:
      customOwner, NSNibOwner, customObjects, NSNibTopLevelObjects, nil];
    GSModelLoader *customLoader;
    NixTestNode *placeholder;
    NSData *rewritten;
    NSString *rewrittenXML;

    [NSClassSwapper setIsInInterfaceBuilder: YES];
    customLoader = [GSModelLoaderFactory modelLoaderForData: customData];
    loaded = [customLoader loadModelData: customData
                       externalNameTable: customContext
                                withZone: NULL];
    placeholder = [customObjects count] != 0 ? [customObjects objectAtIndex: 0] : nil;
    PASS(loaded && [placeholder isKindOfClass: [NixTestNode class]]
         && [[GSNixSerialization intendedClassNameForObject: placeholder]
              isEqual: @"UnlinkedApplicationView"],
         "Gorm mode substitutes the design superclass and retains the custom class")
    PASS([placeholder isKindOfClass: [NixTestDesignNode class]],
         "Gorm mode honors allocSubstitute for editable design-time objects")
    PASS([customOwner node] == nil && ![placeholder awakened],
         "Gorm mode suppresses runtime connections and awakeFromNib")
    rewritten = [GSNixSerialization
      dataWithTopLevelObjects: customObjects
      keyValuePairs: [NSDictionary dictionaryWithObject:
        [NSDictionary dictionaryWithObject: @"name" forKey: @"name"]
        forKey: @"NixTestNode"]
      connections: nil
      errorDescription: &error];
    rewrittenXML = [[[NSString alloc] initWithData: rewritten
                                           encoding: NSUTF8StringEncoding] autorelease];
    PASS([rewrittenXML rangeOfString: @"UnlinkedApplicationView"].location != NSNotFound
         && [rewrittenXML rangeOfString: @"applicationState"].location != NSNotFound
         && [rewrittenXML rangeOfString: @"preserve me"].location != NSNotFound
         && [rewrittenXML rangeOfString: @"<string>node</string>"].location != NSNotFound,
         "Gorm rewrites unresolved custom class metadata, properties, and connections losslessly")
    [NSClassSwapper setIsInInterfaceBuilder: NO];
    [customOwner release];
  }

  encoded = [GSNixSerialization
    dataWithTopLevelObjects: [NSArray arrayWithObject: root]
    keyValuePairs: [NSDictionary dictionaryWithObject:
      [NSDictionary dictionaryWithObjectsAndKeys:
        @"displayName", @"name", @"child", @"child", @"peer", @"peer", nil]
      forKey: @"NixTestNode"]
    connections: [NSArray arrayWithObject:
      [NSDictionary dictionaryWithObjectsAndKeys:
        @"outlet", @"kind", @"owner", @"source", root, @"destination",
        @"node", @"label", nil]]
    errorDescription: &error];
  PASS(encoded != nil && error == nil, "the framework produces NIX data")
  encodedString = [[[NSString alloc] initWithData: encoded
                                          encoding: NSUTF8StringEncoding] autorelease];
  PASS([encodedString rangeOfString: @"<string>NIX</string>"].location != NSNotFound,
       "produced data is readable XML and identifies itself as NIX")

  {
    NSData *firstResponderData = [GSNixSerialization
      dataWithTopLevelObjects: [NSArray arrayWithObject: root]
      keyValuePairs: [NSDictionary dictionaryWithObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
          @"displayName", @"name", @"child", @"child", @"peer", @"peer", nil]
        forKey: @"NixTestNode"]
      connections: [NSArray arrayWithObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
          @"action", @"kind", root, @"source", @"firstResponder", @"destination",
          @"performAction:", @"label", nil]]
      errorDescription: &error];
    NSString *firstResponderXML = [[[NSString alloc]
      initWithData: firstResponderData encoding: NSUTF8StringEncoding] autorelease];
    PASS(firstResponderData != nil
         && [firstResponderXML rangeOfString: @"<string>firstResponder</string>"].location
              != NSNotFound,
         "the writer supports the reserved first-responder connection endpoint")
  }

  {
    NixTestNode *detached = [[[NixTestNode alloc] init] autorelease];
    NSData *detachedData = [GSNixSerialization
      dataWithTopLevelObjects: [NSArray arrayWithObject: root]
      keyValuePairs: [NSDictionary dictionaryWithObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
          @"displayName", @"name", @"child", @"child", @"peer", @"peer", nil]
        forKey: @"NixTestNode"]
      connections: [NSArray arrayWithObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
          @"outlet", @"kind", root, @"source", detached, @"destination",
          @"detachedNode", @"label", nil]]
      errorDescription: &error];
    NSDictionary *detachedDocument = [NSPropertyListSerialization
      propertyListFromData: detachedData
          mutabilityOption: NSPropertyListImmutable
                    format: NULL
          errorDescription: NULL];
    PASS(detachedData != nil
         && [[detachedDocument objectForKey: @"objects"] count] == 2
         && [[detachedDocument objectForKey: @"topLevelObjects"] count] == 1,
         "connection-only endpoints are preserved without becoming top-level objects")
  }

  inferred = [GSNixSerialization
    dataWithTopLevelObjects: [NSArray arrayWithObject: root]
    keyValuePairs: [NSDictionary dictionary]
    connections: nil
    errorDescription: &error];
  PASS(inferred != nil
       && [[[[NSString alloc] initWithData: inferred
                                  encoding: NSUTF8StringEncoding] autorelease]
             rangeOfString: @"<key>child</key>"].location != NSNotFound
       && [[[[NSString alloc] initWithData: inferred
                                  encoding: NSUTF8StringEncoding] autorelease]
             rangeOfString: @"<key>name</key>"].location != NSNotFound,
       "matching KVC accessor pairs serialize custom classes without metadata")
  PASS([[[[NSString alloc] initWithData: inferred
                                encoding: NSUTF8StringEncoding] autorelease]
          rangeOfString: @"<key>needsDisplay</key>"].location == NSNotFound,
       "transient needs... flags are excluded from inferred state")

  transientOptIn = [GSNixSerialization
    dataWithTopLevelObjects: [NSArray arrayWithObject: root]
    keyValuePairs: [NSDictionary dictionaryWithObject:
      [NSDictionary dictionaryWithObject: @"needsDisplay"
                                  forKey: @"needsDisplay"]
      forKey: @"NixTestNode"]
    connections: nil
    errorDescription: &error];
  PASS([[[[NSString alloc] initWithData: transientOptIn
                                encoding: NSUTF8StringEncoding] autorelease]
          rangeOfString: @"<key>needsDisplay</key>"].location != NSNotFound,
       "explicit metadata can opt a normally transient key back in")

  {
    NixTestNode *inserted = [[NixTestNode alloc] init];
    NSMapTable *identifiers = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
                                               NSObjectMapValueCallBacks, 1);
    NSDictionary *pairs = [NSDictionary dictionaryWithObject:
      [NSDictionary dictionaryWithObjectsAndKeys:
        @"name", @"name", @"child", @"child", @"peer", @"peer", nil]
      forKey: @"NixTestNode"];
    NSData *withInsertion;
    NSData *afterReorder;
    NSString *withInsertionXML;
    NSString *afterReorderXML;

    [inserted setName: @"inserted"];
    NSMapInsert(identifiers, inserted, @"inserted-node");
    withInsertion = [GSNixSerialization
      dataWithTopLevelObjects: [NSArray arrayWithObjects: inserted, root, nil]
      keyValuePairs: pairs
      excludedKeys: nil
      identifiers: identifiers
      connections: nil
      errorDescription: &error];
    afterReorder = [GSNixSerialization
      dataWithTopLevelObjects: [NSArray arrayWithObjects: root, inserted, nil]
      keyValuePairs: pairs
      connections: nil
      errorDescription: &error];
    withInsertionXML = [[[NSString alloc] initWithData: withInsertion
                                               encoding: NSUTF8StringEncoding] autorelease];
    afterReorderXML = [[[NSString alloc] initWithData: afterReorder
                                              encoding: NSUTF8StringEncoding] autorelease];
    PASS([withInsertionXML rangeOfString: @"<string>root</string>"].location != NSNotFound
         && [withInsertionXML rangeOfString: @"<string>child</string>"].location != NSNotFound
         && [withInsertionXML rangeOfString: @"<string>inserted-node</string>"].location != NSNotFound,
         "inserting an earlier object preserves all existing IDs")
    PASS([afterReorderXML rangeOfString: @"<string>inserted-node</string>"].location != NSNotFound
         && [[GSNixSerialization identifierForObject: inserted]
              isEqual: @"inserted-node"],
         "caller-supplied IDs persist when objects are later reordered")
    NSFreeMapTable(identifiers);
    [inserted release];
  }
  if (inferred != nil)
    {
      NSMutableArray *inferredObjects = [NSMutableArray array];
      NSDictionary *inferredContext = [NSDictionary dictionaryWithObjectsAndKeys:
        owner, NSNibOwner, inferredObjects, NSNibTopLevelObjects, nil];
      GSModelLoader *inferredLoader =
        [GSModelLoaderFactory modelLoaderForData: inferred];
      BOOL inferredLoaded = [inferredLoader loadModelData: inferred
                                        externalNameTable: inferredContext
                                                 withZone: NULL];
      NixTestNode *inferredRoot = [inferredObjects count] != 0
        ? [inferredObjects objectAtIndex: 0] : nil;
      PASS(inferredLoaded
           && [[inferredRoot name] isEqual: @"root"]
           && [[inferredRoot child] peer] == inferredRoot,
           "inferred custom-class state survives a NIX round trip")
    }
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
    NSMutableDictionary *pairsA = [NSMutableDictionary dictionary];
    NSMutableDictionary *pairsB = [NSMutableDictionary dictionary];
    [pairsA setObject: @"peer" forKey: @"peer"];
    [pairsA setObject: @"displayName" forKey: @"name"];
    [pairsA setObject: @"child" forKey: @"child"];
    [pairsB setObject: @"child" forKey: @"child"];
    [pairsB setObject: @"displayName" forKey: @"name"];
    [pairsB setObject: @"peer" forKey: @"peer"];
    canonicalA = [GSNixSerialization
      dataWithTopLevelObjects: [NSArray arrayWithObject: root]
      keyValuePairs: [NSDictionary dictionaryWithObject: pairsA
                                                  forKey: @"NixTestNode"]
      connections: [NSArray arrayWithObjects: firstConnection, secondConnection, nil]
      errorDescription: NULL];
    canonicalB = [GSNixSerialization
      dataWithTopLevelObjects: [NSArray arrayWithObject: root]
      keyValuePairs: [NSDictionary dictionaryWithObject: pairsB
                                                  forKey: @"NixTestNode"]
      connections: [NSArray arrayWithObjects: secondConnection, firstConnection, nil]
      errorDescription: NULL];
    PASS([canonicalA isEqual: canonicalB],
         "property, dictionary, and connection insertion order does not change NIX output")
  }

  if (encoded != nil)
    {
      NSMutableArray *roundTripObjects = [NSMutableArray array];
      NixTestOwner *roundTripOwner = [[NixTestOwner alloc] init];
      NSDictionary *roundTripContext = [NSDictionary dictionaryWithObjectsAndKeys:
        roundTripOwner, NSNibOwner,
        roundTripObjects, NSNibTopLevelObjects, nil];
      GSModelLoader *roundTripLoader =
        [GSModelLoaderFactory modelLoaderForData: encoded];
      BOOL roundTripLoaded = [roundTripLoader loadModelData: encoded
                                         externalNameTable: roundTripContext
                                                  withZone: NULL];
      NixTestNode *roundTripRoot = [roundTripObjects count] != 0
        ? [roundTripObjects objectAtIndex: 0] : nil;
      PASS(roundTripLoaded && [[roundTripRoot child] peer] == roundTripRoot,
           "produced NIX reloads with hierarchy and cycles intact")
      PASS([roundTripOwner node] == roundTripRoot,
           "produced NIX preserves connections")
      [roundTripOwner release];
    }

  [error release];
  [owner release];
  END_SET("NIX loading and writing")
  return 0;
}
