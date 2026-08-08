//! Emits closure-ordered instruction bytes with source-local call rebasing.

module wheeler.compiler.closure.linked_instruction_code;

import wheeler.compiler.opcodes;
import wheeler.core.encoding.binary;

classical class LinkedInstructionCode {
  private const long CLOSURE_FUNCTION_ROWS = 49152;
  private const long CLOSURE_INSTRUCTION_ROWS = 917504;
  private const long MAX_ARTIFACT_BYTES = 16777216;
  private const long MAX_ARTIFACTS = 512;
  private const long MAX_CLOSURE_FUNCTIONS = 4096;
  private const long MAX_CLOSURE_INSTRUCTIONS = 131072;
  private const long MAX_LINKED_CODE_BYTES = 4194304;
  private const long MAX_MODULES = 512;

  private boolean isCall(long opcode) {
    boolean call = false;
    if (opcode == OPCODE_CALL) {
      call = true;
    }

    if (opcode == OPCODE_UNCALL) {
      call = true;
    }

    if (opcode == OPCODE_CALL_VALUE) {
      call = true;
    }

    if (opcode == OPCODE_CALL_VOID) {
      call = true;
    }

    if (opcode == OPCODE_CALL_RESULT_SLOT) {
      call = true;
    }

    if (opcode == OPCODE_UNCALL_RESULT_SLOT) {
      call = true;
    }

    return call;
  }

  private void writeSigned(long value, borrow mut bytes output, long cursor) {
    long remaining = value;
    long index = 0;
    while (index < 8) limit 8 {
      long octet = remaining % 256;
      if (octet < 0) {
        octet += 256;
      }

      setByte(output, cursor + index, octet);
      remaining = (remaining - octet) / 256;
      index += 1;
    }
  }

  /// Emits one linked code-section product after validating all artifact ranges.
  public long emitLinkedInstructionCode(
    borrow byteview archive,
    long archiveBytes,
    borrow mut words artifactStarts,
    borrow mut words artifactLengths,
    long functionCount,
    long instructionCount,
    borrow mut words moduleFirstFunctions,
    borrow mut words moduleFunctionCounts,
    borrow mut words closureFunctionRows,
    borrow mut words closureInstructionRows,
    borrow mut bytes output
  ) {
    assert(-1 < archiveBytes);
    assert(archiveBytes < MAX_ARTIFACT_BYTES + 1);
    assert(archiveBytes < bufferLength(archive) + 1);
    assert(bufferLength(artifactStarts) == MAX_ARTIFACTS);
    assert(bufferLength(artifactLengths) == MAX_ARTIFACTS);
    assert(-1 < functionCount);
    assert(functionCount < MAX_CLOSURE_FUNCTIONS + 1);
    assert(-1 < instructionCount);
    assert(instructionCount < MAX_CLOSURE_INSTRUCTIONS + 1);
    assert(bufferLength(moduleFirstFunctions) == MAX_MODULES);
    assert(bufferLength(moduleFunctionCounts) == MAX_MODULES);
    assert(bufferLength(closureFunctionRows) == CLOSURE_FUNCTION_ROWS);
    assert(bufferLength(closureInstructionRows) == CLOSURE_INSTRUCTION_ROWS);
    assert(bufferLength(output) == MAX_LINKED_CODE_BYTES);

    long outputBytes = 0;
    long previousFunction = -1;
    long instruction = 0;
    while (instruction < instructionCount) limit MAX_CLOSURE_INSTRUCTIONS {
      long function = closureInstructionRows[instruction];
      assert(-1 < function);
      assert(function < functionCount);
      assert(previousFunction < function + 1);
      previousFunction = function;
      long artifactRank = closureInstructionRows[262144 + instruction];
      assert(-1 < artifactRank);
      assert(artifactRank < MAX_ARTIFACTS);
      long instructionStart = closureInstructionRows[393216 + instruction];
      long instructionLength = closureInstructionRows[786432 + instruction];
      assert(-1 < instructionStart);
      assert(7 < instructionLength);
      assert(instructionStart < artifactLengths[artifactRank] + 1);
      assert(instructionLength < artifactLengths[artifactRank] - instructionStart + 1);
      assert(instructionLength < MAX_LINKED_CODE_BYTES - outputBytes + 1);
      outputBytes += instructionLength;
      instruction += 1;
    }

    long outputCursor = 0;
    instruction = 0;
    while (instruction < instructionCount) limit MAX_CLOSURE_INSTRUCTIONS {
      long selectedFunction = closureInstructionRows[instruction];
      long selectedArtifact = closureInstructionRows[262144 + instruction];
      long selectedStart = artifactStarts[selectedArtifact] + closureInstructionRows[393216
        + instruction];
      long selectedLength = closureInstructionRows[786432 + instruction];
      long instructionByte = 0;
      while (instructionByte < selectedLength) limit 520 {
        setByte(
          output,
          outputCursor + instructionByte,
          archive[selectedStart + instructionByte]
        );
        instructionByte += 1;
      }

      long selectedOpcode = closureInstructionRows[524288 + instruction];
      if (isCall(selectedOpcode)) {
        long moduleOwner = closureFunctionRows[selectedFunction];
        assert(-1 < moduleOwner);
        assert(moduleOwner < MAX_MODULES);
        long localTarget = readUnsigned(archive, selectedStart + 8, 8);
        assert(localTarget < moduleFunctionCounts[moduleOwner]);
        long linkedTarget = moduleFirstFunctions[moduleOwner] + localTarget;
        assert(linkedTarget < functionCount);
        writeSigned(linkedTarget, output, outputCursor + 8);
      }

      outputCursor += selectedLength;
      instruction += 1;
    }

    assert(outputCursor == outputBytes);
    return outputBytes;
  }
}
