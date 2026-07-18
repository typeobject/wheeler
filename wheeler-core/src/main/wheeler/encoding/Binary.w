//! Reads bounded little-endian fields and validates canonical text atoms.

module wheeler.core.encoding.binary;
classical class Binary {
    /// Reads `unsigned` from a bounded canonical input.
    public long readUnsigned(byteview source, long offset, long width) {
        long result = 0;
        long multiplier = 1;
        long cursor = 0;
        while (cursor < width) limit 8 {
            result += source[offset + cursor] * multiplier;
            cursor += 1;
            if (cursor < width) {
                multiplier = multiplier * 256;
            }
        }
        return result;
    }

    private boolean lowercase(long value) {
        if (96 < value) {
            return value < 123;
        }
        return false;
    }

    private boolean digit(long value) {
        if (47 < value) {
            return value < 58;
        }
        return false;
    }

    /// Compares `asciiRanges` under canonical byte ordering.
    public long compareAsciiRanges(
        byteview source,
        long leftStart,
        long leftLength,
        long rightStart,
        long rightLength
    ) {
        long cursor = 0;
        while (cursor < leftLength) limit 4096 {
            if (cursor < rightLength) {
                long left = source[leftStart + cursor];
                long right = source[rightStart + cursor];
                if (left < right) {
                    return -1;
                }
                if (right < left) {
                    return 1;
                }
                cursor += 1;
            } else {
                return 1;
            }
        }
        if (cursor < rightLength) {
            return -1;
        }
        return 0;
    }

    /// Checks whether `asciiName` satisfies the canonical profile.
    public boolean validAsciiName(byteview source, long start, long length) {
        if (length == 0) {
            return false;
        }
        if (lowercase(source[start])) {} else {
            return false;
        }
        boolean needValue = false;
        long cursor = 1;
        while (cursor < length) limit 256 {
            long value = source[start + cursor];
            if (needValue) {
                if (lowercase(value)) {
                    needValue = false;
                } else {
                    if (digit(value)) {
                        needValue = false;
                    } else {
                        return false;
                    }
                }
            } else {
                if (lowercase(value)) {} else {
                    if (digit(value)) {} else {
                        if (value == 45) {
                            needValue = true;
                        } else {
                            if (value == 46) {
                                needValue = true;
                            } else {
                                return false;
                            }
                        }
                    }
                }
            }
            cursor += 1;
        }
        if (needValue) {
            return false;
        }
        return true;
    }

    /// Checks whether `numericRelease` satisfies the canonical profile.
    public boolean validNumericRelease(byteview source, long start, long length) {
        if (length < 5) {
            return false;
        }
        long component = 0;
        long digits = 0;
        long cursor = 0;
        boolean leadingZero = false;
        while (cursor < length) limit 64 {
            long value = source[start + cursor];
            if (digit(value)) {
                if (digits == 0) {
                    leadingZero = value == 48;
                } else {
                    if (leadingZero) {
                        return false;
                    }
                }
                digits += 1;
            } else {
                if (value == 46) {
                    if (digits == 0) {
                        return false;
                    }
                    component += 1;
                    digits = 0;
                    leadingZero = false;
                } else {
                    return false;
                }
            }
            cursor += 1;
        }
        if (digits == 0) {
            return false;
        }
        return component == 2;
    }

    /// Checks whether `asciiPath` satisfies the canonical profile.
    public boolean validAsciiPath(byteview source, long start, long length) {
        if (length == 0) {
            return false;
        }
        if (source[start] == 47) {
            return false;
        }
        if (source[start + length - 1] == 47) {
            return false;
        }
        long componentStart = 0;
        long cursor = 0;
        while (cursor < length) limit 256 {
            long value = source[start + cursor];
            if (value < 32) {
                return false;
            }
            if (126 < value) {
                return false;
            }
            if (value == 92) {
                return false;
            }
            if (value == 47) {
                long componentLength = cursor - componentStart;
                if (componentLength == 0) {
                    return false;
                }
                if (componentLength == 1) {
                    if (source[start + componentStart] == 46) {
                        return false;
                    }
                }
                if (componentLength == 2) {
                    if (source[start + componentStart] == 46) {
                        if (source[start + componentStart + 1] == 46) {
                            return false;
                        }
                    }
                }
                componentStart = cursor + 1;
            }
            cursor += 1;
        }
        long finalLength = length - componentStart;
        if (finalLength == 1) {
            if (source[start + componentStart] == 46) {
                return false;
            }
        }
        if (finalLength == 2) {
            if (source[start + componentStart] == 46) {
                if (source[start + componentStart + 1] == 46) {
                    return false;
                }
            }
        }
        return true;
    }
}
