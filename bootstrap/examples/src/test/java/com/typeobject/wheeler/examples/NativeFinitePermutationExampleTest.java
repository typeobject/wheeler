package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.VariantType;
import com.typeobject.wheeler.core.quantum.FiniteEnumPermutation;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for Wheeler-native finite permutation and coherent basis products. */
final class NativeFinitePermutationExampleTest {
  @Test
  void checksInverseAmplitudeAdjointAndMeasurementProducts() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false));
    machine.run();

    FiniteEnumPermutation java = javaPermutation();
    assertEquals(1, machine.global("valid"));
    assertEquals(2, machine.global("qubitCount"));
    assertEquals(index(java.apply("Call")), machine.global("mapped"));
    assertEquals(index(java.applyInverse("Uncall")), machine.global("inverseMapped"));
    assertEquals(2, machine.global("inverseZero"));
    assertEquals(1, machine.global("inverseOne"));
    assertEquals(3, machine.global("inverseTwo"));
    assertEquals(0, machine.global("inverseThree"));
    assertEquals(30, machine.global("permutedZero"));
    assertEquals(10, machine.global("permutedThree"));
    assertEquals(10, machine.global("restoredZero"));
    assertEquals(40, machine.global("restoredThree"));
    assertEquals(1, machine.global("measured"));
  }

  @Test
  void malformedOrNonPowerProductsPublishNothing() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true));
    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(-1, machine.global("qubitCount"));
    assertEquals(-1, machine.global("mapped"));
    assertEquals(91, machine.global("inverseZero"));
    assertEquals(91, machine.global("permutedZero"));
    assertEquals(-1, machine.global("measured"));
  }

  private static com.typeobject.wheeler.core.bytecode.Program program(boolean invalid)
      throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put(
        "FinitePermutations.w",
        CoreSources.read("quantum/FinitePermutations.w"));
    sources.put("FinitePermutationExample.w", """
        module example.finite_permutation;

        import wheeler.core.finite_permutations;

        classical class FinitePermutationExample {
          state long valid = 0;
          state long qubitCount = 0;
          state long mapped = 0;
          state long inverseMapped = 0;
          state long inverseZero = 0;
          state long inverseOne = 0;
          state long inverseTwo = 0;
          state long inverseThree = 0;
          state long permutedZero = 0;
          state long permutedThree = 0;
          state long restoredZero = 0;
          state long restoredThree = 0;
          state long measured = 0;

          entry void main() {
            region arena = new region(/* bytes= */ 288, /* allocations= */ 9);
            words mapping = allocate(arena, 4);
            words inverse = allocate(arena, 4);
            words real = allocate(arena, 4);
            words imaginary = allocate(arena, 4);
            words outputReal = allocate(arena, 4);
            words outputImaginary = allocate(arena, 4);
            words restoredReal = allocate(arena, 4);
            words restoredImaginary = allocate(arena, 4);
            words malformedOutput = allocate(arena, 4);
            set(mapping, 0, FIRST_TARGET);
            set(mapping, 1, 1);
            set(mapping, 2, 0);
            set(mapping, 3, 2);
            set(inverse, 0, 91);
            set(inverse, 1, 91);
            set(inverse, 2, 91);
            set(inverse, 3, 91);
            set(malformedOutput, 0, 91);
            set(outputReal, 0, 91);
            set(real, 0, 10);
            set(real, 1, 20);
            set(real, 2, 30);
            set(real, 3, 40);
            set(imaginary, 0, 1);
            set(imaginary, 1, 2);
            set(imaginary, 2, 3);
            set(imaginary, 3, 4);
            if (writeInverseFinitePermutation(CARDINALITY, mapping, inverse)) {
              if (
                permuteFiniteAmplitudes(
                  CARDINALITY,
                  mapping,
                  real,
                  imaginary,
                  outputReal,
                  outputImaginary
                )
              ) {
                if (
                  permuteFiniteAmplitudes(
                    CARDINALITY,
                    inverse,
                    outputReal,
                    outputImaginary,
                    restoredReal,
                    restoredImaginary
                  )
                ) {
                  valid = 1;
                }
              }
            }
            qubitCount = coherentFiniteQubitCount(CARDINALITY);
            mapped = applyFinitePermutation(CARDINALITY, mapping, 0);
            inverseMapped = applyFinitePermutation(CARDINALITY, inverse, 3);
            inverseZero = inverse[0];
            inverseOne = inverse[1];
            inverseTwo = inverse[2];
            inverseThree = inverse[3];
            permutedZero = outputReal[0];
            permutedThree = outputReal[3];
            restoredZero = restoredReal[0];
            restoredThree = restoredReal[3];
            set(restoredReal, 0, 0);
            set(restoredReal, 1, 16);
            set(restoredReal, 2, 0);
            set(restoredReal, 3, 0);
            set(restoredImaginary, 0, 0);
            set(restoredImaginary, 1, 0);
            set(restoredImaginary, 2, 0);
            set(restoredImaginary, 3, 0);
            measured = measureExactFiniteBasis(
              CARDINALITY,
              /* scale= */ 16,
              restoredReal,
              restoredImaginary
            );
            drop(malformedOutput);
            drop(restoredImaginary);
            drop(restoredReal);
            drop(outputImaginary);
            drop(outputReal);
            drop(imaginary);
            drop(real);
            drop(inverse);
            drop(mapping);
            drop(arena);
          }
        }
        """
        .replace("FIRST_TARGET", invalid ? "1" : "3")
        .replace("CARDINALITY", invalid ? "3" : "4"));
    return new WheelerCompiler().compileModuleFiles(sources, "example.finite_permutation");
  }

  private static FiniteEnumPermutation javaPermutation() {
    VariantType type = new VariantType(3, "Example", List.of(
        new VariantType.Case("Call", List.of()),
        new VariantType.Case("Halt", List.of()),
        new VariantType.Case("Return", List.of()),
        new VariantType.Case("Uncall", List.of())));
    return new FiniteEnumPermutation(type, Map.of(
        "Call", "Uncall",
        "Halt", "Halt",
        "Return", "Call",
        "Uncall", "Return"));
  }

  private static int index(String name) {
    return List.of("Call", "Halt", "Return", "Uncall").indexOf(name);
  }
}
