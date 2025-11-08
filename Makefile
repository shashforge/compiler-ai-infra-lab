# ============================================================================
# compiler-ai-infra-lab — Makefile
# Owner: @shashforge
# Purpose: Turn-key build/run helpers for the two ecosystems you’re contributing to:
#   Primary (Compiler & AI-Compiler): LLVM/MLIR → OpenXLA/XLA → IREE
#   Secondary (Serving & Performance): Triton Inference Server → TensorRT-LLM → CUTLASS → NCCL
# Optional Rust signal: Firecracker/Tokio (handled outside this Makefile).
#
# Notes:
# - This Makefile creates a clean build workspace under $(BUILD_ROOT).
# - It does NOT modify your upstream forks; use it to build, test, and demo locally.
# - Most targets assume Linux; Triton GPU targets need NVIDIA driver + nvidia-container-toolkit.
# ============================================================================

# ---------- Global configuration ----------
BUILD_ROOT ?= $(HOME)/.cail/builds

# Primary: LLVM/MLIR
LLVM_DIR     := $(BUILD_ROOT)/llvm-project
LLVM_BUILD   := $(LLVM_DIR)/build
LLVM_TARGETS ?= "X86;AArch64"
LLVM_PROJECTS?= "clang;mlir"
BUILD_TYPE   ?= Release

# Primary: OpenXLA (XLA) & IREE
XLA_DIR      := $(BUILD_ROOT)/xla
IREE_DIR     := $(BUILD_ROOT)/iree
IREE_BUILD   := $(IREE_DIR)/build

# Secondary: NVIDIA stack
TRITON_MODELS := $(PWD)/secondary/triton-nvidia/model_repository
TRITON_IMG    ?= nvcr.io/nvidia/tritonserver:25.10-py3
CUTLASS_DIR   := $(BUILD_ROOT)/cutlass
CUTLASS_BUILD := $(CUTLASS_DIR)/build
NCCL_DIR      := $(BUILD_ROOT)/nccl

# Utilities
SHELL := /bin/bash

# ---------- Help ----------
.PHONY: help
help:
	@echo "compiler-ai-infra-lab — Make targets"
	@echo ""
	@echo " Global:"
	@echo "  make ensure-dirs        - Create build workspace at $(BUILD_ROOT)"
	@echo "  make clean-all          - Remove the entire build workspace"
	@echo ""
	@echo " Primary (Compiler & AI-Compiler):"
	@echo "  make setup-llvm         - Clone + build LLVM with Clang & MLIR (Release+assert)"
	@echo "  make check-mlir         - Run MLIR tests (if tree and tests are present)"
	@echo "  make clone-xla          - Clone OpenXLA/XLA (build via dev container per docs)"
	@echo "  make setup-iree         - Clone + build IREE tools (iree-compile, iree-run-module)"
	@echo ""
	@echo " Secondary (Serving & Performance):"
	@echo "  make triton-quickstart  - Run Triton server container (maps ./secondary/.../model_repository)"
	@echo "  make cutlass-build      - Clone + build CUTLASS examples/tests"
	@echo "  make nccl-notes         - Clone NCCL (build/test pointers)"
	@echo ""
	@echo " Utilities:"
	@echo "  make deps-ubuntu        - Install common Ubuntu packages (requires sudo)"
	@echo "  make verify             - Print tool versions and GPU info (if available)"
	@echo ""

# ---------- Utilities ----------
.PHONY: ensure-dirs
ensure-dirs:
	@mkdir -p "$(BUILD_ROOT)"; \
	echo "Build workspace: $(BUILD_ROOT)"

.PHONY: deps-ubuntu
deps-ubuntu:
	@echo "Installing common packages (sudo required) ..."
	sudo apt-get update
	sudo apt-get install -y \
	  build-essential cmake ninja-build git python3 python3-pip \
	  docker.io pkg-config curl
	@echo "If you need NVIDIA GPU containers, install nvidia-container-toolkit:"
	@echo "  https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html"

.PHONY: verify
verify:
	@echo "===== Tool versions ====="
	-@gcc --version | head -1 || true
	-@clang --version | head -1 || true
	-@cmake --version | head -1 || true
	-@ninja --version || true
	-@python3 --version || true
	@echo "===== GPU ====="
	-@nvidia-smi -L || echo "No NVIDIA GPU detected or nvidia-smi not found"
	@echo "===== Docker ====="
	-@docker --version || true

# ---------- Primary: LLVM/MLIR ----------
.PHONY: setup-llvm
setup-llvm: ensure-dirs
	@if [ ! -d "$(LLVM_DIR)" ]; then \
	  echo "[LLVM] Cloning llvm-project ..."; \
	  git clone https://github.com/llvm/llvm-project "$(LLVM_DIR)"; \
	else \
	  echo "[LLVM] Using existing clone at $(LLVM_DIR)"; \
	fi
	@mkdir -p "$(LLVM_BUILD)"; \
	cd "$(LLVM_BUILD)" && cmake -G Ninja \
	  -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
	  -DLLVM_ENABLE_PROJECTS=$(LLVM_PROJECTS) \
	  -DLLVM_TARGETS_TO_BUILD=$(LLVM_TARGETS) \
	  -DLLVM_ENABLE_ASSERTIONS=ON ../llvm
	@echo "[LLVM] Building clang, mlir-opt, mlir-translate ..."
	@cd "$(LLVM_BUILD)" && ninja clang mlir-opt mlir-translate
	@echo "[LLVM] Done. Binaries in $(LLVM_BUILD)/bin"

