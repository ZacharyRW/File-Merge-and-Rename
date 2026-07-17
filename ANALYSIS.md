# Project Analysis

Audit date: 2026-07-13
Audited revision: `c1d423f` (`main`, matching `origin/main` locally)
Scope: tracked repository contents, local Git metadata and history, static source review, available validation, and GitHub review.
GitHub review updated: 2026-07-16 (authenticated read-only access)

## Executive Summary

File-Merge-and-Rename is a small recovery utility for failed video/audio merges caused by Windows path-length constraints. It offers a Windows batch implementation and a newer PowerShell 7 implementation; both rename inputs to short temporary names, invoke FFmpeg with stream copy, restore names on merge failure, and copy a successful result to the Desktop.

The project is healthy in its core scope: it has a narrow dependency surface, clear user documentation, a GPL-3.0 license, mock-based Pester coverage for both implementations, an opt-in real-FFmpeg smoke test, recent maintenance on `main`, and a verified passing Windows workflow. The batch implementation is the main risk concentration: its success exit code is not explicit, temporary-name retries are unbounded, rollback reporting is weak, and cmd metacharacter-bearing paths remain hazardous.

Recommended direction: stabilize and harden the existing two-implementation contract before adding features. Make the PowerShell implementation the preferred maintained path over time, retain batch for compatibility, and consolidate the historical review material into a clearly marked archive plus this roadmap rather than treating old findings as a live backlog.

## Project Overview

| Area | Current state |
|---|---|
| Purpose | Recover separate video and audio files after a failed downloader/FFmpeg merge by shortening filenames before a stream-copy merge. |
| Intended users | Windows users with FFmpeg who already have compatible video and audio files in one directory. |
| Main features | Exact three-argument validation, MKV-only output, same-directory validation, collision-avoiding temp names, rollback on failures, Desktop copy, batch and PowerShell entry points. |
| Stack | Windows batch (`.bat`), PowerShell 7 (`.ps1`), FFmpeg, Pester 5.x, GitHub Actions. |
| External services | Local FFmpeg executable; GitHub Actions downloads Pester from PSGallery. No application API, database, telemetry, network client, or credential storage. |
| Maturity | Maintained utility with useful automated coverage, but with a compatibility implementation and several deferred batch-script hardening items. |

### Architecture and data flow

1. The caller supplies video path, audio path, and a plain `.mkv` output name.
2. The implementation validates arguments and locates FFmpeg before modifying input files.
3. It works in the video directory, requires the audio file to resolve there too, and generates short `frm_<random>_*` filenames.
4. It renames the two inputs, calls FFmpeg with `-c copy` and explicit video/audio stream maps, then renames the temporary MKV to the requested output.
5. On known rename or FFmpeg failures, it restores original input names where possible. On success it removes temporary inputs and attempts a non-fatal Desktop copy.

The batch and PowerShell scripts duplicate this contract. Pester uses a temporary `ffmpeg.bat` shim to exercise both implementations without real media; an opt-in integration test creates short real fixtures and currently exercises only PowerShell.

## Repository Structure

| Path | Role |
|---|---|
| `File_Renamer.bat` | Original Windows-compatible implementation (187 lines). |
| `File_Renamer.ps1` | PowerShell 7 implementation with strict mode, structured exception handling, literal-path operations, and a bounded name generator. |
| `File_Renamer.Tests.ps1` | Pester mock-FFmpeg suite for batch and PowerShell behavior. |
| `File_Renamer.Integration.Tests.ps1` | Opt-in real-FFmpeg PowerShell smoke test. |
| `tests/` | Test running notes and a manual dummy-fixture generator. |
| `.github/workflows/test.yml` | Windows GitHub Actions Pester workflow. |
| `README.md` | User-facing use, behavior, and testing guide. |
| `CLAUDE.md` | Long AI-maintainer guide; partly stale after the July PowerShell/test additions. |
| `AUDIT.md`, `CODE_REVIEW.md`, `REVIEW_TASKS.md`, `TEST_COVERAGE_ANALYSIS.md` | Historical review artifacts, not a coherent current tracker. |
| `LICENSE` | GPL-3.0 license text. |

There are 15 tracked files and no package/dependency manifest, build system, release automation, or generated artifacts.

## Validation Results

