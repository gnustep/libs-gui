/* Direct storyboard scene loading.
   Copyright (C) 2026 Free Software Foundation, Inc.
   Distributed under the GNU LGPL, version 2.1 or later. */
#import "GSStoryboardArchive.h"
#import "GSXib5KeyedUnarchiver.h"
#import "GNUstepGUI/GSXibElement.h"
#import "GNUstepGUI/GSXibLoading.h"
#import "AppKit/NSApplication.h"
#import "AppKit/NSViewController.h"
#import "AppKit/NSWindowController.h"
#import "AppKit/NSWindow.h"
#import "AppKit/NSMenu.h"
#import "AppKit/NSSeguePerforming.h"

@interface NSViewController (GSStoryboardControllerPrivate)
- (void) _setTopLevelObjects: (NSArray *)objects;
- (void) _setSegueMap: (NSMapTable *)map;
- (void) _setStoryboard: (NSStoryboard *)storyboard;
@end
@interface NSWindowController (GSStoryboardControllerPrivate)
- (void) _setTopLevelObjects: (NSArray *)objects;
- (void) _setSegueMap: (NSMapTable *)map;
- (void) _setStoryboard: (NSStoryboard *)storyboard;
- (void) _setOwner: (id)owner;
@end

@interface IBObjectContainer (GSInstantiationPhases)
- (void) establishConnections;
- (void) awakeObjects;
@end
@interface NSMenu (GSStoryboardMenu)
- (BOOL) _isMainMenu;
@end
@interface NSApplication (GSStoryboardMenu)
- (void) _setMainMenu: (NSMenu *)menu;
@end

static GSXibElement *
GSChild(GSXibElement *parent, NSString *tag)
{
  GSXibElement *child;
  for (child in [parent values])
    if ([[child type] isEqual: tag])
      return child;
  return nil;
}

static void
GSValidateIDs(GSXibElement *element, NSMutableSet *identifiers)
{
  NSString *identifier = [element attributeForKey: @"id"];
  GSXibElement *child;
  if (identifier != nil)
    {
      if ([identifiers containsObject: identifier])
        [NSException raise: NSInvalidUnarchiveOperationException
                    format: @"Duplicate storyboard object ID %@", identifier];
      [identifiers addObject: identifier];
    }
  for (child in [element values])
    GSValidateIDs(child, identifiers);
}

static BOOL
GSIsController(GSXibElement *element)
{
  NSString *tag = [element type];
  Class cls = NSClassFromString([GSXib5KeyedUnarchiver classNameForXibTag: tag]);
  return [tag isEqual: @"controllerPlaceholder"]
    || [cls isSubclassOfClass: [NSViewController class]]
    || [cls isSubclassOfClass: [NSWindowController class]];
}

/* This decoder normalizes the selected scene directly into XIB decoding
 * records.  It never changes the archive's input nodes, and never writes XML.
 * Objects, connections and decoder-generated properties are scene-local. */
@interface GSStoryboardSceneUnarchiver : GSXib5KeyedUnarchiver
{
  NSString *_controllerID;
  GSXibElement *_scene;
  NSStoryboardControllerCreator _creator;
  NSMutableArray *_segueDefinitions;
  NSMutableArray *_inputStack;
  NSBundle *_bundle;
}
- (id) initWithScene: (GSXibElement *)scene document: (GSXibElement *)document
       controllerID: (NSString *)identifier bundle: (NSBundle *)bundle
            creator: (NSStoryboardControllerCreator)creator;
- (id) objectWithID: (NSString *)identifier;
- (NSArray *) segueDefinitions;
@end

@implementation GSStoryboardSceneUnarchiver
- (id) initWithScene: (GSXibElement *)scene document: (GSXibElement *)document
       controllerID: (NSString *)identifier bundle: (NSBundle *)bundle
            creator: (NSStoryboardControllerCreator)creator
{
  _controllerID = [identifier copy];
  _creator = creator; // Used synchronously, only during this instantiation.
  _bundle = RETAIN(bundle);
  _segueDefinitions = [NSMutableArray new];
  _inputStack = [NSMutableArray new];
  _scene = scene; // The archive owns the parsed input for the entire load.
  return [super initForReadingWithElement: document];
}

- (void) dealloc
{
  RELEASE(_controllerID);
  RELEASE(_segueDefinitions);
  RELEASE(_inputStack);
  RELEASE(_bundle);
  [super dealloc];
}

- (NSArray *) segueDefinitions
{
  return _segueDefinitions;
}

