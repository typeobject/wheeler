package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.packageformat.BootstrapCompilerLimits;
import com.typeobject.wheeler.packageformat.BootstrapCompilerLimitsParser;
import com.typeobject.wheeler.packageformat.BootstrapCompilerOptions;
import com.typeobject.wheeler.packageformat.BootstrapCompilerOptionsParser;
import com.typeobject.wheeler.packageformat.BootstrapFeatureManifest;
import com.typeobject.wheeler.packageformat.BootstrapFeatureManifestParser;
import com.typeobject.wheeler.packageformat.BootstrapManifest;
import com.typeobject.wheeler.packageformat.BootstrapManifest.DiverseDerivation;
import com.typeobject.wheeler.packageformat.BootstrapManifest.OrdinaryDerivation;
import com.typeobject.wheeler.packageformat.BootstrapManifest.Source;
import com.typeobject.wheeler.packageformat.BootstrapManifestParser;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifestParser;
import com.typeobject.wheeler.packageformat.BootstrapToolchain;
import com.typeobject.wheeler.packageformat.BootstrapToolchainParser;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageArchive.DecodedPackage;
import com.typeobject.wheeler.packageformat.PackageLock;
import com.typeobject.wheeler.packageformat.PackageLockParser;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Creates bootstrap evidence only after comparing all ordinary and diverse outputs. */
final class BootstrapManifestCommand {
  private static final long MAX_EVIDENCE_BYTES = 16L * 1024 * 1024;
  private static final List<String> FILE_OPTIONS = List.of(
      "--source-archive",
      "--source-lock",
      "--feature-manifest",
      "--module-manifest",
      "--options-manifest",
      "--limits-manifest",
      "--ordinary-toolchain",
      "--ordinary-compiler",
      "--ordinary-runtime",
      "--ordinary-verifier",
      "--stage-1",
      "--stage-2",
      "--ordinary-diagnostics",
      "--diverse-toolchain",
      "--diverse-compiler",
      "--diverse-runtime",
      "--diverse-verifier",
      "--diverse-output",
      "--diverse-diagnostics");
  private static final Set<String> DIRECTORY_OPTIONS = Set.of("--acceptance-artifacts");
  private static final Set<String> OUTPUT_OPTIONS = Set.of("--output");
  private static final Set<String> ALL_OPTIONS;

  static {
    java.util.HashSet<String> options = new java.util.HashSet<>(FILE_OPTIONS);
    options.addAll(DIRECTORY_OPTIONS);
    options.addAll(OUTPUT_OPTIONS);
    ALL_OPTIONS = Set.copyOf(options);
  }

  private BootstrapManifestCommand() {}

