#!/usr/bin/env nix
#!nix develop .#ci --command nu

# Run all linters and formatters.
def main []: nothing -> nothing {
    let markdown: list<string> = files "*.md"
    let scripts: list<string> = files "*.nu"
    let nix: list<string> = files "*.nix"

    # Git
    committed origin/main..HEAD

    # GitHub
    zizmor --pedantic .github

    # Spellchecking
    typos

    # Markdown
    lychee --verbose .
    let alerts = vale --no-exit --output=JSON ...$markdown | from json
    if ($alerts | is-not-empty) {
        vale ...$markdown
        exit 1
    }

    # TOML
    tombi lint --error-on-warnings

    # Nushell
    nufmt --dry-run ...$scripts
    nu-lint --config .nu-lint.toml ...$scripts

    # Tree Sitter
    tree-sitter-check

    # Nix
    nix flake check
    nix build --no-link .#tree-sitter-cedar .#tree-sitter-cedarschema .#tree-sitter-cedarentities
    nixfmt --check --width=120 ...$nix
    deadnix --fail .

    # Node
    npm ci
    npx vitest run
}

def files [pattern: string]: nothing -> list<string> {
    git ls-files --cached --others --exclude-standard $pattern | lines
}

def tree-sitter-check []: nothing -> nothing {
    let grammars: list<string> = open tree-sitter.json | get grammars | get path

    for grammar in $grammars {
        do {
            cd $grammar
            tree-sitter generate
        }
    }

    let dirty = git status --porcelain -- "*/src/*" | str trim
    if ($dirty | is-not-empty) {
        print --stderr "Working tree dirty"
        exit 1
    }

    for grammar in $grammars {
        do {
            cd $grammar
            tree-sitter test
            tree-sitter fuzz --iterations 1000
        }
    }

    for grammar in $grammars {
        ts_query_ls check --format $"($grammar)/queries"
    }
}
