package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.PublicKey;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.regex.Pattern;

/** Ordered immutable repository policy stored as {@code wheeler.repositories.yaml}. */
public record RepositoryPolicy(int schemaVersion, List<Repository> repositories) {
  public static final int SCHEMA_VERSION = 2;
  public static final String FILE_NAME = "wheeler.repositories.yaml";
  private static final int MAX_REPOSITORIES = 64;
  private static final Pattern ALIAS = Pattern.compile("[a-z][a-z0-9]*(?:-[a-z0-9]+)*");
  private static final Pattern NAMESPACE = Pattern.compile(
      "[a-z][a-z0-9]*(?:\\.[a-z][a-z0-9]*)*");

  public RepositoryPolicy {
    if (schemaVersion != SCHEMA_VERSION) {
      throw new PackageFormatException("Unsupported repository policy schema " + schemaVersion);
    }
    repositories = List.copyOf(repositories);
    if (repositories.isEmpty() || repositories.size() > MAX_REPOSITORIES) {
      throw new PackageFormatException(
          "Repository policy must contain 1.." + MAX_REPOSITORIES + " repositories");
    }
    Set<String> aliases = new HashSet<>();
    for (Repository repository : repositories) {
      if (!aliases.add(repository.alias())) {
        throw new PackageFormatException("Duplicate repository alias " + repository.alias());
      }
    }
  }

  /** Creates the implicit one-entry policy without writing configuration as a side effect. */
  public static RepositoryPolicy defaultLocal(Path dataRepository) {
    Objects.requireNonNull(dataRepository, "dataRepository");
    if (!dataRepository.isAbsolute()) {
      throw new PackageFormatException("Default local repository path is not absolute");
    }
    return new RepositoryPolicy(
        SCHEMA_VERSION,
        List.of(new Repository(
            "local",
            localIdentity(),
            Transport.FILE,
            dataRepository.normalize().toString(),
            true,
            List.of("*"),
            List.of())));
  }

