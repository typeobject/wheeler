package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeCompilerSelfSourceExampleTest.assertCompilerLibrary;
import static com.typeobject.wheeler.examples.NativeCompilerSelfSourceExampleTest.assertNoPublication;
import static com.typeobject.wheeler.examples.NativeCompilerSelfSourceExampleTest.nativeWriter;
import static com.typeobject.wheeler.examples.NativeCompilerSelfSourceExampleTest.twoHelperSource;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for bounded native scalar helper tables. */
final class NativeCompilerHelperTableExampleTest {
  private static final String[] HELPER_NAMES = {
      "omega", "alpha", "theta", "beta", "zeta", "gamma", "sigma", "delta", "kappa"
  };

  @Test
  void compilesCanonicalHelperAbiByteForByte() throws Exception {
    Program decoded = assertCompilerLibrary(
        "compiler/syntax/helpers/HelperAbi.w",
        "wheeler.compiler.helper_abi");
    assertEquals("$library", decoded.functions().getFirst().name());
  }

  @Test
  void compilesEightEntrylessHelpersByteForByte() throws Exception {
    Program compiler = CompilerSources.minimalCompilerProgram();
    String source = helperSource(8);
    VirtualMachine writer = nativeWriter(compiler, source);
    CompilerMachineRunner.runWithoutRewindHistory(writer);

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("EightHelpers.w", source),
        "examples.two_helpers");
    byte[] artifact = writer.hostOutput();
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals("examples.two_helpers::omega", decoded.functions().getFirst().name());
    assertEquals("examples.two_helpers::delta", decoded.functions().get(7).name());
    assertEquals("$library", decoded.functions().getLast().name());
  }

  @Test
  void rejectsNinthEntrylessHelperBeforePublication() throws Exception {
    assertNoPublication(CompilerSources.minimalCompilerProgram(), helperSource(9));
  }

  private static String helperSource(int count) {
    StringBuilder members = new StringBuilder();
    for (int index = 0; index < count; index += 1) {
      members.append("  public long ")
          .append(HELPER_NAMES[index])
          .append("(long value) {\n    return value;\n  }\n\n");
    }
    return twoHelperSource(members.toString());
  }
}
