//! Decodes bounded aggregate layouts from validated source-local bytecode products.

module wheeler.compiler.closure.compiled_aggregate_layouts;

import wheeler.core.encoding.binary;

classical class CompiledAggregateLayouts {
  private const long AGGREGATE_ROWS = 576;
  private const long CASE_ROWS = 512;
  private const long MEMBER_ROWS = 1024;
  private const long MAX_AGGREGATES_PER_MODULE = 64;
  private const long MAX_CASES_PER_MODULE = 128;
  private const long MAX_MEMBERS_PER_MODULE = 256;
  private const long MAX_SECTIONS = 64;

  /// Names a validated bytecode section range.
  private record SectionRange(boolean valid, long start, long length) {}

  /// Reports the aggregate rows published for one compiled module product.
  public record CompiledAggregatePlan(long aggregateCount, long caseCount, long memberCount) {}

  private boolean rangeValid(long start, long length, long artifactLength) {
    boolean valid = true;
    if (start < 0) {
      valid = false;
    }

    if (length < 0) {
      valid = false;
    }

    if (artifactLength < start) {
      valid = false;
    }

    if (valid) {
      if (artifactLength - start < length) {
        valid = false;
      }
    }

    return valid;
  }

  private SectionRange sectionRange(
    borrow byteview artifact,
    long artifactLength,
    long wantedType
  ) {
    if (artifactLength < 40) {
      return new SectionRange(false, 0, 0);
    }

    boolean headerValid = true;
    if (artifact[0] != 87) {
      headerValid = false;
    }

    if (artifact[1] != 72) {
      headerValid = false;
    }

    if (artifact[2] != 69) {
      headerValid = false;
    }

    if (artifact[3] != 69) {
      headerValid = false;
    }

    if (artifact[4] != 76) {
      headerValid = false;
    }

    if (artifact[5] != 66) {
      headerValid = false;
    }

    if (artifact[6] != 67) {
      headerValid = false;
    }

    if (artifact[7] != 0) {
      headerValid = false;
    }

    if (readUnsigned(artifact, 8, 2) != 1) {
      headerValid = false;
    }

    if (readUnsigned(artifact, 10, 2) != 0) {
      headerValid = false;
    }

    if (readUnsigned(artifact, 16, 8) != artifactLength) {
      headerValid = false;
    }

    if (readUnsigned(artifact, 28, 4) != 32) {
      headerValid = false;
    }

    if (readUnsigned(artifact, 32, 8) != 40) {
      headerValid = false;
    }

    if (headerValid == false) {
      return new SectionRange(false, 0, 0);
    }

    long sectionCount = readUnsigned(artifact, 24, 4);
    if (sectionCount < 6) {
      return new SectionRange(false, 0, 0);
    }

    if (MAX_SECTIONS < sectionCount) {
      return new SectionRange(false, 0, 0);
    }

    long previousType = 0;
    long previousEnd = 40 + sectionCount * 32;
    long foundStart = 0;
    long foundLength = 0;
    boolean found = false;
    long section = 0;
    while (section < sectionCount) limit MAX_SECTIONS {
      long directory = 40 + section * 32;
      long sectionType = readUnsigned(artifact, directory, 4);
      long flags = readUnsigned(artifact, directory + 4, 4);
      long start = readUnsigned(artifact, directory + 8, 8);
      long length = readUnsigned(artifact, directory + 16, 8);
      long alignment = readUnsigned(artifact, directory + 24, 4);
      long reserved = readUnsigned(artifact, directory + 28, 4);
      boolean entryValid = true;
      if (sectionType < previousType + 1) {
        entryValid = false;
      }

      if (flags != 1) {
        entryValid = false;
      }

      if (alignment != 8) {
        entryValid = false;
      }

      if (reserved != 0) {
        entryValid = false;
      }

      if (start % 8 != 0) {
        entryValid = false;
      }

      if (rangeValid(start, length, artifactLength) == false) {
        entryValid = false;
      }

      if (start < previousEnd) {
        entryValid = false;
      }

      if (entryValid == false) {
        return new SectionRange(false, 0, 0);
      }

      previousType = sectionType;
      previousEnd = start + length;
      if (sectionType == wantedType) {
        found = true;
        foundStart = start;
        foundLength = length;
      }

      section += 1;
    }

    return new SectionRange(found, foundStart, foundLength);
  }

  private boolean readable(long cursor, long width, long end) {
    return rangeValid(cursor, width, end);
  }

  /// Decodes record, array, slice, variant, case, and member layout rows.
  public CompiledAggregatePlan indexCompiledAggregateLayouts(
    borrow byteview artifact,
    long artifactLength,
    long owner,
    borrow mut words aggregateRows,
    borrow mut words caseRows,
    borrow mut words memberRows
  ) {
    assert(-1 < owner);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(caseRows) == CASE_ROWS);
    assert(bufferLength(memberRows) == MEMBER_ROWS);

    SectionRange strings = sectionRange(artifact, artifactLength, 2);
    SectionRange types = sectionRange(artifact, artifactLength, 3);
    SectionRange variants = sectionRange(artifact, artifactLength, 4);
    assert(strings.valid);
    assert(types.valid);
    assert(variants.valid);
    assert(3 < strings.length);
    long stringCount = readUnsigned(artifact, strings.start, 4);

    long aggregateCount = 0;
    long caseCount = 0;
    long memberCount = 0;
    long cursor = types.start;
    long typesEnd = types.start + types.length;
    assert(readable(cursor, 4, typesEnd));
    long globalCount = readUnsigned(artifact, cursor, 4);
    cursor += 4;
    assert(globalCount < 4097);
    assert(readable(cursor, globalCount * 16, typesEnd));
    cursor += globalCount * 16;
    assert(readable(cursor, 4, typesEnd));
    long recordCount = readUnsigned(artifact, cursor, 4);
    cursor += 4;
    assert(recordCount < MAX_AGGREGATES_PER_MODULE + 1);
    long record = 0;
    while (record < recordCount) limit MAX_AGGREGATES_PER_MODULE {
      assert(readable(cursor, 12, typesEnd));
      long typeId = readUnsigned(artifact, cursor, 4);
      long name = readUnsigned(artifact, cursor + 4, 4);
      long fields = readUnsigned(artifact, cursor + 8, 4);
      cursor += 12;
      assert(name < stringCount);
      assert(fields < MAX_MEMBERS_PER_MODULE - memberCount + 1);
      assert(readable(cursor, fields * 8, typesEnd));
      set(aggregateRows, 0 + aggregateCount, 1);
      set(aggregateRows, 64 + aggregateCount, owner);
      set(aggregateRows, 128 + aggregateCount, typeId);
      set(aggregateRows, 192 + aggregateCount, name);
      set(aggregateRows, 256 + aggregateCount, 0);
      set(aggregateRows, 320 + aggregateCount, 0);
      set(aggregateRows, 384 + aggregateCount, memberCount);
      set(aggregateRows, 448 + aggregateCount, fields);
      set(aggregateRows, 512 + aggregateCount, 0);
      long field = 0;
      while (field < fields) limit MAX_MEMBERS_PER_MODULE {
        long fieldName = readUnsigned(artifact, cursor, 4);
        assert(fieldName < stringCount);
        set(memberRows, 0 + memberCount, aggregateCount);
        set(memberRows, 256 + memberCount, -1);
        set(memberRows, 512 + memberCount, fieldName);
        set(memberRows, 768 + memberCount, readUnsigned(artifact, cursor + 4, 4));
        memberCount += 1;
        cursor += 8;
        field += 1;
      }

      aggregateCount += 1;
      record += 1;
    }

    assert(readable(cursor, 4, typesEnd));
    long arrayCount = readUnsigned(artifact, cursor, 4);
    cursor += 4;
    assert(arrayCount < MAX_AGGREGATES_PER_MODULE - aggregateCount + 1);
    long array = 0;
    while (array < arrayCount) limit MAX_AGGREGATES_PER_MODULE {
      assert(readable(cursor, 12, typesEnd));
      set(aggregateRows, 0 + aggregateCount, 2);
      set(aggregateRows, 64 + aggregateCount, owner);
      set(aggregateRows, 128 + aggregateCount, readUnsigned(artifact, cursor, 4));
      set(aggregateRows, 192 + aggregateCount, -1);
      set(aggregateRows, 256 + aggregateCount, 0);
      set(aggregateRows, 320 + aggregateCount, 0);
      set(aggregateRows, 384 + aggregateCount, memberCount);
      set(aggregateRows, 448 + aggregateCount, 1);
      set(aggregateRows, 512 + aggregateCount, readUnsigned(artifact, cursor + 8, 4));
      assert(memberCount < MAX_MEMBERS_PER_MODULE);
      set(memberRows, 0 + memberCount, aggregateCount);
      set(memberRows, 256 + memberCount, -1);
      set(memberRows, 512 + memberCount, -1);
      set(memberRows, 768 + memberCount, readUnsigned(artifact, cursor + 4, 4));
      memberCount += 1;
      aggregateCount += 1;
      cursor += 12;
      array += 1;
    }

    assert(readable(cursor, 4, typesEnd));
    long sliceCount = readUnsigned(artifact, cursor, 4);
    cursor += 4;
    assert(sliceCount < MAX_AGGREGATES_PER_MODULE - aggregateCount + 1);
    long slice = 0;
    while (slice < sliceCount) limit MAX_AGGREGATES_PER_MODULE {
      assert(readable(cursor, 8, typesEnd));
      set(aggregateRows, 0 + aggregateCount, 3);
      set(aggregateRows, 64 + aggregateCount, owner);
      set(aggregateRows, 128 + aggregateCount, readUnsigned(artifact, cursor, 4));
      set(aggregateRows, 192 + aggregateCount, -1);
      set(aggregateRows, 256 + aggregateCount, 0);
      set(aggregateRows, 320 + aggregateCount, 0);
      set(aggregateRows, 384 + aggregateCount, memberCount);
      set(aggregateRows, 448 + aggregateCount, 1);
      set(aggregateRows, 512 + aggregateCount, -1);
      assert(memberCount < MAX_MEMBERS_PER_MODULE);
      set(memberRows, 0 + memberCount, aggregateCount);
      set(memberRows, 256 + memberCount, -1);
      set(memberRows, 512 + memberCount, -1);
      set(memberRows, 768 + memberCount, readUnsigned(artifact, cursor + 4, 4));
      memberCount += 1;
      aggregateCount += 1;
      cursor += 8;
      slice += 1;
    }

    assert(cursor == typesEnd);

    cursor = variants.start;
    long variantsEnd = variants.start + variants.length;
    assert(readable(cursor, 4, variantsEnd));
    long variantCount = readUnsigned(artifact, cursor, 4);
    cursor += 4;
    assert(variantCount < MAX_AGGREGATES_PER_MODULE - aggregateCount + 1);
    long variant = 0;
    while (variant < variantCount) limit MAX_AGGREGATES_PER_MODULE {
      assert(readable(cursor, 12, variantsEnd));
      long aggregate = aggregateCount;
      long variantTypeId = readUnsigned(artifact, cursor, 4);
      long variantName = readUnsigned(artifact, cursor + 4, 4);
      long variantCases = readUnsigned(artifact, cursor + 8, 4);
      cursor += 12;
      assert(variantName < stringCount);
      assert(variantCases < MAX_CASES_PER_MODULE - caseCount + 1);
      set(aggregateRows, 0 + aggregate, 4);
      set(aggregateRows, 64 + aggregate, owner);
      set(aggregateRows, 128 + aggregate, variantTypeId);
      set(aggregateRows, 192 + aggregate, variantName);
      set(aggregateRows, 256 + aggregate, caseCount);
      set(aggregateRows, 320 + aggregate, variantCases);
      set(aggregateRows, 384 + aggregate, memberCount);
      long variantFirstMember = memberCount;
      set(aggregateRows, 512 + aggregate, 0);
      long nextCase = 0;
      while (nextCase < variantCases) limit MAX_CASES_PER_MODULE {
        assert(readable(cursor, 8, variantsEnd));
        long variantCaseName = readUnsigned(artifact, cursor, 4);
        long variantFields = readUnsigned(artifact, cursor + 4, 4);
        cursor += 8;
        assert(variantCaseName < stringCount);
        assert(variantFields < MAX_MEMBERS_PER_MODULE - memberCount + 1);
        assert(readable(cursor, variantFields * 8, variantsEnd));
        set(caseRows, 0 + caseCount, aggregate);
        set(caseRows, 128 + caseCount, variantCaseName);
        set(caseRows, 256 + caseCount, memberCount);
        set(caseRows, 384 + caseCount, variantFields);
        long variantField = 0;
        while (variantField < variantFields) limit MAX_MEMBERS_PER_MODULE {
          long variantFieldName = readUnsigned(artifact, cursor, 4);
          assert(variantFieldName < stringCount);
          set(memberRows, 0 + memberCount, aggregate);
          set(memberRows, 256 + memberCount, caseCount);
          set(memberRows, 512 + memberCount, variantFieldName);
          set(memberRows, 768 + memberCount, readUnsigned(artifact, cursor + 4, 4));
          memberCount += 1;
          cursor += 8;
          variantField += 1;
        }

        caseCount += 1;
        nextCase += 1;
      }

      set(aggregateRows, 448 + aggregate, memberCount - variantFirstMember);
      aggregateCount += 1;
      variant += 1;
    }

    assert(cursor == variantsEnd);

    return new CompiledAggregatePlan(aggregateCount, caseCount, memberCount);
  }
}
