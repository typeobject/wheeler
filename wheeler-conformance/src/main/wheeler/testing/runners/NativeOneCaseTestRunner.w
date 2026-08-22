//! Executes one bounded artifact and publishes its passing profile-2 report identity.

module wheeler.conformance.testing.runners.native_one_case_test_runner;

import wheeler.runtime.testing.test_artifact_report;

classical class NativeOneCaseTestRunner {
  entry void main(borrow byteview artifact, borrow mut bytes output) {
    region metadata = new region(/* bytes= */ 200, /* allocations= */ 6);
    bytes runner = allocateBytes(metadata, /* length= */ 64);
    writeAscii(
      runner,
      /* offset= */ 0,
      "0000000000000000000000000000000000000000000000000000000000000001"
    );
    bytes packageName = allocateBytes(metadata, /* length= */ 3);
    writeAscii(packageName, /* offset= */ 0, "pkg");
    bytes packageVersion = allocateBytes(metadata, /* length= */ 1);
    writeAscii(packageVersion, /* offset= */ 0, "1");
    bytes target = allocateBytes(metadata, /* length= */ 4);
    writeAscii(target, /* offset= */ 0, "test");
    bytes caseIdentity = allocateBytes(metadata, /* length= */ 64);
    writeAscii(
      caseIdentity,
      /* offset= */ 0,
      "0000000000000000000000000000000000000000000000000000000000000002"
    );
    bytes sourceIdentity = allocateBytes(metadata, /* length= */ 64);
    writeAscii(
      sourceIdentity,
      /* offset= */ 0,
      "0000000000000000000000000000000000000000000000000000000000000003"
    );
    long length = deriveArtifactReportIdentity(
      artifact,
      runner,
      packageName,
      packageVersion,
      target,
      caseIdentity,
      sourceIdentity,
      output
    );
    setOutputLength(output, length);
    drop(sourceIdentity);
    drop(caseIdentity);
    drop(target);
    drop(packageVersion);
    drop(packageName);
    drop(runner);
    drop(metadata);
  }
}
