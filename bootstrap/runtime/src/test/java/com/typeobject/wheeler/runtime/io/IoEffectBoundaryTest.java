package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.runtime.io.DeterministicIo.Delivery;
import java.lang.reflect.Modifier;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

/** Exercises explicit live-I/O and compensation rewind horizons. */
final class IoEffectBoundaryTest {
  private static final IoLimits LIMITS = new IoLimits(4, 4, 4, 4, 4, 16);

  @Test
  void acceptingLiveIoRetainsCurrentStateAndCutsTheRewindTail() {
    VirtualMachine machine = machine();
    machine.step();
    assertEquals(1, machine.historySize());
    IoCompletion<Integer> completion;
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      completion = scope.await(IoRequest.prepare(
          "effect:live", 1, () -> IoProviderResult.success(7, 1)));
    }

    IoEffectBoundary boundary = IoEffectBoundary.acceptLive(machine, completion);
    assertEquals(IoEffectBoundary.Kind.LIVE_IO, boundary.kind());
    assertEquals(completion.operationId(), boundary.operationId());
    assertEquals(0, machine.historySize());
    assertThrows(VmTrap.class, machine::rewindOne);
    assertEquals(1, machine.global("value"));
  }

  @Test
  void compensationIsANewPurelyPreparedEffectWithItsOwnBoundary() {
    VirtualMachine machine = machine();
    IoCompletion<Integer> original;
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      original = scope.await(IoRequest.prepare(
          "effect:original", 1, () -> IoProviderResult.success(1, 1)));
    }
    IoEffectBoundary.acceptLive(machine, original);
    machine.step();
    AtomicInteger actions = new AtomicInteger();
    IoRequest<IoCompensation.Receipt> request = IoCompensation.prepare(
        original,
        "undo-publication",
        1,
        () -> IoProviderResult.success("a".repeat(64), actions.incrementAndGet()));
    assertEquals(0, actions.get());

    IoCompletion<IoCompensation.Receipt> completion;
    try (IoScope scope = new CompletionIo(1, 4).scope(LIMITS)) {
      completion = scope.await(request);
    }
    assertEquals(1, actions.get());
    assertEquals(original.operationId(), completion.value().originalOperationId());
    assertFalse(DurabilityReceipt.class.isInstance(completion.value()));
    IoEffectBoundary boundary = IoCompensation.accept(machine, completion);
    assertEquals(IoEffectBoundary.Kind.COMPENSATION, boundary.kind());
    assertEquals(0, machine.historySize());
    assertThrows(VmTrap.class, machine::rewindOne);
    assertEquals(1, machine.global("value"));
    assertFalse(Modifier.isPublic(
        IoCompensation.Receipt.class.getDeclaredConstructors()[0].getModifiers()));
  }

  @Test
  void failedCompensationCannotEstablishAnAcceptedBoundary() {
    VirtualMachine machine = machine();
    machine.step();
    IoCompletion<Integer> original;
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      original = scope.await(IoRequest.prepare(
          "effect:failed-original", 1, () -> IoProviderResult.success(1, 1)));
    }
    IoCompletion<IoCompensation.Receipt> failed;
    try (IoScope scope = new DeterministicIo(Delivery.INLINE).scope(LIMITS)) {
      failed = scope.await(IoCompensation.prepare(
          original,
          "failed-compensation",
          1,
          () -> IoProviderResult.failure("compensation-rejected", 0)));
    }
    assertThrows(IllegalArgumentException.class, () -> IoCompensation.accept(machine, failed));
    assertEquals(1, machine.historySize());
  }

  private static VirtualMachine machine() {
    FunctionBody main = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(
            Instruction.of(Opcode.ADD_CONST, 0, 1),
            Instruction.of(Opcode.ADD_CONST, 0, 1),
            Instruction.of(Opcode.HALT)),
        List.of());
    return new VirtualMachine(new Program(
        "IoEffect", 0, List.of(new Global("value", 0)), List.of(main)));
  }
}
