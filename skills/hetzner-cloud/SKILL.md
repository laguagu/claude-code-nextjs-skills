---
name: hetzner-cloud
description: Manage Hetzner Cloud infrastructure with the `hcloud` CLI — servers, networks, firewalls, load balancers, volumes, DNS zones, SSH keys, primary/floating IPs, snapshots, certificates, placement groups, storage boxes. Use whenever the user mentions Hetzner, hcloud or Hetzner location codes (fsn1, hel1, nbg1, ash, hil, sin), or wants a VPS or cloud server in a project that already runs on Hetzner — even if they don't say "hcloud". CLI-only; not for Hetzner Robot (dedicated servers, separate product and API).
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

Confirm project/context before writes. Discover server types, system images,
architecture, location/network zone and price through current CLI/API data
(`hcloud server-type list`, `hcloud location list`,
`hcloud image list --type system --architecture arm`, `hcloud all list` for the
whole project). Do not quote a remembered server specification or price.

## Dependencies and verification

Referenced SSH keys/firewalls/networks must exist before server creation.
Inspect a proposed firewall change against the current rules and retain a
working management path. `firewall replace-rules --rules-file` replaces the
set, so omitted rules disappear. `zone import-zonefile --zonefile` likewise
replaces all Zone RRSets; omitted records disappear.

Cloud Firewalls do not yet protect private Network traffic
or Load Balancers. Use host/application controls where needed. Verify rule
changes with fresh connections; established connections survive updates.

Treat server state, network reachability and application health as separate
checks. Read the API action result and resource state back after changes;
verify the intended service from its actual caller.

## Gotchas worth retaining

- A recycled IP can trigger SSH's changed-host-key warning. Authenticate the
  new fingerprint through a trusted console/channel before updating
  known_hosts; `ssh-keyscan` alone does not establish identity.
- Servers and Primary IPs lost their `datacenter` request/response property on
  2026-07-01. The CLI's `--datacenter` flags on `server create` and
  `primary-ip create` are removed; use `--location` (or `--assignee-id` for a
  Primary IP). The datacenter endpoints were removed on 2026-10-01, so the
  still-shipped `hcloud datacenter list/describe` commands fail with HTTP 410
  Gone. Inspect the server type's per-location availability and prices with
  `hcloud server-type describe <type> -o json`.
- Volumes are location-pinned; a server in another location cannot attach them.
  Private networks span locations within one network zone, not across zones.
- DNS zones do not take effect until the registrar delegates to the zone's
  assigned nameservers. Before debugging records, read the Authoritative
  Nameservers section of `hcloud zone describe <zone>` (JSON:
  `.authoritative_nameservers`): `delegation_status` should be `valid` and
  `delegated` should match `assigned`; `delegation_last_check` shows how old
  that result is.
- Deletion is immediate. Confirm resource IDs and the requested destructive
  scope; establish recoverable data first. Automatic backups are deleted with
  the server; snapshots survive. Create a Snapshot or
  convert a backup to one before deletion if recovery is required.
  Server snapshots/backups exclude
  attached Volumes, which need their own backup. See
  [snapshot scope](https://docs.hetzner.com/cloud/servers/backups-snapshots/overview/).
  Assigned Primary/Floating IPs cannot be deleted; unassign them first.
- `status: running` does not prove reachability. Inspect
  `hcloud server describe <srv> -o json | jq '.public_net | {v4:.ipv4.blocked, v6:.ipv6.blocked}'`
  for a provider block (abuse report or unpaid invoice) when several
  otherwise-open ports time out, SSH open to `0.0.0.0/0` included, or every
  server on the account fails at once. Such symptoms alone do not prove a
  block; a provider-level block needs Hetzner support, not an app firewall fix.
- `firewall create`/`replace-rules --rules-file` takes a bare JSON array of
  rule objects (the `rules` value of `hcloud firewall describe <fw> -o json`),
  not the API's `{"rules": [...]}` body, although the flag help points at the
  API schema. `source_ips`/`destination_ips` are arrays of CIDR strings
  (`203.0.113.4/32`, not a bare IP) and `port` is a string (`"22"`, `"80-85"`).
  In PowerShell serialize with `ConvertTo-Json -InputObject @($rules) -Depth 5`
  so a single rule stays an array. A parse or CIDR error rejects the whole file
  and leaves the previous rules in place; verify the returned/live rules.

## Sources

- [API changelog](https://docs.hetzner.cloud/changelog) for renames and removals
- [API reference](https://docs.hetzner.cloud/reference/cloud)
- [Product documentation](https://docs.hetzner.com/cloud/)
- [CLI manual/source](https://github.com/hetznercloud/cli/tree/main/docs/reference/manual)
