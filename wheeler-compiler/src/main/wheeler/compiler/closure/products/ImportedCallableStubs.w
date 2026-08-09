//! Appends nonexecuted recursive stubs from imported callable signature products.

module wheeler.compiler.closure.imported_callable_stubs;

classical class ImportedCallableStubs {
  private const long CALL_ROWS = 1024;
  private const long INSTRUCTION_ROWS = 24576;
  private const long MAX_CALLABLES = 4096;
  private const long MAX_CALLS = 256;
  private const long MAX_PARAMETERS = 64;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long STAGING_BYTES = 66560;

  /// Reports the complete generated source extent and distinct stub count.
  public record ImportedCallableStubPlan(long length, long stubCount) {}

  /// Reports the local prefix retained after synthetic compile functions are excluded.
  public record RetainedFunctionProduct(
    long functionCount,
    long instructionCount,
    long excludedFunctionCount
  ) {}

  private boolean identifierByte(long value) {
    if (64 < value) {
      if (value < 91) {
        return true;
      }
    }

    if (96 < value) {
      if (value < 123) {
        return true;
      }
    }

    if (47 < value) {
      if (value < 58) {
        return true;
      }
    }

    return value == 95;
  }

  private boolean resultIsVoid(borrow byteview archive, long start, long length) {
    if (length != 4) {
      return false;
    }

    if (archive[start] != 118) {
      return false;
    }

    if (archive[start + 1] != 111) {
      return false;
    }

    if (archive[start + 2] != 105) {
      return false;
    }

    return archive[start + 3] == 100;
  }

  private long writeRange(
    borrow byteview archive,
    long start,
    long length,
    borrow mut bytes output,
    long cursor
  ) {
    assert(-1 < start);
    assert(-1 < length);
    assert(start < bufferLength(archive) + 1);
    assert(length < bufferLength(archive) - start + 1);
    assert(cursor < bufferLength(output) + 1);
    assert(length < bufferLength(output) - cursor + 1);
    long sourceByte = 0;
    while (sourceByte < length) limit MAX_SOURCE_BYTES {
      setByte(output, cursor + sourceByte, archive[start + sourceByte]);
      sourceByte += 1;
    }

    return cursor + length;
  }

  private long indexParameterNames(
    borrow byteview archive,
    long signatureStart,
    long signatureLength,
    long parameterCount,
    borrow mut words parameterNameStarts,
    borrow mut words parameterNameLengths
  ) {
    assert(parameterCount < MAX_PARAMETERS + 1);
    long end = signatureStart + signatureLength;
    long open = -1;
    long scan = signatureStart;
    while (scan < end) limit 4096 {
      if (archive[scan] == 40) {
        open = scan;
        scan = end;
      } else {
        scan += 1;
      }
    }

    assert(-1 < open);
    long close = end;
    while (signatureStart < close) limit 4096 {
      close -= 1;
      if (archive[close] == 41) {
        break;
      }
    }

    assert(open < close);
    if (parameterCount == 0) {
      assert(close == open + 1);
      return 0;
    }

    long parameter = 0;
    long segmentStart = open + 1;
    scan = segmentStart;
    while (scan < close + 1) limit 4096 {
      boolean delimiter = scan == close;
      if (delimiter == false) {
        delimiter = archive[scan] == 44;
      }

      if (delimiter) {
        assert(parameter < parameterCount);
        long nameEnd = scan;
        while (segmentStart < nameEnd) limit 4096 {
          if (archive[nameEnd - 1] == 32) {
            nameEnd -= 1;
          } else {
            break;
          }
        }

        long nameStart = nameEnd;
        while (segmentStart < nameStart) limit 256 {
          if (identifierByte(archive[nameStart - 1])) {
            nameStart -= 1;
          } else {
            break;
          }
        }

        assert(nameStart < nameEnd);
        set(parameterNameStarts, parameter, nameStart);
        set(parameterNameLengths, parameter, nameEnd - nameStart);
        parameter += 1;
        segmentStart = scan + 1;
      }

      scan += 1;
    }

    assert(parameter == parameterCount);
    return parameter;
  }

  /// Validates and retains the exact instruction prefix owned by local functions.
  public RetainedFunctionProduct retainLocalFunctionProduct(
    long localFunctionCount,
    long compiledFunctionCount,
    long compiledInstructionCount,
    borrow mut words instructionRows
  ) {
    assert(0 < localFunctionCount);
    assert(localFunctionCount < compiledFunctionCount + 1);
    assert(compiledFunctionCount < 65);
    assert(-1 < compiledInstructionCount);
    assert(compiledInstructionCount < 4097);
    assert(bufferLength(instructionRows) == INSTRUCTION_ROWS);
    long localInstructionCount = 0;
    boolean syntheticStarted = false;
    long instruction = 0;
    while (instruction < compiledInstructionCount) limit 4096 {
      long owner = instructionRows[instruction];
      assert(-1 < owner);
      assert(owner < compiledFunctionCount);
      if (owner < localFunctionCount) {
        assert(syntheticStarted == false);
        localInstructionCount += 1;
      } else {
        syntheticStarted = true;
      }

      instruction += 1;
    }

    return new RetainedFunctionProduct(
      localFunctionCount,
      localInstructionCount,
      compiledFunctionCount - localFunctionCount
    );
  }

  /// Copies one local class and appends one signature-only stub per imported target.
  public ImportedCallableStubPlan writeImportedCallableStubs(
    borrow byteview sourceArchive,
    long sourceStart,
    long sourceLength,
    borrow byteview signatureArchive,
    long callCount,
    borrow mut words callRows,
    borrow mut words callableSignatureStarts,
    borrow mut words callableSignatureLengths,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableParameterCounts,
    borrow mut words callableResultTypeStarts,
    borrow mut words callableResultTypeLengths,
    borrow mut bytes output
  ) {
    assert(-1 < sourceStart);
    assert(0 < sourceLength);
    assert(sourceStart < bufferLength(sourceArchive));
    assert(sourceLength < bufferLength(sourceArchive) - sourceStart + 1);
    assert(-1 < callCount);
    assert(callCount < MAX_CALLS + 1);
    assert(bufferLength(callRows) == CALL_ROWS);
    assert(bufferLength(callableSignatureStarts) == MAX_CALLABLES);
    assert(bufferLength(callableSignatureLengths) == MAX_CALLABLES);
    assert(bufferLength(callableNameStarts) == MAX_CALLABLES);
    assert(bufferLength(callableNameLengths) == MAX_CALLABLES);
    assert(bufferLength(callableParameterCounts) == MAX_CALLABLES);
    assert(bufferLength(callableResultTypeStarts) == MAX_CALLABLES);
    assert(bufferLength(callableResultTypeLengths) == MAX_CALLABLES);
    assert(bufferLength(output) == MAX_SOURCE_BYTES);

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 4);
    bytes stagedSource = allocateBytes(staging, MAX_SOURCE_BYTES);
    words selectedTargets = allocate(staging, MAX_CALLABLES);
    words parameterNameStarts = allocate(staging, MAX_PARAMETERS);
    words parameterNameLengths = allocate(staging, MAX_PARAMETERS);
    long call = 0;
    while (call < callCount) limit MAX_CALLS {
      long callTarget = callRows[768 + call];
      assert(-1 < callTarget);
      assert(callTarget < MAX_CALLABLES);
      set(selectedTargets, callTarget, 1);
      call += 1;
    }

    long cursor = writeRange(
      sourceArchive,
      sourceStart,
      sourceLength,
      stagedSource,
      /* cursor= */ 0
    );
    long closing = cursor;
    while (0 < closing) limit MAX_SOURCE_BYTES {
      closing -= 1;
      if (stagedSource[closing] == 125) {
        break;
      }
    }

    assert(stagedSource[closing] == 125);
    cursor = closing;
    long stubCount = 0;
    long target = 0;
    while (target < MAX_CALLABLES) limit MAX_CALLABLES {
      if (selectedTargets[target] == 1) {
        long signatureStart = callableSignatureStarts[target];
        long signatureLength = callableSignatureLengths[target];
        long nameStart = callableNameStarts[target];
        long nameLength = callableNameLengths[target];
        long parameterCount = callableParameterCounts[target];
        assert(-1 < signatureStart);
        assert(0 < signatureLength);
        assert(-1 < nameStart);
        assert(0 < nameLength);
        assert(parameterCount < MAX_PARAMETERS + 1);
        assert(cursor < MAX_SOURCE_BYTES);
        writeAscii(stagedSource, cursor, " ");
        cursor += 1;
        cursor = writeRange(
          signatureArchive,
          signatureStart,
          signatureLength,
          stagedSource,
          cursor
        );
        assert(cursor < MAX_SOURCE_BYTES - 2);
        writeAscii(stagedSource, cursor, " { ");
        cursor += 3;
        if (
          resultIsVoid(
            signatureArchive,
            callableResultTypeStarts[target],
            callableResultTypeLengths[target]
          ) == false
        ) {
          assert(cursor < MAX_SOURCE_BYTES - 6);
          writeAscii(stagedSource, cursor, "return ");
          cursor += 7;
        }

        cursor = writeRange(signatureArchive, nameStart, nameLength, stagedSource, cursor);
        assert(cursor < MAX_SOURCE_BYTES);
        writeAscii(stagedSource, cursor, "(");
        cursor += 1;
        assert(
          parameterCount == indexParameterNames(
            signatureArchive,
            signatureStart,
            signatureLength,
            parameterCount,
            parameterNameStarts,
            parameterNameLengths
          )
        );
        long parameter = 0;
        while (parameter < parameterCount) limit MAX_PARAMETERS {
          if (0 < parameter) {
            assert(cursor < MAX_SOURCE_BYTES - 1);
            writeAscii(stagedSource, cursor, ", ");
            cursor += 2;
          }

          cursor = writeRange(
            signatureArchive,
            parameterNameStarts[parameter],
            parameterNameLengths[parameter],
            stagedSource,
            cursor
          );
          parameter += 1;
        }

        assert(cursor < MAX_SOURCE_BYTES - 3);
        writeAscii(stagedSource, cursor, "); }");
        cursor += 4;
        stubCount += 1;
      }

      target += 1;
    }

    assert(cursor < MAX_SOURCE_BYTES - 1);
    writeAscii(stagedSource, cursor, " }");
    cursor += 2;

    long outputByte = 0;
    while (outputByte < cursor) limit MAX_SOURCE_BYTES {
      setByte(output, outputByte, stagedSource[outputByte]);
      outputByte += 1;
    }

    drop(parameterNameLengths);
    drop(parameterNameStarts);
    drop(selectedTargets);
    drop(stagedSource);
    drop(staging);
    return new ImportedCallableStubPlan(cursor, stubCount);
  }
}
