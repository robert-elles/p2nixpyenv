{
  description = "Application packaged using poetry2nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:robert-elles/poetry2nix?ref=mychanges";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    let
      py_version = "python311";
      pypkgs = "python311Packages";
      patchedPkgs = nixpkgs.legacyPackages.x86_64-linux.applyPatches {
        name = "nixpkgs-patched";
        src = nixpkgs;
        patches = [
        ];
      };
    in
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import patchedPkgs {
          inherit system;
          config.allowUnfree = true;
          config.allowBroken = true;
          overlays = [ poetry2nix.overlays.default ];
        };
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryEnv;
      in
      {
        packages = {
          poetry = nixpkgs.legacyPackages.${system}.${pypkgs}.poetry;
          myenv = mkPoetryEnv
            {
              projectDir = ./.;
              preferWheels = true;
              python = pkgs.${py_version};
              extraPackages = pypkgs: with pypkgs; [
                pip
              ];

              overrides = pkgs.poetry2nix.overrides.withDefaults (pyfinal: pyprev:
                {
                  # tokenizers = pyprev.tokenizers.override {
                  #   preferWheel = true;
                  # };

                  # sentencepiece = pyprev.sentencepiece.override {
                  #   preferWheel = true;
                  # };

                  # torch = pyprev.torch.override {
                  #   preferWheel = true;
                  # };

                  # torch-struct = pyprev.torch-struct.override {
                  #   preferWheel = true;
                  # };

                  # safetensors = pyprev.safetensors.override {
                  #   preferWheel = true;
                  # };

                  nvidia-cusparse-cu12 = (pyprev.nvidia-cusparse-cu12.override {
                    preferWheel = true;
                  }).overridePythonAttrs (old: {
                    # autoPatchelfIgnoreMissingDeps = true;
                    propagatedBuildInputs = ((old.propagatedBuildInputs or [ ]) ++ [
                      pkgs.cudaPackages.cudatoolkit
                    ]);
                    # src = pyprev.nvidia-cusparse-cu12.src;
                  });

                });
            };
        };

        devShells.default = pkgs.mkShell {
          NIX_PATH = "nixpkgs=${patchedPkgs}";
          buildInputs = [ ];
          packages = [
            self.packages.${system}.myenv
          ];
        };
      }
    ));
}
