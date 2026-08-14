package com.typeobject.wheeler.core.quantum;

import com.typeobject.wheeler.core.bytecode.VariantType;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/** Checked classical and coherent permutation over one payload-free variant authority. */
public final class FiniteEnumPermutation {
  /** Immutable exact amplitude vector in canonical enum-case basis order. */
  public static final class CoherentState {
    private final double[] real;
    private final double[] imaginary;

    /** Creates one finite canonical amplitude vector. */
    public CoherentState(double[] real, double[] imaginary) {
      Objects.requireNonNull(real, "real");
      Objects.requireNonNull(imaginary, "imaginary");
      if (real.length == 0 || real.length != imaginary.length) {
        throw new IllegalArgumentException("coherent enum amplitudes have inconsistent extents");
      }
      this.real = real.clone();
      this.imaginary = imaginary.clone();
      double norm = 0.0;
      for (int index = 0; index < real.length; index++) {
        if (!Double.isFinite(real[index]) || !Double.isFinite(imaginary[index])) {
          throw new IllegalArgumentException("coherent enum amplitudes must be finite");
        }
        norm += real[index] * real[index] + imaginary[index] * imaginary[index];
      }
      if (!Double.isFinite(norm) || Math.abs(norm - 1.0) > 1.0e-12) {
        throw new IllegalArgumentException("coherent enum amplitudes are not normalized");
      }
    }

    /** Returns an independent real-amplitude vector. */
    public double[] real() {
      return real.clone();
    }

    /** Returns an independent imaginary-amplitude vector. */
    public double[] imaginary() {
      return imaginary.clone();
    }

    private int size() {
      return real.length;
    }
  }

  /** Classical result created only by explicit coherent observation. */
  public static final class MeasuredCase {
    private final String typeIdentity;
    private final String caseName;

    private MeasuredCase(String typeIdentity, String caseName) {
      this.typeIdentity = typeIdentity;
      this.caseName = caseName;
    }

    public String typeIdentity() {
      return typeIdentity;
    }

    public String caseName() {
      return caseName;
    }
  }

  private final VariantType type;
  private final List<String> cases;
  private final Map<String, Integer> indices;
  private final int[] forward;
  private final int[] inverse;
  private final String typeIdentity;
  private final String identity;

  /** Validates one complete semantic case-name permutation and derives its inverse. */
  public FiniteEnumPermutation(VariantType type, Map<String, String> mapping) {
    this.type = Objects.requireNonNull(type, "type");
    Objects.requireNonNull(mapping, "mapping");
    List<String> ordered = new ArrayList<>(type.cases().size());
    for (VariantType.Case variantCase : type.cases()) {
      if (!variantCase.fields().isEmpty()) {
        throw new IllegalArgumentException("finite enum permutation requires payload-free cases");
      }
      ordered.add(variantCase.name());
    }
    ordered.sort(String::compareTo);
    if (!ordered.equals(type.cases().stream().map(VariantType.Case::name).toList())) {
      throw new IllegalArgumentException("finite enum cases are not in canonical name order");
    }
    cases = List.copyOf(ordered);
    indices = new HashMap<>();
    for (int index = 0; index < cases.size(); index++) {
      indices.put(cases.get(index), index);
    }
    if (!mapping.keySet().equals(indices.keySet())) {
      throw new IllegalArgumentException("finite enum permutation does not cover every input");
    }
    forward = new int[cases.size()];
    inverse = new int[cases.size()];
    Set<String> outputs = new HashSet<>();
    for (int input = 0; input < cases.size(); input++) {
      String outputName = mapping.get(cases.get(input));
      Integer output = indices.get(outputName);
      if (output == null || !outputs.add(outputName)) {
        throw new IllegalArgumentException("finite enum mapping is not a permutation");
      }
      forward[input] = output;
      inverse[output] = input;
    }
    typeIdentity = digest("wheeler-finite-enum-type-1", typeCanonical());
    identity = digest("wheeler-finite-enum-permutation-1", permutationCanonical());
  }

  /** Applies the checked classical permutation by semantic case name. */
  public String apply(String inputCase) {
    return cases.get(forward[index(inputCase)]);
  }

  /** Applies the generated inverse by semantic case name. */
  public String applyInverse(String outputCase) {
    return cases.get(inverse[index(outputCase)]);
  }

  /** Returns the enum type identity independent of protocol integers. */
  public String typeIdentity() {
    return typeIdentity;
  }

  /** Returns the complete mapping identity. */
  public String identity() {
    return identity;
  }

  /** Returns the exact coherent qubit width or rejects a non-power-of-two cardinality. */
  public int coherentQubitCount() {
    requireCoherentCardinality();
    return Integer.numberOfTrailingZeros(cases.size());
  }

  /** Applies the unitary permutation matrix to canonical enum-basis amplitudes. */
  public CoherentState applyCoherent(CoherentState source) {
    return permute(source, forward);
  }

  /** Applies the generated adjoint permutation matrix. */
  public CoherentState applyAdjoint(CoherentState source) {
    return permute(source, inverse);
  }

  /** Observes one exact basis state and returns a distinct classical enum result. */
  public MeasuredCase measureExactBasis(CoherentState source) {
    requireState(source);
    int selected = -1;
    for (int index = 0; index < cases.size(); index++) {
      double real = source.real[index];
      double imaginary = source.imaginary[index];
      boolean one = real == 1.0 && imaginary == 0.0;
      boolean zero = real == 0.0 && imaginary == 0.0;
      if (one) {
        if (selected != -1) {
          throw new IllegalArgumentException("coherent enum state has several unit bases");
        }
        selected = index;
      } else if (!zero) {
        throw new IllegalArgumentException("exact enum measurement requires one basis state");
      }
    }
    if (selected == -1) {
      throw new IllegalArgumentException("coherent enum state has no unit basis");
    }
    return new MeasuredCase(typeIdentity, cases.get(selected));
  }

  private CoherentState permute(CoherentState source, int[] permutation) {
    requireState(source);
    double[] real = new double[cases.size()];
    double[] imaginary = new double[cases.size()];
    for (int input = 0; input < cases.size(); input++) {
      int output = permutation[input];
      real[output] = source.real[input];
      imaginary[output] = source.imaginary[input];
    }
    return new CoherentState(real, imaginary);
  }

  private void requireState(CoherentState source) {
    requireCoherentCardinality();
    Objects.requireNonNull(source, "source");
    if (source.size() != cases.size()) {
      throw new IllegalArgumentException("coherent enum state has the wrong cardinality");
    }
  }

  private void requireCoherentCardinality() {
    int cardinality = cases.size();
    if ((cardinality & (cardinality - 1)) != 0) {
      throw new IllegalStateException("coherent enum cardinality is not a power of two");
    }
  }

  private int index(String caseName) {
    Integer result = indices.get(Objects.requireNonNull(caseName, "caseName"));
    if (result == null) {
      throw new IllegalArgumentException("case does not belong to finite enum " + type.name());
    }
    return result;
  }

  private String typeCanonical() {
    StringBuilder canonical = new StringBuilder(type.id()).append('\0').append(type.name());
    for (String caseName : cases) {
      canonical.append('\0').append(caseName);
    }
    return canonical.toString();
  }

  private String permutationCanonical() {
    StringBuilder canonical = new StringBuilder(typeIdentity);
    for (int input = 0; input < cases.size(); input++) {
      canonical.append('\0').append(cases.get(input))
          .append('\0').append(cases.get(forward[input]));
    }
    return canonical.toString();
  }

  private static String digest(String domain, String canonical) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(
          (domain + '\0' + canonical).getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }
}
