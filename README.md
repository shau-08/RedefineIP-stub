# RedefineIp

The top-level integration repo for the `morphingmachines` hardware design
org. Consumes all 21 dependency repos as `dependencies/*` submodules and is
the only repo in the org that other repos' releases can automatically
trigger a rebuild in.

## CI/CD wiring

Same convention as every dependency repo (`Makefile` + `rtl-dispatch` +
`cd.config`), calling the same shared workflows from
[`shau-08/CICD`](https://github.com/shau-08/CICD) — with
two differences:

- **No `RTL-CI.yml`** — this repo has no `test` target, so CI is intentionally
  skipped rather than wiring a step that would pass on nothing.
- **No `notify_repo`** in its own `RedefineIP-CD.yml` — there's nothing above
  RedefineIp in the chain to notify.
- **One extra workflow this repo alone has:** `on-dependency-release.yml`.

## The trigger chain, end to end

1. A maintainer runs a dependency repo's CD (e.g. `mmu`) with an **explicit**
   `tag_name` (e.g. `RTL1p2`) — an untagged/blank CD run stops at step 1 and
   never reaches RedefineIp at all.
2. That fires a `repository_dispatch` to this repo, which
   `on-dependency-release.yml` receives (`types: [dependency-released]`).
3. **`bump-submodule` job:** matches the released repo to a `.gitmodules`
   entry by name (org names can differ from this repo's own, so matching is
   by name only), checks whether the pinned commit is already up to date —
   if so, it's a no-op and stops here. Otherwise it checks out the exact
   released commit (captured at build time, not "whatever the branch tip is
   now"), commits the bump (`chore: bump morphingmachines/mmu to RTL1p2
   (a1b2c3d -> e4f5g6h)`), and pushes to whichever branch is actually this
   repo's real default branch (detected dynamically, never hardcoded to
   `main`).
4. **`regenerate-rtl` job:** only runs if step 3 actually changed something.
   Calls `Reusable-RTL-CD.yml` pinned to the exact bump commit (`ref:`), with a
   composed `tag_name` of `<repo>-<branch>-<tag>` — e.g. **`mmu-main-RTL1p2`**
   — so the resulting release is traceable back to the dependency release
   that caused it, without having to dig through commit messages.
5. This regeneration does **not** itself notify anything further — this
   repo's own `cd.yml` never sets `notify_repo`, so there's no cascade risk
   even though `tag_name` is non-empty for this run.

A `concurrency` guard (`group: on-dependency-release`) queues overlapping
runs instead of letting two near-simultaneous dependency releases race to
push to the same branch tip.

## Submodule freshness

Same warning mechanism as every dependency repo: if any of the 21
`dependencies/*` pins are behind their own tracked branch, CI/CD runs show a
`::warning::` — informational only, doesn't change what's built. This is
independent per layer: RedefineIp being behind on its `mmu` pin and `mmu`
being behind on its own `emitrtl` pin are two separate, unrelated facts, and
neither is auto-corrected by the other.

## `playground` is not pinned

Unlike every `dependencies/*` submodule (which are all explicitly pinned),
the shared `playground` toolchain repo is checked out fresh, at whatever's
on its default branch, on every single run — no `ref:` is specified in
`setup-toolchain`. This means two runs of the exact same RedefineIp commit,
on different days, could genuinely produce different output if `playground`
changed underneath in between. A `playground.hash` file exists in at least
one repo that looks like it was meant to pin this, but it isn't read
anywhere in the current `setup-toolchain/action.yml` — flagged as an open
question, not fixed here.

## Manually running a release

```bash
gh workflow run RedefineIP-CD.yml -R morphingmachines/RedefineIp -f tag_name=RTL2p0
```
Same `tag_name` semantics as any dependency repo — blank for a routine
release, explicit for a meaningful one. Since nothing is downstream of
RedefineIp, the practical difference is smaller here, but the composed
naming and release-history clarity still apply.

## Requirements

- Org secret `CI_SUBMODULE_PAT` (see CICD repo's README for exact setup) —
  used both for this repo's own submodule checkouts and by
  `on-dependency-release.yml`'s raw git push back to this repo.
- The GitHub slug used in every dependency's `notify_repo` field
  (`morphingmachines/RedefineIp`) must exactly match this repo's real slug —
  a mismatch fails the notify step loudly rather than silently doing
  nothing, so it's quick to catch if wrong.

## Known open items

- Generated RTL (`generated_sv_dir`) is only ever shipped as a release
  tarball, never committed into this repo's own tree — `commit_generated_output`
  exists as a working option in `reusable-cd.yml` but isn't set `true`
  anywhere. One-line change if you want generated `.sv` files versioned
  directly in git history instead of (or alongside) the release tarball.
- `playground` pinning (above) is an open design question, not a bug fixed
  in this version.
