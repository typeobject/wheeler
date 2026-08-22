//! Derives bounded profile-2 test execution identities.

module wheeler.runtime.testing.test_execution_identity;

import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;

classical class TestExecutionIdentity {
  private const long HASH_ARENA_BYTES = 1088;
  private const long MAX_GLOBALS = 64;
  private const long MAX_JOBS = 64;
  private const long MAX_MEASUREMENTS = 1024;
  private const long MAX_NAME_BYTES = 255;
  private const long MAX_OUTPUT_BYTES = 65535;
  private const long MESSAGE_BYTES = 108255;
  private const long OUTPUT_BYTES = 32;
  private const long STAGING_BYTES = 111391;

  private long writeLong(long value, borrow mut bytes output, long cursor) {
    long remaining = value;
    long index = 0;
    while (index < 8) limit 8 {
      long octet = remaining % 256;
      if (octet < 0) {
        octet += 256;
      }

      setByte(output, cursor + 7 - index, octet);
      remaining = (remaining - octet) / 256;
      index += 1;
    }

    return cursor + 8;
  }

  private long writeRange(
    borrow byteview input,
    long start,
    long length,
    borrow mut bytes output,
    long cursor
  ) {
    long offset = 0;
    while (offset < length) limit MAX_OUTPUT_BYTES {
      setByte(output, cursor + offset, input[start + offset]);
      offset += 1;
    }

    return cursor + length;
  }

  private long writeField(
    borrow byteview input,
    long start,
    long length,
    borrow mut bytes output,
    long cursor
  ) {
    cursor = writeLong(length, output, cursor);
    return writeRange(input, start, length, output, cursor);
  }

  private long compareNames(
    borrow byteview input,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long common = leftLength;
    if (rightLength < common) {
      common = rightLength;
    }

    long offset = 0;
    while (offset < common) limit MAX_NAME_BYTES {
      long left = input[leftStart + offset];
      long right = input[rightStart + offset];
      if (left < right) {
        return -1;
      }

      if (right < left) {
        return 1;
      }

      offset += 1;
    }

    if (leftLength < rightLength) {
      return -1;
    }

    if (rightLength < leftLength) {
      return 1;
    }

    return 0;
  }

  private void validateName(borrow byteview input, long start, long length) {
    assert(0 < length);
    assert(length < MAX_NAME_BYTES + 1);
    long offset = 0;
    while (offset < length) limit MAX_NAME_BYTES {
      long value = input[start + offset];
      boolean valid = value == 46;
      if (47 < value) {
        if (value < 58) {
          valid = true;
        }
      }

      if (64 < value) {
        if (value < 91) {
          valid = true;
        }
      }

      if (value == 95) {
        valid = true;
      }

      if (96 < value) {
        if (value < 123) {
          valid = true;
        }
      }

      assert(valid);
      offset += 1;
    }
  }

  /// Writes the raw SHA-256 identity for one normalized stage-0 execution result.
  public long deriveTestExecutionIdentity(borrow byteview input, borrow mut bytes output) {
    assert(bufferLength(output) == OUTPUT_BYTES);
    assert(4 < bufferLength(input));
    long programLength = readUnsigned(input, /* offset= */ 0, /* width= */ 2);
    assert(0 < programLength);
    assert(programLength < MAX_NAME_BYTES + 1);
    assert(programLength < bufferLength(input) - 2);
    long programStart = 2;
    long cursor = programStart + programLength;
    long kind = input[cursor];
    cursor += 1;
    assert(kind < 3);
    assert(cursor < bufferLength(input) - 1);
    long globalCount = readUnsigned(input, cursor, /* width= */ 2);
    cursor += 2;
    assert(globalCount < MAX_GLOBALS + 1);

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 8);
    words starts = allocate(staging, MAX_GLOBALS);
    words lengths = allocate(staging, MAX_GLOBALS);
    words values = allocate(staging, MAX_GLOBALS);
    words order = allocate(staging, MAX_GLOBALS);
    bytes message = allocateBytes(staging, MESSAGE_BYTES);
    long global = 0;
    while (global < globalCount) limit MAX_GLOBALS {
      assert(cursor < bufferLength(input) - 1);
      long nameLength = readUnsigned(input, cursor, /* width= */ 2);
      cursor += 2;
      assert(nameLength < bufferLength(input) - cursor - 7);
      validateName(input, cursor, nameLength);
      set(starts, global, cursor);
      set(lengths, global, nameLength);
      cursor += nameLength;
      set(values, global, readSigned(input, cursor));
      cursor += 8;
      set(order, global, global);
      global += 1;
    }

    global = 1;
    while (global < globalCount) limit MAX_GLOBALS {
      long selected = order[global];
      long position = global;
      boolean shifting = 0 < position;
      while (shifting) limit MAX_GLOBALS {
        long prior = order[position - 1];
        if (
          compareNames(
            input,
            starts[selected],
            lengths[selected],
            starts[prior],
            lengths[prior]
          ) < 0
        ) {
          set(order, position, prior);
          position -= 1;
          shifting = 0 < position;
        } else {
          shifting = false;
        }
      }

      set(order, position, selected);
      global += 1;
    }

    global = 1;
    while (global < globalCount) limit MAX_GLOBALS {
      long left = order[global - 1];
      long right = order[global];
      assert(
        compareNames(input, starts[left], lengths[left], starts[right], lengths[right]) != 0
      );
      global += 1;
    }

    long written = writeLong(/* length= */ 24, message, /* cursor= */ 0);
    writeAscii(message, written, "wheeler.test-execution/1");
    written += 24;
    written = writeField(input, programStart, programLength, message, written);
    if (kind == 0) {
      written = writeLong(/* length= */ 9, message, written);
      writeAscii(message, written, "CLASSICAL");
      written += 9;
    }

    if (kind == 1) {
      written = writeLong(/* length= */ 7, message, written);
      writeAscii(message, written, "QUANTUM");
      written += 7;
    }

    if (kind == 2) {
      written = writeLong(/* length= */ 6, message, written);
      writeAscii(message, written, "HYBRID");
      written += 6;
    }

    written = writeLong(globalCount, message, written);
    global = 0;
    while (global < globalCount) limit MAX_GLOBALS {
      long emitted = order[global];
      written = writeField(input, starts[emitted], lengths[emitted], message, written);
      written = writeLong(values[emitted], message, written);
      global += 1;
    }

    assert(cursor < bufferLength(input) - 1);
    long measurementCount = readUnsigned(input, cursor, /* width= */ 2);
    cursor += 2;
    assert(measurementCount < MAX_MEASUREMENTS + 1);
    assert(measurementCount * 8 < bufferLength(input) - cursor + 1);
    written = writeLong(measurementCount, message, written);
    long measurement = 0;
    while (measurement < measurementCount) limit MAX_MEASUREMENTS {
      written = writeLong(readSigned(input, cursor), message, written);
      cursor += 8;
      measurement += 1;
    }

    assert(cursor < bufferLength(input) - 1);
    long jobCount = readUnsigned(input, cursor, /* width= */ 2);
    cursor += 2;
    assert(jobCount < MAX_JOBS + 1);
    written = writeLong(jobCount, message, written);
    long job = 0;
    while (job < jobCount) limit MAX_JOBS {
      assert(cursor < bufferLength(input) - 1);
      long jobLength = readUnsigned(input, cursor, /* width= */ 2);
      cursor += 2;
      assert(jobLength < MAX_NAME_BYTES + 1);
      assert(jobLength < bufferLength(input) - cursor + 1);
      written = writeField(input, cursor, jobLength, message, written);
      cursor += jobLength;
      job += 1;
    }

    assert(cursor < bufferLength(input) - 11);
    long workflowSteps = readSigned(input, cursor);
    assert(-1 < workflowSteps);
    cursor += 8;
    written = writeLong(workflowSteps, message, written);
    long outputLength = readUnsigned(input, cursor, /* width= */ 4);
    cursor += 4;
    assert(outputLength < MAX_OUTPUT_BYTES + 1);
    assert(outputLength == bufferLength(input) - cursor);
    written = writeField(input, cursor, outputLength, message, written);

    hashSha256Range(message, /* inputStart= */ 0, written, output, staging);
    drop(message);
    drop(order);
    drop(values);
    drop(lengths);
    drop(starts);
    drop(staging);
    return OUTPUT_BYTES;
  }
}
