# Terragrunt `catalog` + `scaffold` + `stack` demo

A shared module library is only half the win. If wiring a module up still means opening
`variables.tf`, reading twelve variable names, their types and their defaults, and then
hand-writing forty lines of HCL, you haven't actually saved anyone any time — you've just moved
the copy-paste somewhere else.

`terragrunt catalog` and `terragrunt scaffold` close that gap: browse the library, pick a
module, fill in a form, get a correct unit. `terragrunt stack` closes it again one level up,
where a whole environment becomes a single file.

**The payoff, up front.** By Act 5 you'll copy one 21-line file, change two values, and have a
complete second environment — network, service, dependency wiring and all:

```console
$ cp -r live/preview live/preview-eu && $EDITOR live/preview-eu/terragrunt.stack.hcl
$ diff live/preview/terragrunt.stack.hcl live/preview-eu/terragrunt.stack.hcl
17,18c17,18
<     name       = "preview"
<     cidr_block = "10.40.0.0/16"
---
>     name       = "preview-eu"
>     cidr_block = "10.50.0.0/16"

$ terragrunt stack run apply --working-dir live/preview-eu
❯❯ Run Summary  2 units  2s
   Succeeded    2
```

Everything here runs locally, with **no cloud account and no credentials**. The modules are
AWS-shaped on the outside and fake on the inside, so you can `apply` for real.

---

## Prerequisites

