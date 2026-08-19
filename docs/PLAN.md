> **Status: superseded in places by the implementation.**
>
> This is the design document written *before* this repo was built, kept for the rationale -
> why the demo is shaped the way it is, and which Terragrunt behaviours the design had to work
> around. The `README.md` is the source of truth for how the demo actually works.
>
> Where reality diverged from this plan:
>
> - **Scaffold invocation.** This plan says to `cd` into the destination and pass a relative
>   module path. That fails: `terragrunt scaffold` needs a `//` separator between the repo root
>   and the module subdirectory, or it errors with `destination exists and is not a symlink`.
>   The README uses `"$REPO//modules/<name>"` with `$REPO` from `git rev-parse --show-toplevel`.
> - **`stacks/service-env/` was added.** Not in the layout below. Because `live/` is excluded by
>   `.terragrunt-catalog-ignore`, the catalog's Stacks tab would otherwise have been empty.
> - **`local_file` artefacts were dropped** in favour of module outputs. Terragrunt runs modules
>   from `.terragrunt-cache/`, so a `local_file` would be written somewhere the reader cannot
>   find. `terragrunt stack output` is the better "look what got created" moment.
> - **`default_template` points at `./templates/terragrunt-unit/.boilerplate`**, not at the
>   directory itself, so the templated `terragrunt.hcl` inside it is never mistaken for a real
>   unit by `terragrunt run --all`.
> - **`modules/app-service` is classified as a *template*, not a *module***, because it holds a
>   `.boilerplate/` directory. A `module` tag in its README front-matter promotes it into the
>   Modules tab as well.
> - **`catalog --format=jsonl` still requires `--experiment=catalog-format`** on 1.1.3, despite
>   the flag being listed unqualified in `--help`.
> - **A real bug was found and fixed:** `mock_outputs_allowed_terraform_commands` must include
>   `destroy`, or tearing down a stack whose dependency has already been destroyed fails.
> - **No upgrade step was needed.** Terragrunt was already at 1.1.3 and OpenTofu 1.12.6 was
>   installed by the time the build started.
>
> See the "Gotchas, collected" section of `README.md` for the full list.

---

# Terragrunt Catalog + Scaffold Demo Repo

## Context

`catalog-scaffold-demo` is currently empty — one commit, a Terraform `.gitignore`, and a
one-line README. The goal is to turn it into a self-contained, runnable demo of three
Terragrunt features that **makes the time saving visceral**:

- `terragrunt catalog` — browse a repo's module/unit/stack/template library in a TUI and
  scaffold straight out of it
- `terragrunt scaffold` — generate a ready-to-run `terragrunt.hcl` from a module by reading its
  `variables.tf`, optionally through a `.boilerplate/` template that encodes house style
- `terragrunt stack` — one `terragrunt.stack.hcl` expands into a whole environment

The pitch the demo has to land: **a shared module library is only half the win — if wiring a
module up is still a 40-line copy-paste job where you must read `variables.tf` by hand, you
haven't saved anyone any time.** Catalog + scaffold close that gap; stacks close it again at the
environment level, where `cp -r` plus a two-line edit buys you a complete new environment.

Audience: infra engineers who know Terraform/Terragrunt basics but have never used
`catalog`/`scaffold`/`stacks`. It must run with **zero cloud credentials** so the reader can go
all the way through `apply`.

## Verified environment

Re-checked on this machine immediately before writing this plan:

| Tool | Version | Note |
|---|---|---|
| terragrunt | **1.1.3** | Was 0.88.1 earlier in the session; now current. Everything below is 1.1+ behaviour, so **no upgrade step is needed**. |
| OpenTofu | **1.12.6** | Terragrunt's `--tf-path` default is `tofu`, so this is the happy path. TG ≥ 1.0.5 is required for OpenTofu 1.12.x — satisfied. |
| Terraform | 1.12.2 | Available as the fallback engine. |