| Check | Result | Evidence / limitation |
|---|---|---|
| Working tree | Pass | Clean before this audit; `main...origin/main` with no local changes. |
| Git integrity | Pass with review note | `git fsck --no-reflogs` found two dangling historical commits (`391c9ae`, `e85fa49`), but no corruption. Do not prune automatically; see Branch Assessment. |
| Whitespace | Pass | `git diff --check` produced no errors. |
| Secret-pattern scan | Pass | No credential-like values found in tracked content; one harmless documentation match for “env var.” This is not a substitute for a hosted secret scanner. |
| Batch/PowerShell test suite | Not run | Host is macOS and has neither `pwsh` nor Windows `cmd.exe`; the suite is intentionally Windows-only. |
| Real-FFmpeg integration test | Not run | Requires `pwsh`, FFmpeg, and explicit `RUN_REAL_FFMPEG_TESTS=1`. |
| PowerShell syntax/type analysis | Not run | `pwsh` and PSScriptAnalyzer are absent. |
| Batch lint | Not run | No batch linter is installed; static review performed. |
| Action lint | Not run | `actionlint` is absent. |
| GitHub remote review (2026-07-16) | Completed with one scope limit | Repository metadata, branches, rulesets, Actions, issues, PRs, releases, tags, security settings, and alert endpoints were inspected with authenticated `gh`. GitHub Projects require the absent `read:project` token scope. |

Commands run included `git status --short --branch`, `git log`, `git branch -a -vv`, `git fsck --no-reflogs`, `git diff --check`, `rg --files`, marker and secret-pattern searches, source/document inspection, `gh auth status`, GitHub API list/view commands, and a public GitHub page fetch attempt. No dependencies were installed: installing PowerShell would still not provide the Windows command processor required for the default suite.

### CI evidence: failure propagation is verified

`.github/workflows/test.yml` runs:

```powershell
Invoke-Pester -Path .\File_Renamer.Tests.ps1 -Output Detailed
exit $LASTEXITCODE
```

