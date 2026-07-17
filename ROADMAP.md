# Project Roadmap

Roadmap date: 2026-07-13
Source of truth: verified findings in [ANALYSIS.md](ANALYSIS.md). Superseded review documents were reconciled and removed on 2026-07-16; Git history preserves their evidence.

## Roadmap Principles

Prioritize work by user data safety, whether the defect can hide a regression, operational risk, dependency order, effort, maintainability, and fit with a small local recovery utility. Each change should be independently reviewable, run on Windows before release, and avoid changing the existing three-positional-argument interface without an explicit product decision. Do not turn exploratory product ideas into defects or commitments.

## Phase 0: Immediate Safety and Repository Hygiene

1. **GH-001 — Decide intentional GitHub governance.** `main` is currently unprotected with no rulesets. Decide whether to require the verified Windows Pester check before merge; do not change remote settings without separate approval.

Completed during the 2026-07-16 cleanup: `ANALYSIS.md` and `ROADMAP.md` are the only planning pair; the four superseded review documents were removed after verification, and `AGENTS.md` replaced the stale duplicated agent guidance.

There are no confirmed exposed secrets, broken local build artifacts, or branches safe to delete now.

## Phase 1: Stabilization

1. **BUG-001 — Make the batch success exit code deterministic.** Return success explicitly after location restoration; add a Windows test for normal success and restoration failure behavior.
2. **BUG-002 — Make batch rollback observable and contained.** Add `setlocal`, immediately capture `where` status, warn on failed restore renames, and include an absolute path for retained temporary output.
3. **BUG-003 — Bound batch temporary-name generation.** Use a defined retry budget matching the PowerShell behavior and return an actionable error.
4. **SEC-001 — Define and implement safe batch filename policy.** Prefer a PowerShell recommendation for unusual names; either robustly refactor cmd comparisons or explicitly reject dangerous metacharacters. Verify the chosen policy in isolated Windows tests.
5. **TEST-002 — Cover failure paths and missing validation variants.** Add deterministic cases for zero/one arguments, colon/forward-slash output names, missing video/input directory, bare relative-audio resolution, second rename failure, failed rollback, missing/occupied Desktop, collision exhaustion, and special-character policy. Add a batch real-FFmpeg smoke test when feasible.
6. **DOC-002 — Correct user-facing drift.** Make temp extension examples generic, state exact mock failure semantics, and align test documentation with the repaired workflow.

## Phase 2: Maintainability and Developer Experience

1. Introduce a single short behavior contract shared by batch, PowerShell, README, and tests.
2. Make PowerShell the preferred implementation in documentation after Windows parity tests pass; retain batch as compatibility support.
3. Add a test-result XML/artifact and a small Windows development/testing guide, including prerequisites and real-FFmpeg opt-in command.
4. Normalize line endings for the batch file in an isolated formatting commit after Windows validation; consider `.gitattributes` for `.bat`/`.ps1` files.
5. Add lightweight repository governance appropriate to public use: `SECURITY.md`; optional `CONTRIBUTING.md`, issue template, and PR template only if contributors need them.
6. Decide whether to add Dependabot version updates for GitHub Actions; GitHub Dependabot security updates are already enabled and have no open alerts.

## Phase 3: Product Improvements

1. **FEAT-001 — Make Desktop copying explicit.** Add an environment-variable opt-out or a documented configuration mechanism while retaining backward-compatible default behavior only if desired. Preflight the destination and avoid ambiguous overwrite prompts.
2. **FEAT-002 — Add dry-run/verbose mode.** Show resolved input paths, temporary names, FFmpeg invocation, and destination plan without modifying files.
3. **FEAT-003 — Improve recovery ergonomics.** Provide a safe, explicit way to identify leftovers created by a failed current invocation; do not bulk-delete arbitrary `frm_*` files.
4. Improve README positioning: when to use the utility versus long-path support and yt-dlp.

## Phase 4: Strategic Expansion

1. **ARCH-001 — PowerShell-first release.** Evaluate formal deprecation boundaries for batch after a Windows support decision. Value: safer path handling and clearer maintenance. Risk: users without PowerShell 7.
2. **FEAT-004 — Optional post-merge validation.** Explore `ffprobe` validation as an opt-in capability. Value: increased confidence; cost: one more external dependency and codec-specific policy.
3. **DIR-001 — yt-dlp postprocessor/plugin.** Explore only as a new product proposal with packaging, compatibility, and distribution plan; do not couple it to maintenance releases.

## Exploratory Ideas

- Directory batch-pairing workflow with explicit preview and confirmation.
- Drag-and-drop/context-menu entry points.
- Codec/container fixture matrix and compatibility policy.
- Versioned releases with a changelog once the project’s public distribution cadence warrants it.

## Deferred or Rejected Ideas

| Idea | Decision | Rationale |
|---|---|---|
| GUI application | Deferred | Disproportionate to current recovery utility scope. |
| Cloud/media-management service | Rejected | Adds accounts, privacy, infrastructure, and support needs unrelated to local merging. |
| Automatic deletion of historical `frm_*` files | Rejected | Could destroy user-recoverable material. |
| Immediate yt-dlp rewrite | Deferred | A separate product direction, not a maintenance fix. |
| Exact FFmpeg minimum-version gate | Deferred | Validate actual compatibility before imposing a potentially unnecessary constraint. |
| Removing `-y` solely because it is redundant | Deferred | No verified current defect; decide in a behavior-tested hardening change. |