  static int execute(String[] args, PrintStream out, PrintStream error) throws IOException {
    Map<String, Path> paths = arguments(args, error);
    if (paths == null) {
      return 2;
    }

    rejectOutputCollision(paths);
    Map<String, PhysicalEvidenceFile> evidence = new HashMap<>();
    for (String option : FILE_OPTIONS) {
      boolean diagnostics = option.equals("--ordinary-diagnostics")
          || option.equals("--diverse-diagnostics");
      evidence.put(option, PhysicalEvidenceFile.read(
          paths.get(option), diagnostics, MAX_EVIDENCE_BYTES, "Bootstrap evidence"));
    }

    DecodedPackage sourcePackage = new PackageArchive().decode(
        evidence.get("--source-archive").bytes());
    if (!sourcePackage.manifest().name().equals("wheeler.compiler")) {
      throw new IOException("Bootstrap source archive is not wheeler.compiler");
    }
    PackageLock sourceLock = new PackageLockParser().parse(
        evidence.get("--source-lock").bytes());
    byte[] canonicalLock = sourceLock.canonicalText().getBytes(StandardCharsets.UTF_8);
    if (!Arrays.equals(evidence.get("--source-lock").bytes(), canonicalLock)) {
      throw new IOException("Bootstrap source lock is not canonical");
    }
    if (!sourceLock.rootManifestIdentity().equals(sourcePackage.manifest().identity())) {
      throw new IOException("Bootstrap source lock does not select the compiler manifest");
    }
    BootstrapFeatureManifest features = new BootstrapFeatureManifestParser().parse(
        evidence.get("--feature-manifest").bytes());
    requireCanonical(
        evidence.get("--feature-manifest"), features.canonicalBytes(), "bootstrap features");
    BootstrapModuleManifest modules = new BootstrapModuleManifestParser().parse(
        evidence.get("--module-manifest").bytes());
    requireCanonical(
        evidence.get("--module-manifest"), modules.canonicalBytes(), "bootstrap modules");
    verifyProfile(sourcePackage, features.profile(), "feature manifest");
    verifyProfile(sourcePackage, modules.profile(), "module manifest");
    BootstrapModuleSources.verify(sourcePackage, modules);
    BootstrapCompilerOptions options = new BootstrapCompilerOptionsParser().parse(
        evidence.get("--options-manifest").bytes());
    requireCanonical(
        evidence.get("--options-manifest"), options.canonicalBytes(), "compiler options");
    verifyProfile(sourcePackage, options.profile(), "compiler options");
    BootstrapCompilerLimits limits = new BootstrapCompilerLimitsParser().parse(
        evidence.get("--limits-manifest").bytes());
    requireCanonical(
        evidence.get("--limits-manifest"), limits.canonicalBytes(), "compiler limits");
    BootstrapToolchain ordinaryToolchain = toolchain(
        evidence.get("--ordinary-toolchain"), "ordinary toolchain");
    BootstrapToolchain diverseToolchain = toolchain(
        evidence.get("--diverse-toolchain"), "diverse toolchain");

    PhysicalEvidenceFile stage1 = evidence.get("--stage-1");
    PhysicalEvidenceFile stage2 = evidence.get("--stage-2");
    PhysicalEvidenceFile diverseOutput = evidence.get("--diverse-output");
    requireCanonicalArtifact(stage1);
    requireCanonicalArtifact(stage2);
    requireCanonicalArtifact(diverseOutput);
    requireEqual(stage1, stage2, "Stage 1 and stage 2 differ");
    requireEqual(stage1, diverseOutput, "Diverse output differs from stage 1");
    requireEqual(
        evidence.get("--ordinary-diagnostics"),
        evidence.get("--diverse-diagnostics"),
        "Ordinary and diverse diagnostics differ");

    ArtifactSetManifest.VerifiedSet acceptance = ArtifactSetManifest.verify(
        paths.get("--acceptance-artifacts"));
    if (!acceptance.artifactIdentities().contains(stage1.identity())) {
      throw new IOException("Acceptance artifact set does not contain the compiler fixed point");
    }
    BootstrapManifest manifest = new BootstrapManifest(
        new Source(
            sourcePackage.identity(),
            sourcePackage.manifest().identity(),
            sourceLock.identity(),
            sourcePackage.manifest().profile(),
            features.identity(),
            modules.identity(),
            options.identity(),
            limits.identity()),
        new OrdinaryDerivation(
            ordinaryToolchain.identity(),
            evidence.get("--ordinary-compiler").identity(),
            evidence.get("--ordinary-runtime").identity(),
            evidence.get("--ordinary-verifier").identity(),
            stage1.identity(),
            stage2.identity(),
            evidence.get("--ordinary-diagnostics").identity()),
        new DiverseDerivation(
            diverseToolchain.identity(),
            evidence.get("--diverse-compiler").identity(),
            evidence.get("--diverse-runtime").identity(),
            evidence.get("--diverse-verifier").identity(),
            diverseOutput.identity(),
            evidence.get("--diverse-diagnostics").identity()),
        acceptance.identity());
    byte[] canonical = manifest.canonicalBytes();
    BootstrapManifest decoded = new BootstrapManifestParser().parse(canonical);
    if (!decoded.equals(manifest)) {
      throw new IOException("Bootstrap manifest failed its canonical self-check");
    }
    PackageProject.writeAtomically(paths.get("--output"), canonical);
    out.println("recorded bootstrap evidence " + manifest.identity()
        + " in " + paths.get("--output"));
    return 0;
  }

