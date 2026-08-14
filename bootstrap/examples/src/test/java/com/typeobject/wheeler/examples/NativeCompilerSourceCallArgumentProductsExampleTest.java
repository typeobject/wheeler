package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for source-call argument value products. */
final class NativeCompilerSourceCallArgumentProductsExampleTest {
  @Test
  void bindsTypedArgumentsToDefiningValues() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(16, 5), "long value = 7; identity(value)".getBytes(StandardCharsets.UTF_8));

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(1, machine.global("callCount"));
    assertEquals(1, machine.global("argumentCount"));
    assertEquals(0, machine.global("firstValue"));
    assertEquals(0, machine.global("firstOffset"));
    assertEquals(1, machine.global("firstType"));
  }

  @Test
  void retainsBooleanArgumentTypes() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(22, 8), "boolean value = true; identity(value)".getBytes(StandardCharsets.UTF_8));

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(1, machine.global("argumentCount"));
    assertEquals(2, machine.global("firstType"));
  }

  @Test
  void rejectsUnknownArgumentsAtomically() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(16, 5), "long value = 7; identity(missing)".getBytes(StandardCharsets.UTF_8));

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("argumentCount"));
    assertEquals(77, machine.global("firstValue"));
    assertEquals(78, machine.global("firstType"));
  }

  private static Program program(int identityStart, int valueStart) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_call_argument_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_call_products"));
    sources.put("SourceCallArgumentProductsExample.w", """
        module example.source_call_argument_products;

        import wheeler.compiler.closure.source_call_argument_products;
        import wheeler.compiler.closure.source_call_products;

        classical class SourceCallArgumentProductsExample {
          state long valid = 0;
          state long callCount = 0;
          state long argumentCount = 0;
          state long firstValue = 0;
          state long firstOffset = 0;
          state long firstType = 0;

          entry void main(borrow utf8 input) {
            region rows = new region(/* bytes= */ 456840, /* allocations= */ 14);
            bytes sourceBytes = allocateBytes(rows, /* length= */ 64);
            bytes binarySource = allocateBytes(rows, /* length= */ 64);
            words nameStarts = allocate(rows, /* length= */ 4096);
            words nameLengths = allocate(rows, /* length= */ 4096);
            words parameterCounts = allocate(rows, /* length= */ 4096);
            words calls = allocate(rows, /* length= */ 1024);
            words callStatements = allocate(rows, /* length= */ 256);
            words statements = allocate(rows, /* length= */ 28672);
            words values = allocate(rows, /* length= */ 7168);
            words callArgumentStarts = allocate(rows, /* length= */ 256);
            words callArgumentCounts = allocate(rows, /* length= */ 256);
            words arguments = allocate(rows, /* length= */ 3584);
            words argumentValues = allocate(rows, /* length= */ 3584);
            words unused = allocate(rows, /* length= */ 1);
            long sourceByte = 0;
            while (sourceByte < bufferLength(input)) limit 64 {
              setByte(sourceBytes, sourceByte, utf8Scalar(input, sourceByte));
              setByte(binarySource, sourceByte, utf8Scalar(input, sourceByte));
              sourceByte += 1;
            }
            utf8 source = freezeUtf8(sourceBytes);
            set(nameStarts, 0, IDENTITY_START);
            set(nameLengths, 0, 8);
            set(parameterCounts, 0, 1);
            set(statements, 0, 0);
            set(statements, 12288, IDENTITY_START);
            set(statements, 16384, bufferLength(input) - IDENTITY_START);
            set(values, 0, 0);
            set(values, 1024, VALUE_START);
            set(values, 2048, 5);
            set(values, 3072, 0);
            set(values, 4096, 1);
            set(values, 5120, 0);
            set(values, 6144, DECLARATION_LENGTH);
            set(argumentValues, 0, 77);
            set(arguments, 1792, 78);
            callCount = resolveLocalProductSourceCallProducts(
              binarySource,
              /* sourceStart= */ 0,
              bufferLength(input),
              binarySource,
              /* firstLocalCallable= */ 0,
              /* localCallableCount= */ 1,
              nameStarts,
              nameLengths,
              parameterCounts,
              calls
            );
            SourceCallStatementPlan statementPlan = bindSourceCallStatements(
              callCount,
              /* callSourceBase= */ 0,
              /* callableOwner= */ 0,
              /* statementCount= */ 1,
              statements,
              calls,
              callStatements
            );
            assert(statementPlan.valid);
            SourceCallArgumentPlan argumentPlan = materializeSourceCallArgumentProducts(
              source,
              /* callSourceBase= */ 0,
              callCount,
              calls,
              callStatements,
              /* statementCount= */ 1,
              statements,
              /* valueCount= */ 1,
              values,
              callArgumentStarts,
              callArgumentCounts,
              arguments,
              argumentValues
            );
            if (argumentPlan.valid) {
              valid = 1;
            }
            argumentCount = argumentPlan.argumentCount;
            firstValue = argumentValues[0];
            firstOffset = argumentValues[1792];
            firstType = arguments[1792];
            drop(unused);
            drop(argumentValues);
            drop(arguments);
            drop(callArgumentCounts);
            drop(callArgumentStarts);
            drop(values);
            drop(statements);
            drop(callStatements);
            drop(calls);
            drop(parameterCounts);
            drop(nameLengths);
            drop(nameStarts);
            drop(binarySource);
            drop(source);
            drop(rows);
          }
        }
        """.replace("IDENTITY_START", Integer.toString(identityStart))
            .replace("VALUE_START", Integer.toString(valueStart))
            .replace("DECLARATION_LENGTH", Integer.toString(identityStart - 1)));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_call_argument_products");
  }
}
