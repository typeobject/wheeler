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
    ArtifactCache.GcResult result = new ArtifactCache(paths.artifactCache()).gc();
    out.println("cache gc retained " + result.retained() + " removed " + result.removed());
    return 0;
  }
}
