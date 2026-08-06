package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for bounded native imported scalar helpers. */
final class NativeCompilerImportedHelperExampleTest {
  @Test
  void resolvesScalarLocalCallFunctionsByteForByte() throws Exception {
    String dependency = """
        module example.local_values;
        classical class LocalValues {
          public boolean skipped(long value) {
            return false;
          }

          public long identity(long value) {
            return value;
          }

          public long answer() {
            return 42;
          }
        }
        """;
    String root = """
        module example.local_value_root;
        import example.local_values;
        classical class LocalValueRoot {
          public long copied(long value) {
            long result = identity(value);
            return result;
          }

          public long fixed() {
            long result = answer();
            return result;
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] actual = NativeModuleCompilerHarness.compile(compiler, List.of(dependency), root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("LocalValues.w", dependency, "LocalValueRoot.w", root),
        "example.local_value_root");
    assertArrayEquals(new BytecodeWriter().write(expected), actual);
    Program decoded = new BytecodeReader().read(actual);
    assertEquals(
        1,
        decoded.functions().get(3).forward().stream()
            .filter(instruction -> instruction.opcode() == Opcode.CALL_VALUE)
            .findFirst()
            .orElseThrow()
            .operands()
            .getFirst());
    assertEquals(
        2,
        decoded.functions().get(4).forward().stream()
            .filter(instruction -> instruction.opcode() == Opcode.CALL_VALUE)
            .findFirst()
            .orElseThrow()
            .operands()
            .getFirst());

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency),
        root.replace("identity(value)", "skipped(value)"));
  }

  @Test
  void compilesOneHelperBesideTwoConstantOwnersByteForByte() throws Exception {
    String firstConstants = """
        module example.constants_alpha;
        classical class ConstantsAlpha {
          public const long FIRST = 1;
        }
        """;
    String secondConstants = """
        module example.constants_beta;
        classical class ConstantsBeta {
          public const long SECOND = 2;
        }
        """;
    String predicate = """
        module example.predicate;
        classical class Predicate {
          public boolean selected(long value) {
            return value == 3;
          }
        }
        """;
    String root = """
        module example.mixed_root;
        import example.constants_alpha;
        import example.constants_beta;
        import example.predicate;
        classical class MixedRoot {
          public boolean accepted(long value) {
            if (selected(value)) {
              return true;
            }

            return value == FIRST;
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "ConstantsAlpha.w", firstConstants,
            "ConstantsBeta.w", secondConstants,
            "Predicate.w", predicate,
            "MixedRoot.w", root),
        "example.mixed_root");
    byte[] expectedBytes = new BytecodeWriter().write(expected);
    List<String> sources = List.of(firstConstants, secondConstants, predicate);
    for (int rotation = 0; rotation < sources.size(); rotation += 1) {
      List<String> arrival = List.of(
          sources.get(rotation),
          sources.get((rotation + 1) % sources.size()),
          sources.get((rotation + 2) % sources.size()));
      assertArrayEquals(
          expectedBytes,
          NativeModuleCompilerHarness.compile(compiler, arrival, root));
    }
  }

