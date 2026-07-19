package com.typeobject.wheeler.examples;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/** Resolves canonical Wheeler runtime sources without smuggling copies into examples. */
final class RuntimeSources {
  private static final Path ROOT = Path.of("../wheeler-runtime/src/main/wheeler");

  private RuntimeSources() {}

  /** Returns one canonical runtime source path. */
  static Path path(String logicalPath) {
    return ROOT.resolve(logicalPath);
  }

  /** Reads one canonical runtime source as strict host text. */
  static String read(String logicalPath) throws IOException {
    return Files.readString(path(logicalPath));
  }
}
