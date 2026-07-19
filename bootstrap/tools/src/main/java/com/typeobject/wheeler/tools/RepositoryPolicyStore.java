package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.RepositoryPolicy;
import com.typeobject.wheeler.packageformat.RepositoryPolicyParser;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;

/** Loads and atomically replaces the XDG repository policy without ambient candidates. */
final class RepositoryPolicyStore {
  private RepositoryPolicyStore() {}

  static RepositoryPolicy load(XdgPaths paths) throws IOException {
    Path policy = paths.repositoryPolicy();
    if (!Files.exists(policy, LinkOption.NOFOLLOW_LINKS)) {
      return RepositoryPolicy.defaultLocal(paths.dataRepository());
    }
    requirePhysicalFile(policy, "repository policy");
    return new RepositoryPolicyParser().parse(Files.readAllBytes(policy));
  }

  static void write(XdgPaths paths, RepositoryPolicy policy) throws IOException {
    Path parent = paths.repositoryPolicy().getParent();
    createPhysicalDirectories(parent);
    if (Files.exists(paths.repositoryPolicy(), LinkOption.NOFOLLOW_LINKS)) {
      requirePhysicalFile(paths.repositoryPolicy(), "repository policy");
    }
    PackageProject.writeAtomically(
        paths.repositoryPolicy(), policy.canonicalText().getBytes(StandardCharsets.UTF_8));
  }

  static void createPhysicalDirectories(Path directory) throws IOException {
    Path absolute = directory.toAbsolutePath().normalize();
    Path current = absolute.getRoot();
    for (Path component : absolute) {
      current = current.resolve(component);
      if (!Files.exists(current, LinkOption.NOFOLLOW_LINKS)) {
        Files.createDirectory(current);
      }
      if (!Files.isDirectory(current, LinkOption.NOFOLLOW_LINKS)
          || Files.isSymbolicLink(current)) {
        throw new IOException("XDG path component is not a physical directory: " + current);
      }
    }
  }

  private static void requirePhysicalFile(Path path, String description) throws IOException {
    if (!Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS) || Files.isSymbolicLink(path)) {
      throw new IOException("Missing physical " + description + ": " + path);
    }
  }
}
