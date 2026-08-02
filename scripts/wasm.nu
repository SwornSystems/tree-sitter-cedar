#!/usr/bin/env nix
#!nix develop .#ci --command nu

# Build the WebAssembly parsers.
def main []: nothing -> nothing {
    for lang in [cedar cedarschema cedarentities] {
        let build = do { nix build --no-link --print-out-paths $".#tree-sitter-($lang).wasm" } | complete
        if $build.exit_code != 0 {
            print --stderr $"Failed to build tree-sitter-($lang).wasm"
            exit 1
        }

        let out: string = $build.stdout | str trim
        open --raw $"($out)/parser.wasm" | save --force $"tree-sitter-($lang).wasm"
    }
}