| Need | Why |
|---|---|
| **Terragrunt ≥ 1.1.0** | The interactive scaffold form, the component tabs, whole-repo discovery and unit/stack scaffolding are all 1.1+. On 0.88 this demo mostly still works, but the good parts are missing — see [Version notes](#version-notes). |
| **OpenTofu or Terraform** | Terragrunt defaults to `tofu`. Either is fine. |
| `jq` | Only for `make list`. |

Terragrunt defaults to the `tofu` binary. If you only have Terraform, point it there:

```bash
export TG_TF_PATH="$(command -v tofu || command -v terraform)"
```

There's an `.envrc` that does this for direnv users. Then check everything is in place:

```console
$ make check
terragrunt  1.1.3
engine      OpenTofu v1.12.6
TG_TF_PATH  /opt/homebrew/bin/tofu
ok - no cloud credentials needed for any of this
```

> The very first `apply` downloads the `hashicorp/random` provider, so step one needs network
> access (or a warm plugin cache). Nothing after that does.

---

## What's in here

```
├── root.hcl                     the catalog block, shared state config, shared tags
├── .terragrunt-catalog-ignore   one line: `live` - keeps environments out of the catalog
│
├── modules/                     ← the module library
│   ├── network/                 no .boilerplate  → built-in scaffold template
│   ├── app-service/             HAS .boilerplate → its own house-style template
│   └── data-store/              no .boilerplate  → falls back to the org template
│
├── templates/terragrunt-unit/   ← the org-wide scaffold template
├── units/                       ← reusable `values`-driven units, consumed by stacks
├── stacks/service-env/          ← a reusable whole environment
│
└── live/                        ← environments (hidden from the catalog)
    ├── dev/                     committed reference - real scaffold output, values filled in
    ├── prod/                    EMPTY - you build this
    └── preview/                 one stack file → a whole environment
```

The catalog sorts all of that into kinds automatically:

```console
$ make list
module    Data Store (DynamoDB)      modules/data-store
module    Network (VPC)              modules/network
stack     Service environment        stacks/service-env
template  App Service (ECS Fargate)  modules/app-service
template  House unit template        templates/terragrunt-unit
unit      App service unit           units/app-service
unit      Network unit               units/network
```

A directory is a **module** if it holds `.tf` files, a **template** if it holds a `.boilerplate/`
directory, a **unit** if it holds `terragrunt.hcl`, and a **stack** if it holds
`terragrunt.stack.hcl`. Note `modules/app-service` shows up as a *template* — the `.boilerplate/`
classification wins. Its README carries a `module` tag, which promotes it back into the Modules
tab as well, so it appears under both.

---

## Act 0 — the problem

Open the module you'd have to wire up by hand:

```bash
$EDITOR modules/app-service/variables.tf
```

Twelve variables across 77 lines. Four are required, eight are optional. To write a unit for it
you need every name, every type, and every default — and there is nothing stopping you getting
one wrong except care and attention.

Hold that thought.

---

## Act 1 — `terragrunt catalog`

```bash
make catalog        # or just: terragrunt catalog
```

You get a searchable table of everything in the library.

| Key | Does |
|---|---|
| `↑` `↓` / `j` `k` | move |
| `tab` / `shift+tab` | cycle the **All / Templates / Stacks / Units / Modules** tabs |
| `/` | search |
| `enter` | read the module's README |
| `s` | **scaffold it** |
| `?` | help |
| `q` | quit |

Pick **Network (VPC)**, press `enter` to read its docs, then `s`. You get a form with every
variable already listed — name, type, description, default. Fill in `name` and `cidr_block`,
press `s` again.

In the form: `j`/`k` to move, `enter` to edit, `x` to unset a field, `r` to reset,
`ctrl+d` to scaffold anyway leaving `# TODO`s, `esc` to cancel. **`esc` writes nothing at all.**

Do it from inside the directory you want the unit in:

```bash
mkdir -p live/prod/network && cd live/prod/network && terragrunt catalog
```

Now compare what you produced against the committed reference:

```console
$ cd - && diff live/prod/network/terragrunt.hcl live/dev/network/terragrunt.hcl
4c4
<   source = "/Users/you/Code/git/catalog-scaffold-demo//modules/network"
---
>   source = "../../../modules/network"
18c18
<   name = "" # TODO: fill in value
---
>   name = "dev"
22c22
<   cidr_block = "" # TODO: fill in value
---
>   cidr_block = "10.0.0.0/16"
32c32
<   # azs = ["eu-west-2a","eu-west-2b"]
---
>   azs = ["eu-west-2a", "eu-west-2b"]
```

Four lines of difference — the source, and the values. Everything else, including the correct
`include "root"` with the right filename, came out of the generator.

### About that absolute `source`

`root.hcl` points the catalog at `"."`, this repo. Terragrunt rewrites a relative catalog URL to
an absolute path, so units scaffolded from a **local** catalog get an absolute, machine-specific
`source`. That's not a bug you can configure away — it's what a local catalog means.

It's also the honest signal about how catalogs are meant to be used: local paths are for
iterating on your own module repo, and git URLs are what you ship. Act 6 switches over and the
`source` becomes portable and version-pinned. Until then, swap it for a relative path by hand,
as `live/dev/` does.

You'll also see these two warnings on every local scaffold. Both are harmless — Terragrunt is
looking for a git release tag to pin to, and a directory doesn't have one:

```
WARN  Failed to parse url file:///Users/you/.../modules/network
WARN  Failed to find last release tag for file:///Users/you/.../modules/network
```

---

## Act 2 — `terragrunt scaffold`, without the TUI

Same generator, no interface — this is the CI and scripting path.

```bash
REPO=$(git rev-parse --show-toplevel)

mkdir -p live/prod/data && cd live/prod/data
terragrunt scaffold "$REPO//modules/data-store" --non-interactive
cd -
```

**Two things matter here.**

**1. The `//` is required.** It separates the repo root from the module subdirectory. Without it
you get a confusing failure:

```console
$ terragrunt scaffold "$REPO/modules/data-store"
ERROR  downloading scaffold module ...: destination exists and is not a symlink
```

**2. Run it from the destination directory.** `scaffold` writes the module URL into `source`
*exactly as you typed it*, and Terragrunt later resolves that relative to the generated file's
own location. So don't do this:

```bash
# DON'T - source becomes "./modules/data-store", which resolves relative to
# live/prod/data/, i.e. to live/prod/data/modules/data-store, which doesn't exist.
terragrunt scaffold ./modules/data-store --output-folder=live/prod/data
```

`cd` in first and pass an absolute path (or one relative to *there*), and the generated unit
works from where it landed.

Useful flags:

```bash
--non-interactive                # skip the form, leave every value as `# TODO`
--var=TeamName=platform          # answer a template's own prompts
--var-file=vars.hcl              # ...from a file
--var=Ref=v0.1.0                 # pin the source to a git tag (Act 6 - needs a git source)
```

---

## Act 3 — templates: making scaffold produce *your* house style

Terragrunt picks a scaffold template in this order, first match wins:

1. a template passed as the second argument to `terragrunt scaffold`
2. the module's own `.boilerplate/` directory
3. `catalog.default_template` in `root.hcl`
4. Terragrunt's built-in template

### Tier 1 → tier 2: a module that brings its own template

`modules/network` has no template, so Act 1 gave you the built-in output. `modules/app-service`
has `.boilerplate/`. Scaffold it and see what changes:

```bash
mkdir -p live/prod/app && cd live/prod/app
terragrunt scaffold "$REPO//modules/app-service" --var=TeamName=platform --non-interactive
cd -
```

The generated unit now contains things the built-in template could never have guessed:

```hcl
locals {
  team = "platform"
}

# This service always needs a VPC and subnets, and they always come from a network unit.
# The template knows that, so you never write this block by hand.
dependency "network" {
  config_path = "../network"

  mock_outputs = {
    vpc_id     = "vpc-mock"
    subnet_ids = ["subnet-mock-a", "subnet-mock-b"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
}

inputs = {
  ...
  # Wired to the network unit by the template.
  vpc_id     = dependency.network.outputs.vpc_id
  subnet_ids = dependency.network.outputs.subnet_ids
  ...
  # Merged with the shared tags from root.hcl rather than replacing them.
  tags = merge(include.root.inputs.tags, {
    Owner = local.team
  })
}
```

Of twelve variables, **two** are left for you to fill in — `service_name` and `image`. The
dependency wiring, the mock outputs, the tag merge and a unit `README.md` all came from
`modules/app-service/.boilerplate/`. Read it: it's a `boilerplate.yml` declaring the extra
prompts, plus Go templates over the `sourceUrl`, `requiredVariables` and `optionalVariables` that
Terragrunt injects.

### Tier 3: house style for modules that don't ship a template

You are not going to add a `.boilerplate/` to two hundred modules. Uncomment one line in
`root.hcl`:

```hcl
catalog {
  urls             = ["."]
  default_template = "./templates/terragrunt-unit/.boilerplate"   # ← uncomment this
}
```

Now re-scaffold `network` **and** `data-store`. Neither module changed, but both now produce
house style — the exposed root include, the `Owner` tag, the merge-don't-replace tag rule:

```bash
rm -rf live/prod/network live/prod/data
mkdir -p live/prod/network && cd live/prod/network
terragrunt scaffold "$REPO//modules/network" --var=TeamName=networking --non-interactive
cd -
head -20 live/prod/network/terragrunt.hcl
```

Then edit `templates/terragrunt-unit/.boilerplate/terragrunt.hcl`, scaffold again, and watch the
convention change for every module that doesn't override it. **One file, every module.**

> The template lives in `.boilerplate/` rather than at the top of `templates/terragrunt-unit/`
> on purpose: a top-level `terragrunt.hcl` full of Go template syntax would look like a real
> unit to `terragrunt run --all`.

---

## Act 4 — scaffolding whole units, not just modules

This is a *different* operation from Acts 1–3, and it's worth being clear about which is which:

| | Source | What happens |
|---|---|---|
| Acts 1–3 | a **module** (`.tf` files) | Terragrunt **generates** a unit by reading `variables.tf` |
| Act 4 | a **unit** or **stack** (`terragrunt.hcl`) | Terragrunt **copies** it, and derives a `terragrunt.values.hcl` from how it uses `values.*` |

```bash
REPO=$(git rev-parse --show-toplevel)
mkdir -p /tmp/unit-demo && cd /tmp/unit-demo
terragrunt scaffold "$REPO//units/app-service"
```

```console
INFO  Scaffolded unit into /tmp/unit-demo
INFO  Generated /tmp/unit-demo/terragrunt.values.hcl; fill in each TODO before running Terragrunt
```

```hcl
# terragrunt.values.hcl

# === Required ===
image        = "TODO"
service_name = "TODO"

# === Optional (defaults from try() fallbacks) ===
desired_count         = 2
environment_variables = {}
team                  = "unassigned"
```

Terragrunt worked that split out by itself. Look at `units/app-service/terragrunt.hcl`:
`values.service_name` and `values.image` are referenced **directly**, so they're required;
`try(values.desired_count, 2)` has a fallback, so it's optional and the fallback is pre-filled.
Write the unit thoughtfully once and the generated form documents itself forever.

Scaffolding a unit or stack never overwrites an existing file, so a name collision aborts
rather than clobbering your work.

---

## Act 5 — stacks: one file, one environment

`live/preview/terragrunt.stack.hcl` is 21 lines of actual configuration:

```hcl
unit "network" {
  source = "../../units/network"
  path   = "network"

  values = {
    name       = "preview"
    cidr_block = "10.40.0.0/16"
    team       = "platform"
  }
}

unit "app" {
  source = "../../units/app-service"
  path   = "app"

  values = {
    service_name = "api"
    image        = "ghcr.io/acme/api:v1.4.2"
    team         = "platform"

    environment_variables = { LOG_LEVEL = "info" }
  }
}
```

Expand it:

```console
$ terragrunt stack generate --working-dir live/preview
INFO  Generating unit app from ./terragrunt.stack.hcl
INFO  Generating unit network from ./terragrunt.stack.hcl

$ find live/preview/.terragrunt-stack -type f -name '*.hcl'
live/preview/.terragrunt-stack/app/terragrunt.hcl
live/preview/.terragrunt-stack/app/terragrunt.values.hcl
live/preview/.terragrunt-stack/network/terragrunt.hcl
live/preview/.terragrunt-stack/network/terragrunt.values.hcl
```

Then run it. The dependency between the two units resolves on its own — `units/app-service`
declares `config_path = "../network"`, which inside a generated stack points at whatever the
stack placed at `path = "network"`:

```console
$ terragrunt stack run apply --working-dir live/preview
❯❯ Run Summary  2 units  3s
   Succeeded    2

$ terragrunt stack output --working-dir live/preview
app = {
  endpoint       = "https://api-b2a508f7.example.internal:8080"
  service_arn    = "arn:aws:ecs:eu-west-2:000000000000:service/api-b2a508f7"
  ...
}
network = {
  cidr_block = "10.40.0.0/16"
  vpc_id     = "vpc-3d45447a86bb95f6"
  ...
}
```

Nothing under `.terragrunt-stack/` is checked in. The stack file is the only source of truth;
regenerate any time.

### The punchline

```bash
cp -r live/preview live/preview-eu
rm -rf live/preview-eu/.terragrunt-stack
$EDITOR live/preview-eu/terragrunt.stack.hcl      # change name and cidr_block
terragrunt stack run apply --working-dir live/preview-eu
```

A two-line diff, and a second complete environment exists.

### Better: scaffold the stack

`stacks/service-env/` is the same environment, parameterised. Scaffold it and Terragrunt tells
you exactly what a new environment needs:

```console
$ mkdir -p live/qa && cd live/qa
$ terragrunt scaffold "$REPO//stacks/service-env"
INFO  Scaffolded stack into .../live/qa
INFO  Generated .../live/qa/terragrunt.values.hcl; fill in each TODO before running Terragrunt

$ cat terragrunt.values.hcl
# === Required ===
cidr_block = "TODO"
env_name   = "TODO"

# === Optional (defaults from try() fallbacks) ===
desired_count = 2
image         = "ghcr.io/acme/api:v1.4.2"
team          = "unassigned"
```

Fill in two values, then:

```bash
cd - && terragrunt stack generate --working-dir live/qa
terragrunt stack run apply --working-dir live/qa
```

**Two values is the entire cost of a new environment.**

### Your turn

`modules/data-store` isn't in the stack yet. Adding it is about five lines in
`stacks/service-env/terragrunt.stack.hcl` plus a `units/data-store/terragrunt.hcl` modelled on
`units/network/`. That's the point — it's cheap.

### Going further

Terragrunt also has an `autoinclude` block, which lets a stack declare a unit's dependencies
without editing the unit itself. This demo uses a plain `dependency` block instead: it's
standard, works on every Terragrunt version, and is the thing you'll reuse everywhere.
`autoinclude` is newer and worth a look once the basics are second nature.

---

## Act 6 — how you'd really run this

Everything so far used a local catalog. In practice the catalog is a shared repo that everyone's
`root.hcl` points at. Switch over by editing two lines in `root.hcl`:

```hcl
catalog {
  urls = [
    # ".",
    "github.com/SamHummerstoneArbor/catalog-scaffold-demo",
  ]
}
```

For that to work the modules have to be pushed and tagged:

```bash
git tag v0.1.0 && git push origin main --tags
```

Now `terragrunt catalog` clones the shared repo, and scaffolded units come out portable and
**version-pinned to the latest release tag** — which is what the local catalog couldn't do:

```hcl
terraform {
  source = "git::https://github.com/SamHummerstoneArbor/catalog-scaffold-demo.git//modules/network?ref=v0.1.0"
}
```

`--var=Ref=v0.1.0` and `--var=SourceUrlType=git-ssh` also become meaningful here. That combination
— a versioned module library plus a generator that pins to it — is the real destination.

> **Security.** Scaffold templates can run shell commands and hooks. `root.hcl` sets
> `no_shell = true` and `no_hooks = true`; keep them set before ever pointing a catalog at a repo
> you don't control. The Terragrunt docs are blunt about this: only scaffold templates you've
> reviewed.

This act is documented rather than walked through, since it needs a push.

---

## What it actually saved

| | By hand | With these tools |
|---|---|---|
| One `app-service` unit | Read 12 variables across 77 lines of `variables.tf`, get every name, type and default right, then write ~89 lines of HCL including the dependency block from memory | One command, then fill in **2** values. The other 10 are pre-filled or correctly commented out |
| Its `include`, tags, dependency wiring | Copy from another unit and hope it was right | Encoded once in `.boilerplate/`, applied every time |
| Changing house style across the library | Edit every unit that already exists | Edit one template |
| A new environment (2 units) | 2 directories, ~130 lines of HCL, dependency paths by hand | One 21-line stack file, or 2 values into a scaffolded one |
| A second environment | All of the above again | A two-line diff |

## Limitations, stated plainly

- **Scaffold is generate-once.** Add a variable to `modules/app-service/variables.tf` tomorrow
  and nothing regenerates the units you already made. These tools remove the cost of the *first*
  wiring, not of ongoing drift.
- **A local catalog produces non-portable `source` values.** See Act 1. Use a git URL for
  anything real.
- **`--output-folder` is a trap** for module sources. See Act 2.

---

## Cleanup and re-running

```bash
make destroy     # destroy every environment, then reset
make reset       # just delete generated files
```

`reset` removes `.terragrunt-state/`, every `.terragrunt-cache/` and `.terragrunt-stack/`,
anything you created under `live/prod/`, and any extra environment directories — leaving
`live/dev`, `live/prod` and `live/preview` exactly as committed. Run the whole demo again from a
clean slate as often as you like.

### Where state lives, and why it matters

`root.hcl` puts local state at `.terragrunt-state/<unit path>/terraform.tfstate`, anchored to the
repo root — **not** inside the unit directory. That's deliberate. Stack-generated units live
under `.terragrunt-stack/`, and `terragrunt stack clean` deletes that whole tree. State anchored
to the unit directory would be silently destroyed by a routine `clean`, with nothing having been
destroyed properly. You can prove the current setup is safe:

```bash
terragrunt stack run apply --working-dir live/preview
terragrunt stack clean     --working-dir live/preview
terragrunt stack generate  --working-dir live/preview
terragrunt stack run plan  --working-dir live/preview     # → "No changes"
```

---

## Version notes

Everything above assumes Terragrunt ≥ 1.1. If a colleague is on something older:

| Feature | Needs |
|---|---|
| `catalog` and `scaffold` at all | 0.54.0 |
| `terragrunt stack generate` | 0.71.3 (behind `--experiment stacks`) |
| Stacks stable, no experiment flag | 1.0.0 |
| README front-matter `tags` | 1.0.5 |
| Interactive scaffold form, component tabs, whole-repo discovery, `.terragrunt-catalog-ignore` | **1.1.0** |
| `scaffold` copying units/stacks + generating `terragrunt.values.hcl` | **1.1.3** |
| `catalog --format=jsonl\|md` | 1.1.3, and still needs `--experiment=catalog-format` |

On 0.88.x specifically: modules are only discovered in the repo root and `modules/`, the
`catalog` block accepts only `urls` and `default_template`, and pressing `s` in the TUI writes a
`# TODO` placeholder file with no form. The core loop works; the parts that make it feel fast
don't exist.

## Why the demo is shaped this way

[`docs/PLAN.md`](docs/PLAN.md) is the design document this repo was built from: what each piece
is meant to teach, which Terragrunt behaviours the layout had to work around, and where the
plan turned out to be wrong. Useful if you want to adapt this demo rather than just run it.

## Gotchas, collected

- `terragrunt scaffold` needs `//` between the repo root and the module subdirectory.
- Run `scaffold` from the directory you want the unit in; avoid `--output-folder` for modules.
- A local catalog URL yields an absolute `source`.
- `WARN Failed to find last release tag` on local sources is expected and harmless.
- A directory holding `.boilerplate/` is classified as a *template*, not a *module*. Add a
  `module` tag to its README front-matter to have it appear under both.
- `mock_outputs_allowed_terraform_commands` must include `destroy`, or tearing down a stack whose
  dependency has already gone fails.
- A custom `.boilerplate/boilerplate.yml` does **not** inherit `EnableRootInclude` and
  `RootFileName` from the built-in template — declare them yourself or the template breaks.
- `include` is not supported inside `terragrunt.stack.hcl`.