Docs note: `terragrunt.gruntwork.io/docs/...` now 308-redirects to `docs.terragrunt.com/...`.

## Decisions taken (confirmed with user)

1. **Module content** — AWS-shaped variable names, tags and naming conventions, fake resources
   underneath, with the real `aws_*` resource commented alongside.
2. **Include Stacks** — yes: `catalog` + `scaffold` + `terragrunt.stack.hcl`.
3. **Catalog source** — `urls = ["."]` so it works offline; the GitHub URL sits commented one
   line below and Act 6 swaps to it.
4. **Engine** — auto-detect, prefer `tofu`, fall back to `terraform`.
5. **`live/` layout** — `live/dev/` committed as the worked reference, `live/prod/` empty for
   the reader.
6. **Absolute local `source`** — accept it and teach it (see "Known wart", below).
7. **No CI workflow** — local-only demo.

## Findings from the DevOps review that changed the design

The review traced the v1.1.3 source and found four things that would have broken the demo.
All four are now designed around:

1. **`--output-folder` produces a broken `source`.** `scaffold` writes the module URL *exactly
   as typed*, before any path resolution, and Terragrunt later resolves it relative to the
   generated file's own directory. So `terragrunt scaffold ./modules/data-store
   --output-folder=live/prod/data` emits `source = "./modules/data-store"`, which then resolves
   to the non-existent `live/prod/data/modules/data-store`. **Every CLI scaffold example in the
   README therefore `cd`s into the destination first** and passes a path relative to *there*:
   `cd live/prod/data && terragrunt scaffold ../../modules/data-store`. This is the load-bearing
   invariant for the whole README.
2. **Local backend state would land inside `.terragrunt-stack/`, which `stack clean` deletes
   unconditionally.** The idiomatic `get_terragrunt_dir()` anchor resolves to the *generated*
   unit directory for stack units, so a plain `stack clean` would silently orphan applied state.
   State is therefore anchored outside the generated tree:
   `path = "${get_repo_root()}/.terragrunt-state/${path_relative_to_include()}/terraform.tfstate"`,
   with `.terragrunt-state/` gitignored.
3. **`catalog.default_template` would have destroyed the "built-in template" act.** The
   resolution order is CLI arg → module `.boilerplate/` → `catalog.default_template`, so setting
   a default template means *no* module ever shows the built-in output. Fix: ship
   `default_template` **commented out**, and make uncommenting it Act 3's central move. This
   turns the conflict into the clearest possible demonstration of the fallback chain, and
   because both `network` and `data-store` lack a `.boilerplate/`, uncommenting one line
   visibly changes two modules at once.
4. **`autoinclude` is the wrong tool for the flagship dependency beat.** It exists and the
   syntax is right, but it's new, absent from the config-blocks reference, and has an open bug
   (gruntwork-io/terragrunt#5980). The demo uses a plain
   `dependency "network" { config_path = "../network" }` inside `units/app-service` — standard,
   rock-solid, and something the reader will reuse everywhere. `autoinclude` becomes an optional
   "going further" aside.

Also confirmed favourably, removing planned complexity:

- **No `--root-file-name` flag needed.** `GetDefaultRootFileName` walks up from the working dir
  and prefers an existing `root.hcl`, so `terragrunt catalog` finds a `catalog` block in
  `root.hcl` with zero flags, from the repo root or any subdirectory. The previously planned
  fallback (a redundant top-level `terragrunt.hcl`) is dropped.
- **`.terragrunt-catalog-ignore` needs a single `live` line.** The matcher is evaluated once per
  directory during the walk and returns `SkipDir`, pruning the whole subtree — no `**` needed.
- **`terraform_data` has no Terragrunt-specific gotcha.**

## Known wart, deliberately taught rather than hidden

`CatalogConfig.normalize()` rewrites a relative `urls` entry to an absolute path, and local-dir
catalog repos keep that absolute path as the clone URL. So TUI-scaffolded units get
`source = "/Users/samuelhummerstone/Code/git/catalog-scaffold-demo//modules/network"`. Two
knock-on effects the README handles head-on:

- Act 1's `diff` against the committed `live/dev/` reference is run with the `source` line
  filtered out, and the README explains exactly why.
- Local paths never resolve a git tag, so `--var=Ref=…` is **not** demonstrated until Act 6
  where there's a real git source. Local scaffolds also log a harmless
  `Failed to find last release tag for …` warning, which the README calls out so nobody thinks
  it broke.

## Repo layout

```
catalog-scaffold-demo/
├── README.md                       # the guided demo (main deliverable)
├── root.hcl                        # catalog block + shared remote_state/inputs
├── Makefile                        # check / catalog / reset / destroy
├── .terragrunt-catalog-ignore      # one line: live
├── .envrc                          # direnv: engine auto-detect
├── .gitignore                      # += .terragrunt-cache/ .terragrunt-stack/ .terragrunt-state/
│
├── modules/                        # ← Modules tab
│   ├── network/                    #   no .boilerplate  → built-in, then org default in Act 3
│   ├── app-service/                #   HAS .boilerplate → module-specific house style
│   │   └── .boilerplate/{boilerplate.yml,terragrunt.hcl,README.md}
│   └── data-store/                 #   no .boilerplate  → same fallback as network
│
├── templates/                      # ← Templates tab
│   └── terragrunt-unit/{boilerplate.yml,terragrunt.hcl}   # org-wide default template
│
├── units/                          # ← Units tab — values.*-driven, consumed by the stack
│   ├── network/terragrunt.hcl
│   └── app-service/terragrunt.hcl  # plain dependency block on ../network
│
└── live/                           # entirely hidden from the catalog
    ├── dev/                        # committed worked example
    │   ├── network/terragrunt.hcl
    │   └── app/terragrunt.hcl
    ├── prod/.gitkeep               # EMPTY — the reader scaffolds this
    └── preview/terragrunt.stack.hcl  # one file → whole environment
