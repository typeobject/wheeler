//! Appends nonexecuted recursive stubs from imported callable signature products.

module wheeler.compiler.closure.imported_callable_stubs;

classical class ImportedCallableStubs {
  private const long CALL_ROWS = 1024;
  private const long INSTRUCTION_ROWS = 24576;
  private const long MAX_CALLABLES = 4096;
  private const long MAX_CALLS = 256;
  private const long MAX_PARAMETERS = 64;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long STAGING_BYTES = 65536;

  /// Reports the complete generated source extent and distinct stub count.
  public record ImportedCallableStubPlan(long length, long stubCount) {}

  /// Reports the local prefix retained after synthetic compile functions are excluded.
  public record RetainedFunctionProduct(
    long functionCount,
    long instructionCount,
    long excludedFunctionCount
  ) {}

  private boolean reservedPrefixAt(borrow byteview source, long start, long end) {
    if (end - start < 17) {
      return false;
    }

    long[17] expected = new long[17](
      95,
      95,
      119,
      104,
      101,
      101,
      108,
      101,
      114,
      95,
      105,
      109,
      112,
      111,
      114,
      116,
      95
    );
    long prefixByte = 0;
    while (prefixByte < 17) limit 17 {
      if (source[start + prefixByte] != expected[prefixByte]) {
        return false;
      }

      prefixByte += 1;
    }

    return true;
  }

  private long writeStubName(long target, borrow mut bytes output, long cursor) {
    assert(-1 < target);
    assert(target < MAX_CALLABLES);
    assert(cursor < MAX_SOURCE_BYTES - 21);
    writeAscii(output, cursor, "__wheeler_import_");
    cursor += 17;
    long divisor = 1;
    while (divisor < target / 10 + 1) limit 4 {
      divisor = divisor * 10;
    }

    if (target < divisor) {
      divisor = divisor / 10;
    }

    if (divisor == 0) {
      divisor = 1;
    }

    boolean writing = true;
    while (writing) limit 4 {
      setByte(output, cursor, target / divisor % 10 + 48);
      cursor += 1;
      if (divisor == 1) {
        writing = false;
      } else {
        divisor = divisor / 10;
      }
    }

    return cursor;
  }

  private long writeParameterName(long parameter, borrow mut bytes output, long cursor) {
    assert(-1 < parameter);
    assert(parameter < MAX_PARAMETERS);
    assert(cursor < MAX_SOURCE_BYTES - 3);
    writeAscii(output, cursor, "p");
    cursor += 1;
    if (9 < parameter) {
      setByte(output, cursor, parameter / 10 + 48);
      cursor += 1;
    }

    setByte(output, cursor, parameter % 10 + 48);
    return cursor + 1;
  }

  private long writeType(long type, long mode, borrow mut bytes output, long cursor) {
    assert(-1 < mode);
    assert(mode < 3);
    if (mode == 1) {
      writeAscii(output, cursor, "borrow ");
      cursor += 7;
    }

    if (mode == 2) {
      writeAscii(output, cursor, "borrow mut ");
      cursor += 11;
    }

    if (type == 0) {
      writeAscii(output, cursor, "void");
      return cursor + 4;
    }

    if (type == 1) {
      writeAscii(output, cursor, "long");
      return cursor + 4;
    }

    if (type == 2) {
      writeAscii(output, cursor, "boolean");
      return cursor + 7;
    }

    if (type == 3) {
      writeAscii(output, cursor, "region");
      return cursor + 6;
    }

    if (type == 4) {
      writeAscii(output, cursor, "words");
      return cursor + 5;
    }

    if (type == 5) {
      writeAscii(output, cursor, "bytes");
      return cursor + 5;
    }

    if (type == 6) {
      writeAscii(output, cursor, "longmap");
      return cursor + 7;
    }

    if (type == 7) {
      writeAscii(output, cursor, "utf8");
      return cursor + 4;
    }

    if (type == 13) {
      writeAscii(output, cursor, "byteview");
      return cursor + 8;
    }

    if (type == 14) {
      writeAscii(output, cursor, "Done");
      return cursor + 4;
    }

    assert(false);
    return cursor;
  }

  private boolean resultIsVoid(long type) {
    return type == 0;
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
    long callCount,
    borrow mut words callRows,
    borrow mut words callableEffects,
    borrow mut words callableFirstParameters,
    borrow mut words callableParameterCounts,
    borrow mut words callableResultTypes,
    borrow mut words parameterTypes,
    borrow mut words parameterModes,
    borrow mut bytes output
  ) {
    assert(-1 < sourceStart);
    assert(0 < sourceLength);
    assert(sourceStart < bufferLength(sourceArchive));
    assert(sourceLength < bufferLength(sourceArchive) - sourceStart + 1);
    assert(-1 < callCount);
    assert(callCount < MAX_CALLS + 1);
    assert(bufferLength(callRows) == CALL_ROWS);
    assert(bufferLength(callableEffects) == MAX_CALLABLES);
    assert(bufferLength(callableFirstParameters) == MAX_CALLABLES);
    assert(bufferLength(callableParameterCounts) == MAX_CALLABLES);
    assert(bufferLength(callableResultTypes) == MAX_CALLABLES);
    assert(bufferLength(parameterTypes) == 16384);
    assert(bufferLength(parameterModes) == 16384);
    assert(bufferLength(output) == MAX_SOURCE_BYTES);
    long reservedScan = sourceStart;
    while (reservedScan < sourceStart + sourceLength) limit MAX_SOURCE_BYTES {
      assert(reservedPrefixAt(sourceArchive, reservedScan, sourceStart + sourceLength) == false);
      reservedScan += 1;
    }

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 2);
    bytes stagedSource = allocateBytes(staging, MAX_SOURCE_BYTES);
    words selectedTargets = allocate(staging, MAX_CALLABLES);
    long call = 0;
    while (call < callCount) limit MAX_CALLS {
      long callTarget = callRows[768 + call];
      assert(-1 < callTarget);
      assert(callTarget < MAX_CALLABLES);
      set(selectedTargets, callTarget, 1);
      call += 1;
    }

    long cursor = 0;
    long sourceCursor = sourceStart;
    call = 0;
    while (call < callCount) limit MAX_CALLS {
      long callStart = sourceStart + callRows[call];
      long callLength = callRows[256 + call];
      long rewrittenTarget = callRows[768 + call];
      assert(sourceCursor < callStart + 1);
      assert(callStart < sourceStart + sourceLength);
      assert(0 < callLength);
      assert(callLength < sourceStart + sourceLength - callStart + 1);
      cursor = writeRange(
        sourceArchive,
        sourceCursor,
        callStart - sourceCursor,
        stagedSource,
        cursor
      );
      cursor = writeStubName(rewrittenTarget, stagedSource, cursor);
      sourceCursor = callStart + callLength;
      call += 1;
    }

    cursor = writeRange(
      sourceArchive,
      sourceCursor,
      sourceStart + sourceLength - sourceCursor,
      stagedSource,
      cursor
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
        long effects = callableEffects[target];
        long firstParameter = callableFirstParameters[target];
        long parameterCount = callableParameterCounts[target];
        long resultType = callableResultTypes[target];
        assert(-1 < firstParameter);
        assert(-1 < parameterCount);
        assert(parameterCount < MAX_PARAMETERS + 1);
        assert(parameterCount < 16384 - firstParameter + 1);
        boolean effectsValid = effects == 0;
        if (effects == 2) {
          effectsValid = true;
        }

        if (effects == 4) {
          effectsValid = true;
        }

        assert(effectsValid);
        assert(cursor < MAX_SOURCE_BYTES - 8);
        writeAscii(stagedSource, cursor, " private ");
        cursor += 9;
        if (effects == 2) {
          writeAscii(stagedSource, cursor, "rev ");
          cursor += 4;
        }

        if (effects == 4) {
          writeAscii(stagedSource, cursor, "coherent ");
          cursor += 9;
        }

        cursor = writeType(resultType, /* mode= */ 0, stagedSource, cursor);
        writeAscii(stagedSource, cursor, " ");
        cursor += 1;
        cursor = writeStubName(target, stagedSource, cursor);
        writeAscii(stagedSource, cursor, "(");
        cursor += 1;
        long parameter = 0;
        while (parameter < parameterCount) limit MAX_PARAMETERS {
          if (0 < parameter) {
            writeAscii(stagedSource, cursor, ", ");
            cursor += 2;
          }

          long parameterRow = firstParameter + parameter;
          cursor = writeType(
            parameterTypes[parameterRow],
            parameterModes[parameterRow],
            stagedSource,
            cursor
          );
          writeAscii(stagedSource, cursor, " ");
          cursor += 1;
          cursor = writeParameterName(parameter, stagedSource, cursor);
          parameter += 1;
        }

        writeAscii(stagedSource, cursor, ") { ");
        cursor += 4;
        if (resultIsVoid(resultType) == false) {
          writeAscii(stagedSource, cursor, "return ");
          cursor += 7;
        }

        cursor = writeStubName(target, stagedSource, cursor);
        writeAscii(stagedSource, cursor, "(");
        cursor += 1;
        parameter = 0;
        while (parameter < parameterCount) limit MAX_PARAMETERS {
          if (0 < parameter) {
            writeAscii(stagedSource, cursor, ", ");
            cursor += 2;
          }

          cursor = writeParameterName(parameter, stagedSource, cursor);
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

    drop(selectedTargets);
    drop(stagedSource);
    drop(staging);
    return new ImportedCallableStubPlan(cursor, stubCount);
  }
}
