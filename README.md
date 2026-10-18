<div align="center">

<img src="docs/assets/logo.svg" width="88" height="88" alt="nfactory-forge kanban logo">

<h1>nfactory-forge</h1>

<p><strong>Add tasks, walk away, get merged PRs with proof.</strong></p>

<p>8 skills (5 you type, 3 the board runs) · 9 commands · 6 guard hooks</p>

<p>
<img alt="Version" src="https://img.shields.io/badge/version-3.1.2-1f883d?style=flat-square">
<img alt="Host" src="https://img.shields.io/badge/Claude%20Code-skills-d97757?style=flat-square">
<img alt="License" src="https://img.shields.io/badge/license-MIT-0969da?style=flat-square">
</p>

<p><a href="https://erictechpro.github.io/nfactory-forge/"><strong>🌐 Live site: erictechpro.github.io/nfactory-forge</strong></a></p>

<p><a href="#install">Install</a> · <a href="#quick-start">Quick start</a> · <a href="#how-it-works">How it works</a> · <a href="#skills">Skills</a> · <a href="#commands">Commands</a> · <a href="#guards--hooks">Guards</a></p>

</div>

<p align="center"><a href="https://erictechpro.github.io/nfactory-forge/skill-map/"><img src="docs/assets/skill-map.png" alt="The nfactory-forge skill map: open the interactive version" width="100%"></a></p>
<p align="center"><sub>The skill map. Click it for the live version: zoom, pan, open any node.</sub></p>

## Install

In your project folder:

```bash
curl -fsSL https://raw.githubusercontent.com/antrung699/nfactory-forge-agent/main/get.sh | bash
```

Or as a Claude Code plugin:

```
/plugin marketplace add antrung699/nfactory-forge-agent
/plugin install nfactory-forge@nfactory-forge
```

> [!NOTE]
> The plugin ships the skills only. Run `/nfactory-forge:nfactory-forge onboard` and its 🔍 Checks step adds the guard hooks, scripts and workflows. Needs Claude Code, `gh`, `jq`, bash 3.2+ and Python 3.9+; the installer checks.

Optional post-run learning can delegate an already installed `calibrate` skill after
verified selected work completes. It applies only to explicitly permitted existing
canonical skill files; the package bundles no private skill. See
[post-run calibration](skills/nfactory-forge/references/calibration.md).

## Quick start

### 1. Install

```bash
curl -fsSL https://raw.githubusercontent.com/antrung699/nfactory-forge-agent/main/get.sh | bash
```

### 2. Onboard

```
/nfactory-forge onboard
```

Checks · GitHub · Board · Branch · AGENTS.md · Policies · Bug sources · Review. <kbd>Enter</kbd> takes the recommended answer.

### 3. Run

```
/nfactory-forge run my-app
```

Add cards to `Ready`. The board drains on its own.

## How it works

<p align="center"><a href="https://youtu.be/aggJvNZxfKA"><img src="https://i.ytimg.com/vi/aggJvNZxfKA/maxresdefault.jpg" alt="Watch I Built a Self-Improving Software Factory by Eric Tech on YouTube" width="100%"></a></p>
<p align="center"><a href="https://youtu.be/aggJvNZxfKA"><strong>▶ Watch on YouTube: I Built a Self-Improving Software Factory</strong></a></p>

## Skills

