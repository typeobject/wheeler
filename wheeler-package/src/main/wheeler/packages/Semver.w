//! Validates bounded canonical releases and version constraints.

module wheeler.packages.semver;
classical class Semver {
    private boolean digit(long scalar) {
        if (47 < scalar) {
            return scalar < 58;
        }
        return false;
    }

    private boolean upper(long scalar) {
        if (64 < scalar) {
            return scalar < 91;
        }
        return false;
    }

    private boolean lower(long scalar) {
        if (96 < scalar) {
            return scalar < 123;
        }
        return false;
    }

    private boolean identifierScalar(long scalar) {
        boolean numeric = digit(scalar);
        if (numeric) {
            return true;
        }
        boolean uppercase = upper(scalar);
        if (uppercase) {
            return true;
        }
        boolean lowercase = lower(scalar);
        if (lowercase) {
            return true;
        }
        return scalar == 45;
    }

    private boolean validCore(utf8 source, long start, long length) {
        long cursor = start;
        long end = start + length;
        long dots = 0;
        long digits = 0;
        long first = 0;
        long value = 0;
        while (cursor < end) limit 64 {
            long scalar = utf8Scalar(source, cursor);
            boolean numeric = digit(scalar);
            if (numeric) {
                long valueDigit = scalar - 48;
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
                    if (7 < valueDigit) {
                        return false;
                    }
                }
                value = value * 10 + valueDigit;
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

    private boolean validPrerelease(utf8 source, long start, long length) {
        long cursor = start;
        long end = start + length;
        long partLength = 0;
        long first = 0;
        boolean numericPart = true;
        while (cursor < end) limit 64 {
            long scalar = utf8Scalar(source, cursor);
            if (scalar == 46) {
                if (partLength == 0) {
                    return false;
                }
                if (numericPart) {
                    if (first == 48) {
                        if (1 < partLength) {
                            return false;
                        }
                    }
                }
                partLength = 0;
                first = 0;
                numericPart = true;
            } else {
                boolean allowed = identifierScalar(scalar);
                if (allowed) {
                    if (partLength == 0) {
                        first = scalar;
                    }
                    boolean numeric = digit(scalar);
                    if (numeric) {
                        partLength += 1;
                    } else {
                        numericPart = false;
                        partLength += 1;
                    }
                } else {
                    return false;
                }
            }
            cursor += utf8Width(source, cursor);
        }
        if (partLength == 0) {
            return false;
        }
        if (numericPart) {
            if (first == 48) {
                return partLength == 1;
            }
        }
        return true;
    }

    /// Checks whether `release` satisfies the canonical profile.
    public boolean validRelease(utf8 source, long start, long length) {
        long cursor = start;
        long end = start + length;
        long coreLength = length;
        long prereleaseStart = end;
        boolean hasPrerelease = false;
        while (cursor < end) limit 64 {
            long scalar = utf8Scalar(source, cursor);
            if (scalar == 45) {
                coreLength = cursor - start;
                prereleaseStart = cursor + 1;
                hasPrerelease = true;
                cursor = end;
            } else {
                cursor += utf8Width(source, cursor);
            }
        }
        boolean core = validCore(source, start, coreLength);
        if (core) {
            if (hasPrerelease) {
                return validPrerelease(source, prereleaseStart, end - prereleaseStart);
            }
            return true;
        }
        return false;
    }

    /// Checks whether `constraint` satisfies the canonical profile.
    public boolean validConstraint(utf8 source, long start, long length) {
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

    private boolean prefixedRelease(utf8 source, long start, long length) {
        if (length == 1) {
            return false;
        }
        return validRelease(source, start + 1, length - 1);
    }
}