  private static void rejectOutputCollision(Map<String, Path> paths) throws IOException {
    Path output = paths.get("--output").toAbsolutePath().normalize();
    Path acceptance = paths.get("--acceptance-artifacts").toRealPath(LinkOption.NOFOLLOW_LINKS);
    if (output.startsWith(acceptance)) {
      throw new IOException("Bootstrap manifest output cannot enter the acceptance artifact set");
    }
    if (Files.exists(output, LinkOption.NOFOLLOW_LINKS)) {
      for (String option : FILE_OPTIONS) {
        if (Files.isSameFile(output, paths.get(option))) {
          throw new IOException("Bootstrap manifest output aliases evidence " + option);
        }
      }
    }
  }

  private static Map<String, Path> arguments(String[] args, PrintStream error) {
    if (args.length != 1 + ALL_OPTIONS.size() * 2) {
      usage(error);
      return null;
    }
    Map<String, Path> paths = new HashMap<>();
    for (int index = 1; index < args.length; index += 2) {
      String option = args[index];
      if (!ALL_OPTIONS.contains(option) || paths.put(option, Path.of(args[index + 1])) != null) {
        usage(error);
        return null;
      }
    }
    if (!paths.keySet().equals(ALL_OPTIONS)) {
      usage(error);
      return null;
    }
    return Map.copyOf(paths);
  }

  private static void verifyProfile(
      DecodedPackage sourcePackage, String profile, String description) throws IOException {
    if (!profile.equals(sourcePackage.manifest().profile())) {
      throw new IOException("Bootstrap " + description + " uses a different source profile");
    }
  }

  private static BootstrapToolchain toolchain(
      PhysicalEvidenceFile evidence, String description) throws IOException {
    BootstrapToolchain toolchain = new BootstrapToolchainParser().parse(evidence.bytes());
    requireCanonical(evidence, toolchain.canonicalBytes(), description);
    return toolchain;
  }

  private static void requireCanonicalArtifact(PhysicalEvidenceFile artifact) throws IOException {
    byte[] canonical = new BytecodeWriter().write(new BytecodeReader().read(artifact.bytes()));
    requireCanonical(artifact, canonical, "bootstrap artifact");
  }

  private static void requireCanonical(
      PhysicalEvidenceFile evidence, byte[] canonical, String description) throws IOException {
    if (!Arrays.equals(evidence.bytes(), canonical)) {
      throw new IOException(description + " is not canonical: " + evidence.path());
    }
  }

  private static void requireEqual(PhysicalEvidenceFile left, PhysicalEvidenceFile right, String message)
      throws IOException {
    if (!MessageDigest.isEqual(left.bytes(), right.bytes())) {
      throw new IOException(message + ": " + left.path() + " != " + right.path());
    }
  }

  private static void usage(PrintStream error) {
    error.println("Usage: wheeler bootstrap-manifest"
        + " --source-archive <wheeler.compiler.wpk> --source-lock <lock>"
        + " --feature-manifest <file> --module-manifest <file>"
        + " --options-manifest <file> --limits-manifest <file>"
        + " --ordinary-toolchain <file> --ordinary-compiler <file>"
        + " --ordinary-runtime <file> --ordinary-verifier <file>"
        + " --stage-1 <wbc> --stage-2 <wbc> --ordinary-diagnostics <file>"
        + " --diverse-toolchain <file> --diverse-compiler <file>"
        + " --diverse-runtime <file> --diverse-verifier <file>"
        + " --diverse-output <wbc> --diverse-diagnostics <file>"
        + " --acceptance-artifacts <directory> --output <wheeler.bootstrap.yaml>");
  }

}