.PHONY: check-mlir
check-mlir:
	@if [ -d "$(LLVM_BUILD)" ]; then \
	  echo "[LLVM] Running MLIR tests ..."; \
	  cd "$(LLVM_BUILD)" && ninja check-mlir; \
	else \
	  echo "[LLVM] Build dir not found. Run 'make setup-llvm' first."; \
	  exit 1; \
	fi

# ---------- Primary: OpenXLA (XLA) ----------
.PHONY: clone-xla
clone-xla: ensure-dirs
	@if [ ! -d "$(XLA_DIR)" ]; then \
	  echo "[XLA] Cloning OpenXLA/XLA ..."; \
	  git clone https://github.com/openxla/xla "$(XLA_DIR)"; \
	else \
	  echo "[XLA] Using existing clone at $(XLA_DIR)"; \
	fi
	@echo "[XLA] Refer to the official developer guide for containerized Bazel builds:"
	@echo "      https://openxla.org/xla/developer_guide"

# ---------- Primary: IREE ----------
.PHONY: setup-iree
setup-iree: ensure-dirs
	@if [ ! -d "$(IREE_DIR)" ]; then \
	  echo "[IREE] Cloning iree-org/iree ..."; \
	  git clone https://github.com/iree-org/iree "$(IREE_DIR)"; \
	else \
	  echo "[IREE] Using existing clone at $(IREE_DIR)"; \
	fi
	@echo "[IREE] Installing Python runtime requirements ..."
	@python3 -m pip install --upgrade pip
	@cd "$(IREE_DIR)" && python3 -m pip install -r runtime/bindings/python/iree/runtime/requirements.txt
	@mkdir -p "$(IREE_BUILD)"; \
	cd "$(IREE_BUILD)" && cmake -G Ninja -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) ..
	@echo "[IREE] Building iree-compile and iree-run-module ..."
	@cd "$(IREE_BUILD)" && ninja iree-compile iree-run-module
	@echo "[IREE] Done. Binaries in $(IREE_BUILD)/bin"

# ---------- Secondary: Triton Inference Server ----------
.PHONY: triton-quickstart
triton-quickstart:
	@echo "[Triton] Expecting NVIDIA GPU + nvidia-container-toolkit"
	@mkdir -p "$(TRITON_MODELS)"
	@echo "[Triton] Launching server. If you have a model repo, place it under:"
	@echo "         $(TRITON_MODELS)"
	@docker run --gpus=1 --rm -p8000:8000 -p8001:8001 -p8002:8002 \
	  -v "$(TRITON_MODELS)":/models \
	  $(TRITON_IMG) tritonserver --model-repository=/models

# ---------- Secondary: CUTLASS ----------
.PHONY: cutlass-build
cutlass-build: ensure-dirs
	@if [ ! -d "$(CUTLASS_DIR)" ]; then \
	  echo "[CUTLASS] Cloning NVIDIA/cutlass ..."; \
	  git clone https://github.com/NVIDIA/cutlass "$(CUTLASS_DIR)"; \
	else \
	  echo "[CUTLASS] Using existing clone at $(CUTLASS_DIR)"; \
	fi
	@mkdir -p "$(CUTLASS_BUILD)"; \
	cd "$(CUTLASS_BUILD)" && cmake -G Ninja -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) ..
	@echo "[CUTLASS] Building examples/tests ..."
	@cd "$(CUTLASS_BUILD)" && ninja
	@echo "[CUTLASS] Done. Binaries in $(CUTLASS_BUILD)"

# ---------- Secondary: NCCL ----------
.PHONY: nccl-notes
nccl-notes: ensure-dirs
	@if [ ! -d "$(NCCL_DIR)" ]; then \
	  echo "[NCCL] Cloning NVIDIA/nccl ..."; \
	  git clone https://github.com/NVIDIA/nccl "$(NCCL_DIR)"; \
	else \
	  echo "[NCCL] Using existing clone at $(NCCL_DIR)"; \
	fi
	@echo "[NCCL] For multi-GPU perf tests, clone nccl-tests as well:"
	@echo "       git clone https://github.com/NVIDIA/nccl-tests $(BUILD_ROOT)/nccl-tests"
	@echo "       Follow its README to build and run bandwidth/latency tests."

# ---------- Housekeeping ----------
.PHONY: clean-all
clean-all:
	@echo "Removing build workspace: $(BUILD_ROOT)"
	@rm -rf "$(BUILD_ROOT)"
	@echo "Done."
