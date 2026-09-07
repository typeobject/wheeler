package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;

import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageArchive.DecodedPackage;
import com.typeobject.wheeler.packageformat.PackageLock;
import com.typeobject.wheeler.packageformat.PackageLockParser;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.function.Executable;

/** Checks every maintained root lock against freshly encoded workspace inputs. */
final class CanonicalWorkspaceLockTest {
  @Test
  void bindsEveryRootAndDependencyBeforeCompilingTargets() throws Exception {
    Path root = Path.of(".").toRealPath();
    WorkspaceProject workspace = WorkspaceProject.load(root);
    PackageArchive codec = new PackageArchive();
    Map<String, DecodedPackage> archives = new TreeMap<>();
    List<PackageProject> projects = new ArrayList<>();
    for (var member : workspace.manifest().members()) {
      PackageProject project = PackageProject.load(root.resolve(member.path()));
      assertArrayEquals(project.manifest().canonicalText().getBytes(StandardCharsets.UTF_8),
          Files.readAllBytes(project.root().resolve(PackageProject.MANIFEST_NAME)),
          project.manifest().name() + " must bind the same raw manifest in native consumers");
      DecodedPackage archive = codec.decode(project.archive());
      assertEquals(project.manifest().identity(), archive.manifest().identity());
      assertNull(archives.put(archive.manifest().name(), archive));
      projects.add(project);
    }

    List<Executable> checks = new ArrayList<>();
    for (PackageProject project : projects) {
      Path lockPath = project.root().resolve(PackageLock.FILE_NAME);
      if (Files.exists(lockPath) || !project.manifest().dependencies().isEmpty()) {
        checks.add(() -> {
          var lock = new PackageLockParser().parse(Files.readAllBytes(lockPath));
          assertEquals(project.manifest().identity(), lock.rootManifestIdentity(),
              project.manifest().name());
          LockedPackageSet.loadWorkspaceMembers(project.root(), project.manifest(), archives);
        });
      }
    }
    assertFalse(checks.isEmpty(), "the maintained workspace has locked dependencies");
    assertAll("canonical workspace locks", checks);
  }
}
