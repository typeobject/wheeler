//! Parses and validates bounded locked archive frames for native test source plans.

module wheeler.runtime.testing.runners.test_external_source_transport;

import wheeler.core.encoding.binary;
import wheeler.runtime.testing.runners.test_external_source_plan;

classical class TestExternalSourceTransport {
  private const long MAX_ARCHIVE_BYTES = 32768;
  private const long MAX_COPY_BYTES = 32768;

  /// Identifies zero, one, or two complete archive frames in borrowed transport storage.
  public record ExternalSourceArchives(
    long count,
    long end,
    long firstNameStart,
    long firstNameLength,
    long firstArchiveStart,
    long firstArchiveLength,
    long secondNameStart,
    long secondNameLength,
    long secondArchiveStart,
    long secondArchiveLength
  ) {}

  private long copyRange(
    borrow byteview input,
    long inputStart,
    long length,
    borrow mut bytes output
  ) {
    long offset = 0;
    while (offset < length) limit MAX_COPY_BYTES {
      setByte(output, offset, input[inputStart + offset]);
      offset += 1;
    }

    return offset;
  }

  /// Parses complete archive boundaries without validating archive semantics.
  public ExternalSourceArchives validatedExternalSourceArchives(borrow byteview input, long start) {
    assert(start < bufferLength(input));
    long count = input[start];
    assert(count < 3);
    long cursor = start + 1;
    long firstNameStart = 0;
    long firstNameLength = 0;
    long firstArchiveStart = 0;
    long firstArchiveLength = 0;
    long secondNameStart = 0;
    long secondNameLength = 0;
    long secondArchiveStart = 0;
    long secondArchiveLength = 0;
    if (0 < count) {
      firstNameLength = input[cursor];
      assert(0 < firstNameLength);
      cursor += 1;
      assert(cursor + firstNameLength + 4 < bufferLength(input));
      firstNameStart = cursor;
      cursor += firstNameLength;
      firstArchiveLength = readUnsigned(input, cursor, /* width= */ 4);
      assert(15 < firstArchiveLength);
      assert(firstArchiveLength < MAX_ARCHIVE_BYTES + 1);
      cursor += 4;
      assert(cursor + firstArchiveLength + 4 < bufferLength(input));
      firstArchiveStart = cursor;
      cursor += firstArchiveLength;
    }

    if (count == 2) {
      secondNameLength = input[cursor];
      assert(0 < secondNameLength);
      cursor += 1;
      assert(cursor + secondNameLength + 4 < bufferLength(input));
      secondNameStart = cursor;
      cursor += secondNameLength;
      secondArchiveLength = readUnsigned(input, cursor, /* width= */ 4);
      assert(15 < secondArchiveLength);
      assert(secondArchiveLength < MAX_ARCHIVE_BYTES + 1);
      cursor += 4;
      assert(cursor + secondArchiveLength + 4 < bufferLength(input));
      secondArchiveStart = cursor;
      cursor += secondArchiveLength;
    }

    return new ExternalSourceArchives(
      count,
      cursor,
      firstNameStart,
      firstNameLength,
      firstArchiveStart,
      firstArchiveLength,
      secondNameStart,
      secondNameLength,
      secondArchiveStart,
      secondArchiveLength
    );
  }

  private boolean validOneArchive(
    borrow byteview input,
    long nameStart,
    long nameLength,
    long archiveStart,
    long archiveLength,
    borrow byteview lock,
    borrow byteview plan,
    borrow mut bytes digest,
    borrow mut region arena
  ) {
    bytes packageName = allocateBytes(arena, nameLength);
    long copied = copyRange(input, nameStart, nameLength, packageName);
    assert(copied == nameLength);
    bytes archive = allocateBytes(arena, archiveLength);
    copied = copyRange(input, archiveStart, archiveLength, archive);
    assert(copied == archiveLength);
    boolean valid = validLockedExternalSourcePlan(
      plan,
      lock,
      packageName,
      archive,
      digest,
      arena
    );
    drop(archive);
    drop(packageName);
    return valid;
  }

  /// Binds every external plan source to exactly one transported locked archive entry.
  public boolean validFramedExternalSourcePlan(
    borrow byteview input,
    ExternalSourceArchives archives,
    long lockStart,
    long lockLength,
    long planStart,
    long planLength,
    borrow mut region arena
  ) {
    long externalCount = validatedExternalSourceCount(input, planStart, planLength);
    if (archives.count == 0) {
      return externalCount == 0;
    }

    if (externalCount == 0) {
      return false;
    }

    long committedCount = readUnsigned(input, archives.firstArchiveStart + 12, /* width= */ 4);
    if (archives.count == 2) {
      committedCount += readUnsigned(input, archives.secondArchiveStart + 12, /* width= */ 4);
    }

    if (7 < committedCount) {
      return false;
    }

    if (externalCount != committedCount) {
      return false;
    }

    bytes lock = allocateBytes(arena, lockLength);
    long copied = copyRange(input, lockStart, lockLength, lock);
    assert(copied == lockLength);
    bytes plan = allocateBytes(arena, planLength);
    copied = copyRange(input, planStart, planLength, plan);
    assert(copied == planLength);
    bytes digest = allocateBytes(arena, /* length= */ 32);
    boolean valid = validOneArchive(
      input,
      archives.firstNameStart,
      archives.firstNameLength,
      archives.firstArchiveStart,
      archives.firstArchiveLength,
      lock,
      plan,
      digest,
      arena
    );
    if (valid) {
      if (archives.count == 2) {
        valid = validOneArchive(
          input,
          archives.secondNameStart,
          archives.secondNameLength,
          archives.secondArchiveStart,
          archives.secondArchiveLength,
          lock,
          plan,
          digest,
          arena
        );
      }
    }

    drop(digest);
    drop(plan);
    drop(lock);
    return valid;
  }
}
