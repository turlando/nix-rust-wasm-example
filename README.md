# Nix Rust WebAssembly Example

## Prerequisites

- [The Nix Package Manager][nix]

## Building

```sh
nix build
```

This will produce a `result` symbolic link in the current working directory
pointing to the WebAssembly binary.

## Running

```sh
nix run
```

This will run the WebAssembly binary using [Wasmtime][wasmtime].

[nix]: https://nixos.org/
[wasmtime]: https://wasmtime.dev/
