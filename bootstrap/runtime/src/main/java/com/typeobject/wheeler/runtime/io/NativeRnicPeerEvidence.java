package com.typeobject.wheeler.runtime.io;

import com.typeobject.wheeler.runtime.io.NativeRnicRegistry.Registration;

/** Ordered native RNIC peer evidence above local write completion. */
public final class NativeRnicPeerEvidence {
  /** Peer protocol acknowledgement of one exact native write completion. */
  public static final class Acknowledgement {
    private final NativeRnicCompletion.Write write;
    private final String evidenceIdentity;
    private final String identity;

    private Acknowledgement(
        NativeRnicCompletion.Write write,
        String evidenceIdentity,
        String identity) {
      this.write = write;
      this.evidenceIdentity = evidenceIdentity;
      this.identity = identity;
    }

    /** Returns the acknowledged native write completion. */
    public NativeRnicCompletion.Write write() {
      return write;
    }

    /** Returns the backend peer-acknowledgement evidence identity. */
    public String evidenceIdentity() {
      return evidenceIdentity;
    }

    /** Returns the canonical acknowledgement identity. */
    public String identity() {
      return identity;
    }
  }

  /** Peer application acceptance after exact protocol acknowledgement. */
  public static final class Application {
    private final Acknowledgement acknowledgement;
    private final String evidenceIdentity;
    private final String identity;

    private Application(
        Acknowledgement acknowledgement,
        String evidenceIdentity,
        String identity) {
      this.acknowledgement = acknowledgement;
      this.evidenceIdentity = evidenceIdentity;
      this.identity = identity;
    }

    /** Returns the exact preceding peer acknowledgement. */
    public Acknowledgement acknowledgement() {
      return acknowledgement;
    }

    /** Returns the backend peer-application evidence identity. */
    public String evidenceIdentity() {
      return evidenceIdentity;
    }

    /** Returns the canonical application identity. */
    public String identity() {
      return identity;
    }
  }

  /** Profile-bound remote persistence after peer application acceptance. */
  public static final class Persistence {
    private final Application application;
    private final String profileIdentity;
    private final String evidenceIdentity;
    private final String identity;

    private Persistence(
        Application application,
        String profileIdentity,
        String evidenceIdentity,
        String identity) {
      this.application = application;
      this.profileIdentity = profileIdentity;
      this.evidenceIdentity = evidenceIdentity;
      this.identity = identity;
    }

    /** Returns the exact preceding peer application acceptance. */
    public Application application() {
      return application;
    }

    /** Returns the exact remote-persistence profile identity. */
    public String profileIdentity() {
      return profileIdentity;
    }

    /** Returns the backend remote-persistence evidence identity. */
    public String evidenceIdentity() {
      return evidenceIdentity;
    }

    /** Returns the canonical remote-persistence identity. */
    public String identity() {
      return identity;
    }
  }

  private NativeRnicPeerEvidence() {}

  static Acknowledgement acknowledgement(
      NativeRnicCompletion.Write write,
      String evidenceIdentity,
      String identity) {
    return new Acknowledgement(write, evidenceIdentity, identity);
  }

  static Application application(
      Acknowledgement acknowledgement,
      String evidenceIdentity,
      String identity) {
    return new Application(acknowledgement, evidenceIdentity, identity);
  }

  static Persistence persistence(
      Application application,
      String profileIdentity,
      String evidenceIdentity,
      String identity) {
    return new Persistence(application, profileIdentity, evidenceIdentity, identity);
  }

  static Registration registration(Acknowledgement acknowledgement) {
    return acknowledgement.write.registration();
  }

  static Registration registration(Application application) {
    return registration(application.acknowledgement);
  }
}