```

`templates/terragrunt-unit/` uses a **top-level `boilerplate.yml`** (not `.boilerplate/`) so it
registers as a Template component and appears in the Templates tab.

On the review's suggestion to cut `units/` as duplicative: keeping it, but trimmed from three
units to two. These aren't copies of `live/dev/*` — `live/dev/*` are concrete `inputs`-driven
units, `units/*` are parameterised `values.*`-driven units that a stack instantiates. The
contrast is itself one of the things worth teaching, and a `unit` block's `source` must point at
a Terragrunt unit directory, so the stack genuinely requires them. Correspondingly `live/dev/`
drops to two units, and `data-store` is module-only — adding it to the stack becomes a
five-line exercise left to the reader, which doubles as a demonstration of how cheap that is.

## Modules — fake, but AWS-shaped

Each ships `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, and a `README.md` with
front-matter (`<!-- Frontmatter … -->` with `name`, `description`, `tags`) so the TUI shows a
real title, description and tag pills. Pattern for every resource:

```hcl
# The real thing this stands in for:
# resource "aws_vpc" "this" {
#   cidr_block = var.cidr_block
#   tags       = merge(var.tags, { Name = var.name })
# }
resource "terraform_data" "vpc" {
  input = { name = var.name, cidr_block = var.cidr_block, tags = var.tags }
}
```

**Deviation to flag:** `terraform_data` rather than `null_resource`. It's built into
Terraform ≥ 1.4 and OpenTofu, so there's no `hashicorp/null` provider to download — one less
dependency on a demo meant to Just Run. `random` (plausible ids/ARNs) and `local` (writes a JSON
"what would have been created" artefact per unit, so `apply` produces something you can look at)
are still real providers. Say the word and I'll switch to `null_resource`.

| Module | Required vars | Optional vars | Outputs | Role in the demo |
|---|---|---|---|---|
| `network` | `name`, `cidr_block` | `azs`, `enable_nat_gateway`, `tags` | `vpc_id`, `subnet_ids`, `cidr_block` | Baseline: built-in template output |
| `app-service` | `service_name`, `image`, `vpc_id`, `subnet_ids` | `desired_count`, `cpu`, `memory`, `container_port`, `health_check_path`, `environment_variables`, `tags` | `service_arn`, `endpoint` | Deliberately optional-var-heavy so the "Optional input variables — uncomment the ones you wish to set" block is dramatic; carries its own `.boilerplate/` |
| `data-store` | `table_name`, `hash_key` | `range_key`, `billing_mode`, `point_in_time_recovery`, `ttl_attribute`, `tags` | `table_name`, `table_arn` | Ships no template → proves the `default_template` fallback |

Honesty note for the README: no cloud credentials are needed, but the **first** `init` still
downloads the `random`/`local` providers, so step one needs network access or a warm plugin cache.

## Templates — three tiers, escalating

1. **Built-in** (`network`, with `default_template` still commented out): nothing to write.
   Shows required vars as `name = ""  # TODO: fill in value` and optional vars emitted as
   commented-out HCL under an "uncomment the ones you wish to set" banner.
2. **Module-specific** (`modules/app-service/.boilerplate/`): `boilerplate.yml` declares extra
   prompts the built-in template can't know about, and the template emits house style —
   `include "root"`, a wired-up `dependency "network"`, `locals` for standard tags, plus a
   per-unit `README.md`. The "your team's conventions, generated for free" moment.

   ```yaml
   variables:
     - name: TeamName
       description: Team that owns this service (used for the Owner tag)
       type: string
       order: 1
     - name: Environment
       description: Environment this unit deploys into
       type: string
       default: dev
       order: 2
   ```

   Its `terragrunt.hcl` template uses the injected `sourceUrl`, `requiredVariables` and
   `optionalVariables` (including `.UserValue`, so values typed into the interactive form land
   uncommented) alongside those two custom vars.
3. **Org default** (`templates/terragrunt-unit/`, wired via `catalog.default_template`): the
   answer to "do I have to touch all 200 modules?" — no. Uncommenting one line in `root.hcl`
   changes both `network` and `data-store` at once.

## Root config

`root.hcl` holds:

- the `catalog` block — `urls = ["."]` with the GitHub URL commented one line below,
  `default_template = "./templates/terragrunt-unit"` **commented out** (Act 3 uncomments it),
  and `no_shell = true` / `no_hooks = true` with a comment on why that matters for third-party
  templates
- `remote_state` on the local backend, anchored outside the generated tree:

  ```hcl
  remote_state {
    backend  = "local"
    generate = { path = "backend.tf", if_exists = "overwrite" }
    config = {
      path = "${get_repo_root()}/.terragrunt-state/${path_relative_to_include()}/terraform.tfstate"
    }
  }
  ```

- shared `inputs` for common tags, and `locals` deriving `env` from the path so `live/dev` and
  `live/prod` differ without duplication

No generated provider block — the fake providers need no configuration, and leaving it out keeps
the scaffold output the star.

## Engine auto-detect

One copy-paste line in the README, so no wrapper script obscures the commands being demoed:

```bash
export TG_TF_PATH="$(command -v tofu || command -v terraform)"
```

Also committed as `.envrc` for direnv users, and asserted by `make check`, which prints the
resolved versions and fails loudly if Terragrunt is < 1.1.0.

## README — the guided walkthrough

The main deliverable. Each act gives the exact command, the expected output, and what it saved.

- **Why this exists** — the module-library-isn't-enough pitch in three sentences, and an
  up-front tease of the Act 5 payoff (`cp -r` plus a two-line edit → a complete new
  environment) so the reader has a concrete destination in mind.
- **Prerequisites** — Terragrunt ≥ 1.1 (you have 1.1.3), an engine (you have both), the
  auto-detect line, `make check`. A short table of what needs 1.1+ vs 0.88, for colleagues on
  older binaries.
- **Repo tour** — the annotated tree above.
- **Act 0 — the baseline.** Read `modules/app-service/variables.tf`, then look at what a unit
  for it must contain: 11 input names, their types and their defaults, all of which you have to
  go and read. *This is the thing being replaced.*
- **Act 1 — `terragrunt catalog`.** Tabs, `/` search, `enter` for the README, `s` to scaffold
  `network` into `live/prod/network/`, fill the interactive form. Then diff against the
  committed `live/dev/network/terragrunt.hcl` with the `source` line filtered, plus the
  explanation of why it's absolute.
- **Act 2 — `terragrunt scaffold` from the CLI.** The CI/automation path, using the
  `cd`-into-destination pattern: `cd live/prod/data && terragrunt scaffold
  ../../modules/data-store --var=TeamName=platform --non-interactive`. Covers `--var`,
  `--var-file`, `--non-interactive`, and why `--output-folder` is avoided.
- **Act 3 — templates.** Scaffold `network` (built-in) and `app-service` (own `.boilerplate/`)
  and compare. Then uncomment `default_template` in `root.hcl`, re-scaffold `network` and
  `data-store`, and watch both pick up house style from one line. Then edit
  `templates/terragrunt-unit/terragrunt.hcl` and re-scaffold to show the conventions changing
  in one place for every module that doesn't ship its own template.
- **Act 4 — scaffolding whole units.** Opens by naming the distinction, or this reads as a
  repeat of Act 1: Acts 1–3 *generate* a unit from a module's `variables.tf`; this *copies* an
  existing unit and derives a `terragrunt.values.hcl` from how it uses `values.*`.
  `terragrunt scaffold ./units/app-service` produces the copied files plus Required (direct
  `values.x` refs) and Optional (`try(values.x, default)` refs) sections.
- **Act 5 — stacks.** `live/preview/terragrunt.stack.hcl`: two `unit` blocks with `values`,
  dependency wiring via the plain `dependency` block inside `units/app-service`.
  `terragrunt stack generate` → inspect `.terragrunt-stack/` → `stack run apply` →
  `stack output`. Then the punchline: `cp -r live/preview live/preview-eu`, change two `values`,
  and a second complete environment exists. Followed by the reader exercise — add `data-store`
  to the stack in five lines. A short "going further" aside points at `autoinclude` for
  declaring dependencies at the stack level without editing the unit.
- **Act 6 — the real-world setup.** Uncomment the GitHub URL in `root.hcl`, tag and push, then
  re-run the catalog to see the same library served remotely with `?ref=` pinning, and
  `--var=Ref=v0.1.0` working properly now that there's a git source. Framed as "if you want to
  try this for real" rather than a verified step, since pushing is out of scope. Includes the
  docs' caution about scaffolding untrusted templates and why `no_shell`/`no_hooks` are set.
- **What it saved** — an honest table: a hand-written `app-service` unit ≈ 35 lines and 11
  looked-up variable names vs. one command with every name, type, default and description
  pre-filled; two units × three environments ≈ 6 directories of hand-maintained HCL vs. stack
  files of ~15 lines each.
- **Limitations** — scaffold is generate-once. If `modules/app-service/variables.tf` gains a
  variable after a unit was scaffolded, nothing updates automatically; catalog/scaffold save the
  *initial* wiring, not ongoing drift. Stated plainly so the pitch stays credible.
- **Cleanup & reset** — `stack run destroy`, `stack clean`, `make reset`.

## Makefile

- `make check` — print Terragrunt/engine versions, fail if Terragrunt < 1.1.0, confirm
  `TG_TF_PATH` resolves.
- `make catalog` — the canonical `terragrunt catalog` invocation.
- `make reset` — delete reader-generated artefacts (`live/prod/*` preserving `.gitkeep`,
  `live/preview*/.terragrunt-stack/`, `.terragrunt-cache/`, `.terragrunt-state/`) so the demo is
  repeatable. This is what makes it usable as a live presentation.
- `make destroy` — tear down state first, then reset.

Written for **BSD userland**, since this is macOS: no `sed -i` without `''`, no `grep -P`, no
`readlink -f`, no `find -printf`, no `date -d`. Every target gets run on this machine before
being called done.

## Implementation order

De-risking first — steps 1–4 must each be verified empirically before the dependent work is
written:

1. Create `root.hcl` with the `catalog` block; confirm discovery needs no flags by running
   `terragrunt catalog --format=jsonl` from the repo root *and* a nested dir. Also confirm
   whether `--format=jsonl` requires `--experiment=catalog-format` on 1.1.3 — the flag is
   listed unqualified in `--help`, but the docs describe it as an experiment.
2. Build `modules/network` plus a hand-written `live/dev/network`, then immediately test the CLI
   scaffold path with the `cd`-into-destination pattern. This validates the source-path
   invariant everything else depends on.
3. Confirm the `get_repo_root()`-anchored local backend survives `stack clean`, before any stack
   work is built on it.
4. Build the stack with the plain `dependency` block and smoke-test `stack generate` /
   `stack run apply` / `stack clean`.
5. Remaining modules, `.boilerplate/` templates, `templates/terragrunt-unit/`, `units/`,
   `live/preview`.
6. Verify TUI scaffold behaviour and capture its real output for the README.
7. `Makefile`, `.envrc`, `.terragrunt-catalog-ignore`, `.gitignore` additions; test the Makefile
   on this machine's actual shell and BSD tools.
8. Write the README last, against captured real output rather than expected output.
9. Run `terragrunt run --all init` once in `live/dev` and commit the resulting
   `.terraform.lock.hcl` files **if** Terragrunt writes them back into the unit directories
   rather than leaving them in `.terragrunt-cache/` — verify which, don't assume.

## Verification

1. `make check` passes; reports Terragrunt 1.1.3 and a resolved engine.
2. `terragrunt catalog` lists three modules, two units, one stack and one template under the
   right tabs, and shows **nothing** from `live/` — proving `.terragrunt-catalog-ignore` works.
   Asserted non-interactively via `--format=jsonl`.
3. `enter` on each module renders its README with the front-matter title, description and tags.
4. `s` on `network` → interactive form → writes `live/prod/network/terragrunt.hcl`, which diffs
   clean against the committed `live/dev/network/terragrunt.hcl` modulo the `source` line and
   env-specific values.
5. Every CLI scaffold example produces a unit that actually `init`s and `plan`s from where it
   was written — the check that catches the `--output-folder` trap.
6. Toggling `default_template` visibly changes `network` and `data-store` output; `app-service`
   is unaffected because its own `.boilerplate/` wins.
7. `terragrunt scaffold ./units/app-service` copies the unit and writes a
   `terragrunt.values.hcl` with Required/Optional sections.
8. `terragrunt run --all plan` then `--all apply` succeed in `live/dev` with **no cloud
   credentials**; the `local_file` artefacts appear; `run --all destroy` is clean.
9. In `live/preview`: `stack generate` produces `.terragrunt-stack/{network,app}/` each with
   `terragrunt.hcl` + `terragrunt.values.hcl`; `stack run apply` succeeds; `stack output`
   returns values; `stack clean` removes the tree **and leaves `.terragrunt-state/` intact**.
10. `cp -r live/preview live/preview-eu` + two value edits yields a second working environment.
11. `make reset` returns `git status` to clean.
12. Every command block in the README executed verbatim from a fresh clone — **except Act 6**,
    which needs a push and is documented as aspirational.
13. Snyk IaC scan over the committed HCL (per repo policy).

## Explicitly out of scope

- Real AWS resources or credentials.
- Pushing or tagging the repo, or making it public — Act 6 documents the commands; running them
  is your call.
- CI workflow (declined).
