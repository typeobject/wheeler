package com.typeobject.wheeler.packageformat;

import com.typeobject.wheeler.packageformat.CanonicalYaml.Mapping;
import com.typeobject.wheeler.packageformat.CanonicalYaml.Value;
import com.typeobject.wheeler.packageformat.WorkspaceManifest.Member;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/** Strict schema decoder for one {@code wheeler.workspace.yaml} document. */
public final class WorkspaceManifestParser {
  private static final int MAX_BYTES = 1024 * 1024;
  private static final Set<String> ROOT_FIELDS = Set.of("schema", "workspace", "members");
  private static final Set<String> WORKSPACE_FIELDS = Set.of("name", "profile");
  private static final Set<String> MEMBER_FIELDS = Set.of("name", "path");

  public WorkspaceManifest parse(byte[] utf8) {
    if (utf8.length > MAX_BYTES) {
      throw new PackageFormatException("Workspace manifest exceeds " + MAX_BYTES + " bytes");
    }
    try {
      String source = StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(utf8))
          .toString();
      return parseDecoded(source);
    } catch (CharacterCodingException exception) {
      throw new PackageFormatException("Workspace manifest is not strict UTF-8", exception);
    }
  }

  public WorkspaceManifest parse(String source) {
    return parse(source.getBytes(StandardCharsets.UTF_8));
  }

  private static WorkspaceManifest parseDecoded(String source) {
    Mapping root = CanonicalYaml.mapping(
        CanonicalYaml.parse(source, "workspace manifest"), "workspace manifest");
    CanonicalYaml.fields(root, ROOT_FIELDS, "workspace manifest");
    int schema = CanonicalYaml.integer(
        CanonicalYaml.required(root, "schema", "workspace manifest"), "workspace schema");
    if (schema != 1) {
      throw new PackageFormatException("Unsupported workspace schema " + schema);
    }
    Mapping header = CanonicalYaml.mapping(
        CanonicalYaml.required(root, "workspace", "workspace manifest"), "workspace header");
    CanonicalYaml.fields(header, WORKSPACE_FIELDS, "workspace");
    String name = requiredString(header, "name", "workspace");
    String profile = requiredString(header, "profile", "workspace");
    List<Member> members = new ArrayList<>();
    for (Value value : CanonicalYaml.sequence(
        CanonicalYaml.required(root, "members", "workspace manifest"), "workspace members")
        .values()) {
      Mapping member = CanonicalYaml.mapping(value, "workspace member");
      CanonicalYaml.fields(member, MEMBER_FIELDS, "workspace member");
      members.add(new Member(
          requiredString(member, "name", "workspace member"),
          requiredString(member, "path", "workspace member")));
    }
    return new WorkspaceManifest(name, profile, members);
  }

  private static String requiredString(Mapping mapping, String key, String description) {
    return CanonicalYaml.string(
        CanonicalYaml.required(mapping, key, description), description + "." + key);
  }
}
