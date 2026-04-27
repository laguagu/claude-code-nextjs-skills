---
name: hetzner-cloud
description: Manage Hetzner Cloud infrastructure with the `hcloud` CLI — servers, networks, firewalls, load balancers, volumes, DNS zones, SSH keys, primary/floating IPs, snapshots, certificates, placement groups, storage boxes. Use whenever the user mentions Hetzner, hcloud, VPS provisioning, or Hetzner location codes (fsn1, hel1, nbg1, ash, hil, sin) — even if they don't say "hcloud". CLI-only; does NOT cover Hetzner Robot (dedicated servers, separate product and API).
---

# Hetzner Cloud

Operate Hetzner Cloud through the `hcloud` CLI. When in doubt about server types, prices, locations, images, or flag syntax, run the discovery command rather than rely on this file or pretraining — the CLI is current.

## Authenticate

Generate a token in Hetzner Console → project → Security → API Tokens, then either:

```bash
hcloud context create <name>      # interactive: stored in cli.toml, persists across shells
export HCLOUD_TOKEN="…"           # CI/scripts: most commands read this automatically
```

`hcloud context create` is the one common case that still prompts even with the env var set — pass `--token-from-env` to skip the prompt in non-interactive sessions.

Health check: `hcloud datacenter list`.

## Mental model

`hcloud` manages everything inside **Hetzner Cloud**: servers, networks, firewalls, load balancers, volumes, DNS zones, SSH keys, primary/floating IPs, snapshots, certificates, placement groups, storage boxes.

It does **not** manage:
- **Hetzner Robot** — dedicated/auction servers, separate product and API.
- Project creation, billing, team membership, API token issuing — web console only.

**Discovery beats memorization.** Pretraining ages; the CLI is current.

| Question | Command |
|---|---|
| Server types and prices | `hcloud server-type list` |
| Locations and datacenters | `hcloud location list` |
| OS images | `hcloud image list --type system` (add `--architecture arm` for ARM) |
| Command/flag details | `hcloud <resource> <verb> --help` |
| Everything in this project at a glance | `hcloud all list` |

Structured output for scripts: `--output json | jq …`, `--output columns=id,name,status`, `--output format='{{.PublicNet.IPv4.IP}}'`.

## Workflows where order matters

Single commands are well-covered by `--help`. The chains worth pinning down:

**Server with SSH key + firewall, ready to log in** — key and firewall must exist before `server create` references them:

```bash
hcloud ssh-key  create --name <key> --public-key-from-file ~/.ssh/id_ed25519.pub
hcloud firewall create --name <fw>  --rules-file rules.json
hcloud server   create --name <srv> --type <type> --image ubuntu-24.04 \
                       --location hel1 --ssh-key <key> --firewall <fw>
hcloud server ssh <srv>
```

**Replace firewall rules atomically** (don't drift via repeated `add-rule`):

```bash
hcloud firewall replace-rules --rules-file rules.json <fw>
```

## Gotchas

1. **Public IPs get recycled.** A new server may inherit a previously-used IP and SSH refuses with `REMOTE HOST IDENTIFICATION HAS CHANGED!`. After deleting a server, `ssh-keygen -R <ip>` and let `ssh-keyscan` re-add the new host key.

2. **Context vs `HCLOUD_TOKEN`.** Context (in user-config `cli.toml`) persists across shells — preferred for interactive work. Env var is preferred for non-interactive use, paired with `--token-from-env`. A token sitting in a `.env` file is **not** automatically exported — shells must source it.

3. **Volumes are location-pinned.** A volume in `fsn1` cannot attach to a server in `hel1`. Match `--location` at creation.

4. **`hcloud zone` is only half of DNS.** The registrar's NS records must point to Hetzner's nameservers before queries resolve. Without that, the zone is just an internal database.

5. **Match location to where users are; pretraining defaults to `fsn1`.** Run `hcloud location list` and pick the closest. Private networks can't span network zones, only locations within one: `eu-central` (fsn1/hel1/nbg1), `us-east` (ash), `us-west` (hil), `ap-southeast` (sin).

6. **Don't quote prices or server-type specs from memory.** Always verify with `hcloud server-type list` before committing — names, specs, and pricing shift.

7. **Deletion is immediate and unrecoverable.** No undo on `server delete` or `volume delete`. `describe` first; create a snapshot (`hcloud server create-image --type snapshot <srv>`) beforehand if you might want the server back.

8. **Hetzner Cloud ≠ Hetzner Robot.** If the user mentions dedicated servers, server auctions, or the Robot dashboard — that's the other product. Surface the distinction; don't try to manage it here.

## Docs

- API reference (per-resource endpoints): https://docs.hetzner.cloud/reference/cloud
- Cloud product guide: https://docs.hetzner.com/cloud/
- CLI source and changelog: https://github.com/hetznercloud/cli
