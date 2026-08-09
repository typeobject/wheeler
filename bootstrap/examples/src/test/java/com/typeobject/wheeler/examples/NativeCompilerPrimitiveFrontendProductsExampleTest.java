package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for primitive frontend value and statement products. */
final class NativeCompilerPrimitiveFrontendProductsExampleTest {
  @Test
  void publishesNamedResultLocalsAndSeparateStatementOrdinals() throws Exception {
    String source = "long first = 3; long second = first;";
    VirtualMachine machine = new VirtualMachine(program(),
        source.getBytes(StandardCharsets.UTF_8), 1);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(2, machine.global("valueCount"));
    assertEquals(2, machine.global("statementCount"));
    assertEquals(4, machine.global("localCount"));
    assertEquals(1, machine.global("firstLocal"));
    assertEquals(3, machine.global("secondLocal"));
    assertEquals(source.indexOf("first"), machine.global("firstNameStart"));
    assertEquals(source.indexOf("second"), machine.global("secondNameStart"));
    assertEquals(1, machine.global("firstSourceOrdinal"));
    assertEquals(0, machine.global("firstSpliceOrdinal"));
    assertEquals(2, machine.global("secondSourceOrdinal"));
    assertEquals(1, machine.global("secondSpliceOrdinal"));
  }

  @Test
  void malformedStatementLeavesCallerRowsUntouched() throws Exception {
    String source = "long first = 3; long second = first";
    VirtualMachine machine = new VirtualMachine(program(),
        source.getBytes(StandardCharsets.UTF_8), 1);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(91, machine.global("sentinelValue"));
    assertEquals(91, machine.global("sentinelStatement"));
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.primitive_frontend_products"));
    sources.put("PrimitiveFrontendProductsExample.w", """
        module example.primitive_frontend_products;

        import wheeler.compiler.closure.primitive_frontend_products;
        import wheeler.lexer.scanner;

        classical class PrimitiveFrontendProductsExample {
          state long valid = 0;
          state long valueCount = 0;
          state long statementCount = 0;
          state long localCount = 0;
          state long firstLocal = 0;
          state long secondLocal = 0;
          state long firstNameStart = 0;
          state long secondNameStart = 0;
          state long firstSourceOrdinal = 0;
          state long firstSpliceOrdinal = 0;
          state long secondSourceOrdinal = 0;
          state long secondSpliceOrdinal = 0;
          state long sentinelValue = 0;
          state long sentinelStatement = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 359424, /* allocations= */ 10);
            words tokenKinds = allocate(products, /* length= */ 4096);
            words tokenStarts = allocate(products, /* length= */ 4096);
            words tokenLengths = allocate(products, /* length= */ 4096);
            words statementStarts = allocate(products, /* length= */ 64);
            words spliceOrdinals = allocate(products, /* length= */ 64);
            words parameterNameStarts = allocate(products, /* length= */ 256);
            words parameterNameLengths = allocate(products, /* length= */ 256);
            words parameterLocals = allocate(products, /* length= */ 256);
            words values = allocate(products, /* length= */ 7168);
            words statements = allocate(products, /* length= */ 24576);
            set(values, 1024, 91);
            set(statements, 16384, 91);
            ScanResult scanned = scan(input, tokenKinds, tokenStarts, tokenLengths);
            match (scanned) {
              case ScanResult.Error(ScanDiagnostic diagnostic) {
                assert(diagnostic.offset < 0);
              }
              case ScanResult.Value(long tokenCount) {
                assert(7 < tokenCount);
              }
            }
            set(statementStarts, 0, 0);
            set(statementStarts, 1, 5);
            set(spliceOrdinals, 0, 0);
            set(spliceOrdinals, 1, 1);
            PrimitiveFrontendProductPlan plan = appendPrimitiveFrontendProducts(
              input,
              /* function= */ 0,
              /* direction= */ 0,
              /* parameterCount= */ 0,
              parameterNameStarts,
              parameterNameLengths,
              parameterLocals,
              /* statementCount= */ 2,
              tokenKinds,
              tokenStarts,
              tokenLengths,
              statementStarts,
              spliceOrdinals,
              /* firstStatementLocal= */ 0,
              /* valueCount= */ 0,
              /* frontendStatementCount= */ 0,
              values,
              statements
            );
            if (plan.valid) {
              valid = 1;
              valueCount = plan.valueCount;
              statementCount = plan.statementCount;
              localCount = plan.localCount;
              firstLocal = values[3072];
              secondLocal = values[3073];
              firstNameStart = values[1024];
              secondNameStart = values[1025];
              firstSourceOrdinal = statements[8192];
              firstSpliceOrdinal = statements[12288];
              secondSourceOrdinal = statements[8193];
              secondSpliceOrdinal = statements[12289];
            }
            sentinelValue = values[1024];
            sentinelStatement = statements[16384];
            setOutputLength(output, 0);
            drop(statements);
            drop(values);
            drop(parameterLocals);
            drop(parameterNameLengths);
            drop(parameterNameStarts);
            drop(spliceOrdinals);
            drop(statementStarts);
            drop(tokenLengths);
            drop(tokenStarts);
            drop(tokenKinds);
            drop(products);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.primitive_frontend_products");
  }
}
