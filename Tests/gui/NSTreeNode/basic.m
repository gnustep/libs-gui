/* Coverage for NSTreeNode: the represented object, the leaf state, the parent
 * and child relationships built through mutableChildNodes, the index path of
 * the descendants and descendantNodeAtIndexPath:.  These are plain model
 * objects and need no backend.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSTreeNode.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("a new node")
    NSTreeNode	*node = [NSTreeNode treeNodeWithRepresentedObject: @"root"];

    PASS([[node representedObject] isEqualToString: @"root"],
      "the represented object reads back");
    PASS([node isLeaf] == YES, "a node with no children is a leaf");
    PASS([[node childNodes] count] == 0, "a new node has no child nodes");
    PASS([node parentNode] == nil, "a new node has no parent");
  END_SET("a new node")

  START_SET("child nodes")
    NSTreeNode	*root = [NSTreeNode treeNodeWithRepresentedObject: @"root"];
    NSTreeNode	*c0 = [NSTreeNode treeNodeWithRepresentedObject: @"c0"];
    NSTreeNode	*c1 = [NSTreeNode treeNodeWithRepresentedObject: @"c1"];

    [[root mutableChildNodes] addObject: c0];
    [[root mutableChildNodes] addObject: c1];

    PASS([root isLeaf] == NO, "a node with children is not a leaf");
    PASS([[root childNodes] count] == 2, "the child nodes are added");
    PASS([[root childNodes] objectAtIndex: 0] == c0
      && [[root childNodes] objectAtIndex: 1] == c1,
      "the child nodes keep their order");
    PASS([c0 parentNode] == root && [c1 parentNode] == root,
      "adding a child sets its parent node");
  END_SET("child nodes")

  START_SET("index paths")
    NSTreeNode	*root = [NSTreeNode treeNodeWithRepresentedObject: @"root"];
    NSTreeNode	*c0 = [NSTreeNode treeNodeWithRepresentedObject: @"c0"];
    NSTreeNode	*c1 = [NSTreeNode treeNodeWithRepresentedObject: @"c1"];
    NSTreeNode	*gc = [NSTreeNode treeNodeWithRepresentedObject: @"gc"];

    [[root mutableChildNodes] addObject: c0];
    [[root mutableChildNodes] addObject: c1];
    [[c1 mutableChildNodes] addObject: gc];

    PASS([[c1 indexPath] length] == 1
      && [[c1 indexPath] indexAtPosition: 0] == 1,
      "a child index path is the child position");
    PASS([[gc indexPath] length] == 2
      && [[gc indexPath] indexAtPosition: 0] == 1
      && [[gc indexPath] indexAtPosition: 1] == 0,
      "a grandchild index path is the path from the root");
  END_SET("index paths")

  START_SET("descendantNodeAtIndexPath:")
    NSTreeNode	*root = [NSTreeNode treeNodeWithRepresentedObject: @"root"];
    NSTreeNode	*c0 = [NSTreeNode treeNodeWithRepresentedObject: @"c0"];
    NSTreeNode	*c1 = [NSTreeNode treeNodeWithRepresentedObject: @"c1"];
    NSTreeNode	*gc = [NSTreeNode treeNodeWithRepresentedObject: @"gc"];
    NSIndexPath	*deep;

    [[root mutableChildNodes] addObject: c0];
    [[root mutableChildNodes] addObject: c1];
    [[c1 mutableChildNodes] addObject: gc];

    PASS([root descendantNodeAtIndexPath: [NSIndexPath indexPathWithIndex: 1]]
      == c1, "a one-step index path reaches the child");

    deep = [[NSIndexPath indexPathWithIndex: 1] indexPathByAddingIndex: 0];
    PASS([root descendantNodeAtIndexPath: deep] == gc,
      "a two-step index path reaches the grandchild");
  END_SET("descendantNodeAtIndexPath:")

  DESTROY(arp);
  return 0;
}
