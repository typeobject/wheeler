//! Executes one bounded artifact and publishes its passing profile-2 report identity.

module wheeler.conformance.testing.native_one_case_test_runner;

import wheeler.runtime.testing.test_artifact_report;

classical class NativeOneCaseTestRunner {
  entry void main(borrow byteview artifact, borrow mut bytes output) {
    region metadata = new region(/* bytes= */ 236, /* allocations= */ 8);
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
    bytes failureCode = allocateBytes(metadata, /* length= */ 8);
    writeAscii(failureCode, /* offset= */ 0, "WTEST003");
    bytes failureMessage = allocateBytes(metadata, /* length= */ 28);
    writeAscii(failureMessage, /* offset= */ 0, "native test assertion failed");
    long length = deriveArtifactReportIdentity(
      artifact,
      runner,
      packageName,
      packageVersion,
      target,
      caseIdentity,
      sourceIdentity,
      failureCode,
      failureMessage,
      output
    );
    setOutputLength(output, length);
    drop(failureMessage);
    drop(failureCode);
    drop(sourceIdentity);
    drop(caseIdentity);
    drop(target);
    drop(packageVersion);
    drop(packageName);
    drop(runner);
    drop(metadata);
  }
}
