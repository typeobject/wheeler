// Classical reversible binary tree
classical class BinaryTree<T extends Comparable<T>> {
    // State
    private let Node<T> root = null;
    private hist<TreeState> history;

    // Node class
    private static class Node<T> {
        let T value;
        let Node<T> left = null;
        let Node<T> right = null;

        pure Node(T value) {
            this.value = value;
        }
    }

    // Reversible insertion
    rev void insert(T value) {
        if (root == null) {
            root = new Node<T>(value);
            return;
        }

        rev Node<T> current = root;
        while (true) {
            if (value.compareTo(current.value) < 0) {
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

    // Clean history periodically
    pure void maintenance() {
        uncompute {
            clean history before timestamp - 24h;
        }
    }
}