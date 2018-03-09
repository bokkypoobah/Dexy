pragma solidity ^0.4.11;

// Adaptation of the Red-black tree solidity library from [AtlantPlatform/rbt-solidity](https://github.com/AtlantPlatform/rbt-solidity)

library RedBlackTree {

    struct Item {
        bool red;
        bytes32 parent;
        bytes32 left;
        bytes32 right;
        uint value;
    }

    struct Tree {
        bytes32 root;
        mapping(bytes32 => Item) items;
    }

    function getItem(Tree storage tree, bytes32 id) public constant returns (bytes32 parent, bytes32 left, bytes32 right, uint value, bool red) {
        require(id != 0);
        parent = tree.items[id].parent;
        left = tree.items[id].left;
        right = tree.items[id].right;
        value = tree.items[id].value;
        red = tree.items[id].red;
    }

    function getFirstId(Tree storage tree) public constant returns (bytes32 id) {
        id = tree.root;
        while (id != 0) {
            if (tree.items[id].left == 0) {
                return id;
            }
            id = tree.items[id].left;
        }
    }

    function getLastId(Tree storage tree) public constant returns (bytes32 id) {
        id = tree.root;
        while (id != 0) {
            if (tree.items[id].right == 0) {
                return id;
            }
            id = tree.items[id].right;
        }
    }

    function find(Tree storage tree, uint value) public constant returns (bytes32 id) {
        id = tree.root;
        while (id != 0) {
            if (value == tree.items[id].value) {
                return;
            }
            if (value < tree.items[id].value) {
                id = tree.items[id].left;
            } else {
                id = tree.items[id].right;
            }
        }
    }

    function findParent(Tree storage tree, uint value) public constant returns (bytes32 parentId) {
        bytes32 id = tree.root;
        parentId = id;
        while (id != 0) {
            if (value == tree.items[id].value) {
                return;
            }

            parentId = id;
            if (value < tree.items[id].value) {
                id = tree.items[id].left;
            } else {
                id = tree.items[id].right;
            }
        }
    }

    function insert(Tree storage tree, bytes32 id, uint value) internal {
        bytes32 parent = findParent(tree, value);
        placeAfter(tree, parent, id, value);
    }

    function placeAfter(Tree storage tree, bytes32 parent, bytes32 id, uint value) internal {
        Item memory item;
        item.value = value;
        item.parent = parent;
        item.red = true;
        if (parent != 0) {
            if (value < tree.items[parent].value) {
                tree.items[parent].left = id;
            } else {
                tree.items[parent].right = id;
            }
        } else {
            tree.root = id;
        }
        tree.items[id] = item;
        insert1(tree, id);
    }

    function insert1(Tree storage tree, bytes32 n) private {
        bytes32 p = tree.items[n].parent;
        if (p == 0) {
            tree.items[n].red = false;
        } else {
            if (tree.items[p].red) {
                bytes32 g = grandparent(tree, n);
                bytes32 u = uncle(tree, n);
                if (u != 0 && tree.items[u].red) {
                    tree.items[p].red = false;
                    tree.items[u].red = false;
                    tree.items[g].red = true;
                    insert1(tree, g);
                } else {
                    if ((n == tree.items[p].right) && (p == tree.items[g].left)) {
                        rotateLeft(tree, p);
                        n = tree.items[n].left;
                    } else if ((n == tree.items[p].left) && (p == tree.items[g].right)) {
                        rotateRight(tree, p);
                        n = tree.items[n].right; 
                    }

                    insert2(tree, n);
                }
            }
        }
    }

    function insert2(Tree storage tree, bytes32 n) internal {
        bytes32 p = tree.items[n].parent;
        bytes32 g = grandparent(tree, n);

        tree.items[p].red = false;
        tree.items[g].red = true;

        if ((n == tree.items[p].left) && (p == tree.items[g].left)) {
            rotateRight(tree, g);
        } else {
            rotateLeft(tree, g);
        }
    }

    function remove(Tree storage tree, bytes32 n) internal {
        bytes32 successor;
        bytes32 nRight = tree.items[n].right;
        bytes32 nLeft = tree.items[n].left;
        if (nRight != 0 && nLeft != 0) {
            successor = nRight;
            while (tree.items[successor].left != 0) {
                successor = tree.items[successor].left;
            }
            bytes32 sParent = tree.items[successor].parent;
            if (sParent != n) {
                tree.items[sParent].left = tree.items[successor].right;
                tree.items[successor].right = nRight;
                tree.items[sParent].parent = successor;
            }
            tree.items[successor].left = nLeft;
            if (nLeft != 0) {
                tree.items[nLeft].parent = successor;
            }
        } else if (nRight != 0) {
            successor = nRight;
        } else {
            successor = nLeft;
        }

        bytes32 p = tree.items[n].parent;
        tree.items[successor].parent = p;

        if (p != 0) {
            if (n == tree.items[p].left) {
                tree.items[p].left = successor; 
            } else {
                tree.items[p].right = successor;
            }
        } else {
            tree.root = successor;
        }

        if (!tree.items[n].red) {
            if (tree.items[successor].red) {
                tree.items[successor].red = false;
            } else {
                delete1(tree, successor);
            }
        }
        delete tree.items[n];
        delete tree.items[0];
    }

    function delete1(Tree storage tree, bytes32 n) private {
        bytes32 p = tree.items[n].parent;
        if (p != 0) {
            bytes32 s = sibling(tree, n);
            if (tree.items[s].red) {
                tree.items[p].red = true;
                tree.items[s].red = false;
                if (n == tree.items[p].left) {
                    rotateLeft(tree, p);
                } else {
                    rotateRight(tree, p);
                }
            }
            delete2(tree, n);
        }
    }

    function delete2(Tree storage tree, bytes32 n) private {
        bytes32 s = sibling(tree, n);
        bytes32 p = tree.items[n].parent;
        bytes32 sLeft = tree.items[s].left;
        bytes32 sRight = tree.items[s].right;
        if (!tree.items[p].red && 
            !tree.items[s].red && 
            !tree.items[sLeft].red && 
            !tree.items[sRight].red) 
        {
            tree.items[s].red = true;
            delete1(tree, p);
        } else {
             if (tree.items[p].red && 
                !tree.items[s].red && 
                !tree.items[sLeft].red && 
                !tree.items[sRight].red) 
            {
                tree.items[s].red = true;
                tree.items[p].red = false;
            } else {
                if (!tree.items[s].red) {
                    if (n == tree.items[p].left && 
                        !tree.items[sRight].red &&
                        tree.items[sLeft].red) 
                    {
                        tree.items[s].red = true;
                        tree.items[sLeft].red = false;
                        rotateRight(tree, s);
                    } else if (n == tree.items[p].right && 
                        !tree.items[sLeft].red &&
                        tree.items[sRight].red) 
                    {
                        tree.items[s].red = true;
                        tree.items[sRight].red = false;
                        rotateLeft(tree, s);
                    }
                }

                tree.items[s].red = tree.items[p].red;
                tree.items[p].red = false;

                if (n == tree.items[p].left) {
                    tree.items[sRight].red = false;
                    rotateLeft(tree, p);
                } else {
                    tree.items[sLeft].red = false;
                    rotateRight(tree, p);
                }
            }
        }
    }

    // BK Ok
    function parent(Tree storage tree, bytes32 n) private view returns (bytes32) {
        return tree.items[n].parent;
    }

    // BK Ok
    function grandparent(Tree storage tree, bytes32 n) private view returns (bytes32) {
        bytes32 p = tree.items[n].parent;
        if (p == 0) {
            return 0;
        } else {
            return tree.items[p].parent;
        }
    }

    // BK Ok
    function sibling(Tree storage tree, bytes32 n) private view returns (bytes32) {
        bytes32 p = tree.items[n].parent;
        if (p == 0) {
            return 0;
        } else {
            if (n == tree.items[p].left) {
                return tree.items[p].right;
            } else {
                return tree.items[p].left;
            }
        }
    }

    // BK Ok
    function uncle(Tree storage tree, bytes32 n) private view returns (bytes32) {
        bytes32 g = grandparent(tree, n);
        if (g == 0) {
            return 0;
        } else {
            if (tree.items[n].parent == tree.items[g].left) {
                return tree.items[g].right;
            } else {
                return tree.items[g].left;
            }
        }
    }

    function rotateRight(Tree storage tree, bytes32 n) private {
        bytes32 pivot = tree.items[n].left;
        bytes32 p = tree.items[n].parent;
        tree.items[pivot].parent = p;
        if (p != 0) {
            if (tree.items[p].left == n) {
                tree.items[p].left = pivot;
            } else {
                tree.items[p].right = pivot;
            }
        } else {
            tree.root = pivot;
        }

        tree.items[n].left = tree.items[pivot].right;
        if (tree.items[pivot].right != 0) {
            tree.items[tree.items[pivot].right].parent = n;
        }

        tree.items[n].parent = pivot;
        tree.items[pivot].right = n;
    }

    function rotateLeft(Tree storage tree, bytes32 n) private {
        bytes32 pivot = tree.items[n].right;
        bytes32 p = tree.items[n].parent;
        tree.items[pivot].parent = p;
        if (p != 0) {
            if (tree.items[p].left == n) {
                tree.items[p].left = pivot;
            } else {
                tree.items[p].right = pivot;
            }
        } else {
            tree.root = pivot;
        }

        tree.items[n].right = tree.items[pivot].left;
        if (tree.items[pivot].left != 0) {
            tree.items[tree.items[pivot].left].parent = n;
        }

        tree.items[n].parent = pivot;
        tree.items[pivot].left = n;
    }
}