- (id) objectWithID: (NSString *)identifier
{
  return identifier ? [self objectForXib: [objects objectForKey: identifier]] : nil;
}

- (void) readElement: (GSXibElement *)element
{
  NSString *tag = [element type];
  GSXibElement *child;
  if ([tag isEqual: @"document"])
    {
      [self beginElement: tag attributes: [element attributes]];
      if (GSChild(element, @"resources") != nil)
        [self readElement: GSChild(element, @"resources")];
      [self readElement: GSChild(_scene, @"objects")];
      [self endElement: tag];
      return;
    }
  if ([[element attributeForKey: @"sceneMemberID"] isEqual: @"firstResponder"])
    {
      NSMutableDictionary *attributes = [[[element attributes] mutableCopy] autorelease];
      [attributes setObject: @"FirstResponder" forKey: @"customClass"];
      [self beginElement: @"customObject" attributes: attributes];
      [self endElement: @"customObject"];
      return;
    }
  if ([tag isEqual: @"segue"])
    {
      NSMutableDictionary *definition = [[element attributes] mutableCopy];
      GSXibElement *owner = [_inputStack objectAtIndex: [_inputStack count] - 2];
      NSString *ownerID = [owner attributeForKey: @"id"];
      if (ownerID != nil)
        [definition setObject: ownerID forKey: @"trigger"];
      if ([definition objectForKey: @"id"] == nil
          || [definition objectForKey: @"destination"] == nil)
        [NSException raise: NSInvalidUnarchiveOperationException
                    format: @"Storyboard segue is missing its ID or destination"];
      [_segueDefinitions addObject: definition];
      RELEASE(definition);
      return;
    }
  if ([tag isEqual: @"application"])
    {
      /* Bind the application by identity.  Its menu and other children remain
       * roots of the application scene, and its outlets use its original ID. */
      NSString *identifier = [element attributeForKey: @"id"];
      if (NSApp == nil)
        [NSApplication sharedApplication];
      [decoded setObject: NSApp forKey: identifier];
      [self beginElement: @"customObject" attributes: [element attributes]];
      [_inputStack addObject: element];
      if (GSChild(element, @"connections") != nil)
        [self readElement: GSChild(element, @"connections")];
      [_inputStack removeLastObject];
      [self endElement: @"customObject"];
      for (child in [element values])
        if (![[child type] isEqual: @"connections"])
          [self readElement: child];
      return;
    }
  if ([tag isEqual: @"controllerPlaceholder"])
    {
      NSMutableDictionary *attributes = [[[element attributes] mutableCopy] autorelease];
      [attributes setObject: @"NSObject" forKey: @"customClass"];
      [self beginElement: tag attributes: attributes];
      [self endElement: tag];
      return;
    }
  [_inputStack addObject: element];
  [super readElement: element];
  [_inputStack removeLastObject];
}

- (id) initializeObject: (id)object forXib: (GSXibElement *)element
{
  if (_creator != NULL
      && [[element attributeForKey: @"id"] isEqual: _controllerID])
    {
      id replacement = CALL_NON_NULL_BLOCK(_creator, self);
      if (replacement != nil)
        {
          if (![replacement isKindOfClass: [NSViewController class]]
              && ![replacement isKindOfClass: [NSWindowController class]])
            [NSException raise: NSInvalidArgumentException
                        format: @"Storyboard creator must return a controller"];
          RELEASE(object); // Consume the allocation's init ownership.
          return RETAIN(replacement);
        }
    }
  return [super initializeObject: object forXib: element];
}

