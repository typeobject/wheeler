module examples.packages.names;
classical class Names {
    private boolean lowercase(long scalar) {
        if (96 < scalar) {
            return scalar < 123;
        }
        return false;
    }

    private boolean digit(long scalar) {
        if (47 < scalar) {
            return scalar < 58;
        }
        return false;
    }

    public boolean validPackageName(
        utf8 source,
        long start,
        long length
    ) {
        if (length == 0) {
            return false;
        }
        long cursor = start;
        long end = start + length;
        boolean segmentStart = true;
        while (cursor < end) limit 128 {
            long scalar = utf8Scalar(source, cursor);
            if (segmentStart) {
                boolean letter = lowercase(scalar);
                if (letter) {
                    segmentStart = false;
                } else {
                    return false;
                }
            } else {
                boolean followingLetter = lowercase(scalar);
                if (followingLetter) {
                    segmentStart = false;
                } else {
                    boolean numeric = digit(scalar);
                    if (numeric) {
                        segmentStart = false;
                    } else {
                        if (scalar == 46) {
                            segmentStart = true;
                        } else {
                            return false;
                        }
                    }
                }
            }
            cursor += utf8Width(source, cursor);
        }
        if (segmentStart) {
            return false;
        }
        return true;
    }
}
