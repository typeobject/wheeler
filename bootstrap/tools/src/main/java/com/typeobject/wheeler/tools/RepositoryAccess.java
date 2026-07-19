package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.RepositoryPolicy;
import com.typeobject.wheeler.packageformat.RepositoryPolicy.Repository;
import com.typeobject.wheeler.packageformat.RepositoryPolicy.Transport;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;

/** Connects ordered repository policy to physical file transports without changing identity. */
final class RepositoryAccess {
  private RepositoryAccess() {}

  static PackageRegistry publication(XdgPaths paths, String alias) throws IOException {
    Repository repository = RepositoryPolicyStore.load(paths).require(alias);
    requireEnabledFile(repository);
    return PackageRegistry.openOrCreate(Path.of(repository.location()));
  }

  static byte[] fetch(XdgPaths paths, String selectedAlias, String name, String version)
      throws IOException {
    RepositoryPolicy policy = RepositoryPolicyStore.load(paths);
    if (selectedAlias != null) {
      Repository repository = policy.require(selectedAlias);
      requireEnabledFile(repository);
      if (!repository.authoritativeFor(name)) {
        throw new PackageFormatException(
            "Repository " + selectedAlias + " is not authoritative for " + name);
      }
      byte[] bytes = present(repository, name, version);
      if (bytes == null) {
        throw new IOException(
            "Repository " + selectedAlias + " has no release " + name + " " + version);
      }
      return bytes;
    }
    for (Repository repository : policy.repositories()) {
      if (!repository.enabled() || !repository.authoritativeFor(name)) {
        continue;
      }
      requireEnabledFile(repository);
      byte[] bytes = present(repository, name, version);
      if (bytes != null) {
        return bytes;
      }
    }
    throw new IOException("No configured repository has release " + name + " " + version);
  }

  private static byte[] present(Repository repository, String name, String version)
      throws IOException {
    Path root = Path.of(repository.location());
    if (!Files.exists(root, LinkOption.NOFOLLOW_LINKS)) {
      return null;
    }
    return PackageRegistry.open(root).fetchIfPresent(name, version);
  }

  private static void requireEnabledFile(Repository repository) {
    if (!repository.enabled()) {
      throw new PackageFormatException("Repository is disabled: " + repository.alias());
    }
    if (repository.transport() != Transport.FILE) {
      throw new PackageFormatException(
          "Repository transport is not implemented: " + repository.transport().keyword());
    }
  }
}
