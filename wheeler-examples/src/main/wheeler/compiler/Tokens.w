module examples.compiler.tokens;
import examples.lexer.scanner;
classical class Tokens {
    public long tokenHash(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long token
    ) {
        long cursor = tokenStarts[token];
        long end = cursor + tokenLengths[token];
        long hash = 0;
        while (cursor < end) limit 16 {
            hash = hash * 31 + utf8Scalar(source, cursor);
            cursor += utf8Width(source, cursor);
        }
        return hash;
    }

    public boolean punctuationAt(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        long token,
        long scalar
    ) {
        if (tokenKinds[token] == 3) {
            return utf8Scalar(source, tokenStarts[token]) == scalar;
        }
        return false;
    }

    public boolean sameTokenText(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long left,
        long right
    ) {
        if (tokenLengths[left] == tokenLengths[right]) {
            long cursor = 0;
            while (cursor < tokenLengths[left]) limit 256 {
                long leftScalar = utf8Scalar(
                    source, tokenStarts[left] + cursor);
                long rightScalar = utf8Scalar(
                    source, tokenStarts[right] + cursor);
                if (leftScalar < rightScalar) {
                    return false;
                }
                if (rightScalar < leftScalar) {
                    return false;
                }
                cursor += 1;
            }
            return true;
        }
        return false;
    }

    public long signedNumberWidth(
        utf8 source,
        words tokenKinds,
        words tokenStarts,
        long token
    ) {
        if (tokenKinds[token] == 2) {
            return 1;
        }
        if (punctuationAt(source, tokenKinds, tokenStarts, token, 45)) {
            if (tokenKinds[token + 1] == 2) {
                return 2;
            }
        }
        return -1;
    }

    public long statementOpcode(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long statementStart
    ) {
        if (tokenHash(
                source, tokenStarts, tokenLengths, statementStart)
                == 2886759238) {
            return 768;
        }
        long operator = utf8Scalar(
            source, tokenStarts[statementStart + 1]);
        if (operator == 61) {
            return 0;
        }
        if (operator == 43) {
            return 1040;
        }
        if (operator == 45) {
            return 1041;
        }
        if (operator == 94) {
            return 1042;
        }
        return -1;
    }

    public boolean signedNumberValid(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long token
    ) {
        long magnitudeToken = token;
        if (utf8Scalar(source, tokenStarts[token]) == 45) {
            magnitudeToken += 1;
        }
        long end = tokenStarts[magnitudeToken]
            + tokenLengths[magnitudeToken];
        long magnitude = parseNumber(
            source, tokenStarts[magnitudeToken], end);
        if (magnitude < 0) {
            return false;
        }
        return true;
    }

    public long parsedSignedNumber(
        utf8 source,
        words tokenStarts,
        words tokenLengths,
        long token
    ) {
        long magnitudeToken = token;
        long sign = 1;
        if (utf8Scalar(source, tokenStarts[token]) == 45) {
            magnitudeToken += 1;
            sign = -1;
        }
        long end = tokenStarts[magnitudeToken]
            + tokenLengths[magnitudeToken];
        long magnitude = parseNumber(
            source, tokenStarts[magnitudeToken], end);
        return sign * magnitude;
    }
}
