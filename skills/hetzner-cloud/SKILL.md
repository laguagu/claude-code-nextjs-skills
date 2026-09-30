---
name: hetzner-cloud
description: Manage Hetzner Cloud infrastructure with the `hcloud` CLI — servers, networks, firewalls, load balancers, volumes, DNS zones, SSH keys, primary/floating IPs, snapshots, certificates, placement groups, storage boxes. Use whenever the user mentions Hetzner, hcloud, VPS provisioning, or Hetzner location codes (fsn1, hel1, nbg1, ash, hil, sin) — even if they don't say "hcloud". CLI-only; does NOT cover Hetzner Robot (dedicated servers, separate product and API).
---

# Hetzner Cloud

Use the installed `hcloud` CLI and its `--help`/JSON output for current
resource types, locations, flags and pricing. This covers Cloud/DNS/Storage
Box APIs supported by that CLI; dedicated servers/auctions use Hetzner Robot.

## Authentication and discovery

Use the authorized project's existing context or `HCLOUD_TOKEN`. A token in
an env file is not automatically exported. Creating a context normally
prompts; `hcloud context create --token-from-env <name>` uses the process
token without prompting. Keep tokens out of command arguments/logs.

Confirm project/context before writes. Do not quote a remembered server
specification or price; read them:

| Question | Command |
|---|---|
| Server types, per-location availability, prices | `hcloud server-type list`, `hcloud server-type describe <type> -o json` |
| Locations and network zones | `hcloud location list` |
| OS images | `hcloud image list --type system --architecture arm` (or `x86`) |
| Everything in the project | `hcloud all list` (`--paid` for billed resources) |
| Flags | `hcloud <resource> <verb> --help` (works offline) |

Scripts: `-o json`, `-o columns=…` or `-o noheader`.

## Dependencies and verification

Referenced SSH keys/firewalls/networks must exist before server creation:

```bash
hcloud ssh-key create --name <key> --public-key-from-file ~/.ssh/id_ed25519.pub
hcloud firewall create --name <fw> --rules-file rules.json
hcloud server create --name <srv> --type <type> --image <image> --location <loc> --ssh-key <key> --firewall <fw>
```

Inspect a proposed firewall change against the current rules and retain a
working management path. `firewall replace-rules --rules-file` and
`zone import-zonefile` replace the whole set, so omitted rules/records disappear.

Treat server state, network reachability and application health as separate
checks. Read the API action result and resource state back after changes;
verify the intended service from its actual caller.

## Gotchas worth retaining

- A recycled IP can trigger SSH's changed-host-key warning. Authenticate the
  new fingerprint through a trusted console/channel before updating
  known_hosts; `ssh-keyscan` alone does not establish identity.
- Servers and Primary IPs lost their `datacenter` property on 2026-07-01:
  `server create --datacenter` no longer exists; use `--location`. Server types
  are location-dependent, so check the type is available where you create it.
- Volumes are location-pinned; a server in another location cannot attach them.
  Private networks span locations within one network zone, not across zones:
  `eu-central` (fsn1, nbg1, hel1), `us-east` (ash), `us-west` (hil),
  `ap-southeast` (sin).
- DNS zones do not take effect until the registrar delegates to the correct
  nameservers. Inspect delegation before debugging records.
- Deletion is immediate. Confirm resource IDs and the requested destructive
  scope; establish recoverable data first
  (`hcloud server create-image --type snapshot <srv>`). Server snapshots/backups
  exclude attached Volumes, which need their own backup. See
  [snapshot scope](https://docs.hetzner.com/cloud/servers/backups-snapshots/overview/).
  Assigned Primary/Floating IPs cannot be deleted; unassign them first.
- `status: running` does not prove reachability. When several otherwise-open
  ports time out, check for an abuse-department block:
  `hcloud server describe <srv> -o json | jq '.public_net | {v4: .ipv4.blocked, v6: .ipv6.blocked}'`.
  Such symptoms alone do not prove a block; a block needs Hetzner support, not
  a firewall or app fix.
- Firewall JSON must match the API schema. `source_ips` is an array of strings;
  PowerShell serialization needs sufficient JSON depth. A parsing failure
  leaves the previous rules in place; verify the returned/live rules.
- Storage Box/DNS subcommands and API boundaries can evolve. Use installed
  command help and the official changelog rather than treating an older
  Cloud-only feature list as current.

## Sources

- [API changelog](https://docs.hetzner.cloud/changelog) for renames and removals
- [API reference](https://docs.hetzner.cloud/reference/cloud)
- [Product documentation](https://docs.hetzner.com/cloud/)
- [CLI manual/source](https://github.com/hetznercloud/cli/tree/main/docs/reference/manual)
