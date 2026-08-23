//! Publishes one exact source entry from one validated locked package archive.

module wheeler.conformance.packages.locked_archive_source;

import wheeler.core.encoding.binary;
import wheeler.packages.archive_provenance;
import wheeler.runtime.testing.runners.test_package_lock;

classical class NativeLockedArchiveSource {
  private const long MAX_ARCHIVE_BYTES = 32768;
  private const long MAX_LOCK_BYTES = 4096;

  private long copyRange(
    borrow byteview input,
    long start,
    long length,
    borrow mut bytes output,
    long outputStart
  ) {
    long offset = 0;
    while (offset < length) limit MAX_ARCHIVE_BYTES {
      setByte(output, outputStart + offset, input[start + offset]);
      offset += 1;
    }

    return outputStart + length;
  }

  private void writeUnsigned32(borrow mut bytes output, long offset, long value) {
    setByte(output, offset, value % 256);
    value = value / 256;
    setByte(output, offset + 1, value % 256);
    value = value / 256;
    setByte(output, offset + 2, value % 256);
    value = value / 256;
    setByte(output, offset + 3, value % 256);
  }

  entry void main(borrow byteview input, borrow mut bytes output) {
    assert(73 < bufferLength(input));
    region arena = new region(/* bytes= */ 131072, /* allocations= */ 32);
    bytes rootIdentity = allocateBytes(arena, /* length= */ 64);
    long copied = copyRange(
      input,
      /* start= */ 0,
      /* length= */ 64,
      rootIdentity,
      /* outputStart= */ 0
    );
    assert(copied == 64);
    long cursor = 64;
    long lockLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(95 < lockLength);
    assert(lockLength < MAX_LOCK_BYTES + 1);
    cursor += 4;
    assert(cursor + lockLength + 7 < bufferLength(input));
    bytes lock = allocateBytes(arena, lockLength);
    copied = copyRange(input, cursor, lockLength, lock, /* outputStart= */ 0);
    assert(copied == lockLength);
    cursor += lockLength;
    long nameLength = input[cursor];
    assert(0 < nameLength);
    cursor += 1;
    assert(cursor + nameLength + 5 < bufferLength(input));
    bytes packageName = allocateBytes(arena, nameLength);
    copied = copyRange(input, cursor, nameLength, packageName, /* outputStart= */ 0);
    assert(copied == nameLength);
    cursor += nameLength;
    long archiveLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(0 < archiveLength);
    assert(archiveLength < MAX_ARCHIVE_BYTES + 1);
    cursor += 4;
    assert(cursor + archiveLength + 1 == bufferLength(input));
    bytes archive = allocateBytes(arena, archiveLength);
    copied = copyRange(input, cursor, archiveLength, archive, /* outputStart= */ 0);
    assert(copied == archiveLength);
    cursor += archiveLength;
    long ordinal = input[cursor];
    assert(validPackageLock(lock, /* start= */ 0, lockLength, rootIdentity));
    bytes digest = allocateBytes(arena, /* length= */ 32);
    LockedArchiveEntry selected = validatedLockedArchiveEntry(
      lock,
      packageName,
      archive,
      ordinal,
      digest,
      arena
    );
    long required = selected.pathLength + selected.sourceLength + 8;
    assert(required < bufferLength(output) + 1);
    writeUnsigned32(output, /* offset= */ 0, selected.pathLength);
    long outputCursor = copyRange(
      archive,
      selected.pathStart,
      selected.pathLength,
      output,
      /* outputStart= */ 4
    );
    writeUnsigned32(output, outputCursor, selected.sourceLength);
    outputCursor += 4;
    outputCursor = copyRange(
      archive,
      selected.sourceStart,
      selected.sourceLength,
      output,
      outputCursor
    );
    assert(outputCursor == required);
    setOutputLength(output, required);
    drop(digest);
    drop(archive);
    drop(packageName);
    drop(lock);
    drop(rootIdentity);
    drop(arena);
  }
}
