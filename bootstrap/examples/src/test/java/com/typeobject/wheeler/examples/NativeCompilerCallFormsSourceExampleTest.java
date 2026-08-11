package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Focused source evidence for generated imported-call call forms. */
final class NativeCompilerCallFormsSourceExampleTest {
  @Test
  void compilesGeneratedCallFormsWithCanonicalTrailingSpace() throws Exception {
    String source = """
        module wheeler.compiler.call_forms;
        classical class CallForms {
          public long twoArgumentFirstToken(long statementStart) {
            return statementStart + 5;
          }
          public long twoArgumentSecondToken(
            borrow utf8 source,
            borrow mut words tokenStarts,
            long statementStart
          ) {
            long firstToken = twoArgumentFirstToken(statementStart);
            long firstStart = tokenStarts[firstToken];
            long firstScalar = utf8Scalar(source, firstStart);
            long narrowToken = firstToken + 2;
            long wideToken = firstToken + 3;
            if (firstScalar == 45) {
              return wideToken;
            }
            return narrowToken;
          }
          public boolean wideLocalCallStatement(long opcode) {
            if (__wheeler_import_498(opcode)) { return true; }
            if (__wheeler_import_424(opcode)) { return true; }
            if (opcode == 919) { return true; }
            if (opcode == 920) { return true; }
            if (opcode == 921) { return true; }
            if (opcode == 30208) { return true; }
            if (opcode == 30464) { return true; }
            return opcode == 30720;
          }
          public boolean scalarResultCallStatement(long opcode) {
            if (opcode == 826) { return true; }
            if (opcode == 845) { return true; }
            if (__wheeler_import_461(opcode)) { return true; }
            if (__wheeler_import_503(opcode)) { return true; }
            return wideLocalCallStatement(opcode);
          }
          private boolean __wheeler_import_424(long p0) {
            return __wheeler_import_424(p0);
          }
          private boolean __wheeler_import_461(long p0) {
            return __wheeler_import_461(p0);
          }
          private boolean __wheeler_import_498(long p0) {
            return __wheeler_import_498(p0);
          }
          private boolean __wheeler_import_503(long p0) {
            return __wheeler_import_503(p0);
          }
        }
        """.stripTrailing() + " ";

    byte[] artifact = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("CallFormsGenerated.w", source), "wheeler.compiler.call_forms");
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);
  }
}
