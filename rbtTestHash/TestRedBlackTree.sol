pragma solidity ^0.4.11;

// Adaptation of the Red-black tree solidity library from [AtlantPlatform/rbt-solidity](https://github.com/AtlantPlatform/rbt-solidity)

import "./RedBlackTree.sol";

contract TestRedBlackTree {
    using RedBlackTree for RedBlackTree.Tree;

    RedBlackTree.Tree public tree;

    function root() public constant returns (bytes32) {
        return tree.root;
    }

    function insert(bytes32 id, uint value) public {
        require(value != 0);
        require(tree.items[id].value == 0);
        tree.insert(id, value);
    }

    function getFirstId() public constant returns (bytes32) {
        return tree.getFirstId();
    }

    function getLastId() public constant returns (bytes32) {
        return tree.getLastId();
    }

    function find(uint value) public constant returns (bytes32) {
        return tree.find(value);
    }

    function findParent(uint value) public constant returns (bytes32) {
        return tree.findParent(value);
    }

    function remove(bytes32 id) public {
        tree.remove(id);
    }

    function getItem(bytes32 id) public constant returns (bytes32 parent, bytes32 left, bytes32 right, uint value, bool red) {
        return tree.getItem(id);
        // RedBlackTree.Item memory item = tree.items[id];
        // parent = item.parent;
        // left = item.left;
        // right = item.right;
        // value = item.value;
        // red = item.red;
    }
}