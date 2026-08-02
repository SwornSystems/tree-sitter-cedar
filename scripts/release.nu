#!/usr/bin/env nix
#!nix develop .#ci --command nu

# Publish a release.
def main []: nothing -> nothing {
    if $env.CI? != "true" {
        print --stderr "Not running in CI"
        exit 1
    }

    let message: string = git log -1 --format=%s | str trim
    if $message !~ '^chore: Release v' {
        return
    }

    npm ci
    ./scripts/wasm.nu

    (
        npx release-please github-release
            --repo-url SwornSystems/tree-sitter-cedar
            --token $env.GITHUB_TOKEN
            --draft
    )

    let version: string = open package.json | get version
    gh release upload $"v($version)" ...(glob "tree-sitter-*.wasm")
    gh release edit $"v($version)" --draft=false

    npm publish --provenance --access public
}
