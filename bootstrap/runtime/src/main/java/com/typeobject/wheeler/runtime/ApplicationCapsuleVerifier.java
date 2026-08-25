package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.packageformat.ApplicationCapsule;
import com.typeobject.wheeler.packageformat.CapsuleEntry;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;

/** Verifies every executable artifact and the fixed root in a framed application capsule. */
public final class ApplicationCapsuleVerifier {
  private ApplicationCapsuleVerifier() {}

  public static VerifiedCapsule verify(byte[] bytes) {
    return verify(ApplicationCapsule.parse(bytes));
  }

  public static VerifiedCapsule verify(ApplicationCapsule capsule) {
    Objects.requireNonNull(capsule, "capsule");
    BytecodeReader reader = new BytecodeReader();
    BytecodeWriter writer = new BytecodeWriter();
    LinkedHashMap<String, Program> programs = new LinkedHashMap<>();
    for (CapsuleEntry entry : capsule.entries()) {
      if (entry.kind() != CapsuleEntry.Kind.WBC) {
        continue;
      }
      byte[] bytes = entry.bytes();
      Program program = reader.read(bytes);
      if (!Arrays.equals(bytes, writer.write(program))) {
        throw new IllegalArgumentException(
            "Capsule WBC is not canonical: " + entry.name());
      }
      programs.put(entry.name(), program);
    }
    Program root = programs.get(capsule.root().rootWbc());
    if (root == null
        || !root.function(root.entryFunctionId()).name().equals(capsule.root().entryFunction())) {
      throw new IllegalArgumentException("Capsule root function does not match its WBC entry");
    }
    return new VerifiedCapsule(capsule, programs, root);
  }

  /** Fully framed capsule with canonical verified WBC programs and one bound root. */
  public record VerifiedCapsule(
      ApplicationCapsule capsule,
      Map<String, Program> programs,
      Program rootProgram) {
    public VerifiedCapsule {
      Objects.requireNonNull(capsule, "capsule");
      programs = Collections.unmodifiableMap(new LinkedHashMap<>(programs));
      Objects.requireNonNull(rootProgram, "rootProgram");
    }
  }
}
