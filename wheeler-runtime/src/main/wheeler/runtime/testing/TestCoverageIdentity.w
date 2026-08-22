//! Derives profile-2 identities from canonical bounded coverage reports.

module wheeler.runtime.testing.test_coverage_identity;

import wheeler.crypto.sha256;

classical class TestCoverageIdentity {
  private const long DOMAIN_BYTES = 30;
  private const long HASH_ARENA_BYTES = 1088;
  private const long MAX_REPORT_BYTES = 32768;
  private const long OUTPUT_BYTES = 32;
  private const long STAGING_BYTES = 33886;

  /// Writes the raw stage-0 identity of one canonical transition coverage report.
  public long deriveTestCoverageIdentity(borrow byteview report, borrow mut bytes output) {
    assert(bufferLength(output) == OUTPUT_BYTES);
    assert(bufferLength(report) < MAX_REPORT_BYTES + 1);
    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 4);
    bytes transcript = allocateBytes(staging, DOMAIN_BYTES + MAX_REPORT_BYTES);
    writeAscii(transcript, /* offset= */ 0, "wheeler-transition-coverage-1");
    setByte(transcript, /* index= */ 29, /* value= */ 0);
    long offset = 0;
    while (offset < bufferLength(report)) limit MAX_REPORT_BYTES {
      setByte(transcript, DOMAIN_BYTES + offset, report[offset]);
      offset += 1;
    }

    hashSha256Range(
      transcript,
      /* inputStart= */ 0,
      DOMAIN_BYTES + bufferLength(report),
      output,
      staging
    );
    drop(transcript);
    drop(staging);
    return OUTPUT_BYTES;
  }
}
