package com.typeobject.wheeler.runtime.io;

import com.typeobject.wheeler.runtime.io.NativeRnicRegistry.Registration;

/** Unforgeable native RNIC completion authorities below peer and persistence stages. */
public final class NativeRnicCompletion {
  /** Exact native completion of one 64-bit compare-and-swap. */
  public static final class Atomic {
    private final Registration registration;
    private final int relativeOffset;
    private final long expected;
    private final long update;
    private final long observed;
    private final String evidenceIdentity;
    private final String identity;

    private Atomic(
        Registration registration,
        int relativeOffset,
        long expected,
        long update,
        long observed,
        String evidenceIdentity,
        String identity) {
      this.registration = registration;
      this.relativeOffset = relativeOffset;
      this.expected = expected;
      this.update = update;
      this.observed = observed;
      this.evidenceIdentity = evidenceIdentity;
      this.identity = identity;
    }

    /** Returns the exact target registration. */
    public Registration registration() {
      return registration;
    }

    /** Returns the first registration-relative atomic byte. */
    public int relativeOffset() {
      return relativeOffset;
    }

    /** Returns the requested comparison value. */
    public long expected() {
      return expected;
    }

    /** Returns the requested replacement value. */
    public long update() {
      return update;
    }

    /** Returns the value observed by the native atomic operation. */
    public long observed() {
      return observed;
    }

    /** Reports whether the comparison admitted the replacement. */
    public boolean exchanged() {
      return observed == expected;
    }

    /** Returns the backend completion evidence identity. */
    public String evidenceIdentity() {
      return evidenceIdentity;
    }

    /** Returns the canonical native atomic-completion identity. */
    public String identity() {
      return identity;
    }
  }

  /** Exact native completion of one one-sided read. */
  public static final class Read {
    private final Registration registration;
    private final int relativeOffset;
    private final int bytes;
    private final String contentIdentity;
    private final String evidenceIdentity;
    private final String identity;

    private Read(
        Registration registration,
        int relativeOffset,
        int bytes,
        String contentIdentity,
        String evidenceIdentity,
        String identity) {
      this.registration = registration;
      this.relativeOffset = relativeOffset;
      this.bytes = bytes;
      this.contentIdentity = contentIdentity;
      this.evidenceIdentity = evidenceIdentity;
      this.identity = identity;
    }

    /** Returns the exact source registration. */
    public Registration registration() {
      return registration;
    }

    /** Returns the first registration-relative byte read. */
    public int relativeOffset() {
      return relativeOffset;
    }

    /** Returns the exact completed byte count. */
    public int bytes() {
      return bytes;
    }

    /** Returns the exact received-content identity. */
    public String contentIdentity() {
      return contentIdentity;
    }

    /** Returns the backend completion evidence identity. */
    public String evidenceIdentity() {
      return evidenceIdentity;
    }

    /** Returns the canonical native read-completion identity. */
    public String identity() {
      return identity;
    }
  }

  /** Exact native completion of one one-sided write. */
  public static final class Write {
    private final Registration registration;
    private final int relativeOffset;
    private final int bytes;
    private final String contentIdentity;
    private final String evidenceIdentity;
    private final String identity;

    private Write(
        Registration registration,
        int relativeOffset,
        int bytes,
        String contentIdentity,
        String evidenceIdentity,
        String identity) {
      this.registration = registration;
      this.relativeOffset = relativeOffset;
      this.bytes = bytes;
      this.contentIdentity = contentIdentity;
      this.evidenceIdentity = evidenceIdentity;
      this.identity = identity;
    }

    /** Returns the exact target registration. */
    public Registration registration() {
      return registration;
    }

    /** Returns the first registration-relative byte written. */
    public int relativeOffset() {
      return relativeOffset;
    }

    /** Returns the exact completed byte count. */
    public int bytes() {
      return bytes;
    }

    /** Returns the exact source-content identity. */
    public String contentIdentity() {
      return contentIdentity;
    }

    /** Returns the backend completion evidence identity. */
    public String evidenceIdentity() {
      return evidenceIdentity;
    }

    /** Returns the canonical native write-completion identity. */
    public String identity() {
      return identity;
    }
  }

  private NativeRnicCompletion() {}

  static Atomic atomic(
      Registration registration,
      int relativeOffset,
      long expected,
      long update,
      long observed,
      String evidenceIdentity,
      String identity) {
    return new Atomic(
        registration,
        relativeOffset,
        expected,
        update,
        observed,
        evidenceIdentity,
        identity);
  }

  static Read read(
      Registration registration,
      int relativeOffset,
      int bytes,
      String contentIdentity,
      String evidenceIdentity,
      String identity) {
    return new Read(
        registration,
        relativeOffset,
        bytes,
        contentIdentity,
        evidenceIdentity,
        identity);
  }

  static Write write(
      Registration registration,
      int relativeOffset,
      int bytes,
      String contentIdentity,
      String evidenceIdentity,
      String identity) {
    return new Write(
        registration,
        relativeOffset,
        bytes,
        contentIdentity,
        evidenceIdentity,
        identity);
  }
}
