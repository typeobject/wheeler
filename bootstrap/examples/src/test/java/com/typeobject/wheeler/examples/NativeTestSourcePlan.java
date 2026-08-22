package com.typeobject.wheeler.examples;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.List;

/** Encodes and independently reads canonical native test source plans. */
final class NativeTestSourcePlan {
  record Source(String path, String text) {}

  private NativeTestSourcePlan() {}

  static byte[] write(List<Source> sources) {
    ByteArrayOutputStream plan = new ByteArrayOutputStream();
    plan.writeBytes(ByteBuffer.allocate(4).putInt(sources.size()).array());
    for (Source source : sources) {
      byte[] path = source.path().getBytes(StandardCharsets.UTF_8);
      byte[] text = source.text().getBytes(StandardCharsets.UTF_8);
      plan.writeBytes(ByteBuffer.allocate(4).putInt(path.length).array());
      plan.writeBytes(path);
      plan.writeBytes(ByteBuffer.allocate(4).putInt(text.length).array());
      plan.writeBytes(text);
    }
    return plan.toByteArray();
  }

  static int payloadOffset(byte[] plan, String selectedPath) {
    ByteBuffer input = ByteBuffer.wrap(plan);
    int sourceCount = input.getInt();
    for (int source = 0; source < sourceCount; source++) {
      byte[] path = new byte[input.getInt()];
      input.get(path);
      int sourceLength = input.getInt();
      if (new String(path, StandardCharsets.UTF_8).equals(selectedPath)) {
        return input.position();
      }
      input.position(input.position() + sourceLength);
    }
    throw new AssertionError("missing source " + selectedPath);
  }
}
