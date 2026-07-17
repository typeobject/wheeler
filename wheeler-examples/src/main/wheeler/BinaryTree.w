// A bounded reversible tree fixture. Heap-backed generic trees require the bootstrap profile.
classical class BinaryTree {
    state long root = 0;
    state long left = 0;
    state long right = 0;

    rev void insertRoot() {
        root ^= 8;
    }

    rev void insertLeft() {
        left ^= 3;
    }

    rev void insertRight() {
        right ^= 13;
    }

    entry void main() {
        insertRoot();
        insertLeft();
        insertRight();
        assert root == 8;
        assert left == 3;
        assert right == 13;

        reverse {
            insertRoot();
            insertLeft();
            insertRight();
        }
        assert root == 0;
        assert left == 0;
        assert right == 0;
    }
}
