// Deterministic bounded signed map with update, membership, lookup, and drop.
classical class LongMap {
    state long selected = 0;
    state long present = 0;
    state long missing = 0;
    state long zeroKey = 0;

    entry void main() {
        region arena = new region(96, 1);
        longmap values = allocateMap(arena, 4);
        put(values, 7, 11);
        put(values, 9, 13);
        put(values, 7, 17);
        put(values, 0, 5);

        selected = mapGet(values, 7);
        zeroKey = mapGet(values, 0);
        boolean hasNine = mapHas(values, 9);
        boolean hasThree = mapHas(values, 3);
        if (hasNine) {
            present = 1;
        } else {
            present = 0;
        }
        if (hasThree) {
            missing = 0;
        } else {
            missing = 1;
        }

        assert selected == 17;
        assert zeroKey == 5;
        assert present == 1;
        assert missing == 1;
        drop(values);
        drop(arena);
    }
}
