//! Provides immutable UTF-8 inspection over caller-owned affine text borrows.

module wheeler.core.text.utf8;
classical class Utf8 {
    /// Returns the encoded byte length of one immutable UTF-8 borrow.
    public long byteLength(utf8 text) {
        return bufferLength(text);
    }

    /// Returns the Unicode scalar count of one immutable UTF-8 borrow.
    public long scalarCount(utf8 text) {
        return utf8Count(text);
    }

    /// Reports whether one immutable borrow remains valid strict UTF-8.
    public boolean valid(utf8 text) {
        return utf8Valid(text);
    }

    /// Reads the scalar beginning at a checked UTF-8 byte index.
    public long scalarAtByte(utf8 text, long index) {
        return utf8Scalar(text, index);
    }
}
