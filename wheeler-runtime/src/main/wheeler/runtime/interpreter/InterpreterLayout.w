//! Resolves canonical interpreter section, frame, and instruction coordinates.

module wheeler.runtime.interpreter_layout;

import wheeler.compiler.opcodes;
import wheeler.compiler.type_codes;
import wheeler.core.encoding.binary;

classical class InterpreterLayout {
  /// Resolves one canonical section payload offset.
  public long sectionOffset(borrow byteview artifact, long section) {
    return readUnsigned(artifact, 40 + section * 32 + 8, 8);
  }

  /// Resolves one canonical function descriptor.
  public long descriptorBase(long functionsOffset, long function) {
    return functionsOffset + 4 + function * 40;
  }

  /// Resolves one local in the bounded call-frame store.
  public long localIndex(long depth, long local) {
    return depth * INTERPRETER_LOCAL_WIDTH + local;
  }

  /// Reports whether a call transfers ownership of one parameter.
  public boolean transferredType(long typeCode) {
    if (typeCode == TYPE_REGION) {
      return true;
    }

    if (typeCode == TYPE_WORDS) {
      return true;
    }

    if (typeCode == TYPE_BYTES) {
      return true;
    }

    if (typeCode == TYPE_LONG_MAP) {
      return true;
    }

    if (typeCode == TYPE_UTF8) {
      return true;
    }

    if (typeCode < TYPE_UTF8_BORROW) {
      return false;
    }

    return typeCode < TYPE_BYTE_VIEW + 1;
  }

  /// Resolves the first parameter type in one function descriptor.
  public long parameterTypes(
    borrow byteview artifact,
    long functionsOffset,
    long functionCount,
    long descriptor
  ) {
    long resultCount = 0;
    if ((readUnsigned(artifact, descriptor + 8, 4) & 4) == 4) {
      resultCount = 1;
    }

    long typeOffset = readUnsigned(artifact, descriptor + 36, 4);
    return functionsOffset + 4 + functionCount * 40 + (typeOffset + resultCount) * 4;
  }

  /// Resolves an instruction ordinal inside one canonical function body.
  public long instructionCursor(borrow byteview artifact, long start, long end, long target) {
    long cursor = start;
    long index = 0;
    while (cursor < end) limit MAX_CODE_INSTRUCTIONS {
      if (index == target) {
        return cursor;
      }

      cursor += readUnsigned(artifact, cursor + 4, 4);
      index += 1;
    }

    return -1;
  }
}
