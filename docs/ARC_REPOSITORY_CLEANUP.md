# ARC repository cleanup ? 2026-10-11

Repository hygiene only. No product behavior, schema, hosted records, migration history, account settings or credentials were changed. No staging, commit or push was performed.

## Verification

- Full Flutter suite: 201 passed.
- Analyzer: zero errors, 15 warnings, 70 info findings; exit 1 on the unchanged repository baseline.
- `git diff --check`: passed (exit 0); Git emits an existing LF/CRLF notice for `lib/you_page.dart`.
- SHA-256 comparison: all 179 existing product/config/asset/migration/seed files inspected before cleanup remained byte-identical.
- All test source, required fixtures, migrations and seeds remain present. References were searched before deletion; documentation links to removed evidence were removed or rewritten.

## Preserved

- All application source, assets, Android/iOS source/configuration, pubspec.yaml and pubspec.lock.
- Both deployed migrations in `supabase/migrations/`, including Phase 2A/2B and `20261010134016_arc_phase_2c_plan_activation.sql`.
- Both seeds: `arc_curated_exercise_catalog_v1.sql` and `20261009174458_home_mapping_seed_disabled.sql`.
- Both review-only SQL files, all `docs/sql/` proposals/preflight SQL, and `supabase/README.md`.
- All Flutter/SQL/anatomy test source and durable architecture, checkpoint, deployment, auth, media, navigation and Home handoff documentation.
- `tools/verify_curated_catalog.dart`, `tools/verify_phase2c_pg17.py`, `tools/exercise_navigation_android_probe.dart`, and `tools/home_status_android_probe.dart`: reusable verification/reproduction source.
- Existing tracked design screenshots, repository structure image and tracked IDE/platform configuration were preserved; they are not recent one-run evidence.

The following ten JSON files are intentional test inputs, not disposable evidence. Deleting them breaks Flutter or disposable SQL tests. Original paths are retained to avoid changing test/tool contracts:

- `docs/auth_profile_database_audit.json`
- `docs/curated_catalog_v1_insert_rows.json`
- `docs/curated_catalog_v1_preflight.json`
- `docs/curated_catalog_v1_public_api_catalog.json`
- `docs/curated_catalog_v1_real_previews.json`
- `docs/exercise_catalog_phase2b.json`
- `docs/home_mapping_proposal.json`
- `docs/phase2c_checkpoint3_local_e2e.json`
- `docs/phase2c_checkpoint3_pg17_local_e2e.json`
- `docs/phase2c_readonly_database_audit.json`

## Ignore rules and local files

Added narrow rules for `/supabase/.temp/`, local `.env.*` variants (example/sample exceptions), verification-output JSON, Android UI dumps/screenshots, the Checkpoint 2 evidence directory, and `tools/output/` / `test/sql/output/`. Existing log/build/cache/coverage/environment rules remain; no blanket docs/test/supabase ignore was added.

Ignored local artifacts remain on disk where useful: Supabase CLI project/link/version metadata, build/, .dart_tool/, Flutter plugin metadata and local caches. They are excluded from `git add .`. CLI metadata was not deleted, so the local project link remains available. No secret-bearing local environment file was found in the inspected locations. Retained Git-eligible text files were scanned for privileged Supabase keys, user JWTs, CLI tokens, private API keys, database-password URLs and private keys; no real secret candidate was detected. Test credentials/synthetic tokens and public application keys were distinguished from private keys. No credentials were rotated.

## Deleted files

64 files were removed. The empty `docs/phase2c_checkpoint2_ui_checks/` and accidental nested `ivang/Documents/ARC-Backups/`, `ivang/Documents/`, `ivang/` directories were also removed. The latter contained only a zero-byte schema file, not a usable database backup. No external backup path was accessed or deleted.

The historical preflight-comparison script was one-off tooling asserting the already-superseded pre-deployment state. Its useful SELECT-only query and gate/deployment summaries remain.

