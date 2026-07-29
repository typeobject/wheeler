//! Executes the bounded scalar result-slot primitives used by the native interpreter.
module wheeler.runtime.result_slots;

classical class ResultSlots {
  /// Checks the canonical two-register representation accepted at a return boundary.
  public boolean resultSlotCanonical(long tag, long payload) {
    if (tag == 0) {
      return payload == 0;
    }

    return tag == 1;
  }

  /// Exchanges exact vacancy with one held signed constant.
  ///
  /// - Effects: Mutates both adjacent slot registers only after complete validation.
  public boolean exchangeResultConstant(borrow mut words locals, long slot, long constant) {
    long tag = locals[slot];
    long payload = locals[slot + 1];
    if (tag == 0) {
      if (payload == 0) {
        set(locals, slot, 1);
        set(locals, slot + 1, constant);
        return true;
      }

      return false;
    }

    if (tag == 1) {
      if (payload == constant) {
        set(locals, slot, 0);
        set(locals, slot + 1, 0);
        return true;
      }
    }

    return false;
  }
}
