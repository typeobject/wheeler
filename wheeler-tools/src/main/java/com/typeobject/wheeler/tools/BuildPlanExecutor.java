package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.packageformat.BuildPlan;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.io.IOException;
import java.nio.file.AtomicMoveNotSupportedException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Duration;
import java.time.Instant;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.stream.Stream;

/** Executes a source-bound workspace plan into a new, exact output tree. */
final class BuildPlanExecutor {
  private BuildPlanExecutor() {}

  static void execute(WorkspaceProject workspace, BuildPlan plan, Path requestedOutput)
      throws IOException {
    requireCompleteGrants(plan);
    BuildPlan expected = workspace.plan(plan.compilerIdentity(), true);
    if (!expected.equals(plan)) {
      throw new PackageFormatException(
          "Build plan does not match the current workspace inputs");
    }

    Path output = requestedOutput.toAbsolutePath().normalize();
    if (Files.exists(output, LinkOption.NOFOLLOW_LINKS)) {
      throw new IOException("Build-plan output already exists: " + output);
    }
    Path parent = output.getParent();
    if (parent == null) {
      throw new IOException("Build-plan output has no parent: " + output);
    }
    Files.createDirectories(parent);
    if (Files.isSymbolicLink(parent)) {
      throw new IOException("Build-plan output parent is a symbolic link: " + parent);
    }
    Path physicalParent = parent.toRealPath(LinkOption.NOFOLLOW_LINKS);
    if (!Files.isDirectory(physicalParent, LinkOption.NOFOLLOW_LINKS)) {
      throw new IOException("Build-plan output parent is not physical: " + parent);
    }
    Path staging = physicalParent.resolve("." + output.getFileName() + ".wheeler-staging");
    if (Files.exists(staging, LinkOption.NOFOLLOW_LINKS)) {
      throw new IOException("Build-plan staging path already exists: " + staging);
    }

    Instant started = Instant.now();
    try {
      workspace.build(staging);
      verifyOutputs(staging, plan, started);
      try {
        Files.move(staging, output, StandardCopyOption.ATOMIC_MOVE);
      } catch (AtomicMoveNotSupportedException exception) {
        throw new IOException("Build-plan output requires an atomic directory move", exception);
      }
    } finally {
      if (Files.exists(staging, LinkOption.NOFOLLOW_LINKS)) {
        PackageProject.cleanOutput(staging);
      }
    }
  }

  private static void requireCompleteGrants(BuildPlan plan) {
    for (BuildPlan.Node node : plan.nodes()) {
      if (!node.capabilityGrants().equals(node.capabilityRequests())) {
        throw new PackageFormatException(
            "Build plan lacks requested capability grants for "
                + node.packageName() + ":" + node.targetName());
      }
    }
  }

  private static void verifyOutputs(Path root, BuildPlan plan, Instant started)
      throws IOException {
    Map<String, BuildPlan.Node> expected = new HashMap<>();
    for (BuildPlan.Node node : plan.nodes()) {
      expected.put(node.outputPath(), node);
    }
    Set<String> actual = new HashSet<>();
    try (Stream<Path> paths = Files.walk(root)) {
      for (Path path : paths.toList()) {
        if (Files.isSymbolicLink(path)) {
          throw new IOException("Build output contains a symbolic link: " + path);
        }
        if (!Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS)) {
          continue;
        }
        String separator = path.getFileSystem().getSeparator();
        String relative = root.relativize(path).toString().replace(separator, "/");
        BuildPlan.Node node = expected.get(relative);
        if (node == null) {
          throw new IOException("Build produced undeclared output: " + relative);
        }
        if (Files.size(path) > node.executionLimits().maxOutputBytes()) {
          throw new IOException("Build output exceeds declared limit: " + relative);
        }
        if (Duration.between(started, Instant.now()).toMillis()
            > node.executionLimits().timeoutMillis()) {
          throw new IOException("Build exceeded declared timeout: " + relative);
        }
        new BytecodeReader().read(Files.readAllBytes(path));
        actual.add(relative);
      }
    }
    if (!actual.equals(expected.keySet())) {
      Set<String> missing = new HashSet<>(expected.keySet());
      missing.removeAll(actual);
      throw new IOException("Build omitted declared outputs: " + missing.stream().sorted().toList());
    }
  }
}
