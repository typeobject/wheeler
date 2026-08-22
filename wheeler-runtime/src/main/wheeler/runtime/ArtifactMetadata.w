//! Projects test-report metadata from one verified artifact.

module wheeler.runtime.artifact_metadata;

import wheeler.compiler.opcodes;
import wheeler.core.encoding.binary;

classical class ArtifactMetadata {
  public record ArtifactText(long start, long length) {}

  private long sectionOffset(borrow byteview artifact, long section) {
    return readUnsigned(artifact, 40 + section * 32 + 8, /* width= */ 8);
  }

  private ArtifactText stringText(borrow byteview artifact, long selected) {
    long strings = sectionOffset(artifact, /* section= */ 1);
    long count = readUnsigned(artifact, strings, /* width= */ 4);
    assert(selected < count);
    long cursor = strings + 4;
    long index = 0;
    while (index < count) limit 65535 {
      long length = readUnsigned(artifact, cursor, /* width= */ 4);
      cursor += 4;
      if (index == selected) {
        return new ArtifactText(cursor, length);
      }

      cursor += length;
      index += 1;
    }

    assert(false);
    return new ArtifactText(/* start= */ 0, /* length= */ 0);
  }

  /// Returns the verified manifest program name range.
  public ArtifactText artifactProgramText(borrow byteview artifact) {
    long manifest = sectionOffset(artifact, /* section= */ 0);
    long name = readUnsigned(artifact, manifest, /* width= */ 4);
    return stringText(artifact, name);
  }

  /// Checks the verified manifest program name against exact expected bytes.
  public boolean artifactProgramMatches(borrow byteview artifact, borrow byteview expectedProgram) {
    ArtifactText program = artifactProgramText(artifact);
    if (program.length != bufferLength(expectedProgram)) {
      return false;
    }

    long offset = 0;
    while (offset < program.length) limit 255 {
      if (artifact[program.start + offset] != expectedProgram[offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  /// Returns one verified function name range in descriptor order.
  public ArtifactText artifactFunctionText(borrow byteview artifact, long function) {
    long functions = sectionOffset(artifact, /* section= */ 4);
    long count = readUnsigned(artifact, functions, /* width= */ 4);
    assert(function < count);
    long name = readUnsigned(artifact, functions + 8 + function * 40, /* width= */ 4);
    return stringText(artifact, name);
  }

  /// Checks one verified function name against exact expected bytes.
  public boolean artifactFunctionMatches(
    borrow byteview artifact,
    long function,
    borrow byteview expectedFunction
  ) {
    ArtifactText name = artifactFunctionText(artifact, function);
    if (name.length != bufferLength(expectedFunction)) {
      return false;
    }

    long offset = 0;
    while (offset < name.length) limit 255 {
      if (artifact[name.start + offset] != expectedFunction[offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private boolean instructionMatches(
    borrow byteview artifact,
    long start,
    long opcode,
    long operandCount,
    long length
  ) {
    if (readUnsigned(artifact, start, /* width= */ 2) != opcode) {
      return false;
    }

    if (readUnsigned(artifact, start + 2, /* width= */ 2) != operandCount) {
      return false;
    }

    return readUnsigned(artifact, start + 4, /* width= */ 4) == length;
  }

  /// Checks the verified synthetic entry for one discovered source case.
  public boolean artifactTestEntryMatches(
    borrow byteview artifact,
    long function,
    long caseKind,
    long caseValue
  ) {
    long manifest = sectionOffset(artifact, /* section= */ 0);
    long entry = readUnsigned(artifact, manifest + 4, /* width= */ 4);
    long functions = sectionOffset(artifact, /* section= */ 4);
    long functionCount = readUnsigned(artifact, functions, /* width= */ 4);
    if (entry < functionCount) {} else {
      return false;
    }

    long entryDescriptor = functions + 4 + entry * 40;
    long code = sectionOffset(artifact, /* section= */ 5);
    long cursor = code + readUnsigned(artifact, entryDescriptor + 12, /* width= */ 4);
    long length = readUnsigned(artifact, entryDescriptor + 16, /* width= */ 4);
    if (caseKind == 1) {
      if (length != 40) {
        return false;
      }

      if (instructionMatches(artifact, cursor, OPCODE_CALL_VOID, 3, 32) == false) {
        return false;
      }

      if (readUnsigned(artifact, cursor + 8, /* width= */ 8) != function) {
        return false;
      }

      if (readUnsigned(artifact, cursor + 16, /* width= */ 8) != 0) {
        return false;
      }

      if (readUnsigned(artifact, cursor + 24, /* width= */ 8) != 0) {
        return false;
      }

      return instructionMatches(artifact, cursor + 32, OPCODE_HALT, 0, 8);
    }

    if (caseKind < 2) {
      return false;
    }

    if (3 < caseKind) {
      return false;
    }

    if (length != 88) {
      return false;
    }

    if (instructionMatches(artifact, cursor, OPCODE_LOCAL_CONST, 2, 24) == false) {
      return false;
    }

    if (readUnsigned(artifact, cursor + 8, /* width= */ 8) != 0) {
      return false;
    }

    if (readSigned(artifact, cursor + 16) != caseValue) {
      return false;
    }

    cursor += 24;
    if (instructionMatches(artifact, cursor, OPCODE_LOCAL_MOVE, 2, 24) == false) {
      return false;
    }

    if (readUnsigned(artifact, cursor + 8, /* width= */ 8) != 1) {
      return false;
    }

    if (readUnsigned(artifact, cursor + 16, /* width= */ 8) != 0) {
      return false;
    }

    cursor += 24;
    if (instructionMatches(artifact, cursor, OPCODE_CALL_VOID, 3, 32) == false) {
      return false;
    }

    if (readUnsigned(artifact, cursor + 8, /* width= */ 8) != function) {
      return false;
    }

    if (readUnsigned(artifact, cursor + 16, /* width= */ 8) != 1) {
      return false;
    }

    if (readUnsigned(artifact, cursor + 24, /* width= */ 8) != 1) {
      return false;
    }

    return instructionMatches(artifact, cursor + 32, OPCODE_HALT, 0, 8);
  }

  /// Returns the verified manifest program kind code.
  public long artifactProgramKind(borrow byteview artifact) {
    long manifest = sectionOffset(artifact, /* section= */ 0);
    return readUnsigned(artifact, manifest + 12, /* width= */ 4);
  }

  /// Returns the active verified global count.
  public long artifactGlobalCount(borrow byteview artifact) {
    long types = sectionOffset(artifact, /* section= */ 2);
    return readUnsigned(artifact, types, /* width= */ 4);
  }

  /// Returns one verified global name range in descriptor order.
  public ArtifactText artifactGlobalText(borrow byteview artifact, long global) {
    long types = sectionOffset(artifact, /* section= */ 2);
    long count = readUnsigned(artifact, types, /* width= */ 4);
    assert(global < count);
    long name = readUnsigned(artifact, types + 4 + global * 16, /* width= */ 4);
    return stringText(artifact, name);
  }
}
