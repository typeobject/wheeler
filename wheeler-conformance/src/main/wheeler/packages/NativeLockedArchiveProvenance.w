//! Validates one canonical archive against one complete package-lock row.

module wheeler.conformance.packages.locked_archive_provenance;

import wheeler.core.encoding.binary;
import wheeler.packages.archive_provenance;
import wheeler.runtime.testing.runners.test_package_lock;

classical class NativeLockedArchiveProvenance {
  private const long MAX_ARCHIVE_BYTES = 32768;
  private const long MAX_LOCK_BYTES = 4096;

  private long copyRange(
    borrow byteview input,
    long start,
    long length,
    borrow mut bytes output
  ) {
    long offset = 0;
    while (offset < length) limit MAX_ARCHIVE_BYTES {
      setByte(output, offset, input[start + offset]);
      offset += 1;
    }

    return offset;
  }

  entry void main(borrow byteview input, borrow mut bytes output) {
    assert(72 < bufferLength(input));
    region arena = new region(/* bytes= */ 131072, /* allocations= */ 32);
    bytes rootIdentity = allocateBytes(arena, /* length= */ 64);
    long copied = copyRange(input, /* start= */ 0, /* length= */ 64, rootIdentity);
    assert(copied == 64);
    long cursor = 64;
    long lockLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(95 < lockLength);
    assert(lockLength < MAX_LOCK_BYTES + 1);
    cursor += 4;
    assert(cursor + lockLength + 6 < bufferLength(input));
    bytes lock = allocateBytes(arena, lockLength);
    copied = copyRange(input, cursor, lockLength, lock);
    assert(copied == lockLength);
    cursor += lockLength;
    long nameLength = input[cursor];
    assert(0 < nameLength);
    cursor += 1;
    assert(cursor + nameLength + 4 < bufferLength(input));
    bytes packageName = allocateBytes(arena, nameLength);
    copied = copyRange(input, cursor, nameLength, packageName);
    assert(copied == nameLength);
    cursor += nameLength;
    long archiveLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(0 < archiveLength);
    assert(archiveLength < MAX_ARCHIVE_BYTES + 1);
    cursor += 4;
    assert(cursor + archiveLength == bufferLength(input));
    bytes archive = allocateBytes(arena, archiveLength);
    copied = copyRange(input, cursor, archiveLength, archive);
    assert(copied == archiveLength);
    assert(validPackageLock(lock, /* start= */ 0, lockLength, rootIdentity));
    bytes digest = allocateBytes(arena, /* length= */ 32);
    assert(validLockedArchive(lock, packageName, archive, digest, arena));
    assert(lockedArchiveDependenciesMatch(lock, packageName, archive));
    setByte(output, /* index= */ 0, /* value= */ 1);
    setOutputLength(output, /* length= */ 1);
    drop(digest);
    drop(archive);
    drop(packageName);
    drop(lock);
    drop(rootIdentity);
    drop(arena);
  }
}
