#!/usr/bin/env -S nix develop --command nu

# Open a release pull request.
def main []: nothing -> nothing {
    if (git branch --show-current | str trim) != main {
        print --stderr "Current branch is not main"
        exit 1
    }

    let dirty = git status --porcelain | str trim
    if ($dirty | is-not-empty) {
        print --stderr "Working tree dirty"
        exit 1
    }

    let auth = do { gh auth token } | complete
    if $auth.exit_code != 0 {
        print --stderr "Not signed in to GitHub"
        exit 1
    }

    let token: string = $auth.stdout | str trim

    (
        npx release-please release-pr
            --repo-url SwornSystems/tree-sitter-cedar
            --token $token
            --draft-pull-request
    )

    let list = do { gh pr list --state open --json headRefName,title } | complete
    if $list.exit_code != 0 {
        print --stderr "Failed to list pull requests"
        exit 1
    }

    let branches = (
        $list.stdout
        | from json
        | where title =~ '^chore: Release'
        | get headRefName
    )

    if ($branches | is-empty) {
        return
    }

    let branch = $branches | first
    git fetch origin $branch
    git checkout $branch

    let grammars: list<string> = open tree-sitter.json | get grammars | get path
    for grammar in $grammars {
        do {
            cd $grammar
            tree-sitter generate
        }
    }

    git commit --all --amend --no-edit
    git push --force-with-lease

    gh pr ready
    git checkout main
    git branch -d $branch
}