  /** Stable trust-domain identity for the default local repository. */
  public static String localIdentity() {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
          .digest("wheeler.repository.local/1".getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  public RepositoryPolicy add(Repository repository) {
    List<Repository> changed = new ArrayList<>(repositories);
    changed.add(repository);
    return new RepositoryPolicy(schemaVersion, changed);
  }

  public RepositoryPolicy remove(String alias) {
    List<Repository> changed = repositories.stream()
        .filter(repository -> !repository.alias().equals(alias))
        .toList();
    if (changed.size() == repositories.size()) {
      throw new PackageFormatException("Unknown repository alias " + alias);
    }
    return new RepositoryPolicy(schemaVersion, changed);
  }

  public RepositoryPolicy enabled(String alias, boolean enabled) {
    List<Repository> changed = new ArrayList<>();
    boolean found = false;
    for (Repository repository : repositories) {
      if (repository.alias().equals(alias)) {
        changed.add(repository.withEnabled(enabled));
        found = true;
      } else {
        changed.add(repository);
      }
    }
    if (!found) {
      throw new PackageFormatException("Unknown repository alias " + alias);
    }
    return new RepositoryPolicy(schemaVersion, changed);
  }

  public RepositoryPolicy trustKey(String alias, TrustedKey key) {
    return replace(alias, require(alias).withKey(key));
  }

  public RepositoryPolicy untrustKey(String alias, String keyIdentity) {
    Repository repository = require(alias);
    Repository changed = repository.withoutKey(keyIdentity);
    if (changed.keys().size() == repository.keys().size()) {
      throw new PackageFormatException("Unknown repository trusted key " + keyIdentity);
    }
    return replace(alias, changed);
  }

  private RepositoryPolicy replace(String alias, Repository replacement) {
    List<Repository> changed = repositories.stream()
        .map(repository -> repository.alias().equals(alias) ? replacement : repository)
        .toList();
    return new RepositoryPolicy(schemaVersion, changed);
  }

  public RepositoryPolicy moveBefore(String alias, String before) {
    if (alias.equals(before)) {
      require(alias);
      return this;
    }
    Repository selected = require(alias);
    List<Repository> changed = new ArrayList<>(repositories);
    changed.remove(selected);
    if (before.equals("last")) {
      changed.add(selected);
    } else {
      Repository anchor = require(before);
      changed.add(changed.indexOf(anchor), selected);
    }
    return new RepositoryPolicy(schemaVersion, changed);
  }

  public Repository require(String alias) {
    return repositories.stream()
        .filter(repository -> repository.alias().equals(alias))
        .findFirst()
        .orElseThrow(() -> new PackageFormatException("Unknown repository alias " + alias));
  }

  public String canonicalText() {
    StringBuilder text = new StringBuilder("schema: 2\nrepositories:\n");
    for (Repository repository : repositories) {
      text.append("  - alias: ").append(CanonicalYaml.quote(repository.alias())).append('\n')
          .append("    identity: ").append(CanonicalYaml.quote(repository.identity())).append('\n')
          .append("    transport: ")
          .append(CanonicalYaml.quote(repository.transport().keyword())).append('\n')
          .append("    location: ").append(CanonicalYaml.quote(repository.location())).append('\n')
          .append("    enabled: ").append(repository.enabled()).append('\n');
      if (repository.namespaces().isEmpty()) {
        text.append("    namespaces: []\n");
      } else {
        text.append("    namespaces:\n");
        for (String namespace : repository.namespaces()) {
          text.append("      - ").append(CanonicalYaml.quote(namespace)).append('\n');
        }
      }
      if (repository.keys().isEmpty()) {
        text.append("    keys: []\n");
      } else {
        text.append("    keys:\n");
        for (TrustedKey key : repository.keys()) {
          text.append("      - identity: ").append(CanonicalYaml.quote(key.identity()))
              .append('\n')
              .append("        public-key: ").append(CanonicalYaml.quote(key.publicKey()))
              .append('\n');
        }
      }
    }
    return text.toString();
  }

  /** One canonical Ed25519 public key explicitly trusted for a repository. */
  public record TrustedKey(String identity, String publicKey) {
    public TrustedKey {
      Objects.requireNonNull(identity, "identity");
      Objects.requireNonNull(publicKey, "publicKey");
      byte[] encoded;
      try {
        encoded = Base64.getDecoder().decode(publicKey);
      } catch (IllegalArgumentException exception) {
        throw new PackageFormatException("Invalid repository trusted public key", exception);
      }
      if (encoded.length > 1024
          || !Base64.getEncoder().encodeToString(encoded).equals(publicKey)) {
        throw new PackageFormatException("Repository trusted public key is not canonical base64");
      }
      PublicKey decoded = RepositorySnapshotSignature.decodePublicKey(encoded);
      if (!RepositorySnapshotSignature.keyIdentity(decoded).equals(identity)) {
        throw new PackageFormatException("Repository trusted key identity mismatch");
      }
    }

    public static TrustedKey from(PublicKey key) {
      return new TrustedKey(
          RepositorySnapshotSignature.keyIdentity(key),
          Base64.getEncoder().encodeToString(key.getEncoded()));
    }

    public PublicKey decoded() {
      return RepositorySnapshotSignature.decodePublicKey(Base64.getDecoder().decode(publicKey));
    }
  }

  /** One repository transport, authority allowlist, and trusted signing keys. */
  public record Repository(
      String alias,
      String identity,
      Transport transport,
      String location,
      boolean enabled,
      List<String> namespaces,
      List<TrustedKey> keys) {
    public Repository {
      Objects.requireNonNull(alias, "alias");
      Objects.requireNonNull(identity, "identity");
      Objects.requireNonNull(transport, "transport");
      Objects.requireNonNull(location, "location");
      if (!ALIAS.matcher(alias).matches()) {
        throw new PackageFormatException("Invalid repository alias " + alias);
      }
      if (!identity.matches("[0-9a-f]{64}")) {
        throw new PackageFormatException("Invalid repository identity " + identity);
      }
      if (location.isBlank() || location.length() > 16_384 || location.indexOf('\0') >= 0) {
        throw new PackageFormatException("Invalid repository location");
      }
      if (transport == Transport.FILE) {
        Path path = Path.of(location);
        if (!path.isAbsolute() || !path.normalize().toString().equals(location)) {
          throw new PackageFormatException(
              "File repository location is not absolute and normalized: " + location);
        }
      }
      List<String> ordered = new ArrayList<>(List.copyOf(namespaces));
      ordered.sort(String::compareTo);
      Set<String> unique = new HashSet<>();
      for (String namespace : ordered) {
        if (!(namespace.equals("*") || NAMESPACE.matcher(namespace).matches())) {
          throw new PackageFormatException("Invalid repository namespace " + namespace);
        }
        if (!unique.add(namespace)) {
          throw new PackageFormatException("Duplicate repository namespace " + namespace);
        }
      }
      namespaces = List.copyOf(ordered);
      if (keys.size() > 16) {
        throw new PackageFormatException("Repository exceeds trusted key limit");
      }
      List<TrustedKey> orderedKeys = new ArrayList<>(List.copyOf(keys));
      orderedKeys.sort(java.util.Comparator.comparing(TrustedKey::identity));
      Set<String> keyIdentities = new HashSet<>();
      for (TrustedKey key : orderedKeys) {
        if (!keyIdentities.add(key.identity())) {
          throw new PackageFormatException("Duplicate repository trusted key " + key.identity());
        }
      }
      keys = List.copyOf(orderedKeys);
    }

    public Repository withEnabled(boolean next) {
      return new Repository(alias, identity, transport, location, next, namespaces, keys);
    }

    public Repository withKey(TrustedKey key) {
      List<TrustedKey> changed = new ArrayList<>(keys);
      changed.add(key);
      return new Repository(alias, identity, transport, location, enabled, namespaces, changed);
    }

    public Repository withoutKey(String keyIdentity) {
      return new Repository(
          alias,
          identity,
          transport,
          location,
          enabled,
          namespaces,
          keys.stream().filter(key -> !key.identity().equals(keyIdentity)).toList());
    }

    public boolean authoritativeFor(String packageName) {
      for (String namespace : namespaces) {
        if (namespace.equals("*") || packageName.equals(namespace)
            || packageName.startsWith(namespace + ".")) {
          return true;
        }
      }
      return false;
    }
  }

  public enum Transport {
    FILE;

    public String keyword() {
      return name().toLowerCase(java.util.Locale.ROOT);
    }

    public static Transport parse(String text) {
      if ("file".equals(text)) {
        return FILE;
      }
      throw new PackageFormatException("Unsupported repository transport " + text);
    }
  }
}
