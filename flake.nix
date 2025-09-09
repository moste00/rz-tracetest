{
  description = "build env";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    ocaml-overlay.url = "github:nix-ocaml/nix-overlays";
    ocaml-overlay.inputs.nixpkgs.follows = "nixpkgs";
    b = {
      url = "github:b1llow/my-nix-flakes";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.ocaml-overlay.follows = "ocaml-overlay";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ocaml-overlay,
      b,
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
        inherit (pkgs)
          stdenv
          ;
        ocaml414 = (pkgs.ocaml-ng.ocamlPackages_4_14 or pkgs.ocamlPackages_4_14);

        bap-frames = pkgs.fetchFromGitHub {
          owner = "b1llow";
          repo = "bap-frames";
          rev = "refs/heads/tricore-support";
          sha256 = "sha256-1f65TEIXncDD6N54Ton/VsoNYBoxEr1h0P2HIOSzI+o=";
        };

        tracetest = pkgs.stdenv.mkDerivation {
          pname = "rz-tracetest";
          version = "0.1.0";

          src = self;

          nativeBuildInputs = with pkgs; [
            pkg-config
            cmake
            protobuf_21
            ocaml414.piqi
          ];
          buildInputs = with pkgs; [
            protobuf_21
            openssl.dev
            b.packages.${system}.rizin
          ];

          postPatch = ''
            cp -r ${bap-frames} ./bap-frames
          '';
          preConfigure = ''
            cd rz-tracetest
          '';
        };
      in
      {
        devShells = {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.default ];
            shellHook = ''
              export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -g3 -fno-omit-frame-pointer"
              export CMAKE_BUILD_TYPE="Debug"
            '';
          };
        };

        packages = {
          inherit tracetest;
          default = tracetest;
        };

      }
    );
}
