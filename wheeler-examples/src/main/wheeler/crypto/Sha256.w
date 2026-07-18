module examples.crypto.sha256;
classical class Sha256 {
    private long byteShiftPower(long exponent) {
        if (exponent == 0) { return 1; }
        if (exponent == 8) { return 256; }
        if (exponent == 16) { return 65536; }
        if (exponent == 24) { return 16777216; }
        if (exponent == 32) { return 4294967296; }
        if (exponent == 40) { return 1099511627776; }
        if (exponent == 48) { return 281474976710656; }
        return 72057594037927936;
    }

    private void initializeConstants(words constants) {
        set(constants, 0, 1116352408);
        set(constants, 1, 1899447441);
        set(constants, 2, 3049323471);
        set(constants, 3, 3921009573);
        set(constants, 4, 961987163);
        set(constants, 5, 1508970993);
        set(constants, 6, 2453635748);
        set(constants, 7, 2870763221);
        set(constants, 8, 3624381080);
        set(constants, 9, 310598401);
        set(constants, 10, 607225278);
        set(constants, 11, 1426881987);
        set(constants, 12, 1925078388);
        set(constants, 13, 2162078206);
        set(constants, 14, 2614888103);
        set(constants, 15, 3248222580);
        set(constants, 16, 3835390401);
        set(constants, 17, 4022224774);
        set(constants, 18, 264347078);
        set(constants, 19, 604807628);
        set(constants, 20, 770255983);
        set(constants, 21, 1249150122);
        set(constants, 22, 1555081692);
        set(constants, 23, 1996064986);
        set(constants, 24, 2554220882);
        set(constants, 25, 2821834349);
        set(constants, 26, 2952996808);
        set(constants, 27, 3210313671);
        set(constants, 28, 3336571891);
        set(constants, 29, 3584528711);
        set(constants, 30, 113926993);
        set(constants, 31, 338241895);
        set(constants, 32, 666307205);
        set(constants, 33, 773529912);
        set(constants, 34, 1294757372);
        set(constants, 35, 1396182291);
        set(constants, 36, 1695183700);
        set(constants, 37, 1986661051);
        set(constants, 38, 2177026350);
        set(constants, 39, 2456956037);
        set(constants, 40, 2730485921);
        set(constants, 41, 2820302411);
        set(constants, 42, 3259730800);
        set(constants, 43, 3345764771);
        set(constants, 44, 3516065817);
        set(constants, 45, 3600352804);
        set(constants, 46, 4094571909);
        set(constants, 47, 275423344);
        set(constants, 48, 430227734);
        set(constants, 49, 506948616);
        set(constants, 50, 659060556);
        set(constants, 51, 883997877);
        set(constants, 52, 958139571);
        set(constants, 53, 1322822218);
        set(constants, 54, 1537002063);
        set(constants, 55, 1747873779);
        set(constants, 56, 1955562222);
        set(constants, 57, 2024104815);
        set(constants, 58, 2227730452);
        set(constants, 59, 2361852424);
        set(constants, 60, 2428436474);
        set(constants, 61, 2756734187);
        set(constants, 62, 3204031479);
        set(constants, 63, 3329325298);
    }

    private long paddedByte(
        byteview input,
        long inputStart,
        long inputLength,
        long paddedLength,
        long index
    ) {
        if (index < inputLength) {
            return input[inputStart + index];
        }
        if (index == inputLength) {
            return 128;
        }
        long lengthStart = paddedLength - 8;
        if (index < lengthStart) {
            return 0;
        }
        long bytePosition = index - lengthStart;
        long shiftBytes = 7 - bytePosition;
        long bitLength = inputLength * 8;
        return bitLength / byteShiftPower(shiftBytes * 8) % 256;
    }

    private long paddedLength(long inputLength) {
        long result = inputLength + 9;
        long remainder = result % 64;
        if (0 < remainder) {
            result += 64 - remainder;
        }
        return result;
    }

    public void hashSha256(
        byteview input,
        bytes digest,
        region arena
    ) {
        hashSha256Range(
            input, 0, bufferLength(input), digest, arena);
    }

    public void hashSha256Range(
        byteview input,
        long inputStart,
        long inputLength,
        bytes digest,
        region arena
    ) {
        if (inputStart < 0) {
            long invalidStart = input[-1];
        }
        if (inputLength < 0) {
            long invalidLength = input[-1];
        }
        long inputEnd = inputStart + inputLength;
        if (bufferLength(input) < inputEnd) {
            long invalidEnd = input[inputEnd];
        }
        words hash = allocate(arena, 8);
        words schedule = allocate(arena, 64);
        words constants = allocate(arena, 64);
        initializeConstants(constants);
        set(hash, 0, 1779033703);
        set(hash, 1, 3144134277);
        set(hash, 2, 1013904242);
        set(hash, 3, 2773480762);
        set(hash, 4, 1359893119);
        set(hash, 5, 2600822924);
        set(hash, 6, 528734635);
        set(hash, 7, 1541459225);
        long totalLength = paddedLength(inputLength);
        long blockStart = 0;
        while (blockStart < totalLength) limit 4096 {
            long wordIndex = 0;
            while (wordIndex < 16) limit 16 {
                long sourceIndex = blockStart + wordIndex * 4;
                long word = paddedByte(
                        input,
                        inputStart,
                        inputLength,
                        totalLength,
                        sourceIndex)
                    * 16777216;
                word += paddedByte(
                        input,
                        inputStart,
                        inputLength,
                        totalLength,
                        sourceIndex + 1)
                    * 65536;
                word += paddedByte(
                        input,
                        inputStart,
                        inputLength,
                        totalLength,
                        sourceIndex + 2)
                    * 256;
                word += paddedByte(
                    input,
                    inputStart,
                    inputLength,
                    totalLength,
                    sourceIndex + 3);
                set(schedule, wordIndex, word);
                wordIndex += 1;
            }
            while (wordIndex < 64) limit 48 {
                long sigmaOneValue = schedule[wordIndex - 2];
                long sigmaOneRight17 = rotateRight32(
                    sigmaOneValue, 17);
                long sigmaOneRight19 = rotateRight32(
                    sigmaOneValue, 19);
                long sigmaOne = sigmaOneRight17
                    ^ sigmaOneRight19
                    ^ sigmaOneValue / 1024;
                long sigmaZeroValue = schedule[wordIndex - 15];
                long sigmaZeroRight7 = rotateRight32(
                    sigmaZeroValue, 7);
                long sigmaZeroRight18 = rotateRight32(
                    sigmaZeroValue, 18);
                long sigmaZero = sigmaZeroRight7
                    ^ sigmaZeroRight18
                    ^ sigmaZeroValue / 8;
                long expanded = sigmaOne + schedule[wordIndex - 7];
                expanded += sigmaZero;
                expanded += schedule[wordIndex - 16];
                set(schedule, wordIndex, expanded % 4294967296);
                wordIndex += 1;
            }
            long a = hash[0];
            long b = hash[1];
            long c = hash[2];
            long d = hash[3];
            long e = hash[4];
            long f = hash[5];
            long g = hash[6];
            long h = hash[7];
            long round = 0;
            while (round < 64) limit 64 {
                long eRight6 = rotateRight32(e, 6);
                long eRight11 = rotateRight32(e, 11);
                long eRight25 = rotateRight32(e, 25);
                long eSigma = eRight6 ^ eRight11 ^ eRight25;
                long selected = e & f;
                long complement = 4294967295 - e;
                long rejected = complement & g;
                long choice = selected ^ rejected;
                long temporary1 = h + eSigma + choice;
                temporary1 += constants[round];
                temporary1 += schedule[round];
                temporary1 = temporary1 % 4294967296;
                long aRight2 = rotateRight32(a, 2);
                long aRight13 = rotateRight32(a, 13);
                long aRight22 = rotateRight32(a, 22);
                long aSigma = aRight2 ^ aRight13 ^ aRight22;
                long ab = a & b;
                long ac = a & c;
                long bc = b & c;
                long majorityValue = ab ^ ac ^ bc;
                long temporary2 = (aSigma + majorityValue) % 4294967296;
                h = g;
                g = f;
                f = e;
                e = (d + temporary1) % 4294967296;
                d = c;
                c = b;
                b = a;
                a = (temporary1 + temporary2) % 4294967296;
                round += 1;
            }
            set(hash, 0, (hash[0] + a) % 4294967296);
            set(hash, 1, (hash[1] + b) % 4294967296);
            set(hash, 2, (hash[2] + c) % 4294967296);
            set(hash, 3, (hash[3] + d) % 4294967296);
            set(hash, 4, (hash[4] + e) % 4294967296);
            set(hash, 5, (hash[5] + f) % 4294967296);
            set(hash, 6, (hash[6] + g) % 4294967296);
            set(hash, 7, (hash[7] + h) % 4294967296);
            blockStart += 64;
        }
        long digestWord = 0;
        while (digestWord < 8) limit 8 {
            long value = hash[digestWord];
            setByte(digest, digestWord * 4, value / 16777216 % 256);
            setByte(digest, digestWord * 4 + 1, value / 65536 % 256);
            setByte(digest, digestWord * 4 + 2, value / 256 % 256);
            setByte(digest, digestWord * 4 + 3, value % 256);
            digestWord += 1;
        }
        drop(constants);
        drop(schedule);
        drop(hash);
    }
}
