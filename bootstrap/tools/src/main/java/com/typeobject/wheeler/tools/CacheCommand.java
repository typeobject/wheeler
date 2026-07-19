package com.typeobject.wheeler.tools;

import java.io.PrintStream;

/** Performs bounded maintenance over disposable XDG cache objects only. */
final class CacheCommand {
  private CacheCommand() {}

  static int execute(String[] args, PrintStream out, PrintStream error) throws Exception {
    return execute(args, out, error, XdgPaths.system());
  }

  static int execute(
      String[] args, PrintStream out, PrintStream error, XdgPaths paths) throws Exception {
    if (args.length != 2 || !args[1].equals("gc")) {
      error.println("Usage: wheeler cache gc");
      return 2;
    }
    for (String diagnostic : paths.diagnostics()) {
      error.println("wheeler: " + diagnostic);
    }
    ArtifactCache.GcResult packages = new ArtifactCache(paths.artifactCache()).gc();
    BuildOutputCache.GcResult builds = new BuildOutputCache(
        paths.artifactCache(), paths.state()).gc();
    out.println("cache gc retained " + (packages.retained() + builds.retained())
        + " removed " + (packages.removed() + builds.removed()));
    return 0;
  }
}