  @Test
  void compilesImportedPrimitiveLoanVoidCallsByteForByte() throws Exception {
    String dependency = """
        module example.sinks;
        classical class Sinks {
          public void accept(borrow mut bytes values) {}
          public void locate(borrow mut words values, long index) {}
          public void write(borrow mut bytes values, long index, long element) {}
        }
        """;
    String root = """
        module example.use_sinks;
        import example.sinks;
        classical class UseSinks {
          private void relay(borrow mut bytes output, borrow mut words values, long index) {
            accept(output);
            locate(values, index);
            write(output, index, index);
          }
          private long dummy() { return 0; }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] actual = NativeModuleCompilerHarness.compile(compiler, List.of(dependency), root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Sinks.w", dependency, "UseSinks.w", root), "example.use_sinks");
    assertArrayEquals(new BytecodeWriter().write(expected), actual);

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency.replace("public void accept", "private void accept")),
        root);
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency),
        root.replace("accept(output);", "accept(values);"));
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency),
        root.replace("write(output, index, index);", "write(output, index, output);"));
  }

  @Test
  void compilesImportedFixedArrayReadsByteForByte() throws Exception {
    String dependency = """
        module example.array_reader;
        classical class ArrayReader {
          public long lookup(long[4] values, long index) {
            return values[index];
          }
          public long choose(long[4] values, long index, long fallback) {
            return values[index];
          }
          public long chooseFour(long[4] values, long index, long fallback, long spare) {
            return values[index];
          }
        }
        """;
    String root = """
        module example.use_array_reader;
        import example.array_reader;
        classical class UseArrayReader {
          public long relay(long[4] values, long index) {
            return lookup(values, index);
          }
          public long relayThree(long[4] values, long index, long fallback) {
            return choose(values, index, fallback);
          }
          public long relayFour(long[4] values, long index, long fallback, long spare) {
            return chooseFour(values, index, fallback, spare);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] actual = NativeModuleCompilerHarness.compile(compiler, List.of(dependency), root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("ArrayReader.w", dependency, "UseArrayReader.w", root),
        "example.use_array_reader");
    assertArrayEquals(new BytecodeWriter().write(expected), actual);

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency.replace("public long lookup", "private long lookup")),
        root);
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency),
        root.replace("long[4] values", "long[3] values"));
  }

  @Test
  void compilesEveryTwentyThreeHelperOwnerSplitByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    for (int importedCount = 1; importedCount < 23; importedCount += 1) {
      String dependency = splitDependency(importedCount);
      String root = splitRoot(23 - importedCount);
      byte[] artifact = NativeModuleCompilerHarness.compile(
          compiler,
          List.of(dependency),
          root);
      Program expected = new WheelerCompiler().compileLibraryModuleFiles(
          Map.of("Dependency.w", dependency, "Root.w", root),
          "example.root");
      assertArrayEquals(
          new BytecodeWriter().write(expected),
          artifact,
          "owner split " + importedCount + "+" + (23 - importedCount));
      Program decoded = new BytecodeReader().read(artifact);
      assertEquals("example.split::dep0", decoded.functions().getFirst().name());
      assertEquals("example.root::root0", decoded.functions().get(importedCount).name());
      assertEquals("$library", decoded.functions().getLast().name());
    }

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(splitDependency(23)),
        splitRoot(1));
  }

  @Test
  void compilesDirectImportedVisibilityByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String dependency = sevenHelperDependency();
    String root = String.join("\n",
        "module example.use;",
        "import example.predicates;",
        "classical class Use {",
        "  public boolean accepted(long value) {",
        "    if (below(value)) {",
        "      return true;",
        "    }",
        "",
        "    return below(value);",
        "  }",
        "}",
        "");

    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, List.of(dependency), root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Predicates.w", dependency, "Use.w", root),
        "example.use");
    byte[] expectedArtifact = new BytecodeWriter().write(expected);
    assertArrayEquals(expectedArtifact, artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals("example.predicates::below", decoded.functions().getFirst().name());
    assertEquals("example.predicates::nonzero", decoded.functions().get(6).name());
    assertEquals("example.use::accepted", decoded.functions().get(7).name());
    assertEquals(8, decoded.functions().get(7).localCount());
    assertEquals(11, decoded.functions().get(7).forward().size());
    assertEquals("$library", decoded.functions().getLast().name());

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency.replace("public boolean below", "private boolean below")),
        root);
    String eightHelpers = dependency.replace(
        "  }\n}\n",
        "  }\n\n"
            + "  private boolean spare(long value) {\n"
            + "    return value == 8;\n"
            + "  }\n"
            + "}\n");
    byte[] eightArtifact = NativeModuleCompilerHarness.compile(
        compiler,
        List.of(eightHelpers),
        root);
    Program eightExpected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Predicates.w", eightHelpers, "Use.w", root),
        "example.use");
    assertArrayEquals(new BytecodeWriter().write(eightExpected), eightArtifact);

    String nineHelpers = eightHelpers.replace(
        "  }\n}\n",
        "  }\n\n"
            + "  private boolean overflow(long value) {\n"
            + "    return value == 9;\n"
            + "  }\n"
            + "}\n");
    byte[] nineArtifact = NativeModuleCompilerHarness.compile(
        compiler,
        List.of(nineHelpers),
        root);
    Program nineExpected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Predicates.w", nineHelpers, "Use.w", root),
        "example.use");
    assertArrayEquals(new BytecodeWriter().write(nineExpected), nineArtifact);

    String tenHelpers = nineHelpers.replace(
        "  }\n}\n",
        "  }\n\n"
            + "  private boolean capacity(long value) {\n"
            + "    return value == 10;\n"
            + "  }\n"
            + "}\n");
    byte[] tenArtifact = NativeModuleCompilerHarness.compile(
        compiler,
        List.of(tenHelpers),
        root);
    Program tenExpected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Predicates.w", tenHelpers, "Use.w", root),
        "example.use");
    assertArrayEquals(new BytecodeWriter().write(tenExpected), tenArtifact);

  }

  @Test
  void compilesTwoDirectHelperOwnersByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String alpha = helperOwner("example.alpha", "Alpha", "alpha", 11);
    String beta = helperOwner("example.beta", "Beta", "beta", 11);
    String root = String.join("\n",
        "module example.use_both;",
        "import example.alpha;",
        "import example.beta;",
        "classical class UseBoth {",
        "  public boolean accepted(long value) {",
        "    if (alpha0(value)) {",
        "      return true;",
        "    }",
        "",
        "    return beta0(value);",
        "  }",
        "}",
        "");

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Alpha.w", alpha, "Beta.w", beta, "UseBoth.w", root),
        "example.use_both");
    byte[] expectedArtifact = new BytecodeWriter().write(expected);
    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler,
        List.of(alpha, beta),
        root);
    assertArrayEquals(expectedArtifact, artifact);
    assertArrayEquals(
        expectedArtifact,
        NativeModuleCompilerHarness.compile(compiler, List.of(beta, alpha), root));
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals("example.alpha::alpha0", decoded.functions().getFirst().name());
    assertEquals("example.alpha::alpha10", decoded.functions().get(10).name());
    assertEquals("example.beta::beta0", decoded.functions().get(11).name());
    assertEquals("example.beta::beta10", decoded.functions().get(21).name());
    assertEquals("example.use_both::accepted", decoded.functions().get(22).name());
    assertEquals("$library", decoded.functions().getLast().name());

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(alpha.replace("public boolean alpha0", "private boolean alpha0"), beta),
        root);
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(alpha, helperOwner("example.beta", "Beta", "beta", 12)),
        root);
    String threeOwnerRoot = root.replace(
        "import example.beta;",
        "import example.beta;\nimport example.gamma;");
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(
            alpha,
            beta,
            helperOwner("example.gamma", "Gamma", "gamma", 1)),
        threeOwnerRoot);
  }

  @Test
  void compilesThreeDirectHelperOwnersByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String alpha = helperOwner("example.alpha", "Alpha", "alpha", 8);
    String beta = helperOwner("example.beta", "Beta", "beta", 7);
    String gamma = helperOwner("example.gamma", "Gamma", "gamma", 7);
    String root = String.join("\n",
        "module example.use_three;",
        "import example.alpha;",
        "import example.beta;",
        "import example.gamma;",
        "classical class UseThree {",
        "  public boolean accepted(long value) {",
        "    if (alpha0(value)) { return true; }",
        "    if (beta0(value)) { return false; }",
        "    return gamma0(value);",
        "  }",
        "}",
        "");

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Alpha.w", alpha, "Beta.w", beta, "Gamma.w", gamma, "UseThree.w", root),
        "example.use_three");
    byte[] expectedArtifact = new BytecodeWriter().write(expected);
    List<List<String>> orders = List.of(
        List.of(alpha, beta, gamma),
        List.of(alpha, gamma, beta),
        List.of(beta, alpha, gamma),
        List.of(beta, gamma, alpha),
        List.of(gamma, alpha, beta),
        List.of(gamma, beta, alpha));
    for (List<String> order : orders) {
      assertArrayEquals(expectedArtifact, NativeModuleCompilerHarness.compile(compiler, order, root));
    }

    Program decoded = new BytecodeReader().read(expectedArtifact);
    assertEquals("example.alpha::alpha0", decoded.functions().getFirst().name());
    assertEquals("example.alpha::alpha7", decoded.functions().get(7).name());
    assertEquals("example.beta::beta0", decoded.functions().get(8).name());
    assertEquals("example.beta::beta6", decoded.functions().get(14).name());
    assertEquals("example.gamma::gamma0", decoded.functions().get(15).name());
    assertEquals("example.gamma::gamma6", decoded.functions().get(21).name());
    assertEquals("example.use_three::accepted", decoded.functions().get(22).name());
    assertEquals("$library", decoded.functions().getLast().name());

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(alpha, beta, gamma.replace("public boolean gamma0", "private boolean gamma0")),
        root);
  }

  @Test
  void compilesFourDirectHelperOwnersByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String alpha = helperOwner("example.alpha", "Alpha", "alpha", 6);
    String beta = helperOwner("example.beta", "Beta", "beta", 6);
    String delta = helperOwner("example.delta", "Delta", "delta", 5);
    String gamma = helperOwner("example.gamma", "Gamma", "gamma", 5);
    String root = String.join("\n",
        "module example.use_four;",
        "import example.alpha;",
        "import example.beta;",
        "import example.delta;",
        "import example.gamma;",
        "classical class UseFour {",
        "  public boolean accepted(long value) {",
        "    if (alpha0(value)) { return true; }",
        "    if (beta0(value)) { return false; }",
        "    if (delta0(value)) { return true; }",
        "    return gamma0(value);",
        "  }",
        "}",
        "");

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "Alpha.w", alpha,
            "Beta.w", beta,
            "Delta.w", delta,
            "Gamma.w", gamma,
            "UseFour.w", root),
        "example.use_four");
    byte[] expectedArtifact = new BytecodeWriter().write(expected);
    List<List<String>> orders = List.of(
        List.of(alpha, beta, delta, gamma),
        List.of(beta, delta, gamma, alpha),
        List.of(delta, gamma, alpha, beta),
        List.of(gamma, alpha, beta, delta),
        List.of(gamma, delta, beta, alpha),
        List.of(delta, beta, alpha, gamma),
        List.of(beta, alpha, gamma, delta),
        List.of(alpha, gamma, delta, beta));
    for (List<String> order : orders) {
      assertArrayEquals(expectedArtifact, NativeModuleCompilerHarness.compile(compiler, order, root));
    }

    Program decoded = new BytecodeReader().read(expectedArtifact);
    assertEquals("example.alpha::alpha0", decoded.functions().getFirst().name());
    assertEquals("example.alpha::alpha5", decoded.functions().get(5).name());
    assertEquals("example.beta::beta0", decoded.functions().get(6).name());
    assertEquals("example.beta::beta5", decoded.functions().get(11).name());
    assertEquals("example.delta::delta0", decoded.functions().get(12).name());
    assertEquals("example.delta::delta4", decoded.functions().get(16).name());
    assertEquals("example.gamma::gamma0", decoded.functions().get(17).name());
    assertEquals("example.gamma::gamma4", decoded.functions().get(21).name());
    assertEquals("example.use_four::accepted", decoded.functions().get(22).name());
    assertEquals("$library", decoded.functions().getLast().name());

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(
            alpha,
            beta,
            delta,
            gamma.replace("public boolean gamma0", "private boolean gamma0")),
        root);
  }

  @Test
  void compilesFiveDirectHelperOwnersByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String alpha = helperOwner("example.alpha", "Alpha", "alpha", 5);
    String beta = helperOwner("example.beta", "Beta", "beta", 5);
    String delta = helperOwner("example.delta", "Delta", "delta", 4);
    String epsilon = helperOwner("example.epsilon", "Epsilon", "epsilon", 4);
    String gamma = helperOwner("example.gamma", "Gamma", "gamma", 4);
    String root = String.join("\n",
        "module example.use_five;",
        "import example.alpha;",
        "import example.beta;",
        "import example.delta;",
        "import example.epsilon;",
        "import example.gamma;",
        "classical class UseFive {",
        "  public boolean accepted(long value) {",
        "    if (alpha0(value)) { return true; }",
        "    if (beta0(value)) { return false; }",
        "    if (delta0(value)) { return true; }",
        "    if (epsilon0(value)) { return false; }",
        "    return gamma0(value);",
        "  }",
        "}",
        "");

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "Alpha.w", alpha,
            "Beta.w", beta,
            "Delta.w", delta,
            "Epsilon.w", epsilon,
            "Gamma.w", gamma,
            "UseFive.w", root),
        "example.use_five");
    byte[] expectedArtifact = new BytecodeWriter().write(expected);
    List<List<String>> orders = List.of(
        List.of(alpha, beta, delta, epsilon, gamma),
        List.of(beta, delta, epsilon, gamma, alpha),
        List.of(delta, epsilon, gamma, alpha, beta),
        List.of(epsilon, gamma, alpha, beta, delta),
        List.of(gamma, alpha, beta, delta, epsilon),
        List.of(gamma, epsilon, delta, beta, alpha),
        List.of(epsilon, delta, beta, alpha, gamma),
        List.of(delta, beta, alpha, gamma, epsilon),
        List.of(beta, alpha, gamma, epsilon, delta),
        List.of(alpha, gamma, epsilon, delta, beta));
    for (List<String> order : orders) {
      assertArrayEquals(expectedArtifact, NativeModuleCompilerHarness.compile(compiler, order, root));
    }

    Program decoded = new BytecodeReader().read(expectedArtifact);
    assertEquals("example.alpha::alpha4", decoded.functions().get(4).name());
    assertEquals("example.beta::beta0", decoded.functions().get(5).name());
    assertEquals("example.delta::delta0", decoded.functions().get(10).name());
    assertEquals("example.epsilon::epsilon0", decoded.functions().get(14).name());
    assertEquals("example.gamma::gamma0", decoded.functions().get(18).name());
    assertEquals("example.gamma::gamma3", decoded.functions().get(21).name());
    assertEquals("example.use_five::accepted", decoded.functions().get(22).name());
    assertEquals("$library", decoded.functions().getLast().name());

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(
            alpha,
            beta,
            delta,
            epsilon,
            gamma.replace("public boolean gamma0", "private boolean gamma0")),
        root);
  }

  @Test
  void compilesSixDirectHelperOwnersByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String alpha = helperOwner("example.alpha", "Alpha", "alpha", 4);
    String beta = helperOwner("example.beta", "Beta", "beta", 4);
    String delta = helperOwner("example.delta", "Delta", "delta", 4);
    String epsilon = helperOwner("example.epsilon", "Epsilon", "epsilon", 4);
    String gamma = helperOwner("example.gamma", "Gamma", "gamma", 3);
    String zeta = helperOwner("example.zeta", "Zeta", "zeta", 3);
    String root = String.join("\n",
        "module example.use_six;",
        "import example.alpha;",
        "import example.beta;",
        "import example.delta;",
        "import example.epsilon;",
        "import example.gamma;",
        "import example.zeta;",
        "classical class UseSix {",
        "  public boolean accepted(long value) {",
        "    if (alpha0(value)) { return true; }",
        "    if (beta0(value)) { return false; }",
        "    if (delta0(value)) { return true; }",
        "    if (epsilon0(value)) { return false; }",
        "    if (gamma0(value)) { return true; }",
        "    return zeta0(value);",
        "  }",
        "}",
        "");

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "Alpha.w", alpha,
            "Beta.w", beta,
            "Delta.w", delta,
            "Epsilon.w", epsilon,
            "Gamma.w", gamma,
            "Zeta.w", zeta,
            "UseSix.w", root),
        "example.use_six");
    byte[] expectedArtifact = new BytecodeWriter().write(expected);
    for (List<String> order : cyclicOrders(List.of(alpha, beta, delta, epsilon, gamma, zeta))) {
      assertArrayEquals(expectedArtifact, NativeModuleCompilerHarness.compile(compiler, order, root));
    }

    Program decoded = new BytecodeReader().read(expectedArtifact);
    assertEquals("example.alpha::alpha3", decoded.functions().get(3).name());
    assertEquals("example.beta::beta0", decoded.functions().get(4).name());
    assertEquals("example.delta::delta0", decoded.functions().get(8).name());
    assertEquals("example.epsilon::epsilon0", decoded.functions().get(12).name());
    assertEquals("example.gamma::gamma0", decoded.functions().get(16).name());
    assertEquals("example.zeta::zeta0", decoded.functions().get(19).name());
    assertEquals("example.zeta::zeta2", decoded.functions().get(21).name());
    assertEquals("example.use_six::accepted", decoded.functions().get(22).name());
    assertEquals("$library", decoded.functions().getLast().name());

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(
            alpha,
            beta,
            delta,
            epsilon,
            gamma,
            zeta.replace("public boolean zeta0", "private boolean zeta0")),
        root);
  }

  @Test
  void compilesSevenDirectHelperOwnersByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String alpha = helperOwner("example.alpha", "Alpha", "alpha", 4);
    String beta = helperOwner("example.beta", "Beta", "beta", 3);
    String delta = helperOwner("example.delta", "Delta", "delta", 3);
    String epsilon = helperOwner("example.epsilon", "Epsilon", "epsilon", 3);
    String eta = helperOwner("example.eta", "Eta", "eta", 3);
    String gamma = helperOwner("example.gamma", "Gamma", "gamma", 3);
    String zeta = helperOwner("example.zeta", "Zeta", "zeta", 3);
    String root = String.join("\n",
        "module example.use_seven;",
        "import example.alpha;",
        "import example.beta;",
        "import example.delta;",
        "import example.epsilon;",
        "import example.eta;",
        "import example.gamma;",
        "import example.zeta;",
        "classical class UseSeven {",
        "  public boolean accepted(long value) {",
        "    if (alpha0(value)) { return true; }",
        "    if (beta0(value)) { return false; }",
        "    if (delta0(value)) { return true; }",
        "    if (epsilon0(value)) { return false; }",
        "    if (eta0(value)) { return true; }",
        "    if (gamma0(value)) { return false; }",
        "    return zeta0(value);",
        "  }",
        "}",
        "");

    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "Alpha.w", alpha,
            "Beta.w", beta,
            "Delta.w", delta,
            "Epsilon.w", epsilon,
            "Eta.w", eta,
            "Gamma.w", gamma,
            "Zeta.w", zeta,
            "UseSeven.w", root),
        "example.use_seven");
    byte[] expectedArtifact = new BytecodeWriter().write(expected);
    List<String> sources = List.of(alpha, beta, delta, epsilon, eta, gamma, zeta);
    for (List<String> order : cyclicOrders(sources)) {
      assertArrayEquals(expectedArtifact, NativeModuleCompilerHarness.compile(compiler, order, root));
    }

    Program decoded = new BytecodeReader().read(expectedArtifact);
    assertEquals("example.alpha::alpha3", decoded.functions().get(3).name());
    assertEquals("example.beta::beta0", decoded.functions().get(4).name());
    assertEquals("example.delta::delta0", decoded.functions().get(7).name());
    assertEquals("example.epsilon::epsilon0", decoded.functions().get(10).name());
    assertEquals("example.eta::eta0", decoded.functions().get(13).name());
    assertEquals("example.gamma::gamma0", decoded.functions().get(16).name());
    assertEquals("example.zeta::zeta0", decoded.functions().get(19).name());
    assertEquals("example.zeta::zeta2", decoded.functions().get(21).name());
    assertEquals("example.use_seven::accepted", decoded.functions().get(22).name());
    assertEquals("$library", decoded.functions().getLast().name());

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(
            alpha,
            beta,
            delta,
            epsilon,
            eta,
            gamma,
            zeta.replace("public boolean zeta0", "private boolean zeta0")),
        root);

    String theta = helperOwner("example.theta", "Theta", "theta", 1);
    String eightOwnerRoot = root
        .replace("module example.use_seven;", "module example.use_eight;")
        .replace("import example.gamma;", "import example.gamma;\nimport example.theta;");
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(
            helperOwner("example.alpha", "Alpha", "alpha", 1),
            helperOwner("example.beta", "Beta", "beta", 1),
            helperOwner("example.delta", "Delta", "delta", 1),
            helperOwner("example.epsilon", "Epsilon", "epsilon", 1),
            helperOwner("example.eta", "Eta", "eta", 1),
            helperOwner("example.gamma", "Gamma", "gamma", 1),
            theta,
            helperOwner("example.zeta", "Zeta", "zeta", 1)),
        eightOwnerRoot);
  }

  @Test
  void compilesHelperChainBesideDirectConstantsByteForByte() throws Exception {
    String leaf = """
        module example.a_limits;
        classical class Limits { public const long LIMIT = 4; }
        """;
    String dependency = """
        module example.b_predicate;
        import example.a_limits;
        classical class Predicate {
          public boolean below(long value) { return value < LIMIT; }
        }
        """;
    String first = """
        module example.c_first;
        classical class First { public const long FIRST = 1; }
        """;
    String second = """
        module example.d_second;
        classical class Second { public const long SECOND = 2; }
        """;
    String third = """
        module example.e_third;
        classical class Third { public const long THIRD = 3; }
        """;
    String root = """
        module example.f_use;
        import example.b_predicate;
        import example.c_first;
        import example.d_second;
        import example.e_third;
        classical class Use {
          public boolean accepted(long value) {
            long first = FIRST;
            long second = SECOND;
            long third = THIRD;
            return below(third);
          }
        }
        """;
    Program compiler = NativeModuleCompilerHarness.program();
    List<String> sources = List.of(leaf, dependency, first, second, third);
    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, sources, root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "Limits.w", leaf,
            "Predicate.w", dependency,
            "First.w", first,
            "Second.w", second,
            "Third.w", third,
            "Use.w", root),
        "example.f_use");
    byte[] expectedArtifact = new BytecodeWriter().write(expected);
    assertArrayEquals(expectedArtifact, artifact);
    assertArrayEquals(
        expectedArtifact,
        NativeModuleCompilerHarness.compile(compiler, sources.reversed(), root));

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(leaf, dependency.replace("public boolean below", "private boolean below"),
            first, second, third),
        root);
  }

  @Test
  void compilesCanonicalImportedComparisonHelpersByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String constants = CompilerSources.read("compiler/ir/ResolvedStatements.w");
    String dependency = CompilerSources.read(
        "compiler/syntax/returns/ResolvedEarlyComparisonKinds.w");
    String root = CompilerSources.read("compiler/syntax/returns/EarlyComparisonForms.w");

    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler,
        List.of(constants, dependency),
        root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "compiler/ir/ResolvedStatements.w", constants,
            "compiler/syntax/returns/ResolvedEarlyComparisonKinds.w", dependency,
            "compiler/syntax/returns/EarlyComparisonForms.w", root),
        "wheeler.compiler.early_comparison_forms");
    byte[] expectedArtifact = new BytecodeWriter().write(expected);
    assertArrayEquals(expectedArtifact, artifact);
    assertArrayEquals(
        expectedArtifact,
        NativeModuleCompilerHarness.compile(compiler, List.of(dependency, constants), root));
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals(
        "wheeler.compiler.resolved_early_comparison_kinds::resolvedEarlyEqualityReturn",
        decoded.functions().getFirst().name());
    assertEquals(
        "wheeler.compiler.early_comparison_forms::resolvedEarlyComparisonReturn",
        decoded.functions().get(2).name());
    assertEquals(8, decoded.functions().get(2).localCount());
    assertEquals(11, decoded.functions().get(2).forward().size());
    assertEquals("$library", decoded.functions().getLast().name());

    String privateDependency = dependency.replace(
        "public boolean resolvedEarlyLessReturn",
        "private boolean resolvedEarlyLessReturn");
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(constants, privateDependency),
        root);
  }

  private static List<List<String>> cyclicOrders(List<String> sources) {
    List<List<String>> orders = new ArrayList<>();
    for (int shift = 0; shift < sources.size(); shift += 1) {
      List<String> forward = new ArrayList<>();
      List<String> reverse = new ArrayList<>();
      for (int offset = 0; offset < sources.size(); offset += 1) {
        forward.add(sources.get((shift + offset) % sources.size()));
        reverse.add(sources.get(
            (shift - offset + sources.size()) % sources.size()));
      }
      orders.add(List.copyOf(forward));
      orders.add(List.copyOf(reverse));
    }
    return List.copyOf(orders);
  }

  private static String helperOwner(
      String module,
      String className,
      String prefix,
      int count) {
    StringBuilder source = new StringBuilder("module ")
        .append(module)
        .append(";\nclassical class ")
        .append(className)
        .append(" {\n");
    for (int index = 0; index < count; index += 1) {
      source.append("  public boolean ")
          .append(prefix)
          .append(index)
          .append("(long value) {\n    return value == ")
          .append(index)
          .append(";\n  }\n\n");
    }
    return source.append("}\n").toString();
  }

  private static String splitDependency(int count) {
    StringBuilder source = new StringBuilder(
        "module example.split;\nclassical class Dependency {\n");
    for (int index = 0; index < count; index += 1) {
      source.append("  public boolean dep")
          .append(index)
          .append("(long value) {\n    return value == ")
          .append(index)
          .append(";\n  }\n\n");
    }
    return source.append("}\n").toString();
  }

  private static String splitRoot(int count) {
    StringBuilder source = new StringBuilder(
        "module example.root;\nimport example.split;\nclassical class Root {\n");
    for (int index = 0; index < count; index += 1) {
      source.append("  public boolean root")
          .append(index)
          .append("(long value) {\n    return ");
      if (index == 0) {
        source.append("dep0(value)");
      } else {
        source.append("value == ").append(index + 8);
      }
      source.append(";\n  }\n\n");
    }
    return source.append("}\n").toString();
  }

  private static String sevenHelperDependency() {
    return String.join("\n",
        "module example.predicates;",
        "classical class Predicates {",
        "  public boolean below(long value) {",
        "    return value < 4;",
        "  }",
        "",
        "  private boolean ready() {",
        "    return true;",
        "  }",
        "",
        "  private boolean ordered(long left, long right) {",
        "    return left < right;",
        "  }",
        "",
        "  private boolean same(long value) {",
        "    return value == 4;",
        "  }",
        "",
        "  private boolean different(long value) {",
        "    return value != 5;",
        "  }",
        "",
        "  private boolean negative(long value) {",
        "    return value < 0;",
        "  }",
        "",
        "  private boolean nonzero(long value) {",
        "    return value != 0;",
        "  }",
        "}",
        "");
  }
}
