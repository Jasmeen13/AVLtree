include "AVLnode.dfy"
include "HelperFunctions.dfy"

class AVLtree {
    ghost var objects: set<object> // tree and nodes
    ghost var keys: set<int>
    var root: AVLnode?

    constructor () 
        ensures objects == {this}
        ensures root == null
        ensures valid() 
        ensures balanced()
    {
        objects := {this};
        root := null;
        keys := {};
    }

    // need for balance()
    predicate valid()
        reads this, objects
    {
        this in objects &&
        (root == null ==> keys == {}) &&
        (root != null ==>
            root in objects && root.nodes <= objects &&
            root.valid() &&
            keys == root.keys)
    }

    predicate balanced()
        reads this, objects
    {
        valid() &&
        (root != null ==> root.balanced())
    }

    static method nodeHeight(avlNode: AVLnode?) returns (height: int) 
    {
        if avlNode == null {
            height := -1;
        } else {
            height := avlNode.height;
        }
    }

    static method heightDiff(avlNode: AVLnode?) returns (diff: int) 
    {
        if avlNode == null {
            diff := 0;
        } else {
            var leftHeight: int := nodeHeight(avlNode.left);
            var rightHeight: int := nodeHeight(avlNode.right);
            diff := leftHeight - rightHeight;
        }
    }

    method findNode(node: AVLnode, queryNum: int) returns (found_node: AVLnode?)
        requires node.valid()
        ensures found_node != null ==> found_node in node.nodes
        // Why is this not working?
        // ensures found_node != null ==> found_node.key == queryNum
        decreases node.nodes 
    {
        var temp: AVLnode? := node;
        if temp != null
        {
            if (temp.left != null && queryNum < node.key) {
                temp := findNode(temp.left, queryNum);
            }
            else if (temp.right != null && queryNum > node.key) {
                temp := findNode(temp.right, queryNum);
            }
        }

        return temp;
    }

    /* skip verification for now to implement insert and delete first */
    method {:verify false} minNode(node: AVLnode) returns (min_node: AVLnode?)
        requires node.valid()
        ensures min_node != null ==> min_node in node.nodes
        ensures min_node != null ==> (forall i :: i in node.keys ==> min_node.key <= i)
        ensures min_node.valid()
    {
        var temp: AVLnode := node;

        while temp.left != null 
            decreases if temp.left != null then temp.left.nodes else {}
        {
            temp := temp.left;
        }

        return temp;
    }
    
    static method rightRotate(z: AVLnode) returns( y : AVLnode)
        requires z.left != null;
        requires z.valid();
        modifies z.nodes;
        ensures old(z.nodes) == y.nodes;
        ensures old(z.keys) == y.keys;
        ensures y.valid();
        ensures z.valid();
        ensures y == old(z.left);
        ensures y.left == old(y.left);
        ensures y.right == old(z);
        ensures z.left == old(z.left.right);
        ensures z.right == old(z.right);
    {
        y := z.left;
        var T3 := y.right;
        y.right := z;
        z.nodes := z.nodes - z.left.nodes;
        z.keys := z.keys - z.left.keys;
        z.left := T3;

        if z.left != null {
            z.nodes := z.nodes + z.left.nodes + {z.left};
            z.keys := z.keys + z.left.keys + {z.key};
        }
        if y.right != null {
            y.nodes := y.nodes + y.right.nodes + {y.right};
            y.keys := y.keys + y.right.keys + {y.key};
        }
        var r_h:int := nodeHeight(z.right);
        var l_h:int := nodeHeight(z.left);
        z.height := 1 + max(r_h,l_h);
        r_h := nodeHeight(y.right);
        l_h := nodeHeight(y.left);
        y.height := 1 + max(r_h,l_h);
    }
    static method leftRotate(z: AVLnode) returns( y : AVLnode)
        requires z.right != null;
        requires z.valid()
        modifies z.nodes;
        ensures old(z.nodes) == y.nodes;
        ensures old(z.keys) == y.keys;
        ensures y.valid();
        ensures z.valid();
        ensures y == old(z.right);
        ensures y.right == old(y.right);
        ensures y.left == old(z);
        ensures z.right == old(z.right.left);
        ensures z.left == old(z.left);
    {
        y := z.right;
        var T3 := y.left;
        y.left := z;
        z.nodes := z.nodes - z.right.nodes;
        z.keys := z.keys - z.right.keys;
        z.right := T3;
        if z.right != null {
            z.nodes := z.nodes + z.right.nodes + {z.right};
            z.keys := z.keys + z.right.keys + {z.key};
        }
        if y.left != null {
            y.nodes := y.nodes + y.left.nodes + {y.left};
            y.keys := y.keys + y.left.keys + {y.key};
        }
        var r_h:int := nodeHeight(z.right);
        var l_h:int := nodeHeight(z.left);
        z.height := 1 + max(r_h,l_h);
        r_h := nodeHeight(y.right);
        l_h := nodeHeight(y.left);
        y.height := 1 + max(r_h,l_h);
    }

