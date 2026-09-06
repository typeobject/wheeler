# Wheeler

Wheeler is an experimental language and runtime for reversible classical
computation, coherent quantum programs, and recoverable hybrid workflows. The
current VM is deterministic and single-task.

Generated inverses, history-based rewind, quantum adjoints, and observation
replay have separate contracts. An inverse executes new operations. Rewind needs
retained history. Replay reuses observations and does not restore quantum state.

## Capabilities

“Accepted” means implemented within the linked profile, not production-ready.
The checks below establish specific behavior, not a release-wide correctness
proof. The Java bootstrap remains part of the development and execution path.

| Capability | Status and implementation | Contract and limits | Example and automated checks |
| --- | --- | --- | --- |
| Classical execution and generated inverses | Accepted, Java compiler and VM | [Checked signed arithmetic and restricted reversible bodies](docs/public/reference/language-profile.md). Scalar result slots support selected parameterized relations. | [Counter](wheeler-examples/src/main/wheeler/classical/control/Counter.w), [result-slot tests](bootstrap/stage0/src/test/java/com/typeobject/wheeler/compiler/ReversibleResultSlotSourceTest.java). |
| History-based rewind | Accepted, Java VM | [Complete VM state restoration within retained history](docs/public/reference/virtual-machine.md). Commit closes the earlier rewind horizon, not the generated inverse. | [VM tests](bootstrap/core/src/test/java/com/typeobject/wheeler/core/vm). |
| Coherent execution and adjoints | Bounded, Java compiler and ideal simulator | [Finite-width permutations and ideal quantum gates](docs/public/reference/quantum-targets.md#ideal-state-vector-target). Modular coherent arithmetic differs from checked classical arithmetic. | [CoherentOracle](wheeler-examples/src/main/wheeler/quantum/CoherentOracle.w), [QFT](wheeler-examples/src/main/wheeler/quantum/QFT.w), [quantum examples](bootstrap/examples/src/test/java/com/typeobject/wheeler/examples/QuantumExamplesTest.java). |
| External quantum targets | Experimental, Java adapters and OpenQASM emission | [Application-supplied executors](docs/public/reference/quantum-targets.md). Simulator agreement and emitted QASM are not hardware evidence. | [Adapter tests](bootstrap/runtime/src/test/java/com/typeobject/wheeler/runtime/quantum/OpenQasmTargetTest.java). |
| Hybrid recovery and replay | Bounded, Java runtime | [Acknowledged jobs and accepted observations](docs/public/reference/hybrid-runs.md). No power-loss durability or universal exactly-once execution guarantee. | [Recovery and mock-provider tests](bootstrap/runtime/src/test/java/com/typeobject/wheeler/runtime/hybrid/HybridRunTest.java). |
| Proof certificates | Accepted, Java. Bounded, Wheeler. | [Four finite structural rules](docs/public/reference/bytecode.md#proof-certificates), not arbitrary program or hardware correctness. Step certificates reject every call form. | [CertifiedInverseBounds](wheeler-examples/src/main/wheeler/proof/CertifiedInverseBounds.w), [kernel regression](bootstrap/core/src/test/java/com/typeobject/wheeler/core/proof/StaticStepProofTest.java), [native checks](bootstrap/examples/src/test/java/com/typeobject/wheeler/examples/NativeStaticStepProofExampleTest.java). |
| Wheeler-written compiler and interpreter | Bounded, exercised through the bootstrap VM | [Native profiles and trust boundary](docs/public/reference/bootstrap.md). Selected artifact parity does not establish a compiler fixed point. | [Compiler](wheeler-compiler/src/main/wheeler/MinimalCompiler.w), [native VM checks](bootstrap/examples/src/test/java/com/typeobject/wheeler/examples/NativeVmExampleTest.java). |
| Concurrent tasks | Planned | [Root task only](docs/public/reference/virtual-machine.md#tasks-and-workflow-epoch). No accepted spawn or join forms. | [Task contract](docs/internal/proposals/WIP-0039-deterministic-structured-task-machine-and-global-rewind.md), not an executable concurrency claim. |
| Full self-hosting and Java-free bootstrap | Planned | [Stage equality, recovery, and cutover gates remain open](docs/internal/proposals/self-hosting-status.md). | No completed fixed-point or Java-free acceptance receipt. |

“Verified” names a particular check: artifact well-formedness, a finite
certificate rule, or an executable comparison. None implies general compiler
correctness, algorithm correctness, or physical device fidelity.

## Quickstart

Use Git, JDK 26, and a POSIX shell on Linux or macOS. Set `JAVA_HOME` to that JDK
and put its `bin` directory on `PATH`. The first run needs network access for the
checked-in Gradle wrapper and dependencies. This quickstart does not cover
Windows shells or require a quantum provider.

```bash
git clone https://github.com/typeobject/wheeler.git
cd wheeler
```

Run from the repository root:

<!-- quickstart-command -->
```bash
./bootstrap/gradlew -p bootstrap -q :tools:wheeler --args='run wheeler-examples --target counter'
```

After any first-run downloads, the final output is:

<!-- quickstart-output -->
```text
Counter (classical) halted after 15 steps
count = 0
```

[Counter.w](wheeler-examples/src/main/wheeler/classical/control/Counter.w) calls
`increment` twice, then executes its generated inverse twice. It restores the
counter without consuming saved VM history. This small example is separate from
the full conformance and compiler-integration suites.

The [quickstart check](bootstrap/scripts/check-readme-quickstart.py) reads this
command and expected output directly. Its [CI job](.github/workflows/quickstart.yml)
uses a fresh checkout on Linux and macOS.

Common failures:

- Wrong Java version: check `java -version` and `JAVA_HOME`. The build requires JDK 26.
- Missing source path: run from the cloned repository root, not `bootstrap/`.
- Invalid bytecode magic: `run` accepts bytecode or a package target, not a `.w` source file. Use the package command above.
- Download failure: check network or proxy access before retrying the wrapper.
- Native-access warning: the Gradle launcher may print one on stderr. It is not a failed Wheeler assertion.

## Read next

- [Language profile](docs/public/reference/language-profile.md)
- [Virtual machine](docs/public/reference/virtual-machine.md)
- [Bytecode and certificates](docs/public/reference/bytecode.md)
- [Quantum targets](docs/public/reference/quantum-targets.md)
- [Hybrid recovery](docs/public/reference/hybrid-runs.md)
- [Semantic coverage](docs/public/reference/coverage.md)
- [Development and test guide](docs/public/reference/development.md)
- [Executable conformance](docs/internal/conformance.md)
- [Improvement proposals](docs/internal/proposals/index.mdx)
- [Full documentation](https://wheeler.typeobject.com/)

## License

Wheeler is licensed under the [Apache License 2.0](LICENSE.md).
