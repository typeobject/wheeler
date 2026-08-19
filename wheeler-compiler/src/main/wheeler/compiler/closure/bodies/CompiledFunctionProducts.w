//! Decodes bounded function descriptors and instructions from canonical body artifacts.

module wheeler.compiler.closure.compiled_function_products;

import wheeler.compiler.instruction_forms;
import wheeler.core.encoding.binary;

classical class CompiledFunctionProducts {
  private const long FUNCTION_ROWS = 640;
  private const long INSTRUCTION_ROWS = 24576;
  private const long MAX_FUNCTIONS_PER_MODULE = 64;
  private const long MAX_INSTRUCTIONS_PER_MODULE = 4096;
  private const long MAX_SECTIONS = 64;
  private const long PRODUCT_ARENA_BYTES = 201728;

  private record SectionRange(boolean valid, long start, long length) {}

  /// Reports the exact source-local function product extent.
  public record CompiledFunctionPlan(
    long functionCount,
    long instructionCount,
    long maxLocalCount
  ) {}

  private boolean rangeValid(long start, long length, long end) {
    boolean valid = true;
    if (start < 0) {
      valid = false;
    }

    if (length < 0) {
      valid = false;
    }

    if (end < start) {
      valid = false;
    }

    if (valid) {
      if (end - start < length) {
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

  private long indexInstructionStream(
    borrow byteview artifact,
    long start,
    long length,
    long function,
    long direction,
    long firstInstruction,
    borrow mut words instructionRows
  ) {
    long cursor = start;
    long end = start + length;
    long instructionCount = 0;
    while (cursor < end) limit MAX_INSTRUCTIONS_PER_MODULE {
      assert(rangeValid(cursor, 8, end));
      long opcode = readUnsigned(artifact, cursor, 2);
      long operandCount = readUnsigned(artifact, cursor + 2, 2);
      long instructionLength = readUnsigned(artifact, cursor + 4, 4);
      long expectedOperands = expectedOperandCount(opcode);
      assert(-1 < expectedOperands);
      assert(operandCount == expectedOperands);
      assert(instructionLength == 8 + operandCount * 8);
      assert(rangeValid(cursor, instructionLength, end));
      long instruction = firstInstruction + instructionCount;
      assert(instruction < MAX_INSTRUCTIONS_PER_MODULE);
      set(instructionRows, instruction, function);
      set(instructionRows, 4096 + instruction, direction);
      set(instructionRows, 8192 + instruction, cursor);
      set(instructionRows, 12288 + instruction, opcode);
      set(instructionRows, 16384 + instruction, operandCount);
      set(instructionRows, 20480 + instruction, instructionLength);
      instructionCount += 1;
      cursor += instructionLength;
    }

    assert(cursor == end);
    return instructionCount;
  }

  /// Publishes function and instruction products after complete artifact validation.
  public CompiledFunctionPlan indexCompiledFunctionProducts(
    borrow byteview artifact,
    long artifactLength,
    borrow mut words functionRows,
    borrow mut words instructionRows
  ) {
    assert(bufferLength(functionRows) == FUNCTION_ROWS);
    assert(bufferLength(instructionRows) == INSTRUCTION_ROWS);
    SectionRange functions = sectionRange(artifact, artifactLength, 5);
    SectionRange code = sectionRange(artifact, artifactLength, 6);
    assert(functions.valid);
    assert(code.valid);
    assert(3 < functions.length);
    long functionCount = readUnsigned(artifact, functions.start, 4);
    assert(0 < functionCount);
    assert(functionCount < MAX_FUNCTIONS_PER_MODULE + 1);
    long descriptorBytes = functionCount * 40;
    assert(rangeValid(functions.start + 4, descriptorBytes, functions.start + functions.length));
    long typeStart = functions.start + 4 + descriptorBytes;

    region productArena = new region(/* bytes= */ PRODUCT_ARENA_BYTES, /* allocations= */ 2);
    words stagedFunctions = allocate(productArena, FUNCTION_ROWS);
    words stagedInstructions = allocate(productArena, INSTRUCTION_ROWS);
    long expectedTypeOffset = 0;
    long expectedCodeOffset = 0;
    long instructionCount = 0;
    long maxLocalCount = 0;
    long function = 0;
    while (function < functionCount) limit MAX_FUNCTIONS_PER_MODULE {
      long descriptor = functions.start + 4 + function * 40;
      long functionId = readUnsigned(artifact, descriptor, 4);
      long flags = readUnsigned(artifact, descriptor + 8, 4);
      long forwardOffset = readUnsigned(artifact, descriptor + 12, 4);
      long forwardLength = readUnsigned(artifact, descriptor + 16, 4);
      long inverseOffset = readUnsigned(artifact, descriptor + 20, 4);
      long inverseLength = readUnsigned(artifact, descriptor + 24, 4);
      long parameterCount = readUnsigned(artifact, descriptor + 28, 4);
      long localCount = readUnsigned(artifact, descriptor + 32, 4);
      long functionTypeOffset = readUnsigned(artifact, descriptor + 36, 4);
      assert(functionId == function);
      assert(flags < 16);
      assert(parameterCount < localCount + 1);
      assert(localCount < 257);
      assert(functionTypeOffset == expectedTypeOffset);
      long returnsValue = flags / 4 % 2;
      long typeCount = localCount + returnsValue;
      assert(
        rangeValid(
          typeStart + expectedTypeOffset * 4,
          typeCount * 4,
          functions.start + functions.length
        )
      );
      expectedTypeOffset += typeCount;
      assert(forwardOffset == expectedCodeOffset);
      assert(rangeValid(code.start + forwardOffset, forwardLength, code.start + code.length));
      long forwardInstructions = indexInstructionStream(
        artifact,
        code.start + forwardOffset,
        forwardLength,
        function,
        0,
        instructionCount,
        stagedInstructions
      );
      instructionCount += forwardInstructions;
      expectedCodeOffset += forwardLength;
      long inverseStart = -1;
      long reversible = flags % 2;
      if (reversible == 1) {
        assert(inverseOffset == expectedCodeOffset);
        assert(rangeValid(code.start + inverseOffset, inverseLength, code.start + code.length));
        inverseStart = code.start + inverseOffset;
        long inverseInstructions = indexInstructionStream(
          artifact,
          inverseStart,
          inverseLength,
          function,
          1,
          instructionCount,
          stagedInstructions
        );
        instructionCount += inverseInstructions;
        expectedCodeOffset += inverseLength;
      } else {
        assert(inverseOffset == 4294967295);
        assert(inverseLength == 0);
      }

      set(stagedFunctions, function, functionId);
      set(stagedFunctions, 64 + function, flags);
      set(stagedFunctions, 128 + function, code.start + forwardOffset);
      set(stagedFunctions, 192 + function, forwardLength);
      set(stagedFunctions, 256 + function, inverseStart);
      set(stagedFunctions, 320 + function, inverseLength);
      set(stagedFunctions, 384 + function, parameterCount);
      set(stagedFunctions, 448 + function, localCount);
      set(stagedFunctions, 512 + function, typeStart + functionTypeOffset * 4);
      set(stagedFunctions, 576 + function, typeCount);
      if (maxLocalCount < localCount) {
        maxLocalCount = localCount;
      }

      function += 1;
    }

    assert(typeStart + expectedTypeOffset * 4 == functions.start + functions.length);
    assert(expectedCodeOffset == code.length);

    long column = 0;
    while (column < 10) limit 10 {
      long functionRow = 0;
      while (functionRow < functionCount) limit MAX_FUNCTIONS_PER_MODULE {
        set(
          functionRows,
          column * MAX_FUNCTIONS_PER_MODULE + functionRow,
          stagedFunctions[column * MAX_FUNCTIONS_PER_MODULE + functionRow]
        );
        functionRow += 1;
      }

      column += 1;
    }

    column = 0;
    while (column < 6) limit 6 {
      long instructionRow = 0;
      while (instructionRow < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
        set(
          instructionRows,
          column * MAX_INSTRUCTIONS_PER_MODULE + instructionRow,
          stagedInstructions[column * MAX_INSTRUCTIONS_PER_MODULE + instructionRow]
        );
        instructionRow += 1;
      }

      column += 1;
    }

    drop(stagedInstructions);
    drop(stagedFunctions);
    drop(productArena);
    return new CompiledFunctionPlan(functionCount, instructionCount, maxLocalCount);
  }
}
