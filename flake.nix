{
  description = "Frontend Flake";
  nixConfig.bash-prompt-prefix = "(frontend) ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    nix-filter = {
      url = "github:numtide/nix-filter";
    };

    mach-nix = {
      url = "github:DavHau/mach-nix";
      inputs.pypi-deps-db.follows = "pypi-deps-db";
    };
    pypi-deps-db = {
      url = "github:DavHau/pypi-deps-db";
    };
  };
  outputs = { self, nixpkgs, flake-utils, nix-filter, mach-nix, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (localSystem:
        let
          pkgs = (import nixpkgs) { inherit localSystem; };
          inherit (pkgs) lib;
          inherit (pkgs) stdenv;
          LD_LIBRARY_PATH = "${pkgs.gcc-unwrapped.lib}/lib";

          pythonDeps = pkgs.stdenv.mkDerivation {
            name = "pythonDeps";
            src = nix-filter.lib.filter {
              root = ./.;
              include = [
                "requirements.txt"
              ];
            };
            allowedReferences = [
              "${pkgs.python39Packages.python}"
            ];
            buildInputs = with pkgs; [
              python39Packages.nodeenv
              python39Packages.psycopg2
              python39Packages.python
              python39Packages.pip
              gnumake
              postgresql
              cypress
              stdenv.cc
              gcc6
              gcc-unwrapped.lib
              coreutils
              fd
              ripgrep
              git
            ];
            buildPhase = ''
              export HOME=$(pwd)
              echo $out
              python -m venv venv
              source venv/bin/activate
              #chmod -R +w venv
              pip install -r requirements.txt
              for file in $(fd __pycache__); do
                echo deleting __pycache__ from $file
                rm -rf "$file"
              done
              for file in $(fd RECORD); do
                echo removing record "$file"
                rm "$file"
              done
              for file in $(rg -lF "$HOME"); do
                echo patching $file
                sed -i "s|$HOME|$out|g" $file
                echo "s|$out|tmp_bad_path|g"
                sed -i "s|$out|tmp_bad_path|g" $file
              done
              for file in $(rg -lF "$out"); do
                echo patching $file
                sed -i "s|$HOME|$out|g" $file
                echo "s|$out|tmp_bad_path|g"
                sed -i "s|$out|tmp_bad_path|g" $file
              done
              sed -i "s|${pkgs.python39Packages.python}|bad_python_path|g" venv/pyvenv.cfg
              cat venv/pyvenv.cfg
              echo fuck you
              mkdir $out
              ls venv
              rg /nix/store || true
              rg bad_python_path || true
              mkdir -p $out
              cp -r venv $out/
              #echo "${pkgs.python39Packages.python}"
              #ls $out/venv
              #pwd
              #cp -r $out $HOME
            '';
            installPhase = "true";
            postInstall = "true";
            preFixup = "true";
            fixupPhase = "true";
            postFixup = "true";
            outputHash = "6aqMx1TTXE3t/6vIJS6ueBf1kZagV+cNXWW8oCUZcpQ=";
            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
          };
          buildInputs = with pkgs; [
            gnumake
            yarn
            python39Packages.nodeenv
            python39Packages.python
            python39Packages.pip
            postgresql
            cypress
            fixup_yarn_lock
            stdenv.cc
            nodejs-19_x
            gcc6
            gcc-unwrapped.lib
            git
            fish
            ripgrep
            tree
          ];
          buildPhase = ''
            export HOME=$(pwd)
            #tree ${pythonDeps}/
            cp -r ${pythonDeps}/venv .
            pushd venv
            chmod -R +w .
            for file in $(rg -lF tmp_bad_path); do
              sed -i "s|tmp_bad_path|$HOME|g" "$file"
            done
            sed -i "s|bad_python_path|${pkgs.python39Packages.python}|g" pyvenv.cfg
            popd
            ls venv
          '';
          installPhase = ''
            mkdir $out
          '';
        in
        {
          packages.default = stdenv.mkDerivation {
            LD_LIBRARY_PATH = "${pkgs.gcc-unwrapped.lib}/lib";
            name = "frontend";
            src = ./.;
            inherit buildInputs buildPhase installPhase;
          };
        });
}
