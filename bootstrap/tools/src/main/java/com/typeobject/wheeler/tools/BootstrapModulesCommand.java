package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifestParser;
import com.typeobject.wheeler.packageformat.PackageArchive;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.file.Path;

/** Derives the exact canonical module closure of the compiler tool target. */
final class BootstrapModulesCommand {
  private static final long MAX_ARCHIVE_BYTES = 16L * 1024 * 1024;

  private BootstrapModulesCommand() {}

  static int execute(String[] args, PrintStream out, PrintStream error) throws IOException {
    if (args.length != 5 || !args[1].equals("--source-archive")
        || !args[3].equals("--output")) {
      usage(error);
      return 2;
    }
    Path sourcePath = Path.of(args[2]);
    Path output = Path.of(args[4]);
    if (sourcePath.toAbsolutePath().normalize().equals(output.toAbsolutePath().normalize())) {
      throw new IOException("Bootstrap module output aliases its source archive");
    }
    PhysicalEvidenceFile source = PhysicalEvidenceFile.read(
        sourcePath, false, MAX_ARCHIVE_BYTES, "Compiler source archive");
    PackageArchive.DecodedPackage decoded = new PackageArchive().decode(source.bytes());
    if (!decoded.manifest().name().equals("wheeler.compiler")) {
      throw new IOException("Bootstrap source archive is not wheeler.compiler");
    }
    BootstrapModuleManifest manifest;
    try {
      manifest = BootstrapModuleSources.derive(decoded);
    } catch (RuntimeException exception) {
      throw new IOException("Cannot derive bootstrap module graph", exception);
    }
    BootstrapModuleManifest reparsed = new BootstrapModuleManifestParser().parse(
        manifest.canonicalBytes());
    if (!manifest.equals(reparsed)) {
      throw new IOException("Bootstrap module manifest failed its canonical self-check");
    }
    PackageProject.writeAtomically(output, manifest.canonicalBytes());
    out.println("recorded bootstrap module graph " + manifest.identity() + " in " + output);
    return 0;
  }

  private static void usage(PrintStream error) {
    error.println("Usage: wheeler bootstrap-modules"
        + " --source-archive <wheeler.compiler.wpk>"
        + " --output <wheeler.bootstrap-modules.yaml>");
  }
}