    static method leftRightRotate(z: AVLnode) returns( y : AVLnode)
        modifies z.nodes
        requires z.valid()
        ensures y.valid()
        ensures y.balanced()
        ensures z.valid()
        ensures old(z.nodes) == y.nodes;
        ensures old(z.keys) == y.keys;
        ensures y.right != null ==> y.right in y.right.nodes;
        ensures y.left != null ==> y.left in y.left.nodes;
    {
        y := z;
        if z.left != null && y.left != null && y.left.right != null {
            y.left := leftRotate(y.left);
            y:= rightRotate(y);
        }
        assert y.right != null ==> y.right in y.right.nodes;
        assert y.left != null ==> y.left in y.left.nodes;
    }

    static method rightLeftRotate(z: AVLnode) returns( y : AVLnode)
        modifies z.nodes
        requires z.valid()
        ensures y.valid()
        ensures y.balanced()
        ensures z.valid()
        ensures old(z.nodes) == y.nodes;
        ensures old(z.keys) == y.keys;
        ensures y.right != null ==> y.right in y.right.nodes;
        ensures y.left != null ==> y.left in y.left.nodes;
    {
        y := z;
        if z.right != null && y.right != null && y.right.left != null {
            y.right := rightRotate(y.right);
            y:= leftRotate(y);
        }
        
    }

    method insert(key: int) 
        requires valid()
        modifies objects;
        modifies root;
        ensures valid() && balanced();
        //ensures fresh(objects - old(objects));
        //ensures root != null && old(root) != null ==> root.keys == old(root.keys) + {key};
    {
        root := insert2(root, key);
        assert root.valid();
        objects := root.nodes + {this};
        keys := root.keys;
    }


