# Code Review Findings and Actionable Tasks

1. **Task Type:** Bug Fix  
   **Description:** The script does not validate argument count before using `%1`, `%2`, and `%3`; missing args can trigger incorrect renames or ambiguous failures.  
   **Location:** `File_Renamer.bat` lines 10-15, 21, 28, 47.  
   **Proposed Fix/Task:** Add a startup guard (`if "%~3"=="" ...`) that prints usage and exits non-zero unless exactly three arguments are provided.  
   **Reasoning:** Prevents undefined behavior and gives users deterministic error handling.

2. **Task Type:** Bug Fix  
   **Description:** The script assumes inputs exist and are files, but it does not verify `%~1`/`%~2` before attempting rename operations.  
   **Location:** `File_Renamer.bat` lines 21-34.  
   **Proposed Fix/Task:** Add `if not exist` checks for both inputs (after `pushd`) and fail fast with explicit messages before any rename.  
   **Reasoning:** Improves reliability and avoids partial state transitions when filenames are wrong.

3. **Task Type:** Bug Fix  
   **Description:** FFmpeg availability is not validated before mutating files; if `ffmpeg` is missing, the script fails after renaming inputs.  
   **Location:** `File_Renamer.bat` line 36 and rollback block on lines 38-45.  
   **Proposed Fix/Task:** Add an early check such as `where ffmpeg >nul 2>&1 || (echo ... & exit /b 1)` before any rename.  
   **Reasoning:** Fails fast and reduces risk by avoiding unnecessary file operations.

4. **Task Type:** Bug Fix  
   **Description:** `%RANDOM%`-based temporary names can collide with pre-existing files (`frm_<RANDOM>_v...`, etc.), causing rename failures.  
   **Location:** `File_Renamer.bat` lines 10-13.  
   **Proposed Fix/Task:** Generate temp names in a retry loop and confirm non-existence for all temp paths before renaming; retry on collision.  
   **Reasoning:** Makes operation robust under repeated runs and cluttered directories.

5. **Task Type:** Bug Fix  
   **Description:** Output rename uses `%~nx3`, discarding any directory in the third argument; users may think output paths are supported when they are not.  
   **Location:** `File_Renamer.bat` line 47.  
   **Proposed Fix/Task:** Either (a) explicitly reject path components in arg3, or (b) support full output path by preserving `%~f3` with safe quoting and existence checks.  
   **Reasoning:** Eliminates surprising behavior and aligns implementation with user expectations.

6. **Task Type:** Bug Fix  
   **Description:** `copy "%~nx3" "%USERPROFILE%\Desktop"` has no error handling; failures (missing desktop folder, permission issue) are silent.  
   **Location:** `File_Renamer.bat` line 59.  
   **Proposed Fix/Task:** Check `%ERRORLEVEL%` after copy, emit warning/error, and return an appropriate exit code.  
   **Reasoning:** Prevents false-success outcomes and improves operational observability.

7. **Task Type:** Documentation Update  
   **Description:** Header comments contain a typo (`exstensions`) and claim output can be any file type, which conflicts with the MKV-only muxing behavior.  
   **Location:** `File_Renamer.bat` lines 5-6.  
   **Proposed Fix/Task:** Correct typo and rewrite comment to state output should be `.mkv` unless re-mux logic is expanded.  
   **Reasoning:** Keeps inline documentation accurate and reduces user misuse.

8. **Task Type:** Documentation Update  
   **Description:** README states rollback behavior broadly, but does not clarify that desktop copy failure currently does not trigger rollback/failure status.  
   **Location:** `README.md` lines 42-45.  
   **Proposed Fix/Task:** Clarify post-merge copy semantics (or update script behavior to match stronger guarantees and then document it).  
   **Reasoning:** Aligns user-facing guarantees with real script outcomes.

9. **Task Type:** Test Improvement  
   **Description:** Repository has no automated tests for core control-flow paths (success, missing args, missing ffmpeg, rename failures, copy failures).  
   **Location:** Repository-wide (`README.md`, `File_Renamer.bat`).  
   **Proposed Fix/Task:** Add a Windows CI job (PowerShell/Pester or batch harness) with mocked `ffmpeg` to cover positive/negative paths and exit codes.  
   **Reasoning:** Prevents regressions in a script that manipulates user files.

10. **Task Type:** Test Improvement  
    **Description:** No regression tests validate extension mismatch scenarios (e.g., user passes `.mp4` output while stream container remains MKV).  
    **Location:** Behavior driven by `File_Renamer.bat` lines 13, 47 and documented in `README.md` line 28.  
    **Proposed Fix/Task:** Add tests that assert explicit rejection (if implemented) or documented warning behavior for non-`.mkv` outputs.  
    **Reasoning:** Ensures format-related expectations remain explicit and safe.