- `docs/arc_migration_cleanup_manifest.json`
- `docs/arc_training_deployment_baseline_audit.json`
- `docs/arc_training_pending_migration_check.json`
- `docs/auth_public_settings_audit.json`
- `docs/curated_catalog_v1_duplicate_review.json`
- `docs/curated_catalog_v1_execution.json`
- `docs/curated_catalog_v1_hosted_catalog.json`
- `docs/curated_catalog_v1_postinsert.json`
- `docs/curated_catalog_v1_proposals.json`
- `docs/exercise_detail_analyze.log`
- `docs/exercise_detail_android_after.log`
- `docs/exercise_detail_android_before.log`
- `docs/exercise_detail_android_before.png`
- `docs/exercise_detail_android_build.log`
- `docs/exercise_detail_android_final_return.png`
- `docs/exercise_detail_android_gif_after.png`
- `docs/exercise_detail_android_open_after.png`
- `docs/exercise_detail_android_open_before.png`
- `docs/exercise_detail_android_return_after.png`
- `docs/exercise_detail_android_routes_after.log`
- `docs/exercise_detail_android_trapped_before.png`
- `docs/exercise_detail_before.log`
- `docs/exercise_detail_focused.log`
- `docs/exercise_detail_full_test.log`
- `docs/exercise_detail_verification.json`
- `docs/home_status_analyze.log`
- `docs/home_status_android_active.xml`
- `docs/home_status_android_build.log`
- `docs/home_status_android_completed.png`
- `docs/home_status_android_completed.xml`
- `docs/home_status_android_failed.xml`
- `docs/home_status_android_logout.xml`
- `docs/home_status_android_no_plan.xml`
- `docs/home_status_android_reads.log`
- `docs/home_status_android_resumed.xml`
- `docs/home_status_android_switched.xml`
- `docs/home_status_focused.log`
- `docs/home_status_full_test.log`
- `docs/home_status_regression.log`
- `docs/home_status_verification.json`
- `docs/phase2a_2b_release_database_audit.json`
- `docs/phase2a_2b_release_manifest.json`
- `docs/phase2b_database_metadata_audit.json`
- `docs/phase2c_checkpoint1_database_check.json`
- `docs/phase2c_checkpoint2_database_check.json`
- `docs/phase2c_checkpoint2_real_catalog_example.json`
- `docs/phase2c_checkpoint2_ui_checks/anatomy_android.png`
- `docs/phase2c_checkpoint2_ui_checks/configuration_android.png`
- `docs/phase2c_checkpoint2_ui_checks/loading_android.png`
- `docs/phase2c_checkpoint2_ui_checks/unavailable_android.png`
- `docs/phase2c_checkpoint3_boundary_audit.json`
- `docs/phase2c_checkpoint3_database_audit.json`
- `docs/phase2c_checkpoint3_deployment_after.json`
- `docs/phase2c_checkpoint3_deployment_before.json`
- `docs/phase2c_checkpoint3_deployment_verification.json`
- `docs/phase2c_checkpoint3_final_hosted_preflight.json`
- `docs/phase2c_checkpoint3_final_preflight_comparison.json`
- `docs/phase2c_checkpoint3_hosted_deployment.json`
- `docs/phase2c_checkpoint3_pg17_test.log`
- `docs/phase2c_checkpoint3_pg17_verification.json`
- `docs/phase2c_checkpoint3_verification.json`
- `docs/phase2c_exercise_coverage.csv`
- `ivang/Documents/ARC-Backups/arc_before_training_schema.sql`
- `tools/compare_phase2c_final_preflight.py`

## Earlier migration cleanup record

These three obsolete migrations were already deleted before this task. Their existing Git deletions are preserved; this cleanup did not delete another migration or apply/repair hosted history. Metadata from the removed one-run manifest is retained here:

| Version | Original bytes | SHA-256 |
| --- | ---: | --- |
| 20260902000100 | 15732 | `b36ae29d0add2efbdb473e8df57e4cd063833e6b848730cab0db5cf769cec175` |
| 20260904000100 | 4077 | `cd2380578828c72051dc3d687cf5f19bde7ca752d382fb4bea57a848bcb2cb0d` |
| 20260922000100 | 417 | `54f40a83b049488678dab69d4546253908c284b1ea1b88a44a3491ddab279610` |

## Final staging readiness

Safe to run `git add .` for the intended existing implementation and cleanup changes. No accidental private-key/token candidate or temporary evidence remains Git-eligible from this cleanup. Final `git status --short`: 20 modified tracked files, three pre-existing obsolete-migration deletions and 64 untracked entries (directories are collapsed by Git). All index columns remain unstaged. The working tree intentionally includes implementation changes from earlier authorized tasks; this cleanup does not claim those changes belong to the cleanup itself.
