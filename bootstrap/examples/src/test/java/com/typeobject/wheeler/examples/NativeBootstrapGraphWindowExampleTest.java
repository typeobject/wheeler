package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.NativeBootstrapGraphFixture.accepts;
import static com.typeobject.wheeler.examples.NativeBootstrapGraphFixture.rejectsGraph;
import static com.typeobject.wheeler.examples.NativeBootstrapGraphFixture.rejectsProfile;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest.Module;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Exercises counted owner windows through the canonical parser and identity publisher. */
final class NativeBootstrapGraphWindowExampleTest {
  private static final String IDENTITY = "ab".repeat(32);
  private static final long MAX_GRAPH_TRANSITIONS = 4_000_000;

  @Test
  void preservesDiamondReachabilityWithEveryRootPositionAndEmptyOwnerWindows() throws Exception {
    for (int shift = 0; shift < 4; shift++) {
      var modules = new ArrayList<Module>();
      modules.add(module(shift, List.of(name((shift + 1) % 4), name((shift + 2) % 4))));
      modules.add(module((shift + 1) % 4, List.of(name((shift + 3) % 4))));
      modules.add(module((shift + 2) % 4, List.of(name((shift + 3) % 4))));
      modules.add(module((shift + 3) % 4, List.of()));
      accepts(new BootstrapModuleManifest("bootstrap-1", name(shift), List.of(), modules), true);
    }
    accepts(new BootstrapModuleManifest("bootstrap-1", name(0), List.of(),
        List.of(module(0, List.of()))), true);
    accepts(new BootstrapModuleManifest("bootstrap-1", name(1), List.of(),
        List.of(module(0, List.of()), module(1, List.of(name(0))))), true);
  }

  @Test
  void keepsExternalEdgesOutsideLocalIndegreesAtTheLastOwnerBoundary() throws Exception {
    List<String> externals = externals();
    var imports = new ArrayList<>(externals.subList(0, 62));
    imports.add(externals.getLast());
    imports.add(name(0));
    accepts(new BootstrapModuleManifest("bootstrap-1", name(1), externals,
        List.of(module(0, List.of()), module(1, imports))), true);
    accepts(new BootstrapModuleManifest("bootstrap-1", name(0), externals,
        List.of(module(0, externals))), true);
  }

  @Test
  void rejectsCyclesAndDetachedComponentsBeforeIdentityPublicationAndRewinds() throws Exception {
    rejectsGraph(unchecked(1, List.of(module(0, List.of()), module(1, List.of()))));
    rejectsGraph(unchecked(0, List.of(module(0, List.of(name(1))),
        module(1, List.of(name(0))))));
    rejectsGraph(unchecked(2, List.of(module(0, List.of(name(1))),
        module(1, List.of(name(0))), module(2, List.of(name(0))))));
    rejectsGraph(unchecked(2, List.of(module(0, List.of(name(1))),
        module(1, List.of(name(0))), module(2, List.of()))));
    rejectsGraph(unchecked(0, List.of(module(0, List.of(name(1))),
        module(1, List.of(name(2))), module(2, List.of(name(1))))));
    rejectsGraph(unchecked(1, List.of(module(0, List.of(name(1))),
        module(1, List.of(name(2))), module(2, List.of()))));
  }

  @Test
  void processesTheLastModuleInBothDirectionsWithoutHistory() throws Exception {
    accepts(chain(512, 511), false);
    var ascending = new ArrayList<Module>();
    for (int owner = 0; owner < 512; owner++) {
      ascending.add(module(owner, owner == 511 ? List.of() : List.of(name(owner + 1))));
    }
    accepts(new BootstrapModuleManifest("bootstrap-1", name(0), List.of(), ascending), false);
  }

  @Test
  void boundsGraphWorkWith512ModulesAnd3072ImportsWithoutHistory() throws Exception {
    var run = accepts(chain(512, 3072), false);
    System.out.println("combined graph transitions=" + run.graphTransitions()
        + " total=" + run.transitions());
    assertTrue(run.graphTransitions() < MAX_GRAPH_TRANSITIONS,
        () -> "graph validation transitions: " + run.graphTransitions());
  }

  @Test
  void rejectsIndependentModuleAndImportExcessWithoutHistory() throws Exception {
    rejectsProfile(chain(513, 512));
    rejectsProfile(chain(512, 3073));
  }

  private static BootstrapModuleManifest chain(int count, int edges) {
    var modules = new ArrayList<Module>();
    List<String> externals = edges == count - 1 ? List.of() : externals();
    int remaining = edges - (count - 1);
    for (int owner = 0; owner < count; owner++) {
      var imports = new ArrayList<String>();
      if (0 < owner) { imports.add(name(owner - 1)); }
      for (int external = 0; external < externals.size() && 0 < remaining
          && imports.size() < 64; external++) {
        imports.add(externals.get(external));
        remaining--;
      }
      modules.add(module(owner, imports));
    }
    if (remaining != 0) { throw new AssertionError("unfilled edge fixture"); }
    return new BootstrapModuleManifest("bootstrap-1", name(count - 1), externals, modules);
  }

  private static List<String> externals() {
    return IntStream.range(0, 64).mapToObj(i -> "e.x%02d".formatted(i)).toList();
  }

  private static String name(int index) { return "m%03d".formatted(index); }

  private static Module module(int index, List<String> imports) {
    return new Module(name(index), "s/M%03d.w".formatted(index), IDENTITY, imports);
  }

  private static byte[] unchecked(int root, List<Module> modules) {
    StringBuilder text = new StringBuilder("""
        schema: 1
        profile: "bootstrap-1"
        root: "%s"
        externals: []
        modules:
        """.formatted(name(root)));
    for (Module module : modules.stream().sorted(Comparator.comparing(Module::name)).toList()) {
      text.append("  - name: \"").append(module.name()).append("\"\n")
          .append("    source: \"").append(module.source()).append("\"\n")
          .append("    identity: \"").append(module.identity()).append("\"\n");
      if (module.imports().isEmpty()) { text.append("    imports: []\n"); }
      else {
        text.append("    imports:\n");
        for (String imported : module.imports()) {
          text.append("      - \"").append(imported).append("\"\n");
        }
      }
    }
    return text.toString().getBytes(StandardCharsets.UTF_8);
  }
}
