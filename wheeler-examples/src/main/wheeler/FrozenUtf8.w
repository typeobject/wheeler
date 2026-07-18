//! Freezes a byte owner and inspects it through the immutable core UTF-8 API.

module examples.text.frozen_utf8_main;
import wheeler.core.text.utf8;
classical class FrozenUtf8 {
    state long byteLength = 0;
    state long scalarCount = 0;
    state long middleScalar = 0;
    state long valid = 0;

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
        byteLength = byteLength(text);
        scalarCount = scalarCount(text);
        middleScalar = scalarAtByte(text, 1);
        boolean isValid = valid(text);
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