- (id) decodeObjectForXib: (GSXibElement *)element
            forClassName: (NSString *)className withID: (NSString *)identifier
{
  if ([[element attributeForKey: @"key"] isEqual: @"controllerPlaceholder"])
    {
      NSString *name = [element attributeForKey: @"storyboardName"];
      NSString *bundleID = [element attributeForKey: @"bundleIdentifier"];
      NSBundle *bundle = bundleID ? [NSBundle bundleWithIdentifier: bundleID] : _bundle;
      NSString *reference = [element attributeForKey: @"referencedIdentifier"];
      NSStoryboard *storyboard;
      id controller;
      if (bundle == nil || name == nil)
        [NSException raise: NSInvalidUnarchiveOperationException
                    format: @"Invalid storyboard reference %@", identifier];
      NSMutableDictionary *state = [[NSThread currentThread] threadDictionary];
      NSMutableSet *references = [state objectForKey: @"GSStoryboardReferences"];
      NSString *key = [NSString stringWithFormat: @"%@/%@:%@",
        [bundle bundlePath], name, reference ?: @"<initial>"];
      if (references == nil)
        {
          references = [NSMutableSet set];
          [state setObject: references forKey: @"GSStoryboardReferences"];
        }
      if ([references containsObject: key])
        [NSException raise: NSInvalidUnarchiveOperationException
                    format: @"Cyclic storyboard reference %@", key];
      [references addObject: key];
      @try
        {
          storyboard = [NSStoryboard storyboardWithName: name bundle: bundle];
          NSStoryboardControllerCreator creator =
            [identifier isEqual: _controllerID] ? _creator : NULL;
          controller = reference
            ? [storyboard instantiateControllerWithIdentifier: reference creator: creator]
            : [storyboard instantiateInitialControllerWithCreator: creator];
        }
      @finally
        {
          [references removeObject: key];
          if ([references count] == 0)
            [state removeObjectForKey: @"GSStoryboardReferences"];
        }
      if (controller == nil)
        [NSException raise: NSInvalidUnarchiveOperationException
                    format: @"Storyboard reference %@ has no controller", identifier];
      [decoded setObject: controller forKey: identifier];
      return controller;
    }
  return [super decodeObjectForXib: element forClassName: className withID: identifier];
}

@end

@implementation GSStoryboardSegueAction
- (id) initWithDefinition: (NSDictionary *)definition
              storyboard: (NSStoryboard *)storyboard source: (id)source
                  anchor: (id)anchor
{
  if ((self = [super init]) != nil)
    {
      _definition = [definition copy];
      _storyboard = storyboard; // Owned by the controller, or main storyboard.
      _source = source;         // The controller owns its segue bindings.
      _anchor = RETAIN(anchor);
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_definition);
  RELEASE(_anchor);
  RELEASE(_relationshipDestination);
  [super dealloc];
}

- (NSString *) identifier
{
  return [_definition objectForKey: @"identifier"];
}

- (void) doAction: (id)sender
{
  NSString *identifier = [self identifier];
  if ([_source respondsToSelector: @selector(shouldPerformSegueWithIdentifier:sender:)]
      && ![_source shouldPerformSegueWithIdentifier: identifier sender: sender])
    return;
  if ([_source respondsToSelector: @selector(performSegueWithIdentifier:sender:)])
    [_source performSegueWithIdentifier: identifier sender: sender];
  else
    [self performWithSender: sender];
}

- (void) performWithSender: (id)sender
{
  NSString *className = [_definition objectForKey: @"customClass"];
  Class cls = className ? NSClassFromString(className) : [NSStoryboardSegue class];
  id destination;
  NSStoryboardSegue *segue;
  NSString *behavior = [_definition objectForKey: @"popoverBehavior"];
  NSString *edge = [_definition objectForKey: @"preferredEdge"];
  if (![cls isSubclassOfClass: [NSStoryboardSegue class]])
    [NSException raise: NSInvalidUnarchiveOperationException
                format: @"Invalid storyboard segue class %@", className];
  destination = [_storyboard _instantiateControllerWithID:
                              [_definition objectForKey: @"destination"]];
  if ([[_definition objectForKey: @"kind"] isEqual: @"relationship"])
    ASSIGN(_relationshipDestination, destination);
  segue = AUTORELEASE([[cls alloc] initWithIdentifier: [self identifier]
                                              source: _source destination: destination]);
  [segue _setKind: [_definition objectForKey: @"kind"]];
  [segue _setRelationship: [_definition objectForKey: @"relationship"]];
  [segue _setPopoverAnchorView: _anchor];
  [segue _setPopoverBehavior: [behavior isEqual: @"t"] ? NSPopoverBehaviorTransient
    : ([behavior isEqual: @"s"] ? NSPopoverBehaviorSemitransient
       : NSPopoverBehaviorApplicationDefined)];
  [segue _setPreferredEdge: [edge isEqual: @"maxY"] ? NSMaxYEdge
    : ([edge isEqual: @"minY"] ? NSMinYEdge
       : ([edge isEqual: @"maxX"] ? NSMaxXEdge : NSMinXEdge))];
  if ([_source respondsToSelector: @selector(prepareForSegue:sender:)])
    [_source prepareForSegue: segue sender: sender];
  [segue perform];
}

@end

