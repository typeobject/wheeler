package com.typeobject.wheeler.packageformat;

import com.typeobject.wheeler.packageformat.CanonicalYaml.Mapping;
import com.typeobject.wheeler.packageformat.CanonicalYaml.Value;
import com.typeobject.wheeler.packageformat.RepositoryPolicy.Repository;
import com.typeobject.wheeler.packageformat.RepositoryPolicy.Transport;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/** Strict schema decoder for {@code wheeler.repositories.yaml}. */
public final class RepositoryPolicyParser {
  private static final int MAX_BYTES = 1024 * 1024;
  private static final Set<String> ROOT_FIELDS = Set.of("schema", "repositories");
  private static final Set<String> REPOSITORY_FIELDS = Set.of(
      "alias", "identity", "transport", "location", "enabled", "namespaces");

  public RepositoryPolicy parse(byte[] utf8) {
    if (utf8.length > MAX_BYTES) {
      throw new PackageFormatException("Repository policy exceeds " + MAX_BYTES + " bytes");
    }
    try {
      String source = StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(utf8))
          .toString();
      return parseDecoded(source);
    } catch (CharacterCodingException exception) {
      throw new PackageFormatException("Repository policy is not strict UTF-8", exception);
    }
  }

  public RepositoryPolicy parse(String source) {
    return parse(source.getBytes(StandardCharsets.UTF_8));
  }

  private static RepositoryPolicy parseDecoded(String source) {
    Mapping root = CanonicalYaml.mapping(
        CanonicalYaml.parse(source, "repository policy"), "repository policy");
    CanonicalYaml.fields(root, ROOT_FIELDS, "repository policy");
    int schema = CanonicalYaml.integer(
        CanonicalYaml.required(root, "schema", "repository policy"), "repository schema");
    List<Repository> repositories = new ArrayList<>();
    for (Value value : CanonicalYaml.sequence(
        CanonicalYaml.required(root, "repositories", "repository policy"),
        "repositories").values()) {
      Mapping repository = CanonicalYaml.mapping(value, "repository");
      CanonicalYaml.fields(repository, REPOSITORY_FIELDS, "repository");
      repositories.add(new Repository(
          string(repository, "alias"),
          string(repository, "identity"),
          Transport.parse(string(repository, "transport")),
          string(repository, "location"),
          CanonicalYaml.bool(
              CanonicalYaml.required(repository, "enabled", "repository"),
              "repository.enabled"),
          strings(repository, "namespaces")));
    }
    return new RepositoryPolicy(schema, repositories);
  }

  private static String string(Mapping mapping, String key) {
    return CanonicalYaml.string(
        CanonicalYaml.required(mapping, key, "repository"), "repository." + key);
  }

  private static List<String> strings(Mapping mapping, String key) {
    List<String> result = new ArrayList<>();
    for (Value value : CanonicalYaml.sequence(
        CanonicalYaml.required(mapping, key, "repository"), "repository." + key).values()) {
      result.add(CanonicalYaml.string(value, "repository namespace"));
    }
    return List.copyOf(result);
  }
}