Pester 5 documents `-CI` as enabling test-result output and exiting after a failed run. Although this workflow uses `$LASTEXITCODE` instead, GitHub evidence verifies that it currently propagates failure correctly: run `29050066527` recorded three Pester failures and the job exited 1; the current `main` run `29050699150` completed with 20 passed, 0 failed, and a successful job. The original CI-001 concern is therefore **obsolete as a confirmed defect**. Using `-CI` or a result-object check remains a readability/diagnostic improvement, not an urgent correctness fix. See [Invoke-Pester documentation](https://pester.dev/docs/commands/Invoke-Pester).

## Existing Issue Verification

The repository has no meaningful inline `TODO`, `FIXME`, `HACK`, `BUG`, or `XXX` markers. Its work inventory is instead spread across four review documents. “Historical” below means the source remains useful evidence but must not be used as a live backlog without this verification.

| Existing item(s) | Source | Current status | Verification | Still relevant? | Recommended action |
|---|---|---|---|---|---|
| Tasks 1–8: argument/input/FFmpeg/output validation and Desktop-copy handling | `REVIEW_TASKS.md` | Already fixed | Present in batch lines 10–60, 101–113, and 175–184. | No | Preserve as historical resolved work. |
| Task 9: automated tests and CI | `REVIEW_TASKS.md` | Already fixed | Pester suite and Windows workflow exist; authenticated Actions logs verify both a failing job and a current 20/20 passing run. | No | Preserve as historical resolved work. |
| Task 10: extension-validation test | `REVIEW_TASKS.md` | Already fixed | Both implementations have a non-MKV Pester case. | No | Preserve as resolved. |
| Task 11: deterministic success exit | `REVIEW_TASKS.md` | Confirmed | Batch ends at bare `popd` (line 187); its proposed `&&`/`||` fix is invalid for this purpose in cmd. | Yes | BUG-001: use explicit, tested batch exit handling. |
| Task 12: incomplete CLAUDE behavior list | `REVIEW_TASKS.md` | Already fixed | The list includes current validations. | No | Mark historical resolved. |
| Tasks 13–15: stale CLAUDE enhancement/limitation claims | `REVIEW_TASKS.md` | Partially confirmed | Some were corrected, but CLAUDE still says a PowerShell alternative is future work and omits current files. | Yes | DOC-001: replace/shorten stale guide sections. |
| Task 16 / SEC-1: batch metacharacter path hazard | `REVIEW_TASKS.md`, `AUDIT.md` | Confirmed risk | Batch expands path values in parenthesized `IF` blocks; documented `)`, `%`, `!`, and related cmd parsing hazards remain. | Yes | SEC-001: harden/restrict batch path handling and add Windows cases. |
| Task 17: unbounded `%RANDOM%` loop | `REVIEW_TASKS.md` | Confirmed | Lines 92–99 loop indefinitely on collisions; PowerShell already bounds its generator at 100 attempts. | Yes | BUG-003. |
| Findings 1, 3, 5: rollback invariant/reporting | `CODE_REVIEW.md` | Confirmed | Batch rollback renames have no warning checks; final-rename error omits absolute temporary-output location. | Yes | BUG-002. |
| Finding 2: too-few-arguments message | `CODE_REVIEW.md` | Confirmed, low | Batch prints usage but no `Error:` prefix. | Yes, low | Fold into stabilization work. |
| Finding 4: capture `where` exit code | `CODE_REVIEW.md` | Confirmed maintenance risk | Uses `%ERRORLEVEL%` directly immediately after `where`; currently works but is fragile to edits. | Yes | Fold into BUG-002. |
| Finding 6: Task 11’s proposed syntax | `CODE_REVIEW.md` | Confirmed | The erroneous historical proposal remains in `REVIEW_TASKS.md`. | Yes | Archive/correct it when consolidating docs. |
| Finding 7: relative audio-path caveat | `CODE_REVIEW.md` | Mostly fixed | Batch comment now explicitly limits its guarantee to bare audio filenames; README requests names in the working directory. | No material defect | Preserve historical note only. |
| Finding 8: weak failure exit claim | `CODE_REVIEW.md` | Confirmed documentation drift | README says “non-zero”; the Pester mock verifies exact `23`. | Yes, low | DOC-002. |
| Finding 9: four tasks falsely open | `CODE_REVIEW.md` | Already fixed | `REVIEW_TASKS.md` records tasks 12–15 as remaining, but task 12/14/15 are now resolved and 13 changed scope. | Yes, documentation only | Retire the old tracker. |
| Finding 10: hard-coded temp extensions in examples | `CODE_REVIEW.md` | Confirmed | README says `.mp4`/`.m4a` although code preserves input extensions. | Yes, low | DOC-002. |
| Finding 11: pending error messages | `CODE_REVIEW.md` | Already fixed | No longer listed as a pending enhancement. | No | Preserve historical resolved note. |
| Findings 12–13: spelling/comment precision | `CODE_REVIEW.md` | Confirmed, low | “randomised” remains; FFmpeg comment says failure occurs there although validation is earlier. | Yes | Fold into DOC-002. |
| Finding 14: rollback-failure tests | `CODE_REVIEW.md` | Partially confirmed | Output-name conflict is tested; forced second-rename/rollback failure is not. | Yes | TEST-002. |
| Findings 15–17: stale dates/cross-reference | `CODE_REVIEW.md` | Historical, partly obsolete | Review dates are appropriately historical, but documents lack a clear archival/current-status banner. | Yes | DOC-001. |
| N-1: duplicated review documents | `AUDIT.md` | Confirmed | Four overlapping planning/audit documents disagree about current tests and PowerShell support. | Yes | DOC-001. |
| N-3/N-8: Desktop copy UX | `AUDIT.md` | Confirmed improvement | Copy is unconditional and assumes `%USERPROFILE%\Desktop`; no opt-out or preflight. | Yes | FEAT-001. |
| N-4: `ffmpeg -y` could overwrite temp output | `AUDIT.md` | Obsolete as defect | The temp name is checked before FFmpeg; `-y` is redundant but not a current data-loss path. | No | Do not prioritize removal without a behavior decision. |
| N-5: `pushd` before existence check | `AUDIT.md` | Already explained | Current batch comments explain the working-directory behavior. | No | No action. |
| N-6: no yt-dlp mention | `AUDIT.md` | Already fixed | README now lists yt-dlp as an alternative. | No | Improve positioning only if desired. |
| N-7: no PowerShell alternative | `AUDIT.md` | Already fixed | `File_Renamer.ps1`, tests, and docs exist. | No | Update historical docs. |
| N-9: no FFmpeg minimum version | `AUDIT.md` | Confirmed, low | Requirement does not state/test a version. | Optional | Validate before documenting a minimum. |
| N-10: batch environment leakage | `AUDIT.md` | Confirmed | No `setlocal`; assignments such as `_OUT3`, `TMP*`, and `FFERR` persist to a calling cmd session. | Yes | BUG-002. |
| SEC-2 wildcard deletion concern | `AUDIT.md` | Obsolete | Temp names are generated internally from a numeric random value and fixed suffixes, not caller-controlled wildcards. | No | Do not carry forward. |
| SEC-3 output verification | `AUDIT.md` | Optional enhancement | No post-merge `ffprobe`/playability verification. FFmpeg success alone is the current contract. | Exploratory | Evaluate with real fixtures before committing. |
| Claims of “no tests/CI” and untested happy/rollback paths | `AUDIT.md`, `TEST_COVERAGE_ANALYSIS.md` | Obsolete | July 2026 Pester tests cover happy path, exact FFmpeg error propagation, rollback, output conflict, and Desktop copy. | No | Label these files historical or archive them. |

## Newly Discovered Findings

### Medium

#### BUG-001 — Batch success exit status is not explicit

- **Category:** Correctness / scripting reliability
- **Affected:** `File_Renamer.bat:187`
- **Evidence:** The successful path ends at `popd`, whose result becomes the script exit status. The PowerShell implementation explicitly exits 0.
- **Impact:** Automation can see a non-zero status after a completed merge if directory restoration fails; behavior is inconsistent across implementations.
- **Verification:** Code path inspection; needs Windows reproduction with a controlled `popd` failure for full runtime proof.
- **Recommended fix:** Restore location, capture/check its status, then explicitly return 0 on normal completion; add a batch happy-path exit assertion.
- **Confidence:** High.

#### BUG-002 — Batch cleanup/rollback lacks containment and actionable reporting

- **Category:** Reliability / maintainability
- **Affected:** `File_Renamer.bat:31, 56–60, 126–132, 142–151, 157–164`
- **Evidence:** No `setlocal` leaks variables into callers; rollback `RENAME` operations are unchecked; the final-output rename failure reports only a bare temporary filename; the `where` status is not captured.
- **Impact:** A locked or colliding file can leave a user with temp-named inputs without a clear warning; callers can inherit script variables; future edits can accidentally invalidate the FFmpeg availability check.
- **Verification:** Static inspection. Existing Pester tests cover normal rollback, not rollback failure.
- **Recommended fix:** Add `setlocal`, capture `where` exit status, create a small restore helper or repeated existence-check warnings, and print `%CD%\%TMPOUT%` before restoring location.
- **Confidence:** High.

#### BUG-003 — Batch temporary-name generation can loop indefinitely

- **Category:** Reliability
- **Affected:** `File_Renamer.bat:92–99`
- **Evidence:** Each collision jumps to the same label with no counter. PowerShell uses a 100-attempt bound.
- **Impact:** A polluted directory or adversarial test case can hang the utility.
- **Verification:** Direct code inspection.
- **Recommended fix:** Match PowerShell’s bounded attempt semantics and test the failure message.
- **Confidence:** High.

#### SEC-001 — Batch filename/path metacharacters remain a cmd parsing risk

- **Category:** Security / correctness
- **Affected:** Batch validation and same-directory comparison, especially `File_Renamer.bat:31–45, 79–85`
- **Evidence:** Caller-derived values are percent-expanded in parenthesized batch blocks. Quoting mitigates ordinary spaces but does not fully neutralize cmd metacharacters such as `%`, `!`, and `)`.
- **Impact:** A legitimate unusual filename can misparse or execute unintended command fragments in the caller’s local context. The tool has no remote attack surface; severity is therefore medium, not critical.
- **Verification:** Static review and existing documented risk; safe runtime reproduction requires isolated Windows testing.
- **Recommended fix:** Prefer PowerShell for untrusted/unusual names; constrain/reject unsafe characters in batch or refactor comparisons to avoid unsafe expansion; add isolated Windows tests.
- **Confidence:** Medium-high.

### Low

#### TEST-001 — Test suite lacks an enforced Windows result and diagnostic artifact

- **Category:** Testing / developer experience
- **Affected:** `.github/workflows/test.yml`
- **Evidence:** Current workflow logs show detailed console output but the workflow creates no result file/artifact.
- **Impact:** Failures are harder to diagnose and historical test health cannot be reviewed from the repository.
- **Recommended fix:** Produce NUnit/JUnit XML and upload it; optionally add a status badge after access is restored.
- **Confidence:** High.

#### TEST-002 — Data-loss-sensitive failure modes remain under-tested

- **Category:** Testing
- **Affected:** `File_Renamer.Tests.ps1`, both implementations
- **Evidence:** Tests cover FFmpeg failure and final-output conflict, but not forced second input rename failure, locked-file rollback failure, missing Desktop, special characters, temp collision exhaustion, or batch `popd` behavior.
- **Impact:** The known error paths most likely to strand renamed files lack regression coverage.
- **Recommended fix:** Add Windows-only cases for each path, keeping tests deterministic and isolated.
- **Confidence:** High.

#### DOC-001 — The planning/docs corpus is contradictory and stale

- **Category:** Documentation / maintainability
- **Affected:** `AUDIT.md`, `CODE_REVIEW.md`, `REVIEW_TASKS.md`, `TEST_COVERAGE_ANALYSIS.md`, `CLAUDE.md`
- **Evidence:** Older documents say there is no CI, no tests, and no PowerShell port; all now exist. `CLAUDE.md` lists only five repository files and calls a present PowerShell implementation future work.
- **Impact:** A maintainer can prioritize already-complete work or overlook the actual CI defect.
- **Recommended fix:** Make this analysis and roadmap canonical; move legacy reviews under `docs/archive/` with an explicit historical banner or retain them in place with that banner; simplify `CLAUDE.md`.
- **Confidence:** High.

#### DOC-002 — Small README/script documentation mismatches

- **Category:** Documentation
- **Affected:** `README.md:53,104`, `File_Renamer.bat:88,141`
- **Evidence:** Examples hard-code `.mp4`/`.m4a` even though extensions are preserved; README says “non-zero” despite exact exit propagation being tested; wording is inconsistent.
- **Impact:** Minor confusion and future review noise.
- **Recommended fix:** Correct during documentation consolidation.
- **Confidence:** High.

#### GH-001 — Public repository governance/presentation is incomplete

- **Category:** GitHub hygiene
- **Affected:** repository configuration and public landing page
- **Evidence:** The public repository has no topics, homepage, releases, tags, open issues, or open PRs. `main` is unprotected and there are no rulesets. Wiki is enabled but no wiki/content review was available through the API. No local issue/PR templates, `CONTRIBUTING.md`, `SECURITY.md`, Dependabot configuration, funding configuration, release workflow, or social-preview asset exists. Dependabot security updates are enabled with zero open Dependabot alerts; secret scanning is disabled and code scanning has no analysis.
- **Impact:** Regressions can merge without a required check; contribution, disclosure, dependency-update, and project-evaluation paths are thin.
- **Recommended fix:** Decide whether this public repository warrants protected `main`; if yes, require the Windows Pester check after confirming its exact check name. Add a short security policy and only the lightweight metadata/templates that match desired participation. Configure version updates separately from the enabled Dependabot security updates.
- **Confidence:** High, except GitHub Projects (token lacks `read:project` scope).

### Informational

- No secrets, credentials, network calls, authentication, telemetry, or persistent data stores were found.
- `File_Renamer.bat` has mixed CRLF/LF line endings. Windows tolerates this, but normalize it in a dedicated formatting commit after Windows validation.
- `git fsck` reports two dangling commits. One (`391c9ae`, November 2025) describes a divergent old test experiment; one (`e85fa49`) is a prior merge connected through reflog during the default-branch migration. Neither is a branch deletion candidate or proof of current lost work.

## Architecture Assessment

### Strengths

- The product boundary is small and coherent: local files plus FFmpeg, no account or service dependency.
- Both implementations use short temporary names, explicit stream maps, and known rollback paths.
- PowerShell uses `Set-StrictMode`, `-LiteralPath`, process argument lists, exception handling, and a bounded name generator—substantially safer primitives than cmd parsing.
- Tests isolate temporary workspaces and mock FFmpeg rather than relying on developer media files.

### Weaknesses and technical debt

- Two implementations duplicate behavioral logic and can drift; tests assert many shared behaviors but do not define a single formal contract.
- Batch is the risk concentration: global environment variables, command parser hazards, no bound on random attempts, and incomplete failure reporting.
- The always-copy-to-Desktop side effect is a product decision embedded in core flow rather than an explicit user option.
- The project lacks a release/versioning model and a single canonical maintenance tracker.

### Recommended architectural path

Keep batch as the compatibility entry point while declaring PowerShell the preferred implementation after parity and Windows validation. Do not rewrite the utility into a service or introduce a framework. If the batch path must remain first-class, extract its behavioral contract into shared test cases/documentation and keep feature work focused on parity. A larger yt-dlp plugin is a separate product and should not be mixed into maintenance work.

## Test and Quality Assessment

The default Pester suite contains 16 test invocations (eight scenarios for each implementation) and covers argument count, output path validation, non-MKV rejection, missing FFmpeg, different directories, missing audio, FFmpeg failure/error-code propagation, output conflict, happy path, temporary cleanup, and Desktop copy. The integration suite has one opt-in real-FFmpeg PowerShell test.

This is meaningful behavioral coverage, but no coverage percentage is measured; prior 92%/96% claims in dangling historical work are not applicable to `main`. The biggest gaps are locked/failed rollback operations, special characters, batch-only exit and parser behavior, missing or occupied Desktop targets, collision exhaustion, and real media behavior for the batch path. CI must be fixed before its current passing status is trusted.

## Security and Privacy Assessment

### Confirmed

- No secrets or sensitive logging were found.
- The only external runtime dependency is an executable found on `PATH`; the user controls local execution context.
- The batch parser cannot safely promise support for every valid Windows filename. This is a local-input correctness and command-injection risk (SEC-001), not a remotely exploitable application vulnerability.

### Potential risks requiring runtime validation

- Desktop copy behavior when the destination folder is redirected, missing, read-only, or already contains the output name. The batch `copy` command has no explicit overwrite/no-prompt policy; validate on Windows before classifying actual behavior.
- A malicious `ffmpeg` placed earlier on `PATH` can run with the user’s account, which is normal command-resolution behavior. The project should document that users must trust their PATH; do not add brittle executable-location checks without a product need.

## Performance Assessment

The primary operation is FFmpeg stream copy and therefore I/O-bound. The wrapper does not re-encode or process media in memory. No confirmed performance bottleneck exists. The batch unbounded retry is a liveness issue rather than normal-case performance. Measure real-world merge time only if progress reporting or batch processing is selected later.

## Documentation Assessment

| Document | Status | Problems | Recommended action |
|---|---|---|---|
| `README.md` | Mostly accurate | Does not clearly distinguish supported batch platform from PowerShell portability; a few example/exit-code details drift. | Update. |
| `CLAUDE.md` | Outdated and overlong | Omits PowerShell/tests/current docs from structure, says PowerShell is future work, has stale state/date, and mixes instructions with historical review. | Replace or substantially shorten. |
| `AUDIT.md` | Historical | Claims no tests/CI/PowerShell; overlaps other reviews. | Archive with banner; do not delete. |
| `CODE_REVIEW.md` | Historical evidence | Several findings are resolved; duplicates tracker content. | Archive with banner; retain provenance. |
| `REVIEW_TASKS.md` | Historical, misleading as live work | Open list includes resolved items and an invalid cmd proposal. | Supersede with `ROADMAP.md`; archive with banner. |
| `TEST_COVERAGE_ANALYSIS.md` | Historical | “No test exists” claims contradicted by current Pester tests. | Archive with banner or replace with a current concise test matrix. |
| `tests/README.md` | Accurate | Does not state CI mode/result artifact expectations. | Update after CI fix. |
| `LICENSE` | Accurate | None. | Keep. |
| `CONTRIBUTING.md` | Missing | Optional for a small public utility. | Create only if outside contributors are invited. |
| `SECURITY.md` | Missing | No disclosure route. | Create a short policy if the repository is public. |
| `CHANGELOG.md` | Missing | Git history is currently adequate. | Do not create until releases/versioning begin. |

Recommended structure: root `README.md`, `LICENSE`, `CONTRIBUTING.md`/`SECURITY.md` only if adopted; `docs/architecture.md`, `docs/testing.md`, and `docs/archive/` for dated reviews. Keep `ANALYSIS.md` and `ROADMAP.md` at root while actively used, then archive future snapshots rather than multiplying trackers.

## GitHub Repository Assessment

Authenticated review confirms this is a public, unarchived GPL-3.0 repository with `main` as default branch; its description is accurate but dated around “YouTube-DL,” its homepage and topics are empty, and it has no stars or forks. The wiki is enabled and Discussions disabled. There are no releases, tags, open issues, open PRs, or remote branches other than `main`. All 12 historical PRs are merged; PRs 1–9 targeted former `master`, while 10–12 target `main`.

One active Windows Pester workflow exists. The latest `main` run passed all 20 tests; a prior run with three failures correctly failed, so the workflow’s current exit handling is evidenced. `main` has no protection and the repository has no rulesets. Actions are enabled with all actions permitted and SHA pinning not required. Dependabot security updates are enabled and there are no open Dependabot alerts; secret scanning is disabled, code scanning has no analysis, and GitHub Pages is not configured. The token lacks `read:project`, so Projects could not be listed; wiki content was likewise not audited.

The high-value GitHub improvements are to choose an intentional protection policy for `main`, add a short security disclosure policy, enable Dependabot version updates for GitHub Actions if wanted, and improve the public landing page with accurate topics/positioning and a release only after a Windows-validated stabilization change. Do not apply remote settings without separate approval.

## Branch Assessment

### Default branch

`main` is the local current branch, tracks `origin/main`, and `origin/HEAD` resolves to `origin/main`. Authenticated GitHub metadata confirms `main` is the remote default branch. The desired default-branch name is already in place.

### Branch-cleanup table

| Branch/ref | Last activity | Merge status | Associated PR | Unique commits | Recommended action | Reason |
|---|---|---|---|---:|---|---|
| `main` / `origin/main` | 2026-07-09, `c1d423f` | Current default | Historical merge commit is PR #12 | 0 vs tracked remote | Keep | Clean, synchronized baseline. |
| `origin/HEAD` | 2026-07-09 | Symbolic ref to `origin/main` | N/A | 0 | Keep | Correct default-branch pointer locally. |
| Other local/remote branches | None | No other remote branches returned by GitHub | None open | 0 | No action | GitHub branch listing contains only `main`. |

No branches were deleted. Do not delete the two dangling commits or run garbage collection as part of this audit; they are recoverable historical objects and may represent work someone wishes to inspect.

## Product and Feature Opportunities

### Near-term improvements

- Make Desktop copying opt-in or configurable via environment variable, with clear handling for missing/occupied destinations.
- Make PowerShell the documented recommended route for unusual filenames and modern Windows use.
- Add a concise “when to use this vs. enabling long paths or yt-dlp” section to clarify the utility’s recovery niche.

### Larger feature ideas

- Optional output directory and no-copy mode; preserves the current three-positional-argument interface.
- Dry-run/verbose mode that prints the resolved input/output plan without renaming files.
- Optional `ffprobe` post-merge validation, clearly documented as an additional dependency and not a substitute for media quality review.
- Batch-pair discovery for a directory only after a safe pairing model and confirmation UX are designed; automatic pairing risks merging the wrong streams.

### Alternative directions

- A PowerShell-first release with batch deprecated but retained for old cmd workflows. This fits the existing identity and reduces parser risk.
- A yt-dlp postprocessor/plugin is a separate distribution/product decision; it could remove the manual recovery workflow but requires a new language, packaging, compatibility, and support commitment.

### Experimental ideas

- Drag-and-drop wrapper or Windows context-menu integration.
- Real-FFmpeg fixture matrix for codec/container compatibility.

### Ideas not recommended now

- A GUI, cloud service, database, authentication layer, or broad media library. Each is disproportionate to a single-purpose local recovery tool.
- Automatic deletion of leftovers beyond files created in the current invocation. It risks deleting recoverable user material.

## Recommended Priorities

1. Harden batch completion and rollback behavior (BUG-001, BUG-002, BUG-003).
2. Address batch metacharacter policy and test it in isolation (SEC-001).
3. Consolidate/archive stale planning docs and correct user/maintainer documentation (DOC-001, DOC-002).
4. Add missing failure-path and real-media test coverage (TEST-002).
5. Decide whether Desktop copy should remain default behavior (FEAT-001).
6. Choose and separately authorize any `main` protection, metadata, security-policy, or Dependabot-version-update changes (GH-001).

## Limitations

- Runtime behavior was not exercised because this macOS host lacks both PowerShell and Windows cmd.exe; no test or build result is claimed.
- GitHub Projects could not be listed because the authenticated token lacks `read:project`; wiki content was not inspected through the API.
- No dependency vulnerability database scan was run because the project has no manifest and its primary dependency is system-managed FFmpeg.
- Static review can identify parser and workflow defects but cannot substitute for isolated Windows reproduction with real FFmpeg.