@implementation GSStoryboardArchive
- (id) initWithData: (NSData *)data bundle: (NSBundle *)bundle
{
  if ((self = [super init]) != nil)
    {
      NSXMLParser *parser = nil;
      _bundle = RETAIN(bundle);
      _parseStack = [NSMutableArray new];
      _scenes = [NSMutableDictionary new];
      _identifiers = [NSMutableDictionary new];
      _loading = [NSMutableSet new];
      @try
        {
          GSXibElement *scene;
          if (data != nil)
            parser = [[NSXMLParser alloc] initWithData: data];
          [parser setDelegate: self];
          if (data == nil || ![parser parse]
              || ![[_document type] isEqual: @"document"])
            [NSException raise: NSInvalidUnarchiveOperationException
                        format: @"Cannot parse storyboard: %@", [parser parserError]];
          GSValidateIDs(_document, [NSMutableSet set]);
          _initialID = [[_document attributeForKey: @"initialViewController"] copy];
          for (scene in [GSChild(_document, @"scenes") values])
            {
              GSXibElement *root;
              GSXibElement *primary = nil;
              for (root in [GSChild(scene, @"objects") values])
                {
                  if (GSIsController(root) || [[root type] isEqual: @"application"])
                    {
                      if (primary != nil)
                        [NSException raise: NSInvalidUnarchiveOperationException
                                    format: @"Scene %@ has multiple primary controllers",
                                            [scene attributeForKey: @"sceneID"]];
                      primary = root;
                    }
                }
              if (primary != nil)
                {
                  NSString *identifier = [primary attributeForKey: @"id"];
                  NSString *publicID = [primary attributeForKey: @"storyboardIdentifier"];
                  if (identifier == nil || [_scenes objectForKey: identifier] != nil
                      || (publicID != nil && [_identifiers objectForKey: publicID] != nil))
                    [NSException raise: NSInvalidUnarchiveOperationException
                                format: @"Missing or duplicate storyboard controller identifier"];
                  [_scenes setObject: scene forKey: identifier];
                  if (publicID != nil)
                    [_identifiers setObject: identifier forKey: publicID];
                  if ([[primary type] isEqual: @"application"])
                    ASSIGNCOPY(_applicationID, identifier);
                }
            }
        }
      @catch (id exception)
        {
          RELEASE(self);
          @throw;
        }
      @finally
        {
          RELEASE(parser);
        }
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_document);
  RELEASE(_parseStack);
  RELEASE(_scenes);
  RELEASE(_identifiers);
  RELEASE(_loading);
  RELEASE(_bundle);
  RELEASE(_initialID);
  RELEASE(_applicationID);
  RELEASE(_applicationObjects);
  RELEASE(_applicationSegues);
  [super dealloc];
}

- (void) parser: (NSXMLParser *)parser didStartElement: (NSString *)name
  namespaceURI: (NSString *)uri qualifiedName: (NSString *)qualifiedName
     attributes: (NSDictionary *)attributes
{
  GSXibElement *node = [[GSXibElement alloc] initWithType: name andAttributes: attributes];
  if ([_parseStack count] == 0)
    ASSIGN(_document, node);
  else
    [[_parseStack lastObject] addElement: node];
  [_parseStack addObject: node];
  RELEASE(node);
}

- (void) parser: (NSXMLParser *)parser foundCharacters: (NSString *)characters
{
  GSXibElement *node = [_parseStack lastObject];
  NSString *previous = [node value];
  [node setValue: previous ? [previous stringByAppendingString: characters] : characters];
}

- (void) parser: (NSXMLParser *)parser didEndElement: (NSString *)name
  namespaceURI: (NSString *)uri qualifiedName: (NSString *)qualifiedName
{
  [_parseStack removeLastObject];
}

- (NSString *) initialControllerID { return _initialID; }

- (NSString *) applicationControllerID { return _applicationID; }

- (id) instantiateIdentifier: (NSString *)identifier
                 storyboard: (NSStoryboard *)storyboard
                    creator: (NSStoryboardControllerCreator)creator
{
  NSString *controllerID = identifier ? [_identifiers objectForKey: identifier] : nil;
  // Preserve GNUstep's earlier acceptance of XML controller IDs.
  return [self instantiateControllerID: controllerID ?: identifier
                            storyboard: storyboard creator: creator];
}

