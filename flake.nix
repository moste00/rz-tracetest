{
  description = "rz-tracetest - Testing of RzIL against real traces";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    b = {
      url = "github:b1llow/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      b,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        inherit (pkgs)
          stdenv
          ocaml-ng
          nixfmt-tree
          ;

        bap-frames = pkgs.fetchFromGitHub {
          owner = "b1llow";
          repo = "bap-frames";
          rev = "refs/heads/tricore-support";
          sha256 = "sha256-1f65TEIXncDD6N54Ton/VsoNYBoxEr1h0P2HIOSzI+o=";
        };

        rizin = b.packages.${system}.rizin;

        rz-tracetest = pkgs.stdenv.mkDerivation {
          pname = "rz-tracetest";
          version = "0.1.0";

          src = self;

          nativeBuildInputs = with pkgs; [
            pkg-config
            cmake
            protobuf_21
            ocaml-ng.ocamlPackages_4_14.piqi
          ];
          buildInputs = with pkgs; [
            protobuf_21
            openssl.dev
            rizin
          ];

          postPatch = ''
            cp -r ${bap-frames} ./bap-frames
          '';
          preConfigure = ''
            cd rz-tracetest
          '';

          meta = with pkgs.lib; {
            description = "Testing of RzIL against real traces";
            homepage = "https://github.com/rizinorg/rz-tracetest";
            license = licenses.lgpl3Only;
            mainProgram = "rz-tracetest";
          };
        };
      in
      {
        devShells = {
          default = pkgs.mkShell {
            inputsFrom = [ rz-tracetest ];
            packages = [ ];
          };
        };

        packages = {
          inherit rz-tracetest;
          default = rz-tracetest;
        };

        formatter = nixfmt-tree;

      }
    );
}
