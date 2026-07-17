package com.typeobject.wheeler.runtime.hybrid;

import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

final class ArtifactIdentity {
  private ArtifactIdentity() {}

  static String of(Program program) {
    try {
      byte[] artifact = new BytecodeWriter().write(program);
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(artifact));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }
}
