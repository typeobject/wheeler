package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.PackageRelease;
import com.typeobject.wheeler.packageformat.PackageResolver;
import com.typeobject.wheeler.packageformat.RepositoryPolicy;
import com.typeobject.wheeler.packageformat.RepositoryRelease;
import com.typeobject.wheeler.packageformat.RepositoryPolicy.Repository;
import com.typeobject.wheeler.packageformat.RepositoryPolicy.Transport;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Connects ordered repository policy to physical file transports without changing identity. */
final class RepositoryAccess {
  private RepositoryAccess() {}

  static PackageRegistry publication(XdgPaths paths, String alias) throws IOException {
    Repository repository = RepositoryPolicyStore.load(paths).require(alias);
    requireEnabledFile(repository);
    return PackageRegistry.openOrCreate(Path.of(repository.location()));
  }

  static PackageResolver resolver(XdgPaths paths, List<String> selectedAliases)
      throws IOException {
    RepositoryPolicy policy = RepositoryPolicyStore.load(paths);
    List<Repository> selected;
    if (selectedAliases.isEmpty()) {
      selected = policy.repositories();
    } else {
      Set<String> unique = new HashSet<>();
      List<Repository> requested = new ArrayList<>();
      for (String alias : selectedAliases) {
        if (!unique.add(alias)) {
          throw new PackageFormatException("Duplicate selected repository " + alias);
        }
        requested.add(policy.require(alias));
      }
      selected = List.copyOf(requested);
    }
    List<PackageResolver.RepositoryCatalog> catalogs = new ArrayList<>();
    for (Repository repository : selected) {
      if (!repository.enabled()) {
        continue;
      }
      requireEnabledFile(repository);
      Path root = Path.of(repository.location());
      List<PackageRelease> releases = Files.exists(root, LinkOption.NOFOLLOW_LINKS)
          ? PackageRegistry.open(root).releases().stream()
              .filter(release -> repository.authoritativeFor(release.manifest().name()))
              .toList()
          : List.of();
      catalogs.add(new PackageResolver.RepositoryCatalog(repository.identity(), releases));
    }
    if (catalogs.isEmpty()) {
      throw new PackageFormatException("No enabled repositories are selected");
    }
    return PackageResolver.orderedRepositories(catalogs);
  }

  static byte[] fetch(XdgPaths paths, String selectedAlias, String name, String version)
      throws IOException {
    RepositoryPolicy policy = RepositoryPolicyStore.load(paths);
    ArtifactCache cache = new ArtifactCache(paths.artifactCache());
    if (selectedAlias != null) {
      Repository repository = policy.require(selectedAlias);
      requireEnabledFile(repository);
      if (!repository.authoritativeFor(name)) {
        throw new PackageFormatException(
            "Repository " + selectedAlias + " is not authoritative for " + name);
      }
      byte[] bytes = present(repository, name, version, cache);
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
      byte[] bytes = present(repository, name, version, cache);
      if (bytes != null) {
        return bytes;
      }
    }
    throw new IOException("No configured repository has release " + name + " " + version);
  }

  private static byte[] present(
      Repository repository,
      String name,
      String version,
      ArtifactCache cache) throws IOException {
    Path root = Path.of(repository.location());
    if (!Files.exists(root, LinkOption.NOFOLLOW_LINKS)) {
      return null;
    }
    PackageRegistry registry = PackageRegistry.open(root);
    RepositoryRelease release = registry.releaseIfPresent(name, version);
    if (release == null) {
      return null;
    }
    byte[] cached = cache.load(release);
    if (cached != null) {
      return cached;
    }
    byte[] fetched = registry.fetch(release);
    cache.store(release, fetched);
    return fetched;
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
