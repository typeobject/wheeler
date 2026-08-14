package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for exact callable-local type windows. */
final class NativeCompilerCallableLocalTypePlansExampleTest {
  @Test
  void composesSignatureDirectAndLoopLocalTypes() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false));

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("valid"));
    assertEquals(8, machine.global("typeCount"));
    assertEquals(5, machine.global("maxLocalCount"));
    assertEquals(0, machine.global("firstType"));
    assertEquals(5, machine.global("secondType"));
    assertEquals(5, machine.global("firstCount"));
    assertEquals(3, machine.global("secondCount"));
    assertEquals(1, machine.global("directKind"));
    assertEquals(2, machine.global("loopKind"));
    assertEquals(536870912, machine.global("nominalType"));
  }

  @Test
  void rejectsLocalGapsWithoutChangingCallerRows() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true));

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("valid"));
    assertEquals(91, machine.global("firstOwner"));
    assertEquals(92, machine.global("firstLocal"));
  }

  private static Program program(boolean gap) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_local_type_plans"));
    sources.put("CallableLocalTypePlansExample.w", """
        module example.callable_local_type_plans;

        import wheeler.compiler.closure.callable_local_type_plans;

        classical class CallableLocalTypePlansExample {
          state long valid = 0;
          state long typeCount = 0;
          state long maxLocalCount = 0;
          state long firstType = 0;
          state long secondType = 0;
          state long firstCount = 0;
          state long secondCount = 0;
          state long directKind = 0;
          state long loopKind = 0;
          state long nominalType = 0;
          state long firstOwner = 0;
          state long firstLocal = 0;

          entry void main() {
            region products = new region(/* bytes= */ 5245000, /* allocations= */ 3);
            words localCounts = allocate(products, /* length= */ 64);
            words types = allocate(products, /* length= */ 327680);
            words output = allocate(products, /* length= */ 327808);
            set(localCounts, 0, 5);
            set(localCounts, 1, 3);
            long type = 0;
            while (type < 8) limit 8 {
              long owner = 0;
              long local = type;
              if (4 < type) {
                owner = 1;
                local = type - 5;
              }
              set(types, type, owner);
              set(types, 65536 + type, local);
              set(types, 131072 + type, 2);
              set(types, 196608 + type, 0);
              set(types, 262144 + type, type);
              type += 1;
            }
            set(types, 65539, %d);
            set(types, 131079, 536870912);
            set(types, 196610, 1);
            set(types, 196611, 2);
            set(output, 0, 91);
            set(output, 65536, 92);
            CallableLocalTypePlan plan = materializeCallableLocalTypePlans(
              /* callableCount= */ 2,
              localCounts,
              /* typeCount= */ 8,
              types,
              output
            );
            if (plan.valid) {
              valid = 1;
            }
            typeCount = plan.typeCount;
            maxLocalCount = plan.maxLocalCount;
            firstType = output[327680];
            secondType = output[327681];
            firstCount = output[327744];
            secondCount = output[327745];
            directKind = output[196610];
            loopKind = output[196611];
            nominalType = output[131079];
            firstOwner = output[0];
            firstLocal = output[65536];
            drop(output);
            drop(types);
            drop(localCounts);
            drop(products);
          }
        }
        """.formatted(gap ? 4 : 3));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.callable_local_type_plans");
  }
}