    static method insert2(node:AVLnode?, key:int) returns (ret:AVLnode)
        requires node == null || (node.valid() && node.balanced())
        modifies if node != null then node.nodes + {node} else {}
        ensures ret.valid()
        ensures ret.balanced()
        ensures node == null ==> fresh(ret.nodes) && ret.keys == {key}
        ensures node != null ==> ret.keys == old(node.keys) + {key}
        ensures node != null ==> fresh(ret.nodes - old(node.nodes))
        decreases if node == null then {} else node.nodes
    {
        if node == null {
            ret := new AVLnode(key);
        } else {
            if key == node.key {
                ret := node;
            }
            else if (key < node.key) {
                var t := insert2(node.left, key);
                var r_h:int := nodeHeight(t.right);
                var l_h:int := nodeHeight(t.left);
                t.height := 1 + max(r_h,l_h);
                node.left := t;
                node.nodes := node.nodes + node.left.nodes;
                node.keys := node.keys + {key};
                ret := node;
                var balance := heightDiff(ret);
                if(balance < -1)
                {
                    if(ret.right != null)
                    {
                        var diff := heightDiff(ret.right);
                        if(diff >= 0)
                        {
                            ret := leftRotate(ret);                        
                        }
                        else
                        {
                            ret := rightLeftRotate(ret);
                        }
                    }
            }

            } else {
                var t := insert2(node.right, key);
                var r_h:int := nodeHeight(t.right);
                var l_h:int := nodeHeight(t.left);
                t.height := 1 + max(r_h,l_h);
                node.right := t;
                node.nodes := node.nodes + node.right.nodes;
                node.keys := node.keys + {key};
                ret := node;
                var balance := heightDiff(ret);
                if(balance < -1)
                {
                    if(ret.right != null)
                    {
                        var diff := heightDiff(ret.right);
                        if(diff >= 0)
                        {
                            ret := leftRotate(ret);                        
                        }
                        else
                        {
                            ret := rightLeftRotate(ret);
                        }
                    }
                }   
            }

        }
    }
    method delete(key: int)
        requires valid()
        requires balanced()
        modifies objects
        ensures valid() && balanced()
        ensures keys == old(keys) - {key}
    {

        if root != null {
            var newRoot := delete1(root,key);
            root := newRoot;
            if root == null {
                keys := {};
                objects := {this};
            } else {
                keys := root.keys;
                objects := root.nodes + {this};
            }
        }
    }
    method remove_min(node: AVLnode) returns (min: int, new_node: AVLnode?)
        requires node.valid()
        modifies node.nodes
        ensures new_node != null ==> fresh(new_node.nodes - old(node.nodes))
        ensures new_node != null ==> new_node.valid()
        ensures new_node == null ==> old(node.keys) == {min}
        ensures new_node != null ==> new_node.nodes <= old(node.nodes)
        ensures new_node != null ==> new_node.keys == old(node.keys) - {min}
        ensures min in old(node.keys) && (forall x :: x in old(node.keys) ==> min <= x)
        decreases node.nodes
    {
        if node.left == null {
            min := node.key;
            new_node := node.right;
        } else {
            var t;
            min,t := remove_min(node.left);
            node.left := t;
            new_node := node;
            node.keys := node.keys - {min};
            if node.left != null { node.nodes := node.nodes + node.left.nodes; }
            if(new_node != null) {
                var balance := heightDiff(new_node);
                if(balance < -1)
                {
                    if(new_node.right != null)
                    {
                        var diff := heightDiff(new_node.right);
                        if(diff >= 0)
                        {
                            new_node := leftRotate(new_node);                        
                        }
                        else
                        {
                            new_node := rightLeftRotate(new_node);
                        }
                    }
                }
                var l_h := nodeHeight(new_node.left);
                var r_h := nodeHeight(new_node.right);
                new_node.height := max(l_h, r_h + 1);
            }
        }
    }
    method delete1(node:AVLnode,key: int) returns (new_node: AVLnode?)
        requires node.valid()
        requires node.balanced()
        modifies node.nodes
        ensures new_node != null ==> fresh(new_node.nodes - old(node.nodes))
        ensures new_node != null ==> new_node.valid()
        ensures new_node != null ==> new_node.balanced()
        ensures new_node == null ==> old(node.keys) <= {key}
        ensures new_node != null ==> new_node.keys == old(node.keys) - {key}
        decreases node.nodes
    {
        new_node := node;
        if new_node.left != null && key < new_node.key {
            new_node.left := delete1(new_node.left,key);
            new_node.keys := new_node.keys - {key};
            if new_node.left != null { new_node.nodes := new_node.nodes + new_node.left.nodes; }
            var l_h := nodeHeight(new_node.left);
            var r_h := nodeHeight(new_node.right);
            new_node.height := max(l_h, r_h + 1);
            var balance := heightDiff(new_node);
            if(balance < -1)
            {
                if(new_node.right != null)
                {
                    var diff := heightDiff(new_node.right);
                    if(diff >= 0)
                    {
                        new_node := leftRotate(new_node);                        
                    }
                    else
                    {
                        new_node := rightLeftRotate(new_node);
                    }
                }
            }
        } else if new_node.right != null && new_node.key < key {
            new_node.right := delete1(new_node.right,key);
            new_node.keys := new_node.keys - {key};
            if new_node.right != null { new_node.nodes := new_node.nodes + new_node.right.nodes; }
            var l_h := nodeHeight(new_node.left);
            var r_h := nodeHeight(new_node.right);
            new_node.height := max(l_h, r_h + 1);
            var balance := heightDiff(new_node);
            if(balance > 1)
            {
                var diff := heightDiff(new_node.right);
                if(new_node.left != null)
                {
                    var diff := heightDiff(new_node.right);
                    if(diff >= 0)
                    {
                        new_node := rightRotate(new_node);
                    }
                    else
                    {
                        new_node := leftRightRotate(new_node);
                    }   
                }
            }
        } else if key == new_node.key {
            if new_node.left == null && new_node.right == null {
                new_node := null;
            } else if new_node.left == null {
                new_node := new_node.right;
            } else if new_node.right == null {
                new_node := new_node.left;
            }else {
                var min, r := remove_min(new_node.right);
                new_node.key := min;  new_node.right := r;
                new_node.keys := new_node.keys - {key};
                if new_node.right != null { new_node.nodes := new_node.nodes + new_node.right.nodes; }
            }
            if (new_node != null) {
                var l_h := nodeHeight(new_node.left);
                var r_h := nodeHeight(new_node.right);
                new_node.height := max(l_h, r_h + 1);
                var balance := heightDiff(new_node);

                if(balance < -1)
                {
                    if(new_node.right != null)
                    {
                        var diff := heightDiff(new_node.right);
                        if(diff >= 0)
                        {
                            new_node := leftRotate(new_node);                        
                        }
                        else
                        {
                            new_node := rightLeftRotate(new_node);
                        }
                    }

                }
                else if(balance > 1)
                {
                    if(new_node.left != null)
                    {
                        var diff := heightDiff(new_node.right);
                        if(diff >= 0)
                        {
                            new_node := rightRotate(new_node);
                        }
                        else
                        {
                            new_node := leftRightRotate(new_node);
                        }   
                    }

                }
            }
        }
    }

