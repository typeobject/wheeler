package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

/** The finite step rule must not borrow a callee's uncounted transitions. */
final class NativeStaticStepProofExampleTest {
  @Test
  void rejectsTheInverseCallCounterexampleInTheNativeCompleteArtifactVerifier() throws Exception {
    byte[] valid = StaticStepProofArtifacts.artifact(Opcode.UNCALL);
    Program decoded = new BytecodeReader().read(valid);
    var machine = new VirtualMachine(decoded);
    machine.run();
    assertEquals(6, machine.snapshot().sequence());
    assertEquals(0, machine.global("value"));
    Program verifier = verifier();
    check(verifier, valid, 1);
    check(verifier, StaticStepProofArtifacts.retarget(valid, 1), 0);
  }

  @ParameterizedTest
  @EnumSource(value = Opcode.class, names = {
      "CALL", "UNCALL", "CALL_VALUE", "CALL_VOID", "CALL_RESULT_SLOT", "UNCALL_RESULT_SLOT",
      "JUMP", "JUMP_IF_ZERO"
  })
  void rejectsEveryCallAndBranchWithAnOtherwiseValidCertificate(Opcode opcode) throws Exception {
    byte[] valid = StaticStepProofArtifacts.artifact(opcode);
    Program decoded = new BytecodeReader().read(valid);
    assertArrayEquals(valid, new BytecodeWriter().write(decoded));
    var machine = new VirtualMachine(decoded);
    var initial = machine.snapshot();
    machine.run();
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
    Program verifier = verifier();
    check(verifier, valid, 1);
    byte[] forged = StaticStepProofArtifacts.retarget(valid, 1);
    assertThrows(BytecodeException.class, () -> new BytecodeReader().read(forged));
    check(verifier, forged, 0);
  }

  @Test
  void checksExactFirstExcessSignedAndMalformedCertificateBounds() throws Exception {
    byte[] valid = StaticStepProofArtifacts.artifact(Opcode.UNCALL);
    Program verifier = verifier();
    long ceiling = new BytecodeReader().read(valid).maxSteps();
    for (long bound : List.of(2L, ceiling)) {
      byte[] admitted = bound(valid, bound);
      new BytecodeReader().read(admitted);
      check(verifier, admitted, 1);
    }
    for (long bound : List.of(1L, 0L, -1L, ceiling + 1, Long.MIN_VALUE, Long.MAX_VALUE)) {
      reject(verifier, bound(valid, bound));
    }
    reject(verifier, StaticStepProofArtifacts.retarget(valid, 3));
    reject(verifier, StaticStepProofArtifacts.retarget(valid, -1));
    reject(verifier, Arrays.copyOf(valid, valid.length - 1));
    byte[] unknownRule = valid.clone();
    ByteBuffer.wrap(unknownRule).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(StaticStepProofArtifacts.proofOffset(unknownRule) + 4 + 8, 99);
    reject(verifier, unknownRule);
    byte[] badName = valid.clone();
    ByteBuffer.wrap(badName).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(StaticStepProofArtifacts.proofOffset(badName) + 4 + 4, Integer.MAX_VALUE);
    reject(verifier, badName);
  }

  private static byte[] bound(byte[] artifact, long bound) {
    byte[] changed = artifact.clone();
    ByteBuffer.wrap(changed).order(ByteOrder.LITTLE_ENDIAN)
        .putLong(StaticStepProofArtifacts.proofOffset(changed) + 4 + 16, bound);
    return changed;
  }

  private static void reject(Program verifier, byte[] artifact) {
    assertThrows(BytecodeException.class, () -> new BytecodeReader().read(artifact));
    check(verifier, artifact, 0);
  }

  private static void check(Program verifier, byte[] artifact, long expected) {
    var machine = VirtualMachine.withBinaryInput(verifier, artifact);
    var initial = machine.snapshot();
    machine.run();
    assertEquals(expected, machine.global("verification"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  private static Program verifier() throws Exception {
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.verifier"));
    CoreSources.addBinaryClosure(modules);
    modules.put("StaticStepVerifier.w", """
        module example.static_step_verifier;
        import wheeler.compiler.verifier;
        classical class StaticStepVerifier {
          state long verification = 0;
          entry void main(borrow byteview artifact) {
            verification = verifyArtifact(artifact, bufferLength(artifact));
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(modules, "example.static_step_verifier");
  }
}
