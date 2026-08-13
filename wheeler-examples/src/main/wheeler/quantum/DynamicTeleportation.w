//! Transfers one prepared basis bit through target-resident measurement and correction.
quantum class DynamicTeleportation {
  state long measured = 0;
  qreg q = new qreg(3);

  /// Prepares a Bell pair and applies both measured corrections without a host split.
  dynamic void teleport() {
    prepare(q, 1);
    H(q[1]);
    CNOT(q[1], q[2]);
    CNOT(q[0], q[1]);
    H(q[0]);
    measure(q[0], 0);
    measure(q[1], 1);
    applyIf(1, true, X, q[2]);
    applyIf(0, true, Z, q[2]);
  }

  /// Runs the bounded teleportation fixture.
  entry void main() {
    teleport();
  }
}
