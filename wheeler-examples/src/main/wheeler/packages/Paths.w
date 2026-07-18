module examples.packages.paths;
classical class Paths {
    private boolean invalidDotComponent(
        long componentLength,
        long dotCount
    ) {
        if (componentLength == 1) {
            return dotCount == 1;
        }
        if (componentLength == 2) {
            return dotCount == 2;
        }
        return false;
    }

    public boolean validLogicalPath(
        utf8 source,
        long start,
        long length
    ) {
        if (length == 0) {
            return false;
        }
        long cursor = start;
        long end = start + length;
        long componentLength = 0;
        long dotCount = 0;
        while (cursor < end) limit 256 {
            long scalar = utf8Scalar(source, cursor);
            if (scalar == 92) {
                cursor += utf8Width(source, cursor);
                scalar = utf8Scalar(source, cursor);
            }
            if (scalar == 47) {
                if (componentLength == 0) {
                    return false;
                }
                boolean dots = invalidDotComponent(
                    componentLength,
                    dotCount);
                if (dots) {
                    return false;
                }
                componentLength = 0;
                dotCount = 0;
            } else {
                if (scalar == 0) {
                    return false;
                }
                if (scalar == 92) {
                    return false;
                }
                componentLength += 1;
                if (scalar == 46) {
                    dotCount += 1;
                }
            }
            cursor += utf8Width(source, cursor);
        }
        if (componentLength == 0) {
            return false;
        }
        boolean finalDots = invalidDotComponent(
            componentLength,
            dotCount);
        if (finalDots) {
            return false;
        }
        return true;
    }
}
