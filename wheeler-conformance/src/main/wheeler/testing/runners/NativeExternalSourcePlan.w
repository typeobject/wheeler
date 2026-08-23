//! Composes one locked dependency source into one canonical native test source plan.

module wheeler.conformance.testing.runners.native_external_source_plan;

import wheeler.core.encoding.binary;
import wheeler.runtime.testing.runners.test_external_source_plan;
import wheeler.runtime.testing.runners.test_package_lock;

classical class NativeExternalSourcePlan {
  private const long MAX_ARCHIVE_BYTES = 32768;
  private const long MAX_LOCK_BYTES = 4096;
  private const long MAX_COPY_BYTES = 40960;
  private const long MAX_PLAN_BYTES = 40960;

  private long copyRange(
    borrow byteview input,
    long start,
    long length,
    borrow mut bytes output
  ) {
    long offset = 0;
    while (offset < length) limit MAX_COPY_BYTES {
      setByte(output, offset, input[start + offset]);
      offset += 1;
    }

    return offset;
  }

  entry void main(borrow byteview input, borrow mut bytes output) {
    assert(77 < bufferLength(input));
    region arena = new region(/* bytes= */ 196608, /* allocations= */ 40);
    bytes rootIdentity = allocateBytes(arena, /* length= */ 64);
    long copied = copyRange(input, /* start= */ 0, /* length= */ 64, rootIdentity);
    assert(copied == 64);
    long cursor = 64;
    long lockLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(95 < lockLength);
    assert(lockLength < MAX_LOCK_BYTES + 1);
    cursor += 4;
    assert(cursor + lockLength + 11 < bufferLength(input));
    bytes lock = allocateBytes(arena, lockLength);
    copied = copyRange(input, cursor, lockLength, lock);
    assert(copied == lockLength);
    cursor += lockLength;
    long nameLength = input[cursor];
    assert(0 < nameLength);
    cursor += 1;
    assert(cursor + nameLength + 9 < bufferLength(input));
    bytes packageName = allocateBytes(arena, nameLength);
    copied = copyRange(input, cursor, nameLength, packageName);
    assert(copied == nameLength);
    cursor += nameLength;
    long archiveLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(0 < archiveLength);
    assert(archiveLength < MAX_ARCHIVE_BYTES + 1);
    cursor += 4;
    assert(cursor + archiveLength + 5 < bufferLength(input));
    bytes archive = allocateBytes(arena, archiveLength);
    copied = copyRange(input, cursor, archiveLength, archive);
    assert(copied == archiveLength);
    cursor += archiveLength;
    long ordinal = input[cursor];
    cursor += 1;
    long planLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(0 < planLength);
    assert(planLength < MAX_PLAN_BYTES + 1);
    cursor += 4;
    assert(cursor + planLength == bufferLength(input));
    bytes localPlan = allocateBytes(arena, planLength);
    copied = copyRange(input, cursor, planLength, localPlan);
    assert(copied == planLength);
    assert(validPackageLock(lock, /* start= */ 0, lockLength, rootIdentity));
    bytes digest = allocateBytes(arena, /* length= */ 32);
    long outputLength = composeValidatedExternalSourcePlan(
      localPlan,
      lock,
      packageName,
      archive,
      ordinal,
      digest,
      output,
      arena
    );
    setOutputLength(output, outputLength);
    drop(digest);
    drop(localPlan);
    drop(archive);
    drop(packageName);
    drop(lock);
    drop(rootIdentity);
    drop(arena);
  }
}