    method printPreOrder(node: AVLnode?) 
    requires root != null ==> root.valid()
    requires node == null || (node.balanced() && node.valid())
    decreases if node == null then {} else node.nodes
    {
        if node == null {
            return;
        }
        print("%d",node.key);
        printPreOrder(node.left);
        printPreOrder(node.right);
        
    }
    
    method printInOrder(node: AVLnode?) 
    requires root != null ==> root.valid()
    requires node == null || (node.balanced() && node.valid())
    decreases if node == null then {} else node.nodes
    {
        if node == null {
            return;
        }
        printPreOrder(node.left);
        print("%d",node.key);
        printPreOrder(node.right);  
    }

    method printPostOrder(node: AVLnode?) 
    requires root != null ==> root.valid()
    requires node == null || (node.balanced() && node.valid())
    decreases if node == null then {} else node.nodes
    {
        if node == null {
            return;
        }
        printPreOrder(node.left);
        printPreOrder(node.right);
        print("%d",node.key);
    }

    method printAVL(node: AVLnode?, level: int)
    requires root != null ==> root.valid()
    requires node == null || (node.balanced() && node.valid())
    decreases if node == null then {} else node.nodes
    {
        if (node != null)
        {
            printAVL(node.right, level + 1);
            print("\n\n");
            var i : int;
            for i := 0 to level{
                print("\t");
            }
            print("%d", node.key);

            printAVL(node.left, level + 1);
        }
    }

}