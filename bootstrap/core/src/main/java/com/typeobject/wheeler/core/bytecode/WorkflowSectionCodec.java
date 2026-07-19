package com.typeobject.wheeler.core.bytecode;

import com.typeobject.wheeler.core.workflow.WorkflowOpcode;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.List;

/** Strict bounded codec for the canonical workflow section. */
final class WorkflowSectionCodec {
  private static final int RECORD_BYTES = 32;

  private WorkflowSectionCodec() {}

  static byte[] write(List<WorkflowStep> workflow) {
    ByteBuffer buffer = ByteBuffer.allocate(4 + workflow.size() * RECORD_BYTES)
        .order(ByteOrder.LITTLE_ENDIAN);
    buffer.putInt(workflow.size());
    for (WorkflowStep step : workflow) {
      buffer.putInt(step.opcode().ordinal());
      buffer.putInt(0);
      buffer.putLong(step.first());
      buffer.putLong(step.second());
      buffer.putLong(step.third());
    }
    return buffer.array();
  }

  static List<WorkflowStep> read(ByteBuffer buffer) {
    if (buffer.remaining() < 4) {
      throw new BytecodeException("Missing workflow count");
    }
    int count = buffer.getInt();
    if (count < 0 || count > 1_000_000 || buffer.remaining() != count * RECORD_BYTES) {
      throw new BytecodeException("Invalid workflow section length");
    }
    List<WorkflowStep> result = new ArrayList<>(count);
    for (int i = 0; i < count; i++) {
      WorkflowOpcode opcode = WorkflowOpcode.fromCode(buffer.getInt());
      if (buffer.getInt() != 0) {
        throw new BytecodeException("Invalid workflow reserved field");
      }
      result.add(new WorkflowStep(opcode, buffer.getLong(), buffer.getLong(), buffer.getLong()));
    }
    return List.copyOf(result);
  }
}
