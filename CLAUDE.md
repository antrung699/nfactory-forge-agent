# nfactory-forge — agent-facing notes

This repo ships eight skills under `skills/`: five you type (`nfactory-forge`, `forge-collect`,
`ui-refine-loop`, `visual`, `git-sync`) and three the board runs (the lane workers `forge-build`, `forge-qa`,
`forge-review`). Architecture findings come from `/forge-collect architecture`.
Worktree cleanup (`hooks/cleanup-wt.py`) is a hook, not a skill. README skill tables are generated
by `scripts/nfactory-forge-readme-sync.py` from SKILL.md frontmatter and `skills/families.json`.

## The cardinal rule

**`nfactory-forge` is an autonomous trader. The interactive Claude session that invokes `/nfactory-forge run` is an *orchestrator*, NOT a worker.** Its only jobs are:

1. Verify preconditions (clean git, no orphan workers, GraphQL quota, etc.).
2. Dispatch per the config's `worker_backend`:
   - `"workflow"` (default) — stay in-session and run the wave loop in `skills/nfactory-forge/references/run-workflow.md`: plan a wave, claim assignees, launch the `nfactory-forge-wave` dynamic workflow, reconcile, repeat. Lane agents inside the workflow do all product work.
   - `"claude-p"` (legacy, explicit opt-in only) — spawn the headless runner `nohup .claude/bin/nfactory-forge-run.sh <slug> &`, report PID + log path, exit. The runner refuses to start (exit 78) unless the config sets this value.
3. Report back to the user (dispatch confirmation, or one status line per wave).

The orchestrator MUST NOT:

- Build, test, review, or fix issues itself. All product work is delegated to workflow lane agents (or `claude -p` workers on the legacy backend).
- Patch the dispatcher script or skill files mid-run, even if it sees a problem. Capture the symptom and tell the user; wait for explicit approval.
- Wait on individual workers or relay their work. They write their evidence back to the GitHub issue + PR. The orchestrator's user-facing output is the dispatch confirmation (claude-p) or one short report per wave (workflow), not the run result.
- Hold context for multi-card progress. State lives on the GitHub Project board + the inflight lockfiles, not in the orchestrator's session.

If a problem surfaces during the run, the orchestrator's reply is: "I saw X. Want me to dig in or stop the runner?" — not "I went ahead and fixed it."

## Worker rules

Workers (`forge-build`, `forge-qa`, `forge-review`) share the dispatcher's `gh` token bucket. They MUST:

- Required GitHub reads use `.claude/bin/nfactory-forge-github-read.py`; exit 79 stops the run.
- Check its `--check` before GitHub writes, migrations, merges, and new dispatch; preserve work when halted.
- Source `.claude/bin/nfactory-forge-gh-guard.sh` (`scripts/` in this repo) at worker start.
- Call `sb_gh_guard_check 200` before any burst of `gh` calls.
- Prefer local `git blame` / `git log` over `gh api graphql` for any sub-agent that doesn't need fresh state.
- Cap adversarial sub-agents at 50 gh calls each. If a sub-agent runs out, it returns `confidence: insufficient_data` rather than burning the shared quota.
- Append `gh-quota-on-exit: graphql=<n>/5000 rest=<n>/5000` to the PR handoff comment.

See `skills/nfactory-forge/references/rate-limit-etiquette.md` for the full discipline.

## Installation contract

`install.sh [--no-hooks] [--protect-main] <target>` copies the pack into the target project's `.claude/` tree:

```
.claude/
├── skills/<all eight>/...
├── hooks/guard-*.py, cleanup-wt.py   (wired into settings.json; --no-hooks skips)
├── workflows/nfactory-forge-wave.js, ui-refine-loop.js
└── bin/nfactory-forge-*.sh (incl. pr-body), nfactory-forge-*.py (status, merge-policy, agents-md, settings, setup), forge-qa-file-bug.sh, forge-review-file-refactor.sh
```

It also refreshes the managed `<!-- nfactory-forge:begin … -->` block in the target's AGENTS.md when
one exists (nothing outside the markers), records an older install in
`.claude/nfactory-forge/upgrade.json`, prints grouped emoji output, and asks nothing:
`nfactory-forge onboard` asks the questions. Onboard's 🔍 Checks (`scripts/nfactory-forge-setup.py`)
fixes must-haves and finishes upgrades with no question.

## Board shape (v3.0.0)

Columns are always Backlog · Ready · Building · QA · Review · Blocked · Done — no Skipped, no
per-board `variant`. Labels `qa` · `bug` · `feature` route cards: `qa` skips Building, everything
else (and no label) is built. Change routing in `scripts/nfactory-forge-wave-plan.sh`,
`workflows/nfactory-forge-wave.js` and `run.md` → "Lanes and label routing" together.

Skills call the dispatcher scripts as `.claude/bin/<script>`.

## Writing

Commits, PR bodies, tickets and comments in this repo follow
`skills/nfactory-forge/references/writing-standard.md`, the same standard nfactory-forge writes into
every project it is installed in.

| Thing | Format |
|---|---|
| Commit | `<emoji> [type] scope: subject` + short bullets (✨ feat · 🐛 fix · 🔧 chore · ♻️ refactor · 🧪 test · ⚡ perf · 📝 docs · 👷 ci · 💄 ui · 🔒 security · ⏪ revert · 🚧 wip) |
| PR body | marker blocks, one owner each: status · problem · solution · ac · history · visual · risk |
| Ticket | Problem · Context · Fix · Acceptance Criteria · Risk · Blocked by (+ Evidence for bugs) |
| Comment | `[role] [label] status` · Did · ✅ Done · ❌ Not done · Next · ≤ 8 lines |
| PR author notes | Purpose · What changed · Why it matters, in native file/inline review comments; follow `skills/nfactory-forge/references/pr-author-notes.md` |

- NEVER rewrite a whole PR body: `scripts/nfactory-forge-pr-body.sh` rewrites one block.
- ALWAYS change a format in `writing-standard.md` first, then the templates and `tests/test_writing_format.py`.

## Release checks

Run `bash tests/run-safety.sh` for the offline suite. A pushed `v*` tag runs the same checks
on Linux/macOS plus status-reader smoke checks, then publishes only if they pass. Follow
[RELEASING.md](RELEASING.md); it also lists the settings needed to limit manual bypass.

## Map pages (diagrams/)

Every map page must be listed in the nav and in Explore, from the registry `diagrams/_shared/maps.json`. To add one: create `diagrams/<map>/map.json` (or `map.py`), add its entry (title, blurb, path, thumb, logo) to the registry, add a 960x600 thumb, run `python3 diagrams/_shared/sync_explore.py` then `python3 diagrams/_shared/build_skillmap.py <map>`. The build and `sync_explore.py --check` fail if a map page has no registry entry or the Explore cards are stale.
