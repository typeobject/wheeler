package com.typeobject.wheeler.runtime.quantum;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

/** Bounded masked-bit delegation fixture under one explicit narrow threat model. */
public final class DelegatedComputationSession {
  public enum Protocol {
    MASKED_NOT_V1
  }

  public enum ThreatModel {
    HONEST_BUT_CURIOUS_SINGLE_PROVIDER
  }

  /** Provider-visible request with no client mask or opening nonce. */
  public record Request(
      Protocol protocol,
      ThreatModel threatModel,
      String taskIdentity,
      String secretCommitment,
      boolean blindedInput,
      String challengeIdentity,
      String identity) {
    public Request {
      if (protocol == null || threatModel == null || !lowerHex(taskIdentity)
          || !lowerHex(secretCommitment) || !lowerHex(challengeIdentity)
          || !identity.equals(requestIdentity(
              protocol,
              threatModel,
              taskIdentity,
              secretCommitment,
              blindedInput,
              challengeIdentity))) {
        throw new IllegalArgumentException("delegated request is invalid");
      }
    }
  }

  /** Provider response bound to the request and public verification challenge. */
  public record ProviderResult(
      String requestIdentity,
      boolean blindedOutput,
      String verificationTag,
      String identity) {
    public ProviderResult {
      if (!lowerHex(requestIdentity) || !lowerHex(verificationTag)
          || !identity.equals(resultIdentity(
              requestIdentity, blindedOutput, verificationTag))) {
        throw new IllegalArgumentException("delegated provider result is invalid");
      }
    }
  }

  /** Accepted client output and transcript identity, never a privacy theorem. */
  public record VerificationResult(
      boolean output,
      String requestIdentity,
      String providerResultIdentity,
      String transcriptIdentity) {
    public VerificationResult {
      if (!lowerHex(requestIdentity) || !lowerHex(providerResultIdentity)
          || !lowerHex(transcriptIdentity)) {
        throw new IllegalArgumentException("delegated verification result is invalid");
      }
    }
  }

  private final boolean secret;
  private final boolean mask;
  private final Request request;
  private boolean consumed;

  private DelegatedComputationSession(boolean secret, boolean mask, Request request) {
    this.secret = secret;
    this.mask = mask;
    this.request = request;
  }

  /** Prepares one masked NOT request under an explicit client-owned mask and opening nonce. */
  public static DelegatedComputationSession prepare(
      boolean secret,
      boolean mask,
      String secretOpeningNonceIdentity,
      String challengeIdentity) {
    if (!lowerHex(secretOpeningNonceIdentity) || !lowerHex(challengeIdentity)) {
      throw new IllegalArgumentException("delegated client identities are invalid");
    }
    Protocol protocol = Protocol.MASKED_NOT_V1;
    ThreatModel threatModel = ThreatModel.HONEST_BUT_CURIOUS_SINGLE_PROVIDER;
    String taskIdentity = digest("wheeler-delegated-task-1\nnot\n");
    String commitment = digest("wheeler-delegated-secret-commitment-1\n"
        + secretOpeningNonceIdentity + '\n' + bit(secret) + '\n');
    boolean blinded = secret ^ mask;
    String identity = requestIdentity(
        protocol,
        threatModel,
        taskIdentity,
        commitment,
        blinded,
        challengeIdentity);
    return new DelegatedComputationSession(
        secret,
        mask,
        new Request(
            protocol,
            threatModel,
            taskIdentity,
            commitment,
            blinded,
            challengeIdentity,
            identity));
  }

  public Request request() {
    return request;
  }

  /** Executes the accepted honest-provider NOT operation over the blinded bit. */
  public static ProviderResult evaluateNot(Request request) {
    boolean blindedOutput = !request.blindedInput();
    String tag = verificationTag(
        request.identity(), request.challengeIdentity(), blindedOutput);
    return new ProviderResult(
        request.identity(),
        blindedOutput,
        tag,
        resultIdentity(request.identity(), blindedOutput, tag));
  }

  /** Verifies and unmasks one exact provider result once. */
  public synchronized VerificationResult verify(ProviderResult result) {
    if (consumed) {
      throw new IllegalStateException("delegated result was already consumed");
    }
    if (!result.requestIdentity().equals(request.identity())) {
      throw new IllegalArgumentException("delegated result belongs to another request");
    }
    String expectedTag = verificationTag(
        request.identity(), request.challengeIdentity(), result.blindedOutput());
    if (!expectedTag.equals(result.verificationTag())) {
      throw new IllegalArgumentException("delegated verification tag mismatch");
    }
    boolean output = result.blindedOutput() ^ mask;
    if (output == secret) {
      throw new IllegalArgumentException("delegated NOT relation failed");
    }
    consumed = true;
    String transcript = digest("wheeler-delegated-transcript-1\n"
        + request.identity() + '\n' + result.identity() + '\n' + bit(output) + '\n');
    return new VerificationResult(output, request.identity(), result.identity(), transcript);
  }

  private static String requestIdentity(
      Protocol protocol,
      ThreatModel threatModel,
      String taskIdentity,
      String commitment,
      boolean blindedInput,
      String challengeIdentity) {
    return digest("wheeler-delegated-request-1\n" + protocol.name() + '\n'
        + threatModel.name() + '\n' + taskIdentity + '\n' + commitment + '\n'
        + bit(blindedInput) + '\n' + challengeIdentity + '\n');
  }

  private static String verificationTag(
      String requestIdentity, String challengeIdentity, boolean blindedOutput) {
    return digest("wheeler-delegated-verification-tag-1\n" + requestIdentity + '\n'
        + challengeIdentity + '\n' + bit(blindedOutput) + '\n');
  }

  private static String resultIdentity(
      String requestIdentity, boolean blindedOutput, String verificationTag) {
    return digest("wheeler-delegated-result-1\n" + requestIdentity + '\n'
        + bit(blindedOutput) + '\n' + verificationTag + '\n');
  }

  private static String bit(boolean value) {
    return value ? "1" : "0";
  }

  private static boolean lowerHex(String value) {
    return value != null && value.length() == 64
        && value.chars().allMatch(character -> character >= '0' && character <= '9'
            || character >= 'a' && character <= 'f');
  }

  private static String digest(String canonical) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(
          canonical.getBytes(StandardCharsets.US_ASCII)));
    } catch (NoSuchAlgorithmException impossible) {
      throw new IllegalStateException("SHA-256 is unavailable", impossible);
    }
  }
}
