package com.typeobject.wheeler.packageformat;

import com.typeobject.wheeler.packageformat.CanonicalYaml.Mapping;
import com.typeobject.wheeler.packageformat.CanonicalYaml.Sequence;
import com.typeobject.wheeler.packageformat.CanonicalYaml.Value;
import com.typeobject.wheeler.packageformat.PackageManifest.Capability;
import com.typeobject.wheeler.packageformat.PackageManifest.Dependency;
import com.typeobject.wheeler.packageformat.PackageManifest.DependencyKind;
import com.typeobject.wheeler.packageformat.PackageManifest.Target;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/** Strict schema decoder for one {@code wheeler.package.yaml} document. */
public final class PackageManifestParser {
  private static final int MAX_BYTES = 1024 * 1024;
  private static final Set<String> ROOT_FIELDS = Set.of(
      "schema", "package", "targets", "dependencies", "capabilities");
  private static final Set<String> PACKAGE_FIELDS = Set.of("name", "version", "profile");
  private static final Set<String> TARGET_FIELDS = Set.of(
      "kind", "name", "root", "module", "sources", "test");
  private static final Set<String> DEPENDENCY_FIELDS = Set.of("kind", "name", "version");
  private static final Set<String> CAPABILITY_FIELDS = Set.of("name", "path");

  public PackageManifest parse(byte[] utf8) {
    if (utf8.length > MAX_BYTES) {
      throw new PackageFormatException("Manifest exceeds " + MAX_BYTES + " bytes");
    }
    try {
      String source = StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(utf8))
          .toString();
      return parseDecoded(source);
    } catch (CharacterCodingException exception) {
      throw new PackageFormatException("Manifest is not strict UTF-8", exception);
    }
  }

  public PackageManifest parse(String source) {
    return parse(source.getBytes(StandardCharsets.UTF_8));
  }

  private static PackageManifest parseDecoded(String source) {
    Mapping root = CanonicalYaml.mapping(CanonicalYaml.parse(source, "package manifest"), "manifest");
    CanonicalYaml.fields(root, ROOT_FIELDS, "manifest");
    int schema = CanonicalYaml.integer(
        CanonicalYaml.required(root, "schema", "manifest"), "manifest.schema");
    if (schema != 1) {
      throw new PackageFormatException("Unsupported package manifest schema " + schema);
    }
    Mapping header = CanonicalYaml.mapping(
        CanonicalYaml.required(root, "package", "manifest"), "manifest.package");
    CanonicalYaml.fields(header, PACKAGE_FIELDS, "manifest.package");
    String name = requiredString(header, "name", "manifest.package");
    String version = requiredString(header, "version", "manifest.package");
    String profile = requiredString(header, "profile", "manifest.package");

    List<Target> targets = new ArrayList<>();
    Sequence targetValues = requiredSequence(root, "targets", "manifest");
    for (Value value : targetValues.values()) {
      Mapping target = CanonicalYaml.mapping(value, "manifest target");
      CanonicalYaml.fields(target, TARGET_FIELDS, "manifest target");
      String module = optionalString(target, "module", "manifest target");
      List<String> sources = module == null
          ? List.of()
          : stringList(requiredSequence(target, "sources", "manifest target"), "target source");
      targets.add(new Target(
          TargetKind.parse(requiredString(target, "kind", "manifest target")),
          requiredString(target, "name", "manifest target"),
          requiredString(target, "root", "manifest target"),
          module,
          sources,
          CanonicalYaml.bool(
              CanonicalYaml.required(target, "test", "manifest target"), "target.test")));
    }

    List<Dependency> dependencies = new ArrayList<>();
    for (Value value : requiredSequence(root, "dependencies", "manifest").values()) {
      Mapping dependency = CanonicalYaml.mapping(value, "manifest dependency");
      CanonicalYaml.fields(dependency, DEPENDENCY_FIELDS, "manifest dependency");
      dependencies.add(new Dependency(
          DependencyKind.parse(requiredString(dependency, "kind", "manifest dependency")),
          requiredString(dependency, "name", "manifest dependency"),
          requiredString(dependency, "version", "manifest dependency")));
    }

    List<Capability> capabilities = new ArrayList<>();
    for (Value value : requiredSequence(root, "capabilities", "manifest").values()) {
      Mapping capability = CanonicalYaml.mapping(value, "manifest capability");
      CanonicalYaml.fields(capability, CAPABILITY_FIELDS, "manifest capability");
      capabilities.add(new Capability(
          requiredString(capability, "name", "manifest capability"),
          requiredString(capability, "path", "manifest capability")));
    }
    return new PackageManifest(name, version, profile, targets, dependencies, capabilities);
  }

  private static String requiredString(Mapping mapping, String key, String description) {
    return CanonicalYaml.string(
        CanonicalYaml.required(mapping, key, description), description + "." + key);
  }

  private static String optionalString(Mapping mapping, String key, String description) {
    Value value = mapping.values().get(key);
    return value == null ? null : CanonicalYaml.string(value, description + "." + key);
  }

  private static Sequence requiredSequence(Mapping mapping, String key, String description) {
    return CanonicalYaml.sequence(
        CanonicalYaml.required(mapping, key, description), description + "." + key);
  }

  private static List<String> stringList(Sequence sequence, String description) {
    List<String> result = new ArrayList<>();
    for (Value value : sequence.values()) {
      result.add(CanonicalYaml.string(value, description));
    }
    return List.copyOf(result);
  }
}
