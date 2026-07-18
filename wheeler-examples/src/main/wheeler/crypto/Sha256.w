module examples.crypto.sha256;
classical class Sha256 {
    private long mod32(long value) {
        return value % 4294967296;
    }

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

    private long bitAnd(long left, long right) {
        long differing = left ^ right;
        return (left + right - differing) / 2;
    }

    private long rotateRight(long value, long amount) {
        if (amount == 2) {
            return value / 4 + value % 4 * 1073741824;
        }
        if (amount == 6) {
            return value / 64 + value % 64 * 67108864;
        }
        if (amount == 7) {
            return value / 128 + value % 128 * 33554432;
        }
        if (amount == 11) {
            return value / 2048 + value % 2048 * 2097152;
        }
        if (amount == 13) {
            return value / 8192 + value % 8192 * 524288;
        }
        if (amount == 17) {
            return value / 131072 + value % 131072 * 32768;
        }
        if (amount == 18) {
            return value / 262144 + value % 262144 * 16384;
        }
        if (amount == 19) {
            return value / 524288 + value % 524288 * 8192;
        }
        if (amount == 22) {
            return value / 4194304 + value % 4194304 * 1024;
        }
        return value / 33554432 + value % 33554432 * 128;
    }

    private long choose(long first, long second, long third) {
        long selected = bitAnd(first, second);
        long rejected = bitAnd(4294967295 - first, third);
        return selected ^ rejected;
    }

    private long majority(long first, long second, long third) {
        long firstSecond = bitAnd(first, second);
        long firstThird = bitAnd(first, third);
        long secondThird = bitAnd(second, third);
        return firstSecond ^ firstThird ^ secondThird;
    }

    private long largeSigma0(long value) {
        return rotateRight(value, 2)
            ^ rotateRight(value, 13)
            ^ rotateRight(value, 22);
    }

    private long largeSigma1(long value) {
        return rotateRight(value, 6)
            ^ rotateRight(value, 11)
            ^ rotateRight(value, 25);
    }

    private long smallSigma0(long value) {
        return rotateRight(value, 7)
            ^ rotateRight(value, 18)
            ^ value / 8;
    }

    private long smallSigma1(long value) {
        return rotateRight(value, 17)
            ^ rotateRight(value, 19)
            ^ value / 1024;
    }

    private long roundConstant(long index) {
        if (index == 0) { return 1116352408; }
        if (index == 1) { return 1899447441; }
        if (index == 2) { return 3049323471; }
        if (index == 3) { return 3921009573; }
        if (index == 4) { return 961987163; }
        if (index == 5) { return 1508970993; }
        if (index == 6) { return 2453635748; }
        if (index == 7) { return 2870763221; }
        if (index == 8) { return 3624381080; }
        if (index == 9) { return 310598401; }
        if (index == 10) { return 607225278; }
        if (index == 11) { return 1426881987; }
        if (index == 12) { return 1925078388; }
        if (index == 13) { return 2162078206; }
        if (index == 14) { return 2614888103; }
        if (index == 15) { return 3248222580; }
        if (index == 16) { return 3835390401; }
        if (index == 17) { return 4022224774; }
        if (index == 18) { return 264347078; }
        if (index == 19) { return 604807628; }
        if (index == 20) { return 770255983; }
        if (index == 21) { return 1249150122; }
        if (index == 22) { return 1555081692; }
        if (index == 23) { return 1996064986; }
        if (index == 24) { return 2554220882; }
        if (index == 25) { return 2821834349; }
        if (index == 26) { return 2952996808; }
        if (index == 27) { return 3210313671; }
        if (index == 28) { return 3336571891; }
        if (index == 29) { return 3584528711; }
        if (index == 30) { return 113926993; }
        if (index == 31) { return 338241895; }
        if (index == 32) { return 666307205; }
        if (index == 33) { return 773529912; }
        if (index == 34) { return 1294757372; }
        if (index == 35) { return 1396182291; }
        if (index == 36) { return 1695183700; }
        if (index == 37) { return 1986661051; }
        if (index == 38) { return 2177026350; }
        if (index == 39) { return 2456956037; }
        if (index == 40) { return 2730485921; }
        if (index == 41) { return 2820302411; }
        if (index == 42) { return 3259730800; }
        if (index == 43) { return 3345764771; }
        if (index == 44) { return 3516065817; }
        if (index == 45) { return 3600352804; }
        if (index == 46) { return 4094571909; }
        if (index == 47) { return 275423344; }
        if (index == 48) { return 430227734; }
        if (index == 49) { return 506948616; }
        if (index == 50) { return 659060556; }
        if (index == 51) { return 883997877; }
        if (index == 52) { return 958139571; }
        if (index == 53) { return 1322822218; }
        if (index == 54) { return 1537002063; }
        if (index == 55) { return 1747873779; }
        if (index == 56) { return 1955562222; }
        if (index == 57) { return 2024104815; }
        if (index == 58) { return 2227730452; }
        if (index == 59) { return 2361852424; }
        if (index == 60) { return 2428436474; }
        if (index == 61) { return 2756734187; }
        if (index == 62) { return 3204031479; }
        return 3329325298;
    }

    private long paddedByte(
        byteview input,
        long inputLength,
        long paddedLength,
        long index
    ) {
        if (index < inputLength) {
            return input[index];
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
        words hash = allocate(arena, 8);
        words schedule = allocate(arena, 64);
        set(hash, 0, 1779033703);
        set(hash, 1, 3144134277);
        set(hash, 2, 1013904242);
        set(hash, 3, 2773480762);
        set(hash, 4, 1359893119);
        set(hash, 5, 2600822924);
        set(hash, 6, 528734635);
        set(hash, 7, 1541459225);
        long inputLength = bufferLength(input);
        long totalLength = paddedLength(inputLength);
        long blockStart = 0;
        while (blockStart < totalLength) limit 4096 {
            long wordIndex = 0;
            while (wordIndex < 16) limit 16 {
                long sourceIndex = blockStart + wordIndex * 4;
                long word = paddedByte(
                        input, inputLength, totalLength, sourceIndex)
                    * 16777216;
                word += paddedByte(
                        input, inputLength, totalLength, sourceIndex + 1)
                    * 65536;
                word += paddedByte(
                        input, inputLength, totalLength, sourceIndex + 2)
                    * 256;
                word += paddedByte(
                    input, inputLength, totalLength, sourceIndex + 3);
                set(schedule, wordIndex, word);
                wordIndex += 1;
            }
            while (wordIndex < 64) limit 48 {
                long expanded = smallSigma1(schedule[wordIndex - 2]);
                expanded += schedule[wordIndex - 7];
                expanded += smallSigma0(schedule[wordIndex - 15]);
                expanded += schedule[wordIndex - 16];
                set(schedule, wordIndex, mod32(expanded));
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
                long temporary1 = h + largeSigma1(e);
                temporary1 += choose(e, f, g);
                temporary1 += roundConstant(round);
                temporary1 += schedule[round];
                temporary1 = mod32(temporary1);
                long temporary2 = mod32(
                    largeSigma0(a) + majority(a, b, c));
                h = g;
                g = f;
                f = e;
                e = mod32(d + temporary1);
                d = c;
                c = b;
                b = a;
                a = mod32(temporary1 + temporary2);
                round += 1;
            }
            set(hash, 0, mod32(hash[0] + a));
            set(hash, 1, mod32(hash[1] + b));
            set(hash, 2, mod32(hash[2] + c));
            set(hash, 3, mod32(hash[3] + d));
            set(hash, 4, mod32(hash[4] + e));
            set(hash, 5, mod32(hash[5] + f));
            set(hash, 6, mod32(hash[6] + g));
            set(hash, 7, mod32(hash[7] + h));
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
        drop(schedule);
        drop(hash);
    }
}
