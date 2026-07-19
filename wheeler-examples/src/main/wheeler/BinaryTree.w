//! A bounded reversible tree fixture. Heap-backed generic trees require the bootstrap profile.
classical class BinaryTree {
    state long root = 0;
    state long left = 0;
    state long right = 0;

    /// Applies the reversible `insertRoot` state transition.
    ///
    /// - Inverse: Applies the compiler-generated inverse transition.
    rev void insertRoot() {
        root ^= 8;
    }

    /// Applies the reversible `insertLeft` state transition.
    ///
    /// - Inverse: Applies the compiler-generated inverse transition.
    rev void insertLeft() {
        left ^= 3;
    }

    /// Applies the reversible `insertRight` state transition.
    ///
    /// - Inverse: Applies the compiler-generated inverse transition.
    rev void insertRight() {
        right ^= 13;
    }

    /// Runs the bounded `BinaryTree` fixture.
    ///
    /// - Effects: Mutates only the fixture's declared state.
    entry void main() {
        insertRoot();
        insertLeft();
        insertRight();
        assert(root == 8);
        assert(left == 3);
        assert(right == 13);

        reverse {
            insertRoot();
            insertLeft();
            insertRight();
        }
        assert(root == 0);
        assert(left == 0);
        assert(right == 0);
    }
}
