package com.typeobject.wheeler.examples;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/** Resolves canonical Wheeler package sources without cloning them into the example portfolio. */
final class PackageSources {
  private static final Path ROOT = Path.of("../wheeler-package/src/main/wheeler");

  private PackageSources() {}

  /** Returns one canonical package source path. */
  static Path path(String logicalPath) {
    return ROOT.resolve(logicalPath);
  }

  /** Reads one canonical package source as strict host text. */
  static String read(String logicalPath) throws IOException {
    return Files.readString(path(logicalPath));
  }
}
