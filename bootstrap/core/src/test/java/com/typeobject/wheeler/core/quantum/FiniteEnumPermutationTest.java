package com.typeobject.wheeler.core.quantum;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.RecordType;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.bytecode.VariantType;
import com.typeobject.wheeler.core.quantum.FiniteEnumPermutation.CoherentState;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Exercises exhaustive finite permutations and coherent enum basis semantics. */
final class FiniteEnumPermutationTest {
  @Test
  void everyFourCasePermutationDerivesItsExactInverse() {
    VariantType type = type("Call", "Halt", "Return", "Uncall");
    List<List<String>> outputs = permutations(type.cases().stream()
        .map(VariantType.Case::name).toList());
    assertEquals(24, outputs.size());
    for (List<String> output : outputs) {
      Map<String, String> mapping = mapping(type, output);
      FiniteEnumPermutation permutation = new FiniteEnumPermutation(type, mapping);
      for (String input : mapping.keySet()) {
        assertEquals(input, permutation.applyInverse(permutation.apply(input)));
      }
    }
  }

  @Test
  void duplicateMissingUnknownAndPayloadOutputsFailBeforeAuthorityExists() {
    VariantType type = type("Call", "Halt", "Return", "Uncall");
    Map<String, String> duplicate = mapping(
        type, List.of("Halt", "Halt", "Call", "Uncall"));
    assertThrows(
        IllegalArgumentException.class,
        () -> new FiniteEnumPermutation(type, duplicate));
    Map<String, String> missing = new LinkedHashMap<>(identityMapping(type));
    missing.remove("Call");
    assertThrows(
        IllegalArgumentException.class,
        () -> new FiniteEnumPermutation(type, missing));
    Map<String, String> unknown = new LinkedHashMap<>(identityMapping(type));
    unknown.put("Call", "Missing");
    assertThrows(
        IllegalArgumentException.class,
        () -> new FiniteEnumPermutation(type, unknown));

    VariantType payload = new VariantType(4, "Payload", List.of(
        new VariantType.Case("Value", List.of(new RecordType.Field("value", ValueType.SIGNED)))));
    assertThrows(
        IllegalArgumentException.class,
        () -> new FiniteEnumPermutation(payload, Map.of("Value", "Value")));
  }

  @Test
  void coherentPermutationMatchesAnIndependentAmplitudeOracleAndAdjoint() {
    VariantType type = type("Call", "Halt", "Return", "Uncall");
    FiniteEnumPermutation permutation = new FiniteEnumPermutation(type, Map.of(
        "Call", "Uncall",
        "Halt", "Halt",
        "Return", "Call",
        "Uncall", "Return"));
    CoherentState initial = new CoherentState(
        new double[] {0.5, 0.0, -0.5, 0.0},
        new double[] {0.0, 0.5, 0.0, -0.5});

    CoherentState transformed = permutation.applyCoherent(initial);
    double[] expectedReal = independentPermutation(
        initial.real(), new int[] {3, 1, 0, 2});
    double[] expectedImaginary = independentPermutation(
        initial.imaginary(), new int[] {3, 1, 0, 2});
    assertArrayEquals(expectedReal, transformed.real());
    assertArrayEquals(expectedImaginary, transformed.imaginary());
    CoherentState restored = permutation.applyAdjoint(transformed);
    assertArrayEquals(initial.real(), restored.real());
    assertArrayEquals(initial.imaginary(), restored.imaginary());
    assertEquals(2, permutation.coherentQubitCount());
    assertNotEquals(permutation.typeIdentity(), permutation.identity());
  }

  @Test
  void nonPowerOfTwoEnumRejectsCoherentUseBeforeChangingInput() {
    VariantType type = type("Blue", "Green", "Red");
    FiniteEnumPermutation permutation = new FiniteEnumPermutation(type, identityMapping(type));
    CoherentState state = new CoherentState(
        new double[] {1.0, 0.0, 0.0}, new double[] {0.0, 0.0, 0.0});
    double[] before = state.real();
    assertThrows(IllegalStateException.class, () -> permutation.applyCoherent(state));
    assertThrows(IllegalStateException.class, permutation::coherentQubitCount);
    assertArrayEquals(before, state.real());
  }

  @Test
  void measurementProducesANominalClassicalResultWithNoInverseOperation() {
    VariantType type = type("Off", "On");
    FiniteEnumPermutation permutation = new FiniteEnumPermutation(type, Map.of(
        "Off", "On", "On", "Off"));
    CoherentState basis = new CoherentState(
        new double[] {0.0, 1.0}, new double[] {0.0, 0.0});
    FiniteEnumPermutation.MeasuredCase measured = permutation.measureExactBasis(basis);
    assertEquals("On", measured.caseName());
    assertEquals(permutation.typeIdentity(), measured.typeIdentity());
    assertFalse(CoherentState.class.isInstance(measured));
    assertTrue(Modifier.isPrivate(
        FiniteEnumPermutation.MeasuredCase.class.getDeclaredConstructors()[0].getModifiers()));
    assertTrue(List.of(FiniteEnumPermutation.MeasuredCase.class.getDeclaredMethods()).stream()
        .noneMatch(method -> method.getName().contains("uncall")
            || method.getName().contains("inverse")));
  }

  @Test
  void coherentStatesRequireFiniteNormalizedAmplitudesAndExactExtents() {
    assertThrows(
        IllegalArgumentException.class,
        () -> new CoherentState(new double[] {1.0}, new double[] {0.0, 0.0}));
    assertThrows(
        IllegalArgumentException.class,
        () -> new CoherentState(new double[] {Double.NaN}, new double[] {0.0}));
    assertThrows(
        IllegalArgumentException.class,
        () -> new CoherentState(new double[] {0.5}, new double[] {0.0}));
  }

  private static VariantType type(String... names) {
    List<VariantType.Case> cases = new ArrayList<>();
    for (String name : names) {
      cases.add(new VariantType.Case(name, List.of()));
    }
    return new VariantType(3, "Example", cases);
  }

  private static Map<String, String> identityMapping(VariantType type) {
    return mapping(type, type.cases().stream().map(VariantType.Case::name).toList());
  }

  private static Map<String, String> mapping(VariantType type, List<String> outputs) {
    Map<String, String> mapping = new LinkedHashMap<>();
    for (int index = 0; index < outputs.size(); index++) {
      mapping.put(type.cases().get(index).name(), outputs.get(index));
    }
    return mapping;
  }

  private static List<List<String>> permutations(List<String> values) {
    List<List<String>> result = new ArrayList<>();
    permute(new ArrayList<>(values), 0, result);
    return result;
  }

  private static void permute(List<String> values, int start, List<List<String>> result) {
    if (start == values.size()) {
      result.add(List.copyOf(values));
      return;
    }
    for (int index = start; index < values.size(); index++) {
      String held = values.get(start);
      values.set(start, values.get(index));
      values.set(index, held);
      permute(values, start + 1, result);
      held = values.get(start);
      values.set(start, values.get(index));
      values.set(index, held);
    }
  }

  private static double[] independentPermutation(double[] input, int[] outputs) {
    double[] result = new double[input.length];
    for (int index = 0; index < input.length; index++) {
      result[outputs[index]] = input[index];
    }
    return result;
  }
}
