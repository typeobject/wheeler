package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.BootstrapFeatureManifest;
import com.typeobject.wheeler.packageformat.BootstrapFeatureManifestParser;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.file.Path;

/** Publishes the complete closed feature vocabulary for a known bootstrap profile. */
final class BootstrapFeaturesCommand {
  private BootstrapFeaturesCommand() {}

  static int execute(String[] args, PrintStream out, PrintStream error) throws IOException {
    if (args.length != 5 || !args[1].equals("--profile") || !args[3].equals("--output")) {
      usage(error);
      return 2;
    }
    BootstrapFeatureManifest manifest;
    if (args[2].equals("bootstrap-1")) {
      manifest = BootstrapFeatureManifest.bootstrap1();
    } else {
      error.println("Unknown bootstrap feature profile: " + args[2]);
      return 2;
    }
    BootstrapFeatureManifest reparsed = new BootstrapFeatureManifestParser().parse(
        manifest.canonicalBytes());
    if (!manifest.equals(reparsed)) {
      throw new IOException("Bootstrap feature manifest failed its canonical self-check");
    }
    Path output = Path.of(args[4]);
    PackageProject.writeAtomically(output, manifest.canonicalBytes());
    out.println("recorded bootstrap feature profile " + manifest.identity() + " in " + output);
    return 0;
  }

  private static void usage(PrintStream error) {
    error.println("Usage: wheeler bootstrap-features"
        + " --profile <bootstrap-1> --output <wheeler.bootstrap-features.yaml>");
  }
}
