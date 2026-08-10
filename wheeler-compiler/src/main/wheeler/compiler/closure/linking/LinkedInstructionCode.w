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
  private const long MAX_IMPORTED_RELOCATIONS = 65536;
  private const long MAX_LINKED_CODE_BYTES = 4194304;
  private const long MAX_MODULES = 512;
  private const long RELOCATION_ROWS = 131072;

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

  /// Rewrites imported call operands at a caller-selected code-section offset.
  public void rewriteImportedInstructionTargetsAt(
    long functionCount,
    long instructionCount,
    borrow mut words closureInstructionRows,
    long relocationCount,
    borrow mut words relocationRows,
    borrow mut bytes output,
    long outputStart
  ) {
    assert(-1 < outputStart);
    assert(-1 < functionCount);
    assert(functionCount < MAX_CLOSURE_FUNCTIONS + 1);
    assert(-1 < instructionCount);
    assert(instructionCount < MAX_CLOSURE_INSTRUCTIONS + 1);
    assert(bufferLength(closureInstructionRows) == CLOSURE_INSTRUCTION_ROWS);
    assert(-1 < relocationCount);
    assert(relocationCount < MAX_IMPORTED_RELOCATIONS + 1);
    assert(bufferLength(relocationRows) == RELOCATION_ROWS);
    assert(outputStart < bufferLength(output) + 1);

    long relocation = 0;
    long previousInstruction = -1;
    while (relocation < relocationCount) limit MAX_IMPORTED_RELOCATIONS {
      long instruction = relocationRows[relocation];
      long target = relocationRows[65536 + relocation];
      assert(previousInstruction < instruction);
      assert(instruction < instructionCount);
      assert(-1 < target);
      assert(target < functionCount);
      assert(isCall(closureInstructionRows[524288 + instruction]));
      previousInstruction = instruction;
      relocation += 1;
    }

    long outputCursor = outputStart;
    long instructionCursor = 0;
    relocation = 0;
    while (instructionCursor < instructionCount) limit MAX_CLOSURE_INSTRUCTIONS {
      if (relocation < relocationCount) {
        if (relocationRows[relocation] == instructionCursor) {
          writeSigned(relocationRows[65536 + relocation], output, outputCursor + 8);
          relocation += 1;
        }
      }

      outputCursor += closureInstructionRows[786432 + instructionCursor];
      assert(outputCursor < bufferLength(output) + 1);
      instructionCursor += 1;
    }

    assert(relocation == relocationCount);
  }

  /// Rewrites imported targets in the historical fixed-width code buffer.
  public void rewriteImportedInstructionTargets(
    long functionCount,
    long instructionCount,
    borrow mut words closureInstructionRows,
    long relocationCount,
    borrow mut words relocationRows,
    borrow mut bytes output
  ) {
    assert(bufferLength(output) == MAX_LINKED_CODE_BYTES);
    rewriteImportedInstructionTargetsAt(
      functionCount,
      instructionCount,
      closureInstructionRows,
      relocationCount,
      relocationRows,
      output,
      /* outputStart= */ 0
    );
  }

  /// Emits one linked code-section product at a caller-selected section offset.
  public long emitLinkedInstructionCodeAt(
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
    borrow mut bytes output,
    long outputStart
  ) {
    assert(-1 < outputStart);
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
    assert(outputStart < bufferLength(output) + 1);

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

    assert(outputBytes < bufferLength(output) - outputStart + 1);
    long outputCursor = outputStart;
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

    assert(outputCursor == outputStart + outputBytes);
    return outputBytes;
  }

  /// Emits code whose call operands already carry final closure function rows.
  public long emitResolvedLinkedInstructionCodeAt(
    borrow byteview archive,
    long archiveBytes,
    borrow mut words artifactStarts,
    borrow mut words artifactLengths,
    long functionCount,
    long instructionCount,
    borrow mut words closureInstructionRows,
    borrow mut words resolvedCallTargets,
    borrow mut bytes output,
    long outputStart
  ) {
    assert(-1 < outputStart);
    assert(-1 < archiveBytes);
    assert(archiveBytes < MAX_ARTIFACT_BYTES + 1);
    assert(archiveBytes < bufferLength(archive) + 1);
    assert(bufferLength(artifactStarts) == MAX_ARTIFACTS);
    assert(bufferLength(artifactLengths) == MAX_ARTIFACTS);
    assert(-1 < functionCount);
    assert(functionCount < MAX_CLOSURE_FUNCTIONS + 1);
    assert(-1 < instructionCount);
    assert(instructionCount < MAX_CLOSURE_INSTRUCTIONS + 1);
    assert(bufferLength(closureInstructionRows) == CLOSURE_INSTRUCTION_ROWS);
    assert(bufferLength(resolvedCallTargets) == MAX_CLOSURE_INSTRUCTIONS);
    assert(outputStart < bufferLength(output) + 1);

    long outputBytes = 0;
    long instruction = 0;
    while (instruction < instructionCount) limit MAX_CLOSURE_INSTRUCTIONS {
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
      if (isCall(closureInstructionRows[524288 + instruction])) {
        assert(-1 < resolvedCallTargets[instruction]);
        assert(resolvedCallTargets[instruction] < functionCount);
      }

      outputBytes += instructionLength;
      instruction += 1;
    }

    assert(outputBytes < bufferLength(output) - outputStart + 1);
    long outputCursor = outputStart;
    instruction = 0;
    while (instruction < instructionCount) limit MAX_CLOSURE_INSTRUCTIONS {
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

      if (isCall(closureInstructionRows[524288 + instruction])) {
        writeSigned(resolvedCallTargets[instruction], output, outputCursor + 8);
      }

      outputCursor += selectedLength;
      instruction += 1;
    }

    assert(outputCursor == outputStart + outputBytes);
    return outputBytes;
  }

  /// Emits into the historical fixed-width section buffer.
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
    assert(bufferLength(output) == MAX_LINKED_CODE_BYTES);
    return emitLinkedInstructionCodeAt(
      archive,
      archiveBytes,
      artifactStarts,
      artifactLengths,
      functionCount,
      instructionCount,
      moduleFirstFunctions,
      moduleFunctionCounts,
      closureFunctionRows,
      closureInstructionRows,
      output,
      /* outputStart= */ 0
    );
  }
}
