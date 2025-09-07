{
  description = "build env";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    ocaml-overlay.url = "github:nix-ocaml/nix-overlays";
    ocaml-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ocaml-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            ocaml-overlay.overlays.default
          ];
        };
        ocaml414 = (pkgs.ocaml-ng.ocamlPackages_4_14 or pkgs.ocamlPackages_4_14);

      in
      {
        devShells = {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              pkg-config
              cmake
              protobuf_21
              ocaml414.piqi
            ];
            buildInputs = with pkgs; [
              protobuf_21
            ];
            shellHook = ''
              export PATH=$PWD/build:$PATH
              export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -g3 -O0 -fno-omit-frame-pointer"
              export CMAKE_BUILD_TYPE="Debug"
            '';
          };
        };

      }
    );
}
