package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.RepositoryPolicy;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/** Resolves Wheeler's identity-neutral XDG configuration, data, cache, and state paths. */
record XdgPaths(
    Path repositoryPolicy,
    Path dataRepository,
    Path artifactCache,
    Path state,
    List<String> diagnostics) {
  XdgPaths {
    repositoryPolicy = absolute(repositoryPolicy, "repository policy");
    dataRepository = absolute(dataRepository, "data repository");
    artifactCache = absolute(artifactCache, "artifact cache");
    state = absolute(state, "state");
    diagnostics = List.copyOf(diagnostics);
  }

  static XdgPaths system() {
    return resolve(System.getenv(), Path.of(System.getProperty("user.home")));
  }

  static XdgPaths resolve(Map<String, String> environment, Path home) {
    Objects.requireNonNull(environment, "environment");
    home = absolute(home, "home");
    List<String> diagnostics = new ArrayList<>();
    Path config = base(environment, "XDG_CONFIG_HOME", home.resolve(".config"), diagnostics);
    Path data = base(
        environment, "XDG_DATA_HOME", home.resolve(".local/share"), diagnostics);
    Path cache = base(environment, "XDG_CACHE_HOME", home.resolve(".cache"), diagnostics);
    Path state = base(
        environment, "XDG_STATE_HOME", home.resolve(".local/state"), diagnostics);
    return new XdgPaths(
        config.resolve("wheeler").resolve(RepositoryPolicy.FILE_NAME),
        data.resolve("wheeler/repository"),
        cache.resolve("wheeler/artifacts"),
        state.resolve("wheeler"),
        diagnostics);
  }

  private static Path base(
      Map<String, String> environment,
      String variable,
      Path fallback,
      List<String> diagnostics) {
    String value = environment.get(variable);
    if (value == null || value.isBlank()) {
      return fallback.normalize();
    }
    Path candidate = Path.of(value);
    if (!candidate.isAbsolute()) {
      diagnostics.add(variable + " is relative and was ignored");
      return fallback.normalize();
    }
    return candidate.normalize();
  }

  private static Path absolute(Path path, String description) {
    Objects.requireNonNull(path, description);
    if (!path.isAbsolute()) {
      throw new PackageFormatException("XDG " + description + " path is not absolute: " + path);
    }
    return path.normalize();
  }
}
