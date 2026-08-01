{
  description = "tree-sitter-cedar";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };
  };

  # nix flake show
  outputs =
    {
      self,
      nixpkgs,
      ...
    }:

    let
      perSystem = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

      systemPkgs = perSystem (
        system:

        import nixpkgs {
          inherit system;

          overlays = [
            self.overlays.default
          ];
        }
      );

      perSystemPkgs = f: perSystem (system: f (systemPkgs.${system}));

      tree-sitter-json = nixpkgs.lib.importJSON ./tree-sitter.json;
      version = tree-sitter-json.metadata.version;
    in
    {
      overlays = {
        default = final: _prev: {
          vale-styles = final.symlinkJoin {
            name = "vale-styles";
            paths = with final.valeStyles; [
              proselint
              write-good
              redhat
            ];
          };

          tree-sitter-cedar = final.callPackage ./nix/pkgs/tree-sitter-cedar/package.nix { inherit version; };
          tree-sitter-cedarschema = final.callPackage ./nix/pkgs/tree-sitter-cedarschema/package.nix { inherit version; };
          tree-sitter-cedarentities = final.callPackage ./nix/pkgs/tree-sitter-cedarentities/package.nix { inherit version; };
        };
      };

      packages = perSystemPkgs (pkgs: {
        inherit (pkgs)
          tree-sitter-cedar
          tree-sitter-cedarschema
          tree-sitter-cedarentities
          ;
      });

      devShells = perSystemPkgs (pkgs: {
        # nix develop
        default = pkgs.mkShell {
          name = "tree-sitter-cedar-shell";

          env = {
            # Nix
            NIX_PATH = "nixpkgs=${nixpkgs.outPath}";

            # Vale
            VALE_STYLES_PATH = "${pkgs.vale-styles}/share/vale/styles";

            # Snapshots
            PLAYWRIGHT_BROWSERS_PATH = pkgs.playwright-driver.browsers;
            FONTCONFIG_FILE = pkgs.makeFontsConf {
              fontDirectories = [
                pkgs.julia-mono
                pkgs.noto-fonts-cjk-sans
              ];
            };
          };

          buildInputs = with pkgs; [
            # Node
            nodejs
            vtsls

            # Snapshots
            pngquant

            # Tree Sitter
            tree-sitter
            ts_query_ls

            # Policy
            cedar

            # Nix
            deadnix
            nil
            nixd
            nixfmt

            # Spellchecking
            typos
            typos-lsp

            # Markdown
            lychee
            vale
            vale-ls

            # TOML
            tombi

            # YAML
            yaml-language-server

            # JSON
            jq
            vscode-langservers-extracted

            # Nushell
            nushell
            nufmt
            nu-lint

            # Git
            committed

            # GitHub
            gh
            pinact
            zizmor
          ];
        };

        # nix develop .#ci
        ci = pkgs.mkShell {
          name = "tree-sitter-cedar-ci-shell";

          env = {
            # Vale
            VALE_STYLES_PATH = "${pkgs.vale-styles}/share/vale/styles";

            # Snapshots
            PLAYWRIGHT_BROWSERS_PATH = pkgs.playwright-driver.browsers;
            FONTCONFIG_FILE = pkgs.makeFontsConf {
              fontDirectories = [
                pkgs.julia-mono
                pkgs.noto-fonts-cjk-sans
              ];
            };
          };

          buildInputs = with pkgs; [
            # Node
            nodejs

            # Snapshots
            pngquant

            # Tree Sitter
            tree-sitter
            ts_query_ls

            # Nix
            deadnix
            nixfmt

            # Spellchecking
            typos

            # Markdown
            lychee
            vale

            # TOML
            tombi

            # JSON
            jq

            # Nushell
            nushell
            nufmt
            nu-lint

            # Git
            committed

            # GitHub
            zizmor
          ];
        };
      });
    };
}
