package com.typeobject.wheeler.compiler;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;

public class WheelerCompiler {
  public byte[] compile(String sourceCode) {
    // For now, just a basic implementation that handles the counter example
    ByteArrayOutputStream bytecode = new ByteArrayOutputStream();
    DataOutputStream out = new DataOutputStream(bytecode);

    try {
      // Write header
      out.writeBytes("WHEEL");
      out.writeByte(0);
      out.writeByte(1);
      out.writeShort(1); // version 1.0

      // Write constant pool
      // ... simplified for example

      // Write class data
      writeClassData(out);

      // Write methods
      writeMethodIncrement(out);
      writeMethodDecrement(out);
      writeMethodGet(out);
      writeMethodMain(out);

      return bytecode.toByteArray();
    } catch (IOException e) {
      throw new CompilationException("Failed to generate bytecode", e);
    }
  }

  private void writeMethodIncrement(DataOutputStream out) throws IOException {
    // Simplified bytecode generation for increment method
    out.writeByte(Opcodes.RLOAD);
    out.writeByte(0); // count field
    out.writeByte(Opcodes.RINC);
    out.writeByte(Opcodes.RSTORE);
    out.writeByte(0); // count field
  }
}
