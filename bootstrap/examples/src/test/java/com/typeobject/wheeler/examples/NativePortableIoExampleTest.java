package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Executes the Wheeler-owned nominal portable I/O API over its lifecycle kernel. */
final class NativePortableIoExampleTest {
  @Test
  void sourceOwnsRequestCompletionQueueReapAndEffectLowering() throws Exception {
    Program program = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "Lifecycle.w", RuntimeSources.read("runtime/io/Lifecycle.w"),
            "Portable.w", RuntimeSources.read("runtime/io/Portable.w"),
            "PortableIoExample.w", """
                module example.portable_io;

                import wheeler.runtime.io.lifecycle;
                import wheeler.runtime.io.portable;

                classical class PortableIoExample {
                  state long operationIdentity = 0;
                  state long completionProgress = 0;
                  state long queuedOperation = 0;
                  state long boundaryKind = 0;
                  state long reapedOperation = 0;

                  entry void main() {
                    region arena = new region(8192, 8);
                    words states = allocate(arena, 64);
                    words work = allocate(arena, 64);
                    words progress = allocate(arena, 64);
                    words terminalKinds = allocate(arena, 64);
                    words cancellationRelations = allocate(arena, 64);
                    words resourcesReleased = allocate(arena, 64);
                    words reaped = allocate(arena, 64);
                    words queueValues = allocate(arena, 4);
                    Request request = new Request(77, 5);
                    Scope scope = new Scope(4, 32);
                    Admission admission = admitRequest(
                      request,
                      scope,
                      states,
                      work,
                      progress,
                      terminalKinds,
                      cancellationRelations,
                      resourcesReleased,
                      reaped,
                      0,
                      0
                    );
                    match (admission) {
                      case Admission.Rejected() {
                        operationIdentity = -1;
                      }
                      case Admission.Accepted(
                        Operation acceptedOperation,
                        long acceptedCount,
                        long acceptedWork
                      ) {
                        operationIdentity = acceptedOperation.identity;
                        assert(acceptedCount == 1);
                        assert(acceptedWork == 5);
                        Completion completion = publishCompletion(
                          acceptedOperation,
                          IO_TERMINAL_SUCCESS,
                          IO_CANCEL_NOT_REQUESTED,
                          5,
                          true,
                          states,
                          work,
                          progress,
                          terminalKinds,
                          cancellationRelations,
                          resourcesReleased,
                          reaped
                        );
                        match (completion) {
                          case Completion.Success(
                            Operation successOperation,
                            long successProgress,
                            long successWork,
                            boolean successReleased
                          ) {
                            completionProgress = successProgress;
                            assert(successOperation.identity == acceptedOperation.identity);
                            assert(successWork == 5);
                            assert(successReleased);
                          }
                          case Completion.Failure(
                            Operation failureOperation,
                            long failureProgress,
                            long failureWork,
                            boolean failureReleased
                          ) {
                            completionProgress = failureProgress + failureWork;
                            assert(failureReleased);
                            operationIdentity = failureOperation.identity;
                          }
                          case Completion.Canceled(
                            Operation canceledOperation,
                            long canceledRelation,
                            long canceledProgress,
                            long canceledWork,
                            boolean canceledReleased
                          ) {
                            completionProgress = canceledProgress + canceledWork;
                            assert(canceledReleased);
                            operationIdentity = canceledOperation.identity + canceledRelation;
                          }
                          case Completion.Uncertain(
                            Operation uncertainOperation,
                            long uncertainRelation,
                            long uncertainProgress,
                            long uncertainWork,
                            boolean uncertainReleased
                          ) {
                            completionProgress = uncertainProgress + uncertainWork;
                            assert(uncertainReleased);
                            operationIdentity = uncertainOperation.identity + uncertainRelation;
                          }
                        }

                        CompletionQueue empty = new CompletionQueue(0, 0, 4);
                        QueuePush pushed = pushOperation(
                          queueValues,
                          empty,
                          acceptedOperation
                        );
                        match (pushed) {
                          case QueuePush.Full(CompletionQueue fullQueue) {
                            queuedOperation = fullQueue.tail + 100;
                          }
                          case QueuePush.Value(CompletionQueue queued) {
                            QueuePop popped = popOperation(queueValues, queued);
                            match (popped) {
                              case QueuePop.Empty(CompletionQueue emptyQueue) {
                                queuedOperation = emptyQueue.head + 100;
                              }
                              case QueuePop.Value(
                                Operation poppedOperation,
                                CompletionQueue remaining
                              ) {
                                queuedOperation = poppedOperation.identity;
                                assert(remaining.head == remaining.tail);
                              }
                            }
                          }
                        }

                        EffectLowering lowering = lowerEffect(completion);
                        match (lowering) {
                          case EffectLowering.Reversible() {
                            boundaryKind = -1;
                          }
                          case EffectLowering.Live(EffectBoundary boundary) {
                            boundaryKind = boundary.terminalKind;
                            assert(boundary.operation == acceptedOperation.identity);
                            assert(boundary.progress == 5);
                            assert(boundary.declaredWork == 5);
                          }
                        }

                        if (reapOperation(
                          acceptedOperation,
                          states,
                          resourcesReleased,
                          reaped
                        )) {
                          reapedOperation = acceptedOperation.identity;
                        }
                      }
                    }

                    assert(operationIdentity == 0);
                    assert(completionProgress == 5);
                    assert(queuedOperation == 0);
                    assert(boundaryKind == IO_TERMINAL_SUCCESS);
                    assert(reapedOperation == 0);
                    assert(scopeCanClose(states, 1));
                    drop(queueValues);
                    drop(reaped);
                    drop(resourcesReleased);
                    drop(cancellationRelations);
                    drop(terminalKinds);
                    drop(progress);
                    drop(work);
                    drop(states);
                    drop(arena);
                  }
                }
                """),
        "example.portable_io");
    VirtualMachine machine = new VirtualMachine(program);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(0, machine.global("operationIdentity"));
    assertEquals(5, machine.global("completionProgress"));
    assertEquals(0, machine.global("queuedOperation"));
    assertEquals(1, machine.global("boundaryKind"));
    assertEquals(0, machine.global("reapedOperation"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }
}
