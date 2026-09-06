package com.typeobject.wheeler.examples;

/** Shared physical source inputs for native discovery and admission tests. */
final class NativeTestSourceFixtures {
  static final String MANIFEST = """
      schema: 1
      package:
        name: "pkg"
        version: "1.0.0"
        profile: "bootstrap-1"
      targets:
        - kind: "deployable"
          name: "test"
          root: "src/Test.w"
          module: "pkg.test"
          sources:
            - "src/Test.w"
          test: true
      dependencies: []
      capabilities: []
      """;

  static final String TAGGED_TESTS = """
      module pkg.test;
      classical class TaggedTests {
        test void alpha() tags(fast, unit.core) limits(steps = 512, history = 1) {
          assert(true);
        }
        test void beta() tags(slow) {
          assert(true);
        }
        entry void main() { assert(false); }
      }
      """;

  private NativeTestSourceFixtures() {}
}