**8 skills (5 you type, 3 the board runs).** Uses [Matt Pocock skills](https://github.com/mattpocock/skills), ponytail, impeccable and humanizer.

<!-- skills:start -->
**You type — 5 skills**

| Skill | What it does |
|---|---|
| [`/nfactory-forge`](skills/nfactory-forge/README.md) | Orchestrator: plans waves, runs Build → QA → Review, merges when green. |
| [`/forge-collect`](skills/forge-collect/README.md) | Finds problems (Sentry, PostHog, issues, PRs, architecture) and files verified Backlog cards. |
| [`/ui-refine-loop`](skills/ui-refine-loop/README.md) | Critique → refine loop that polishes one page or component. |
| [`/visual`](skills/visual/README.md) | One HTML page: branch recap, plan, or codebase map with diagrams. |
| [`/git-sync`](skills/git-sync/README.md) | Commit per logical change, merge-pull, push without force, report. |

**The board runs — 3 lanes**

| Skill | What it does |
|---|---|
| [`/forge-build`](skills/forge-build/README.md) | Builder lane: worktree, smallest safe change, tests, draft PR. |
| [`/forge-qa`](skills/forge-qa/README.md) | Tester lane: evidence, test-gap check, screenshots, or bounce to Build. |
| [`/forge-review`](skills/forge-review/README.md) | Reviewer lane: own hypotheses, remembers prior findings, merge gate. |
<!-- skills:end -->

Each name links to that skill's README. Adding a skill? Write its `SKILL.md` and `README.md`, add a line to `skills/families.json`, and this table updates itself.

## Commands

```
/nfactory-forge onboard          # 8-step setup, resumes
/nfactory-forge lint             # vague ACs?
/nfactory-forge status           # read-only snapshot
/nfactory-forge run <slug>       # drain the board
/nfactory-forge stop             # stop workers
/forge-collect [source]       # file problems to Backlog
/ui-refine-loop <route>       # polish one page
/visual [recap|plan|path]     # one HTML page
/git-sync                     # commit, pull, push
```

Flags: `run --low|--high` · `run --codex[=<model>]` · `forge-collect --since 30d`

## Guards & hooks

Run automatically once installed. Python stdlib, JSON in, JSON out.

| | |
| --- | --- |
| [guard-worktree-path](hooks/guard-worktree-path.py) | Blocks `git worktree add` outside `.claude/worktrees/` |
| [guard-secrets](hooks/guard-secrets.py) | Blocks reading or piping dotenv files, SSH keys and credential files; key names via `nfactory-forge-env-check.sh` |
| [guard-key-literals](hooks/guard-key-literals.py) | Blocks a live-looking API key written into a file; flags one already there |
| [guard-delete-outside](hooks/guard-delete-outside.py) | Blocks `rm`, `find -delete` and `git clean` aimed outside the project, `~` or `/` |
| [guard-protected-push](hooks/guard-protected-push.py) | Opt-in (`onboard` asks, or `install.sh --protect-main`): blocks direct and force pushes to main/master/base |
| [README sync](scripts/nfactory-forge-readme-sync.py) | Regenerates the skill table; pre-commit and PostToolUse hooks keep it fresh |
| [cleanup-wt](hooks/cleanup-wt.py) | Removes merged worktrees and branches after each merge and at session start, with a recovery file |
| [merge gate](scripts/nfactory-forge-merge-gate.sh) | Merges only after the current base plus your non-empty project `verify_commands` pass (missing checks halt setup), pinned to the reviewed commit; applies `merge_policy` and runs allowed DB migrations |

## Models

A cheap router grades each card easy, medium or hard first; the run flag picks the model for each grade. With `--codex`, every lane runs on Codex GPT models instead of Claude.

| Command | Router | Easy card | Medium card | Hard card |
| --- | --- | --- | --- | --- |
| `/nfactory-forge run` | Haiku 4.5 | Sonnet 5.5 | Opus 5.5 | session model |
| `/nfactory-forge run --low` | Haiku 4.5 | Haiku 4.5 | Sonnet 5.5 | Opus 5.5 |
| `/nfactory-forge run --high` | Sonnet 5.5 | Opus 5.5 | Opus 5.5 | Opus 5.5 |
| `/nfactory-forge run --codex` | gpt-6-luna | gpt-6.1-sol | gpt-6.1-sol | gpt-6-astra |
| `/nfactory-forge run --codex --low` | gpt-6-luna | gpt-6-luna | gpt-6.1-sol | gpt-6.1-sol |
| `/nfactory-forge run --codex --high` | gpt-6-luna | gpt-6-astra | gpt-6-astra | gpt-6-astra |

`/nfactory-forge run --codex=<model>` pins one model for every card and skips the router.

Run inside Codex? plain `/nfactory-forge run` switches to the Codex ladder by itself. Codex has no
`/nfactory-forge` command: it finds skills in `.agents/skills/` (symlinks followed), so link
`.claude/skills/nfactory-forge` there and type `$nfactory-forge run`.

## Writing standard

Commits, tickets, PR bodies and comments all follow [one writing standard](https://erictechpro.github.io/nfactory-forge/writing-standard/), in the pack and in every project it is installed into.

<details>
<summary><strong>Upgrading from 2.x</strong></summary>

1. Re-run the install line.
2. Run `/nfactory-forge onboard`; step 1 upgrades for you and keeps a backup.
3. Try `board-migrate --dry-run` on a copy of your board first.

[Full notes](RELEASE-NOTES.md#upgrading-from-2x)

</details>

## Credits

MIT © Eric Tech ([LICENSE](LICENSE)). Built on [obra/superpowers](https://github.com/obra/superpowers), [mattpocock/skills](https://github.com/mattpocock/skills), [BuilderIO/skills](https://github.com/BuilderIO/skills) and [tt-a1i/archify](https://github.com/tt-a1i/archify).

---

<p align="center">
<a href="https://erictechpro.github.io/nfactory-forge/">Live site</a> ·
<a href="https://erictechpro.github.io/nfactory-forge/skill-map/">Skill map</a> ·
<a href="https://erictechpro.github.io/nfactory-forge/writing-standard/">Writing standard</a> ·
<a href="https://erictechpro.github.io/nfactory-forge/onboarding/">Setup simulator</a> ·
<a href="https://erictechpro.github.io/nfactory-forge/impeccable/">Impeccable map</a> ·
<a href="https://erictechpro.github.io/nfactory-forge/pstack/">pstack map</a> ·
<a href="RELEASE-NOTES.md">Release notes</a> ·
<a href="RELEASING.md">Release checks</a> ·
<a href="https://youtu.be/nX_bGyIOFM4">YouTube walkthrough</a>
</p>
<p align="center"><sub>Made by Eric Tech</sub></p>

### Worker skill availability

Setup and dispatch resolve real, nonempty `SKILL.md` files for the actual
Claude or Codex host. Missing required skills halt before claims or workers;
lockfiles and arbitrary plugin caches do not count. The shared registry in
`scripts/nfactory-forge-skills-ready.py` owns lane dependencies, overrides and the
two declared ponytail fallbacks. Setup's full helper union may be red while a
selected card is runnable. Read-only checks never install; explicit onboard
repair rechecks files after installation.

The CLI accepts `--home <fixture-home>` and `--catalog <active-skills.json>`.
Launchers accept the same inventory through `NFACTORY_FORGE_SKILLS_HOME` and
`NFACTORY_FORGE_SKILLS_CATALOG`; neither changes the actual host. Catalog shape:
`{"host":"codex","skills":[{"name":"vendor:skill","path":"/exact/SKILL.md",
"enabled":true,"scope":"project","project_root":"/exact/project"}]}`.
User entries use `scope:"user"`. Restart explicitly after repairing missing
skills; readiness certifies availability, not their content or external tools.
