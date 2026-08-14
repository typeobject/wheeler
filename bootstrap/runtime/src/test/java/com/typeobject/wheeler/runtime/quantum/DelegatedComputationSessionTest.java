package com.typeobject.wheeler.runtime.quantum;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import org.junit.jupiter.api.Test;

/** Masked delegation keeps client openings private and binds one verified transcript. */
final class DelegatedComputationSessionTest {
  private static final String NONCE =
      "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
  private static final String CHALLENGE =
      "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789";

  @Test
  void honestProviderComputesMaskedNotAndClientConsumesOneVerifiedTranscript() {
    DelegatedComputationSession session =
        DelegatedComputationSession.prepare(true, false, NONCE, CHALLENGE);
    DelegatedComputationSession.Request request = session.request();
    DelegatedComputationSession.ProviderResult provider =
        DelegatedComputationSession.evaluateNot(request);

    DelegatedComputationSession.VerificationResult verified = session.verify(provider);

    assertFalse(verified.output());
    assertEquals(request.identity(), verified.requestIdentity());
    assertEquals(provider.identity(), verified.providerResultIdentity());
    assertThrows(IllegalStateException.class, () -> session.verify(provider));
  }

  @Test
  void maskedRequestHidesOpeningAndWrongRelationFailsDespiteSelfConsistentEnvelope()
      throws Exception {
    DelegatedComputationSession first =
        DelegatedComputationSession.prepare(false, true, NONCE, CHALLENGE);
    DelegatedComputationSession second = DelegatedComputationSession.prepare(
        true,
        false,
        "1111111111111111111111111111111111111111111111111111111111111111",
        CHALLENGE);
    assertTrue(first.request().blindedInput());
    assertTrue(second.request().blindedInput());
    assertNotEquals(first.request().secretCommitment(), second.request().secretCommitment());

    boolean wrongOutput = first.request().blindedInput();
    String tag = digest("wheeler-delegated-verification-tag-1\n"
        + first.request().identity() + '\n' + CHALLENGE + "\n1\n");
    String resultIdentity = digest("wheeler-delegated-result-1\n"
        + first.request().identity() + "\n1\n" + tag + '\n');
    DelegatedComputationSession.ProviderResult wrong =
        new DelegatedComputationSession.ProviderResult(
            first.request().identity(), wrongOutput, tag, resultIdentity);

    assertThrows(IllegalArgumentException.class, () -> first.verify(wrong));
  }

  private static String digest(String canonical) throws Exception {
    return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(
        canonical.getBytes(StandardCharsets.US_ASCII)));
  }
}
