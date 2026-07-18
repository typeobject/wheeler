//! Freeze a validated byte owner into an immutable affine UTF-8 value.
classical class FrozenUtf8 {
    state long byteLength = 0;
    state long scalarCount = 0;
    state long middleScalar = 0;
    state long valid = 0;

    long scalarAt(utf8 text, long index) {
        return utf8Scalar(text, index);
    }

    long middle(utf8 text) {
        return scalarAt(text, 1);
    }

    /// Runs the bounded `FrozenUtf8` fixture.
    ///
    /// - Effects: Mutates only the fixture's declared state.
    entry void main() {
        region arena = new region(6, 1);
        bytes raw = allocateBytes(arena, 6);
        setByte(raw, 0, 65);
        setByte(raw, 1, 226);
        setByte(raw, 2, 130);
        setByte(raw, 3, 172);
        setByte(raw, 4, 194);
        setByte(raw, 5, 162);

        utf8 text = freezeUtf8(raw);
        byteLength = bufferLength(text);
        scalarCount = utf8Count(text);
        middleScalar = middle(text);
        boolean isValid = utf8Valid(text);
        if (isValid) {
            valid = 1;
        } else {
            valid = 0;
        }

        assert byteLength == 6;
        assert scalarCount == 3;
        assert middleScalar == 8364;
        assert valid == 1;
        drop(text);
        drop(arena);
    }
}
