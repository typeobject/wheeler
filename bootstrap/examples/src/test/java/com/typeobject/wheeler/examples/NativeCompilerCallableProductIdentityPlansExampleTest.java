package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for stable identity carriage through callable composition. */
final class NativeCompilerCallableProductIdentityPlansExampleTest {
  @Test
  void rebasesInstructionIdentitiesWithoutChangingTheirBytes() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false));

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("valid"));
    assertEquals(5, machine.global("identityCount"));
    assertEquals(-1, machine.global("ownershipInstruction"));
    assertEquals(1, machine.global("callInstruction"));
    assertEquals(5, machine.global("aggregateInstruction"));
    assertEquals(0, machine.global("secondCallableInstruction"));
    assertEquals(31, machine.global("proofIdentityByte"));
    assertEquals(62, machine.global("callIdentityByte"));
  }

  @Test
  void rejectsOwnerForgeryWithoutChangingCallerRows() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true));

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("valid"));
    assertEquals(91, machine.global("firstOwner"));
    assertEquals(92, machine.global("firstInstruction"));
    assertEquals(93, machine.global("firstIdentityByte"));
  }

  private static Program program(boolean forgedOwner) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_product_identity_plans"));
    sources.put("CallableProductIdentityPlansExample.w", """
        module example.callable_product_identity_plans;

        import wheeler.compiler.closure.callable_product_identity_plans;

        classical class CallableProductIdentityPlansExample {
          state long valid = 0;
          state long identityCount = 0;
          state long ownershipInstruction = 0;
          state long callInstruction = 0;
          state long aggregateInstruction = 0;
          state long secondCallableInstruction = 0;
          state long proofIdentityByte = 0;
          state long callIdentityByte = 0;
          state long firstOwner = 0;
          state long firstInstruction = 0;
          state long firstIdentityByte = 0;

          entry void main() {
            region products = new region(/* bytes= */ 855000, /* allocations= */ 5);
            words compositions = allocate(products, /* length= */ 33024);
            words identityRows = allocate(products, /* length= */ 20480);
            bytes identities = allocateBytes(products, /* length= */ 131072);
            words outputRows = allocate(products, /* length= */ 20480);
            bytes outputIdentities = allocateBytes(products, /* length= */ 131072);
            set(compositions, 0, 0);
            set(compositions, 1, 0);
            set(compositions, 2, 1);
            set(compositions, 16384, 0);
            set(compositions, 16385, 3);
            set(compositions, 16386, 0);
            set(compositions, 20480, 3);
            set(compositions, 20481, 5);
            set(compositions, 20482, 2);
            set(identityRows, 0, 0);
            set(identityRows, 1, 0);
            set(identityRows, 2, %d);
            set(identityRows, 3, 0);
            set(identityRows, 4, 1);
            set(identityRows, 4096, -1);
            set(identityRows, 4097, -1);
            set(identityRows, 4098, 0);
            set(identityRows, 4099, 1);
            set(identityRows, 4100, 2);
            set(identityRows, 8192, -1);
            set(identityRows, 8193, -1);
            set(identityRows, 8194, 1);
            set(identityRows, 8195, 2);
            set(identityRows, 8196, 0);
            set(identityRows, 12288, 2);
            set(identityRows, 12289, 3);
            set(identityRows, 12290, 0);
            set(identityRows, 12291, 1);
            set(identityRows, 12292, 0);
            set(identityRows, 16384, 7);
            set(identityRows, 16385, 8);
            set(identityRows, 16386, 10);
            set(identityRows, 16387, 11);
            set(identityRows, 16388, 12);
            long identity = 0;
            while (identity < 5) limit 5 {
              long identityByte = 0;
              while (identityByte < 32) limit 32 {
                setByte(
                  identities,
                  identity * 32 + identityByte,
                  (identity * 31 + identityByte) %% 256
                );
                identityByte += 1;
              }
              identity += 1;
            }
            set(outputRows, 0, 91);
            set(outputRows, 4096, 92);
            setByte(outputIdentities, 0, 93);
            CallableProductIdentityPlan plan = materializeCallableProductIdentityPlans(
              /* compositionCount= */ 3,
              compositions,
              /* identityCount= */ 5,
              identityRows,
              identities,
              outputRows,
              outputIdentities
            );
            if (plan.valid) {
              valid = 1;
            }
            identityCount = plan.identityCount;
            ownershipInstruction = outputRows[4096];
            callInstruction = outputRows[4098];
            aggregateInstruction = outputRows[4099];
            secondCallableInstruction = outputRows[4100];
            proofIdentityByte = outputIdentities[32];
            callIdentityByte = outputIdentities[64];
            firstOwner = outputRows[0];
            firstInstruction = outputRows[4096];
            firstIdentityByte = outputIdentities[0];
            drop(outputIdentities);
            drop(outputRows);
            drop(identities);
            drop(identityRows);
            drop(compositions);
            drop(products);
          }
        }
        """.formatted(forgedOwner ? 1 : 0));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.callable_product_identity_plans");
  }
}
