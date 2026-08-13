package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for local types derived from resolved loop products. */
final class NativeCompilerLoopLocalTypeProductsExampleTest {
  private static final String SOURCE = """
      classical class Example {
        entry void main() {
          long cursor = 0;
          while (cursor < 2) limit 2 {
            long delta = 1;
            boolean ready = true;
            ready = false;
            ready = ready;
            ready = true;
            assert(ready);
            assert(cursor < 3);
            assert(cursor == 0);
            cursor = 0;
            cursor = delta;
            cursor += delta;
          }
        }
      }
      """.strip();

  @Test
  void publishesTheStageZeroLoopLocalTypeSuffix() throws Exception {
    Program expected = new WheelerCompiler().compile(SOURCE);
    List<ValueType> allTypes = expected.functions().getFirst().localTypes();
    List<ValueType> expectedTypes = allTypes.subList(2, allTypes.size());
    VirtualMachine machine = new VirtualMachine(
        program(), SOURCE.getBytes(StandardCharsets.UTF_8), 1);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(expectedTypes.size(), machine.global("typeCount"));
    for (int type = 0; type < expectedTypes.size(); type++) {
      assertEquals(0, machine.global("owner" + type));
      assertEquals(type + 2, machine.global("local" + type));
      assertEquals(expectedTypes.get(type).code(), machine.global("code" + type));
    }
  }

  private static Program program() throws Exception {
    int bodyStart = SOURCE.indexOf("{", SOURCE.indexOf("main("));
    int bodyEnd = matchingClose(SOURCE, bodyStart) + 1;
    int cursorStart = SOURCE.indexOf("cursor = 0");
    int deltaStart = SOURCE.indexOf("delta = 1");
    int readyStart = SOURCE.indexOf("ready = true");
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.loop_local_type_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.resolved_loop_body_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_loop_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_statement_products"));
    sources.put("LoopLocalTypeProductsExample.w", """
        module example.loop_local_type_products;

        import wheeler.compiler.closure.loop_local_type_products;
        import wheeler.compiler.closure.resolved_loop_body_products;
        import wheeler.compiler.closure.source_loop_products;
        import wheeler.compiler.closure.source_statement_products;

        classical class LoopLocalTypeProductsExample {
          state long valid = 0;
          state long typeCount = 0;
          %s

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 696328, /* allocations= */ 11);
            words bodyStarts = allocate(products, /* length= */ 4096);
            words bodyLengths = allocate(products, /* length= */ 4096);
            words blocks = allocate(products, /* length= */ 6144);
            words statements = allocate(products, /* length= */ 28672);
            words conditions = allocate(products, /* length= */ 1536);
            words loops = allocate(products, /* length= */ 2304);
            words values = allocate(products, /* length= */ 7168);
            words bodyRows = allocate(products, /* length= */ 20480);
            words loopLocalBases = allocate(products, /* length= */ 256);
            words typeRows = allocate(products, /* length= */ 12288);
            words unused = allocate(products, /* length= */ 1);
            set(bodyStarts, 0, %d);
            set(bodyLengths, 0, %d);
            set(values, 0, 0);
            set(values, 1024, %d);
            set(values, 2048, 6);
            set(values, 3072, 1);
            set(values, 4096, 1);
            set(values, 1, 0);
            set(values, 1025, %d);
            set(values, 2049, 5);
            set(values, 3073, 3);
            set(values, 4097, 3);
            set(values, 2, 0);
            set(values, 1026, %d);
            set(values, 2050, 5);
            set(values, 3074, 5);
            set(values, 4098, 4);
            set(loopLocalBases, 0, 2);
            SourceBlockProductPlan blockPlan = materializeSourceBlockProducts(
              input,
              /* archiveSourceStart= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ 1,
              bodyStarts,
              bodyLengths,
              blocks
            );
            assert(blockPlan.valid);
            SourceLoopProductPlan loopPlan = materializeSourceLoopProducts(
              input,
              blockPlan.blockCount,
              blocks,
              statements,
              conditions,
              loops
            );
            assert(loopPlan.valid);
            ResolvedLoopBodyPlan bodyPlan = materializeResolvedLoopBodyProducts(
              input,
              loopPlan.statementCount,
              statements,
              /* valueCount= */ 3,
              values,
              bodyRows
            );
            assert(bodyPlan.valid);
            LoopLocalTypePlan typePlan = materializeLoopLocalTypeProducts(
              loopPlan.loopCount,
              loops,
              bodyPlan.bodyCount,
              bodyRows,
              loopLocalBases,
              typeRows
            );
            if (typePlan.valid) {
              valid = 1;
            }
            typeCount = typePlan.typeCount;
            %s
            setOutputLength(output, 0);
            drop(unused);
            drop(typeRows);
            drop(loopLocalBases);
            drop(bodyRows);
            drop(values);
            drop(loops);
            drop(conditions);
            drop(statements);
            drop(blocks);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(products);
          }
        }
        """.formatted(
            globals(22),
            bodyStart,
            bodyEnd - bodyStart,
            cursorStart,
            deltaStart,
            readyStart,
            assignments(22)));
    return new WheelerCompiler().compileModuleFiles(sources, "example.loop_local_type_products");
  }

  private static String globals(int count) {
    StringBuilder result = new StringBuilder();
    for (int type = 0; type < count; type++) {
      result.append("state long owner").append(type).append(" = 0;\n");
      result.append("state long local").append(type).append(" = 0;\n");
      result.append("state long code").append(type).append(" = 0;\n");
    }
    return result.toString();
  }

  private static String assignments(int count) {
    StringBuilder result = new StringBuilder();
    for (int type = 0; type < count; type++) {
      result.append("owner").append(type).append(" = typeRows[").append(type).append("];\n");
      result.append("local").append(type).append(" = typeRows[")
          .append(4096 + type).append("];\n");
      result.append("code").append(type).append(" = typeRows[")
          .append(8192 + type).append("];\n");
    }
    return result.toString();
  }

  private static int matchingClose(String source, int open) {
    int depth = 0;
    for (int cursor = open; cursor < source.length(); cursor++) {
      if (source.charAt(cursor) == '{') {
        depth += 1;
      }
      if (source.charAt(cursor) == '}') {
        depth -= 1;
        if (depth == 0) {
          return cursor;
        }
      }
    }
    throw new IllegalArgumentException("Unbalanced fixture");
  }
}
