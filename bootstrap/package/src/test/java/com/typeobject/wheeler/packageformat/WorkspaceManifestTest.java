package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.packageformat.WorkspaceManifest.Member;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Conformance tests for canonical workspace parsing and member validation. */
class WorkspaceManifestTest {
  @Test
  void parserCanonicalizesMemberOrderAndComments() {
    WorkspaceManifestParser parser = new WorkspaceManifestParser();
    WorkspaceManifest manifest = parser.parse("""
        schema: 1
        workspace:
          name: "wheeler.bootstrap"
          profile: "bootstrap-1"
        # Source order does not establish build order.
        members:
          - name: "runtime"
            path: "wheeler-runtime"
          - name: "examples"
            path: "wheeler-examples"
        """);

    assertEquals(List.of("examples", "runtime"),
        manifest.members().stream().map(Member::name).toList());
    assertEquals(manifest, parser.parse(manifest.canonicalText()));
    assertEquals(64, manifest.identity().length());
  }

  @Test
  void duplicateNestedAndEscapingMembersFailClosed() {
    assertThrows(PackageFormatException.class, () -> new WorkspaceManifest(
        "root", "bootstrap-1", List.of(new Member("a", "pkg"), new Member("b", "pkg"))));
    assertThrows(PackageFormatException.class, () -> new WorkspaceManifest(
        "root", "bootstrap-1", List.of(new Member("a", "pkg"), new Member("b", "pkg/sub"))));
    assertThrows(PackageFormatException.class, () -> new Member("a", "../outside"));
  }

  @Test
  void malformedWorkspaceReportsSourceLocation() {
    PackageFormatException failure = assertThrows(
        PackageFormatException.class,
        () -> new WorkspaceManifestParser().parse("""
            schema: 1
            workspace:
              name: "root"
              profile: "bootstrap-1"
            plugins:
              - name: "bad"
                path: "pkg"
            members: []
            """));
    assertTrue(failure.getMessage().contains("plugins"));
    assertThrows(
        PackageFormatException.class,
        () -> new WorkspaceManifestParser().parse(new byte[] {(byte) 0xc3}));
  }
}
