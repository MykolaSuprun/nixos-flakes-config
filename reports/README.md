# NixOS store usage report

The accompanying reports describe the active `geks-nixos` system generation
`8cjaxs11b118dpks7y1h18f7b2dgycbw`, captured on 2026-11-03. The checkout may
have changed since that generation was built. The complete ranked list is in
[geks-nixos-store-usage.txt](geks-nixos-store-usage.txt); the same rows in
[CSV](geks-nixos-store-usage.csv) contain exact byte counts and store paths.

The active closure totals **102.31 GiB** in NAR sizes, across 8,360 store paths.
The report discovers 829 distinct package outputs, system components and
service units. Their union accounts for 102.01 GiB, and the remaining 308.35 MiB
is attributed to the rest of the system graph. Rows overlap; do not sum them.

Largest profile-package candidates by size used by no other profile package:

| Package | Profile-exclusive | Total closure | Where to investigate |
| --- | ---: | ---: | --- |
| ComfyUI | 22.84 GiB | 22.84 GiB | Private ComfyUI NixOS and LLM tools modules, imported in `flake/hosts/geks-nixos/default.nix` |
| OpenClaw | 3.11 GiB | 4.21 GiB | `myconf.openclaw.enable` in `home-manager/users/mykolas/home-geks-nixos.nix`; private module |
| OpenCode | 3.00 GiB | 6.87 GiB | `home-manager/modules/dev-pkgs.nix`, and other system/profile references |
| Lutris | 2.85 GiB | 4.77 GiB | `nixos/desktop-config.nix` |
| llama.cpp | 2.81 GiB | 3.68 GiB | Private LLM tools module |
| GHC | 2.54 GiB | 2.97 GiB | `home-manager/modules/dev-pkgs.nix` |
| LM Studio | 2.32 GiB | 3.69 GiB | Private overlay and system configuration |
| LibreOffice | 1.66 GiB | 3.41 GiB | `home-manager/modules/desktop-config.nix` |
| ChatGPT | 1.62 GiB | 2.51 GiB | `myconf.chatgpt.enable` in `home-manager/users/mykolas/home-geks-nixos.nix`; private module |
| OnlyOffice | 1.29 GiB | 2.14 GiB | `home-manager/modules/desktop-config.nix` |
| Zoom | 1.22 GiB | 2.90 GiB | `home-manager/modules/desktop-config.nix` |
| Steam | 1.17 GiB | 11.11 GiB | System gaming configuration and Home Manager launcher |

For example, ComfyUI's closure includes 11.52 GiB for its PyTorch store path and
1.75 GiB for one hipBLASLt store path. The profile-exclusive number is a
shortlisting aid: ComfyUI is also referenced by its system service. Removing its
Home Manager CLI alone therefore would not necessarily free that closure.
LibreOffice and OnlyOffice are both installed, making them useful candidates
to compare if one office suite is sufficient. Several browsers, terminals and
chat clients are also installed; use the full list to assess them.

## Regenerate or inspect

Requires Node.js and Nix, plus access to the Nix daemon. From the repository:

```sh
node scripts/nixos-store-usage.js --scope packages --limit 30
node scripts/nixos-store-usage.js --sort total --scope system --limit 30
node scripts/nixos-store-usage.js --details comfy-ui --limit 20
node scripts/nixos-store-usage.js --format csv --output store-usage.csv
node scripts/nixos-store-usage.js --format json --output store-usage.json
node scripts/nixos-store-usage.js --system /nix/var/nix/profiles/system-297-link
node scripts/test-nixos-store-usage.js
```

Use `--help` for all options. `--system` must point to a realized system
accessible in the local store. For another host, run the script on that host or
provide a system closure already present locally. The script queries the store;
it does not evaluate the checkout, build packages, remove anything, or run GC.

## Reading the numbers

- **total**: the root's full transitive runtime-reference closure, including
  the root itself.
- **peer**: for profile packages, closure bytes reached by exactly one
  discovered profile package. For other roots, this equals `unique`.
- **peerShared** (CSV/JSON): `total - peer`; for profile packages this is the
  size also reached by another profile package.
- **unique**: closure bytes reached by this root alone among all listed roots,
  and not retained by the residual system graph after cutting the discovered
  profile, direct system-component and service-unit entry edges.
- **shared**: `total - unique`; includes other roots and the residual graph.
  `baselineShared` counts the portion reachable from the residual graph.

The stricter `unique` value is often zero for profile packages because the Home
Manager activation unit or generated system configuration references the same
outputs. This is expected: a configuration rebuild can replace those generated
references, so zero does not mean a package can never be removed. Conversely,
`peer` can overestimate savings when system services, fonts, or other system
components also retain the paths. Use `--details` to inspect individual paths
and their profile/system sharing. Service units can be aggregates: for example,
the Home Manager activation service references a large part of the home
closure. Large service totals must not be treated as independent installations.

Sizes are Nix's uncompressed serialized **NAR sizes**, not measured filesystem
blocks. Compression, reflinks, deduplication, snapshots and filesystem overhead
can change physical disk usage. The report covers runtime references in one
active system closure; it does not measure build-only dependencies, unrelated
Nix profiles or generations, garbage-collection roots, Flatpak, containers,
VM images, Steam downloads, model files, home data or caches. Old generations
or other roots can retain paths after a rebuild, so actual reclaimable space
requires checking GC roots and storage separately. Profile roots are realized
linked outputs, not an evaluated source-package list; generated aggregates,
service-only dependencies and outputs without linked profile files can appear
under a system root or in the residual graph.
