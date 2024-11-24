// Classical reversible binary search tree
classical class BinaryTree<T> {
    let Node<T> root;
    hist<TreeState> history;

    rev void insert(T value) {
        if (root == null) {
            root = new Node<T>(value);
            return;
        }

        rev Node<T> current = root;
        while (true) {
            if (value < current.value) {
                if (current.left == null) {
                    current.left = new Node<T>(value);
                    break;
                }
                current = current.left;
            } else {
                if (current.right == null) {
                    current.right = new Node<T>(value);
                    break;
                }
                current = current.right;
            }
        }
    }

    // Reversible removal
    rev T remove(T value) {
        hist<Node<T>> removedNode;

        transaction {
            removedNode = findAndRemove(value);
            if (removedNode == null) {
                rollback;
            }
            commit;
        }
        return removedNode.value;
    }

    // Clean old history periodically
    pure void maintenance() {
        uncompute {
            clean history before timestamp - 24h;
        }
    }
}