package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for nested aggregate-expression temporary products. */
final class NativeCompilerAggregateExpressionTemporariesExampleTest {
  @Test
  void appendsOneNestedExpressionLocalInEvaluationOrder() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(/* outerDefinitionStart= */ 0),
        "new Outer(new Inner())".getBytes(StandardCharsets.UTF_8), 1);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(2, machine.global("valueCount"));
    assertEquals(1, machine.global("temporaryCount"));
    assertEquals(3, machine.global("temporaryLocal"));
    assertEquals(4, machine.global("functionLocalCount"));
  }

  @Test
  void rejectsAMissingOuterValueBeforePublishingTheNestedTemporary() throws Exception {
    VirtualMachine machine = new VirtualMachine(
        program(/* outerDefinitionStart= */ 5),
        "new Outer(new Inner())".getBytes(StandardCharsets.UTF_8), 1);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(1, machine.global("valueCount"));
    assertEquals(0, machine.global("temporaryCount"));
    assertEquals(91, machine.global("temporaryLocal"));
    assertEquals(3, machine.global("functionLocalCount"));
  }

  private static Program program(int outerDefinitionStart) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_expression_temporaries"));
    sources.put("AggregateExpressionTemporariesExample.w", """
        module example.aggregate_expression_temporaries;

        import wheeler.compiler.closure.aggregate_expression_temporaries;

        classical class AggregateExpressionTemporariesExample {
          state long valid = 0;
          state long valueCount = 0;
          state long temporaryCount = 0;
          state long temporaryLocal = 0;
          state long functionLocalCount = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 270848, /* allocations= */ 4);
            words operations = allocate(products, /* length= */ 2048);
            words statements = allocate(products, /* length= */ 24576);
            words values = allocate(products, /* length= */ 7168);
            words functionLocals = allocate(products, /* length= */ 64);
            set(operations, 256, 14);
            set(operations, 512, 5);
            set(operations, 1280, 10);
            set(operations, 1536, 11);
            set(operations, 257, 4);
            set(operations, 513, 5);
            set(operations, 1281, 0);
            set(operations, 1537, 22);
            set(statements, 0, 0);
            set(statements, 8192, 1);
            set(statements, 16384, 0);
            set(statements, 20480, 22);
            set(values, 0, 0);
            set(values, 3072, 2);
            set(values, 5120, %d);
            set(values, 6144, 22);
            set(values, 3073, 91);
            set(functionLocals, 0, 3);
            AggregateExpressionTemporaryPlan plan = appendAggregateExpressionTemporaries(
              /* operationCount= */ 2,
              operations,
              /* statementCount= */ 1,
              statements,
              /* valueCount= */ 1,
              values,
              functionLocals
            );
            if (plan.valid) {
              valid = 1;
            }
            valueCount = plan.valueCount;
            temporaryCount = plan.temporaryCount;
            temporaryLocal = values[3073];
            functionLocalCount = functionLocals[0];
            setOutputLength(output, 0);
            drop(functionLocals);
            drop(values);
            drop(statements);
            drop(operations);
            drop(products);
          }
        }
        """.formatted(outerDefinitionStart));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.aggregate_expression_temporaries");
  }
}
