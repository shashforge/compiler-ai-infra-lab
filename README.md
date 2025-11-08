# compiler-ai-infra-lab

**Owner:** [@shashforge](https://github.com/shashforge)  
**Purpose:** A public, reproducible **workbench** for my contributions across two ecosystems that top-tier companies care about:

- **Primary (Compiler & AI‑Compiler):** LLVM/MLIR → OpenXLA/XLA → IREE  
- **Secondary (AI Serving & Performance):** Triton Inference Server → TensorRT‑LLM → CUTLASS → NCCL  
- **Optional Rust signal:** Firecracker (Rust VMM) **or** Tokio (async I/O)

This repo contains **scripts, notes, benchmarks, and minimal samples** that reproduce my results and **link to my upstream PRs**. It is **not** a fork of any one project; it is my **personal lab** that others (and hiring panels) can clone and run.

---

## Why these ecosystems?

- **LLVM/MLIR/OpenXLA/IREE** → the long‑horizon backbone for compilers & AI compilers used by **Apple, Google/DeepMind, NVIDIA, AMD, Intel, Arm, Microsoft, Amazon**.  
- **Triton/TensorRT‑LLM/CUTLASS/NCCL** → production AI serving and GPU performance, used across **NVIDIA + MAANG**.  
- **Rust (Firecracker/Tokio)** → demonstrates modern systems safety & async I/O with small, steady PRs.

> **MLIR lives inside the LLVM monorepo.** For MLIR work you branch in `llvm-project` and edit under `mlir/` (not a separate repo).  
> **OpenXLA/XLA and IREE are separate repos** layered on MLIR/LLVM.

---

## Repository layout

```
primary/
  llvm-mlir/          # LLVM/MLIR build scripts + MLIR pass/IR experiments
  openxla-iree/       # XLA/IREE builds, compile+run examples, perf logs
secondary/
  triton-nvidia/      # Triton model repo, TRT-LLM runs, CUTLASS/NCCL benches
rust-signal/          # Firecracker OR Tokio mini-demos + notes
tools/                # helper scripts (env checks, format hooks)
docs/                 # write-ups with commands + numbers + links to PRs
```

---

## Prerequisites (developer workstation)

- Linux (Ubuntu/Debian recommended) or WSL2.  
- Packages: `git build-essential cmake ninja-build python3 python3-pip docker.io`  
- **GPU path:** NVIDIA driver + `nvidia-container-toolkit` (for Triton/TRT‑LLM).  
- **Rust (optional):** `curl https://sh.rustup.rs -sSf | sh`

> Ensure Docker can access the GPU (`nvidia-smi` works *inside* containers).  
> Keep CUDA/NVIDIA drivers aligned with the Triton container tag (see release notes).

---

## Quickstart

```bash
# Clone this lab
git clone https://github.com/shashforge/compiler-ai-infra-lab.git
cd compiler-ai-infra-lab

# (Optional) check environment
bash tools/env_check.sh  # added later; see Tools section

# Build LLVM/MLIR tools (mlir-opt/mlir-translate/clang)
make setup-llvm

# Build IREE tools (iree-compile / iree-run-module)
make setup-iree

# Run Triton quickstart container (requires NVIDIA GPU)
make triton-quickstart

# Build CUTLASS examples/tests
make cutlass-build
```

---

## Upstream projects (where I contribute)

### Compiler & AI‑Compiler
- LLVM (monorepo, includes MLIR): https://github.com/llvm/llvm-project  
- MLIR docs (inside LLVM): https://mlir.llvm.org/getting_started/  
- OpenXLA – XLA site & repo: https://openxla.org/xla • https://github.com/openxla/xla  
- IREE repo & docs: https://github.com/iree-org/iree • https://iree.dev/

### AI Serving & Performance
- Triton Inference Server: https://github.com/triton-inference-server/server  
  Quickstart: https://docs.nvidia.com/deeplearning/triton-inference-server/user-guide/docs/getting_started/quickstart.html  
- TensorRT‑LLM: https://github.com/NVIDIA/TensorRT-LLM  
- CUTLASS: https://github.com/NVIDIA/cutlass  
- NCCL + tests: https://github.com/NVIDIA/nccl • https://github.com/NVIDIA/nccl-tests

### Rust (optional signal)
- Firecracker: https://github.com/firecracker-microvm/firecracker • https://firecracker-microvm.github.io/  
- Tokio: https://github.com/tokio-rs/tokio • https://tokio.rs/tokio/tutorial

---

## Makefile targets

The lab includes a `Makefile` that defaults to building into `$(HOME)/.cail/builds`. You can override with `BUILD_ROOT=/path`.

- `setup-llvm` — clone & build **LLVM+MLIR** (Release + assertions)  
- `check-mlir` — run `ninja check-mlir` tests (if full build tree available)  
- `clone-xla` — clone **OpenXLA/XLA** (build is done via XLA’s dev container / Bazel)  
- `setup-iree` — clone & build **IREE** tools  
- `triton-quickstart` — run **Triton** server in Docker on ports 8000/8001/8002  
- `cutlass-build` — clone & build **CUTLASS** examples/tests  
- `nccl-notes` — clone **NCCL** (and points you to `nccl-tests`)  
- `clean-all` — remove the entire build root (`$(BUILD_ROOT)`)

> OpenXLA/XLA recommends using their **developer container** + Bazel; this Makefile only clones XLA and points to its guide.

---

## Branch & PR workflow (fork → branch → PR)

**Pattern:** fork upstream → add `upstream` remote → create topic branch from `upstream/main` → small PR → link PR in `/docs`.

### LLVM (MLIR is inside)
```bash
# Fork https://github.com/llvm/llvm-project under your account, then:
git clone git@github.com:shashforge/llvm-project.git
cd llvm-project
git remote add upstream https://github.com/llvm/llvm-project.git
git fetch upstream
git checkout -b topic/mlir-<short> upstream/main

# Work under mlir/ (or clang/ for clang-tidy); add tests under mlir/test/...
git clang-format  # or: git clang-format HEAD~1
mkdir -p build && cd build && cmake -G Ninja -DCMAKE_BUILD_TYPE=Release \
 -DLLVM_ENABLE_PROJECTS="clang;mlir" -DLLVM_ENABLE_ASSERTIONS=ON ../llvm
ninja check-mlir

git commit -am "mlir: <area>: <one-line summary>\n\nWhy:\n- ...\nHow:\n- test: ..."
git push -u origin topic/mlir-<short>
# Open PR on GitHub compare page
```

### OpenXLA / XLA
```bash
git clone git@github.com:shashforge/xla.git
cd xla && git remote add upstream https://github.com/openxla/xla.git
git fetch upstream && git checkout -b topic/xla-<short> upstream/main

# Use the official developer container + Bazel (see XLA Developer Guide).
# Make a doc/test tweak or small code fix.
git commit -am "xla: docs(test): <clarify/fix>"
git push -u origin topic/xla-<short>
# Open PR
```

### IREE
```bash
git clone git@github.com:shashforge/iree.git
cd iree && git remote add upstream https://github.com/iree-org/iree.git
git fetch upstream && git checkout -b topic/iree-<short> upstream/main

mkdir -p build && cd build && cmake -G Ninja -DCMAKE_BUILD_TYPE=Release ..
ninja iree-compile iree-run-module

git commit -am "docs: getting-started: fix <flag> / tests: <tiny fix>"
git push -u origin topic/iree-<short>
# Open PR
```

### Triton Inference Server
```bash
git clone git@github.com:shashforge/server.git triton-server
cd triton-server && git remote add upstream https://github.com/triton-inference-server/server.git
git fetch upstream && git checkout -b topic/triton-<short> upstream/main

# Reproduce quickstart; fix a doc path/flag or add a tiny example note
git commit -am "docs: quickstart: clarify model_repository layout + perf_analyzer usage"
git push -u origin topic/triton-<short>
# Open PR
```

### TensorRT‑LLM
```bash
git clone git@github.com:shashforge/TensorRT-LLM.git
cd TensorRT-LLM && git remote add upstream https://github.com/NVIDIA/TensorRT-LLM.git
git fetch upstream && git checkout -b topic/trtllm-<short> upstream/main

git commit -am "docs: quantization flags: clarify <X>"
git push -u origin topic/trtllm-<short>
# Open PR
```

### CUTLASS
```bash
git clone git@github.com:shashforge/cutlass.git
cd cutlass && git remote add upstream https://github.com/NVIDIA/cutlass.git
git fetch upstream && git checkout -b topic/cutlass-<short> upstream/main

git commit -am "docs: bench: add <MxNxK> FP8 example and GFLOPS table"
git push -u origin topic/cutlass-<short>
# Open PR
```

### NCCL (or doc PRs if you lack multi‑GPU)
```bash
git clone git@github.com:shashforge/nccl.git
cd nccl && git remote add upstream https://github.com/NVIDIA/nccl.git
git fetch upstream && git checkout -b topic/nccl-<short> upstream/main

git commit -am "docs: env tuning matrix notes for <arch>"
git push -u origin topic/nccl-<short>
# Open PR
```

### Optional Rust

**Firecracker**
```bash
git clone git@github.com:shashforge/firecracker.git
cd firecracker && git remote add upstream https://github.com/firecracker-microvm/firecracker.git
git fetch upstream && git checkout -b topic/fc-doc-<short> upstream/main
# Some repos require DCO: use -s
git commit -s -am "docs: <tiny fix>"
git push -u origin topic/fc-doc-<short>
# PR
```

**Tokio**
```bash
git clone git@github.com:shashforge/tokio.git
cd tokio && git remote add upstream https://github.com/tokio-rs/tokio.git
git fetch upstream && git checkout -b topic/tokio-<short> upstream/main
cargo fmt -- --check && cargo clippy && cargo test
git commit -am "docs: <example fix>"
git push -u origin topic/tokio-<short>
# PR
```

---

## Repro notebooks & notes in this lab

- `primary/llvm-mlir/README.md` — build steps, MLIR pass pipelines, before/after IR  
- `primary/openxla-iree/README.md` — XLA dev container steps; IREE compile/run examples  
- `secondary/triton-nvidia/README.md` — Triton quickstart, TRT‑LLM run notes, CUTLASS/NCCL benches  
- `docs/` — short blog‑style notes with **commands + numbers**, PR links, and takeaways

---

## Tools (optional convenience)

Add a simple environment check script:

```
tools/env_check.sh
#!/usr/bin/env bash
set -euo pipefail
echo "gcc: $(gcc --version | head -1)"
echo "cmake: $(cmake --version | head -1)"
echo "ninja: $(ninja --version)"
echo "python: $(python3 --version)"
if command -v nvidia-smi >/dev/null; then nvidia-smi -L; else echo "No NVIDIA GPU detected"; fi
```

```bash
chmod +x tools/env_check.sh
```

---

## Study pack (official, high‑yield)

- **LLVM Getting Started / Contributing / GitHub PRs:** https://llvm.org/docs/GettingStarted.html • https://llvm.org/docs/Contributing.html • https://github.com/llvm/llvm-project  
- **MLIR Getting Started / Tutorials:** https://mlir.llvm.org/getting_started/ • https://mlir.llvm.org/docs/Tutorials/  
- **OpenXLA/XLA Developer Guide:** https://openxla.org/xla/developer_guide  
- **IREE build docs:** https://iree.dev/building-from-source/getting-started/  
- **Triton Quickstart & Release Notes:** https://docs.nvidia.com/deeplearning/triton-inference-server/user-guide/docs/getting_started/quickstart.html • https://docs.nvidia.com/deeplearning/triton-inference-server/release-notes/index.html  
- **TensorRT‑LLM docs:** see repo README and docs folder  
- **CUTLASS build/tests:** see repo README/wiki  
- **NCCL / nccl-tests:** repo READMEs  
- **Rust:** Firecracker docs + Tokio tutorial

---

## FAQ

**Q: Why only 2 active ecosystems?**  
A: For Architect/Principal hiring, **depth beats breadth**. Two ecosystems (Compiler+AI‑compiler, NVIDIA serving/perf) show deep C++ systems + AI infra. Optional Rust adds modern safety/concurrency signal.

**Q: Where exactly do I put MLIR work?**  
A: In the **LLVM monorepo** under `mlir/`. Create a topic branch in your `llvm-project` fork, edit `mlir/*`, add tests in `mlir/test/*`, build with `-DLLVM_ENABLE_PROJECTS="clang;mlir"`.

**Q: How do I get recognized fast?**  
A: Start with **docs/tests + tiny fixes**, then a **small pass/diagnostic** or **runtime flag**. Publish numbers and steps in `/docs`, then request maintainers’ feedback.

---

## License

MIT (for this lab). Each upstream project retains its own license.
