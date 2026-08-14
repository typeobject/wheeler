package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for pre-link source call products. */
final class NativeCompilerSourceCallProductsExampleTest {
  private static final byte[] SOURCE = "identity identity(7)".getBytes(StandardCharsets.UTF_8);

  @Test
  void resolvesOneUnqualifiedImportedNameAndArity() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false, false), SOURCE);

    machine.run();

    assertEquals(1, machine.global("callCount"));
    assertEquals(0, machine.global("firstTarget"));
    assertEquals(1, machine.global("firstArity"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void resolvesPackedCallableNameProductsWithoutDependencySource() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(productProgram(false, false), SOURCE, 1);

    machine.run();

    assertEquals(1, machine.global("callCount"));
    assertEquals(3, machine.global("firstTarget"));
    assertEquals(1, machine.global("firstArity"));
    assertEquals(1, machine.global("published"));
    assertEquals(1, machine.global("statementValid"));
    assertEquals(0, machine.global("firstStatement"));
  }

  @Test
  void rejectsDetachedCallStatementBeforePublication() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(productProgram(false, true), SOURCE, 1);

    machine.run();

    assertEquals(1, machine.global("callCount"));
    assertEquals(0, machine.global("statementValid"));
    assertEquals(77, machine.global("firstStatement"));
  }

  @Test
  void rejectsPackedProductAmbiguityBeforeCallRowPublication() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(productProgram(true, false), SOURCE, 1);

    assertThrows(VmTrap.class, machine::run);

    assertEquals(-1, machine.global("firstTarget"));
    assertEquals(0, machine.global("published"));
  }

  @Test
  void localCallableShadowsTheImportedProduct() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true, false), SOURCE);

    machine.run();

    assertEquals(0, machine.global("callCount"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void equalImportedNamesAndAritiesRemainAmbiguous() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false, true), SOURCE);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  private static Program productProgram(boolean ambiguous, boolean detachedStatement) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_call_products"));
    sources.put("ProductSourceCallProductsExample.w", """
        module example.product_source_call_products;

        import wheeler.compiler.closure.source_call_products;

        classical class ProductSourceCallProductsExample {
          state long callCount = 0;
          state long firstTarget = -1;
          state long firstArity = -1;
          state long firstStatement = 77;
          state long statementValid = 0;
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 1452032, /* allocations= */ 8);
            words nameStarts = allocate(rows, /* length= */ 4096);
            words nameLengths = allocate(rows, /* length= */ 4096);
            words parameterCounts = allocate(rows, /* length= */ 4096);
            words dependencies = allocate(rows, /* length= */ 8192);
            words calls = allocate(rows, /* length= */ 1024);
            words callStatements = allocate(rows, /* length= */ 256);
            words statements = allocate(rows, /* length= */ 28672);
            bytes names = allocateBytes(rows, /* length= */ 1048576);
            long nameByte = 0;
            while (nameByte < 8) limit 8 {
              setByte(names, nameByte, source[nameByte]);
              nameByte += 1;
            }
            set(nameStarts, 3, 0);
            set(nameLengths, 3, 8);
            set(parameterCounts, 3, 1);
            set(dependencies, 4096, 3);
            set(statements, 0, 0);
            set(statements, 12288, STATEMENT_START);
            set(statements, 16384, STATEMENT_LENGTH);
            set(callStatements, 0, 77);
            if (AMBIGUOUS) {
              set(nameStarts, 4, 0);
              set(nameLengths, 4, 8);
              set(parameterCounts, 4, 1);
              set(dependencies, 4097, 4);
            }
            callCount = resolveProductSourceCallProducts(
              source,
              /* sourceStart= */ 0,
              bufferLength(source),
              names,
              /* firstLocalCallable= */ 0,
              /* localCallableCount= */ 0,
              nameStarts,
              nameLengths,
              parameterCounts,
              /* dependencyCount= */ DEPENDENCY_COUNT,
              dependencies,
              calls
            );
            if (0 < callCount) {
              firstTarget = calls[768];
              firstArity = calls[512];
            }
            SourceCallStatementPlan statementPlan = bindSourceCallStatements(
              callCount,
              /* callSourceBase= */ 0,
              /* callableOwner= */ 0,
              /* statementCount= */ 1,
              statements,
              calls,
              callStatements
            );
            if (statementPlan.valid) {
              statementValid = 1;
            }
            firstStatement = callStatements[0];
            setOutputLength(output, 0);
            published = 1;
            drop(names);
            drop(statements);
            drop(callStatements);
            drop(calls);
            drop(dependencies);
            drop(parameterCounts);
            drop(nameLengths);
            drop(nameStarts);
            drop(rows);
          }
        }
        """.replace("AMBIGUOUS", ambiguous ? "true" : "false")
            .replace("DEPENDENCY_COUNT", ambiguous ? "2" : "1")
            .replace("STATEMENT_START", detachedStatement ? "18" : "9")
            .replace("STATEMENT_LENGTH", detachedStatement ? "1" : "11"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.product_source_call_products");
  }

  private static Program program(boolean localShadow, boolean ambiguous) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_call_products"));
    sources.put("SourceCallProductsExample.w", """
        module example.source_call_products;

        import wheeler.compiler.closure.source_call_products;

        classical class SourceCallProductsExample {
          state long callCount = 0;
          state long firstTarget = -1;
          state long firstArity = -1;
          state long published = 0;

          entry void main(borrow utf8 source) {
            region rows = new region(/* bytes= */ 106496, /* allocations= */ 4);
            words nameStarts = allocate(rows, /* length= */ 4096);
            words nameLengths = allocate(rows, /* length= */ 4096);
            words parameterCounts = allocate(rows, /* length= */ 4096);
            words calls = allocate(rows, /* length= */ 1024);
            set(nameStarts, 0, 0);
            set(nameLengths, 0, 8);
            set(parameterCounts, 0, 1);
            set(nameStarts, 1, 0);
            set(nameLengths, 1, 8);
            set(parameterCounts, 1, 1);
            callCount = resolveSourceCallProducts(
              source,
              source,
              0,
              LOCAL_COUNT,
              IMPORTED_FIRST,
              IMPORTED_COUNT,
              nameStarts,
              nameLengths,
              parameterCounts,
              calls
            );
            if (0 < callCount) {
              firstTarget = calls[768];
              firstArity = calls[512];
            }
            published = 1;
            drop(calls);
            drop(parameterCounts);
            drop(nameLengths);
            drop(nameStarts);
            drop(rows);
          }
        }
        """.replace("LOCAL_COUNT", localShadow ? "1" : "0")
            .replace("IMPORTED_FIRST", localShadow ? "1" : "0")
            .replace("IMPORTED_COUNT", ambiguous ? "2" : "1"));
    return new WheelerCompiler().compileModuleFiles(sources, "example.source_call_products");
  }
}