- (id) instantiateControllerID: (NSString *)identifier
                   storyboard: (NSStoryboard *)storyboard
                      creator: (NSStoryboardControllerCreator)creator
{
  GSXibElement *scene = identifier ? [_scenes objectForKey: identifier] : nil;
  GSStoryboardSceneUnarchiver *decoder = nil;
  id result = nil;
  if (scene == nil)
    [NSException raise: NSInvalidArgumentException
                format: @"No storyboard controller with identifier %@", identifier];
  if ([_loading containsObject: identifier])
    [NSException raise: NSInvalidUnarchiveOperationException
                format: @"Cyclic storyboard relationship involving %@", identifier];
  [_loading addObject: identifier];
  @try
    {
      NSArray *roots;
      NSMutableArray *owned = [NSMutableArray array];
      NSMutableArray *relationships = [NSMutableArray array];
      NSMapTable *segues = [NSMapTable strongToStrongObjectsMapTable];
      IBObjectContainer *container;
      NSDictionary *definition;
      id object;
      decoder = [[GSStoryboardSceneUnarchiver allocWithZone: [storyboard zone]] initWithScene: scene
        document: _document controllerID: identifier bundle: _bundle creator: creator];
      roots = [decoder decodeObjectForKey: @"IBDocument.RootObjects"];
      result = [decoder objectWithID: identifier];
      // References return an already instantiated controller from another archive.
      for (GSXibElement *root in [GSChild(scene, @"objects") values])
        if ([[root attributeForKey: @"id"] isEqual: identifier]
            && [[root type] isEqual: @"controllerPlaceholder"])
          return result;
      for (object in roots)
        {
          id real = [object respondsToSelector: @selector(nibInstantiate)]
            ? [object nibInstantiate] : object;
          if (real != result && real != NSApp && real != nil
              && ![real isKindOfClass: NSClassFromString(@"FirstResponder")])
            [owned addObject: real];
          if ([real isKindOfClass: [NSMenu class]] && [real _isMainMenu])
            [NSApp _setMainMenu: real];
        }
      if ([result isKindOfClass: [NSWindowController class]])
        {
          GSXibElement *controller;
          for (controller in [GSChild(scene, @"objects") values])
            if ([[controller attributeForKey: @"id"] isEqual: identifier])
              {
                GSXibElement *window = GSChild(controller, @"window");
                if (window != nil)
                  {
                    id w = [decoder objectWithID: [window attributeForKey: @"id"]];
                    if ([w respondsToSelector: @selector(nibInstantiate)])
                      w = [w nibInstantiate];
                    [result setWindow: w];
                  }
              }
          [result _setOwner: NSApp];
        }
      container = [decoder decodeObjectForKey: @"IBDocument.Objects"];
      [container establishConnections];
      for (definition in [decoder segueDefinitions])
        {
          NSString *segueID = [definition objectForKey: @"identifier"]
            ?: [definition objectForKey: @"id"];
          NSMutableDictionary *named = [[definition mutableCopy] autorelease];
          GSStoryboardSegueAction *action;
          id trigger = [decoder objectWithID: [definition objectForKey: @"trigger"]];
          id anchor = [definition objectForKey: @"popoverAnchorView"]
            ? [decoder objectWithID: [definition objectForKey: @"popoverAnchorView"]] : nil;
          if ([anchor respondsToSelector: @selector(nibInstantiate)])
            anchor = [anchor nibInstantiate];
          if ([segues objectForKey: segueID] != nil)
            [NSException raise: NSInvalidUnarchiveOperationException
                        format: @"Duplicate segue identifier %@", segueID];
          [named setObject: segueID forKey: @"identifier"];
          action = AUTORELEASE([[GSStoryboardSegueAction alloc]
            initWithDefinition: named storyboard: storyboard source: result anchor: anchor]);
          [segues setObject: action forKey: segueID];
          if ([[definition objectForKey: @"kind"] isEqual: @"relationship"])
            [relationships addObject: action];
          else if (trigger != result)
            {
              if ([trigger respondsToSelector: @selector(nibInstantiate)])
                trigger = [trigger nibInstantiate];
              if (![trigger respondsToSelector: @selector(setTarget:)]
                  || ![trigger respondsToSelector: @selector(setAction:)])
                [NSException raise: NSInvalidUnarchiveOperationException
                            format: @"Invalid trigger for segue %@", segueID];
              [trigger setTarget: action];
              [trigger setAction: @selector(doAction:)];
            }
        }
      if ([result isKindOfClass: [NSViewController class]]
          || [result isKindOfClass: [NSWindowController class]])
        {
          [result _setStoryboard: storyboard];
          [result _setSegueMap: segues];
          [result _setTopLevelObjects: owned];
        }
      else if (result == NSApp)
        {
          ASSIGN(_applicationObjects, owned);
          ASSIGN(_applicationSegues, segues);
        }
      for (GSStoryboardSegueAction *action in relationships)
        [action performWithSender: result];
      [container awakeObjects];
      RETAIN(result);
    }
  @finally
    {
      RELEASE(decoder);
      [_loading removeObject: identifier];
    }
  return AUTORELEASE(result);
}

@end
