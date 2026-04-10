# Contributing to Pry

Thanks for your interest in Pry! This document explains how the project works and what to expect when opening an issue or a pull request.

## Workflow — GitHub Flow

Pry uses [GitHub Flow](https://docs.github.com/en/get-started/using-github/github-flow):

1. Create a feature branch off `main` (never commit to `main` directly).
2. Make your changes, commit, and push the branch.
3. Open a pull request into `main`.
4. CI runs automatically on every push to the PR — it must pass.
5. Self-merge once CI is green. Solo maintainer for now, so no external reviewers are required.
6. `main` is always releasable; tags are cut from `main` commits that have a green CI run.

## Branch naming

- `feature/short-description` — new features
- `fix/short-description` — bug fixes
- `refactor/short-description` — code changes that preserve behavior
- `docs/short-description` — documentation only
- `ci/short-description` — CI / build tweaks

## Commit messages

Pry uses [Conventional Commits](https://www.conventionalcommits.org/):

```
type: short description

Optional longer body explaining the why, not the what.
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `ci`, `chore`, `build`, `style`.

Examples:
- `feat: add WebSocket frame monitor`
- `fix: capture GraphQL operation name from inline queries`
- `refactor: extract interceptor hooks into PryHooks`

## Local development

```bash
git clone https://github.com/9alvaro0/Pry.git
cd Pry
open Package.swift   # opens in Xcode
```

Pry is a pure Swift Package with zero dependencies. You only need Xcode 16.0+ to build and run the tests.

## Running tests

```bash
xcodebuild test \
  -scheme Pry \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Pry uses [Swift Testing](https://developer.apple.com/xcode/swift-testing/). Add new tests alongside the feature you are changing; prefer small, focused tests.

## Reporting bugs

Open a [GitHub issue](https://github.com/9alvaro0/Pry/issues/new/choose) and use the bug template. Include:
- Pry, iOS and Xcode versions
- Reproduction steps
- Expected vs. actual behavior
- Any relevant logs or screenshots

## Requesting features

Open a [GitHub issue](https://github.com/9alvaro0/Pry/issues/new/choose) with the feature request template. Describe the problem you are trying to solve, not just the solution.

Pry is open-core: the feature you propose may belong in the paid PryPro extension rather than the free core. Please indicate in the issue whether you think it should be free or Pro; the maintainer will make the final call.

## License

By submitting a contribution you agree that it will be licensed under the MIT License that covers this repository.