## Documentation Plan

1. Keep `ANALYSIS.md` and `ROADMAP.md` as the current audit/planning pair.
2. Keep `AGENTS.md` as canonical repository guidance and keep `CLAUDE.md` as a Claude-only pointer.
3. Update README and `tests/README.md` after CI and batch behavior changes; include supported platforms, exact testing scope, special-character policy, and recovery caveats.
4. Add `docs/testing.md` and `docs/architecture.md` only if the concise root documents become unwieldy.
5. Add `SECURITY.md` after defining a contact/disclosure route; do not fabricate one.

## GitHub Improvement Plan

1. Decide whether to protect `main` with the verified Windows Pester check; there are currently no rulesets or protection.
2. Review and improve description, homepage, topics, social preview, README rendering, releases, and Actions history; add only accurate metadata/assets.
3. Add a `SECURITY.md` and minimal contribution templates only if they match desired community participation.
4. Enable Dependabot version updates for Actions if desired; security updates are already enabled and have no open alerts.
5. Review GitHub Projects after granting the CLI `read:project` scope only if project-board state is needed.
6. Do not close historical PRs, alter rulesets, or publish releases based on this audit alone.

## Branch Cleanup Plan

| Category | Items | Action |
|---|---|---|
| Safe to delete now | None | No deletion. |
| Review before deletion | Dangling commits `391c9ae`, `e85fa49` | Inspect/recover if needed; do not prune during this audit. |
| Keep | `main`, `origin/main`, `origin/HEAD` | Current synchronized default branch and pointer. |
| Rename or migrate | None locally | `main` already satisfies the desired default name. |
| Manual GitHub action required | Decide/add `main` protection or rulesets; review GitHub Projects if needed | Requires explicit authorization for settings and `read:project` scope for Projects. |

## Milestones

| ID | Initiative | Priority | Effort | Dependencies | Target phase | Success criteria |
|---|---|---|---|---|---|---|
| GH-001 | Decide intentional GitHub governance | P1 | S | Explicit admin authorization | 0 | `main` protection/ruleset policy is documented and, if selected, enforced. |
| BUG-001 | Explicit batch success exit behavior | P1 | S | Windows test harness | 1 | Happy-path exit is 0 and tested on Windows. |
| BUG-002 | Batch rollback containment/reporting | P1 | M | Windows test harness | 1 | Failed restores warn clearly; no caller environment leakage. |
| BUG-003 | Bound temporary-name retries | P1 | S | Windows tests | 1 | Collision exhaustion exits predictably without a hang. |
| SEC-001 | Batch special-character policy | P1 | M | Isolated Windows tests | 1 | Documented supported/rejected characters and tests. |
| TEST-001 | Publish/retain test diagnostics | P2 | S | Windows workflow | 2 | Failed runs leave actionable result output. |
| TEST-002 | Expand failure-path coverage | P1 | M | BUG changes | 1 | Critical rollback/destination cases covered. |
| DOC-002 | Correct README/script doc drift | P2 | S | DOC-001 | 1 | Examples and test claims match code. |
| ARCH-001 | Define PowerShell-first maintenance policy | P2 | S | Parity validation | 2 | Clear supported implementation roles. |
| FEAT-001 | Configurable Desktop-copy behavior | P2 | M | Destination tests | 3 | User can avoid Desktop copy without positional-interface breakage. |
| FEAT-002 | Dry-run/verbose mode | P3 | M | Shared contract | 3 | Plan is inspectable without mutation. |
| FEAT-003 | Safe leftover recovery guidance | P3 | M | Invocation identifier design | 3 | No bulk deletion risk. |
| FEAT-004 | Optional output verification | P3 | M | Real-FFmpeg test fixtures | 4 | Explicit, opt-in validation policy. |
| DIR-001 | yt-dlp plugin discovery | Exploratory | L | Separate product brief | 4 | Go/no-go decision with distribution/support plan. |

## Success Metrics

- The GitHub Windows test job continues to fail whenever any Pester case fails (verified on 2026-07-09).
- Default mock suite and opt-in real-FFmpeg suite pass on a supported Windows environment.
- Batch exits deterministically, has no unbounded retry, does not leak environment variables, and reports failed restoration clearly.
- All confirmed high/medium findings have a passing regression test or documented accepted limitation.
- There is one current roadmap, and dated audits are visibly historical.
- README setup/testing instructions work verbatim on a supported Windows environment.
- `main` remains synchronized and protected by an evidence-backed required check once remote settings are reviewed.

## Recommended Execution Order

1. Implement and test BUG-001 through BUG-003 in small batch-focused commits.
2. Decide and implement SEC-001’s filename policy with isolated Windows tests.
3. Expand TEST-002 and run real-FFmpeg smoke tests for both supported implementations where possible.
4. Complete DOC-001 and DOC-002 in a documentation-only commit.
5. Decide FEAT-001 only after destination behavior has been reproduced on Windows.
6. Decide GitHub governance/presentation and make only separately approved remote changes.
7. Evaluate PowerShell-first policy and larger ideas only after stabilization is complete.
