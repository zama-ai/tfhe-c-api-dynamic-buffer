SHELL:=$(shell /usr/bin/env which bash)
OS:=$(shell uname)
RS_CHECK_TOOLCHAIN:=$(shell cat toolchain.txt | tr -d '\n')
CARGO_RS_CHECK_TOOLCHAIN:=+$(RS_CHECK_TOOLCHAIN)
RS_BUILD_TOOLCHAIN:=stable
CARGO_RS_BUILD_TOOLCHAIN:=+$(RS_BUILD_TOOLCHAIN)
CARGO_PROFILE?=release

.PHONY: rs_check_toolchain # Echo the rust toolchain used for checks
rs_check_toolchain:
	@echo $(RS_CHECK_TOOLCHAIN)

.PHONY: rs_build_toolchain # Echo the rust toolchain used for builds
rs_build_toolchain:
	@echo $(RS_BUILD_TOOLCHAIN)

.PHONY: install_rs_check_toolchain # Install the toolchain used for checks
install_rs_check_toolchain:
	@rustup toolchain list | grep -q "$(RS_CHECK_TOOLCHAIN)" || \
	rustup toolchain install --profile default "$(RS_CHECK_TOOLCHAIN)" || \
	( echo "Unable to install $(RS_CHECK_TOOLCHAIN) toolchain, check your rustup installation. \
	Rustup can be downloaded at https://rustup.rs/" && exit 1 )

.PHONY: install_rs_build_toolchain # Install the toolchain used for builds
install_rs_build_toolchain:
	@rustup toolchain list | grep -q "$(RS_BUILD_TOOLCHAIN)" || \
	rustup toolchain install --profile default "$(RS_BUILD_TOOLCHAIN)" || \
	( echo "Unable to install $(RS_BUILD_TOOLCHAIN) toolchain, check your rustup installation. \
	Rustup can be downloaded at https://rustup.rs/" && exit 1 )

.PHONY: fmt # Format rust code
fmt: install_rs_check_toolchain
	cargo "$(CARGO_RS_CHECK_TOOLCHAIN)" fmt

.PHONY: check_fmt # Check rust code format
check_fmt: install_rs_check_toolchain
	cargo "$(CARGO_RS_CHECK_TOOLCHAIN)" fmt --check

.PHONY: clippy # Run clippy lints
clippy: install_rs_check_toolchain
	RUSTFLAGS="$(RUSTFLAGS)" cargo "$(CARGO_RS_CHECK_TOOLCHAIN)" clippy --all-targets \
		--features=c_api_print_error_source -- --no-deps -D warnings

.PHONY: build # Build
build: install_rs_build_toolchain
	RUSTFLAGS="$(RUSTFLAGS)" cargo $(CARGO_RS_BUILD_TOOLCHAIN) build --profile $(CARGO_PROFILE) \
		--features=c_api --all-targets
	RUSTFLAGS="$(RUSTFLAGS)" cargo $(CARGO_RS_BUILD_TOOLCHAIN) build --profile $(CARGO_PROFILE) \
		--features=c_api,c_api_print_error_source --all-targets

.PHONY: test_rs # Run the rust tests
test_rs: install_rs_build_toolchain
	RUSTFLAGS="$(RUSTFLAGS)" cargo $(CARGO_RS_BUILD_TOOLCHAIN) test --profile $(CARGO_PROFILE)

.PHONY: test # Alias for test_rs
test: test_rs

.PHONY: test_c # Run the C tests
test_c: install_rs_build_toolchain build
	cd c_api_tests && \
	mkdir -p build && \
	cd build && \
	cmake .. -DCMAKE_BUILD_TYPE=RELEASE -DCARGO_PROFILE=release && \
	make test

.PHONY: check_test_compile # Check C tests compile
check_test_compile: install_rs_build_toolchain build
	cd c_api_tests && \
	mkdir -p build && \
	cd build && \
	cmake .. -DCMAKE_BUILD_TYPE=RELEASE -DCARGO_PROFILE=release && \
	make -j

.PHONY: doc # Build rust doc
doc: install_rs_check_toolchain
	cargo "$(CARGO_RS_CHECK_TOOLCHAIN)" doc \
		--features=c_api_print_error_source --no-deps

.PHONY: docs # Build rust doc alias for doc
docs: doc

.PHONY: lint_doc # Build rust doc with linting enabled
lint_doc: install_rs_check_toolchain
	cargo "$(CARGO_RS_CHECK_TOOLCHAIN)" doc \
		--features=c_api_print_error_source --no-deps

.PHONY: lint_docs # Build rust doc with linting enabled alias for lint_doc
lint_docs: lint_doc

.PHONY: pcc # pcc stands for pre commit checks
pcc: check_fmt lint_doc clippy check_test_compile

.PHONY: help # Generate list of targets with descriptions
help:
	@grep '^\.PHONY: .* #' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1\t\2/' | expand -t30 | sort
