package com.typeobject.wheeler.examples;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/** Resolves canonical Wheeler core sources without maintaining an example-side fork. */
final class CoreSources {
  private static final Path ROOT = Path.of("../wheeler-core/src/main/wheeler");

  private CoreSources() {}

  /** Returns one canonical core source path. */
  static Path path(String logicalPath) {
    return ROOT.resolve(logicalPath);
  }

  /** Reads one canonical core source as strict host text. */
  static String read(String logicalPath) throws IOException {
    return Files.readString(path(logicalPath));
  }
}
