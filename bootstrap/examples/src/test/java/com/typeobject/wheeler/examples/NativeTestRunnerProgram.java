package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;

/** Builds the native canonical test runner and its runtime/compiler closure. */
final class NativeTestRunnerProgram {
  private NativeTestRunnerProgram() {}

  static Program program() throws Exception {
    var modules = modules();
    modules.put(
        "NativeTestRunner.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/runners/NativeTestRunner.w")));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.testing.runners.native_test_runner");
  }

  static LinkedHashMap<String, String> modules() throws Exception {
    var modules = new LinkedHashMap<>(CompilerSources.compilerDriverModules());
    CoreSources.addBinaryClosure(modules);
    for (String source : List.of(
        "AggregateInterpreter", "ArtifactExecution", "ArtifactMetadata", "Interpreter", "MapInterpreter",
        "ResultSlots", "StorageInterpreter", "Utf8Interpreter")) {
      modules.put(source + ".w", RuntimeSources.read("runtime/" + source + ".w"));
    }
    modules.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    modules.put(
        "BootstrapCoverageFragments.w",
        RuntimeSources.read("runtime/BootstrapCoverageFragments.w"));
    modules.put("CoverageReducer.w", RuntimeSources.read("runtime/CoverageReducer.w"));
    for (String source : List.of(
        "TestExecutionIdentity", "TestArtifactExecutionIdentity",
        "TestCoverageIdentity", "TestIdentityText", "TestReportIdentity", "TestArtifactReport",
        "TestCaseIdentity", "TestShard", "TestSummary")) {
      modules.put(source + ".w", RuntimeSources.read("runtime/testing/" + source + ".w"));
    }
    for (String source : List.of(
        "TestDescriptors", "TestDiscoveredDescriptors", "TestSourceCompilation", "TestSourceLowering", "TestSourceModules", "TestSourcePlan", "TestSourceTests",
        "TestRunner")) {
      modules.put(
          source + ".w", RuntimeSources.read("runtime/testing/runners/" + source + ".w"));
    }
    for (String source : List.of(
        "TestManifest", "TestPackageDependencies", "TestPackageLock", "TestPackageVersions")) {
      modules.put(
          source + ".w",
          RuntimeSources.read("runtime/testing/runners/package/" + source + ".w"));
    }
    for (String source : List.of("TestSourceMetadata", "TestTagSelection")) {
      modules.put(
          source + ".w",
          RuntimeSources.read("runtime/testing/runners/metadata/" + source + ".w"));
    }
    return modules;
  }
}
