package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.core.bytecode.Instruction;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.List;

/** Encodes independently compiled instructions without consulting a native encoder. */
final class NativeInstructionBytes {
  private NativeInstructionBytes() {}

  static byte[] encode(List<Instruction> instructions) {
    var bytes = ByteBuffer.allocate(instructions.stream().mapToInt(Instruction::encodedLength).sum())
        .order(ByteOrder.LITTLE_ENDIAN);
    for (var instruction : instructions) {
      bytes.putShort((short) instruction.opcode().code()).putShort((short) instruction.operands().size())
          .putInt(instruction.encodedLength());
      for (long operand : instruction.operands()) { bytes.putLong(operand); }
    }
    return bytes.array();
  }
}
