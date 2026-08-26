package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** Proves one preselected shard of the Wheeler-owned compiler package suite. */
final class NativeCompilerPackageTest {
  private static final int SHARD_COUNT = 16;

  @Test
  void testsOnePhysicalCompilerShardNatively() throws Exception {
    int shard = Integer.getInteger("wheeler.nativeCompilerPackageShard", -1);
    int shardCount = Integer.getInteger("wheeler.nativeCompilerPackageShardCount", -1);
    assertTrue(0 <= shard && shard < shardCount);
    assertEquals(SHARD_COUNT, shardCount);

    Path compiler = Path.of("wheeler-compiler");
    PackageProject project = PackageProject.load(compiler);
    var result = NativePackageTestRunner.run(
        compiler, project.manifest(), shard, shardCount, Set.of()).orElseThrow();
    TestReport report = result.report();

    assertTrue(0 < result.selected());
    assertEquals(result.selected(), result.passed());
    assertEquals(0, result.failed());
    assertEquals(result.report().identity(), report.identity());
    assertEquals(
        TestReportRenderer.render(report, project.manifest().name(), TestReportRenderer.Format.JSON),
        new String(result.json(), StandardCharsets.UTF_8));
    assertEquals(
        TestReportRenderer.render(
            report, project.manifest().name(), TestReportRenderer.Format.TERMINAL),
        new String(result.terminal(), StandardCharsets.UTF_8));
    assertEquals(
        TestReportRenderer.render(
            report, project.manifest().name(), TestReportRenderer.Format.JUNIT_XML),
        new String(result.junit(), StandardCharsets.UTF_8));
  }
}
