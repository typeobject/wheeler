module examples.packages.semver;
classical class Semver {
    private boolean digit(long scalar) {
        if (47 < scalar) {
            return scalar < 58;
        }
        return false;
    }

    public boolean validRelease(
        utf8 source,
        long start,
        long length
    ) {
        long cursor = start;
        long end = start + length;
        long dots = 0;
        long digits = 0;
        long first = 0;
        long value = 0;
        while (cursor < end) limit 64 {
            long scalar = utf8Scalar(source, cursor);
            if (digit(scalar)) {
                long digit = scalar - 48;
                if (digits == 0) {
                    first = scalar;
                } else {
                    if (first == 48) {
                        return false;
                    }
                }
                if (922337203685477580 < value) {
                    return false;
                }
                if (value == 922337203685477580) {
                    if (7 < digit) {
                        return false;
                    }
                }
                value = value * 10 + digit;
                digits += 1;
            } else {
                if (scalar == 46) {
                    if (digits == 0) {
                        return false;
                    }
                    dots += 1;
                    if (2 < dots) {
                        return false;
                    }
                    digits = 0;
                    first = 0;
                    value = 0;
                } else {
                    return false;
                }
            }
            cursor += utf8Width(source, cursor);
        }
        if (dots == 2) {
            return 0 < digits;
        }
        return false;
    }

    public boolean validConstraint(
        utf8 source,
        long start,
        long length
    ) {
        if (length == 0) {
            return false;
        }
        long scalar = utf8Scalar(source, start);
        if (scalar == 61) {
            return prefixedRelease(source, start, length);
        }
        if (scalar == 94) {
            return prefixedRelease(source, start, length);
        }
        if (scalar == 126) {
            return prefixedRelease(source, start, length);
        }
        return validRelease(source, start, length);
    }

    private boolean prefixedRelease(
        utf8 source,
        long start,
        long length
    ) {
        if (length == 1) {
            return false;
        }
        return validRelease(source, start + 1, length - 1);
    }
}
