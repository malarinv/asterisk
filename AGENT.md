# Agent Instructions — asterisk

This repository is a **fork** of asterisk kept in sync by forklift. Everything between the two markers below is generated from `.forklift/registry.yaml`: edit the registry and re-run `forklift render` rather than editing the block. Prose outside the markers is hand-maintained and preserved byte-for-byte.

<!-- GENERATED:FORKLIFT_START -->
<!-- Do not edit this block: `forklift render` regenerates it. The tables come from .forklift/registry.yaml; the situation playbook comes from templates/situations.yaml. -->
## Fork Identity & Remotes
- **Fork remote/branch**: `origin/parity/24.0.0`
- **Upstream remote/branch**: `upstream/24.0.0`
- **Expected fork commits**: `2`

## Fork-Owned Features
These are the paths this fork owns; prefer ours when they conflict with upstream, and register any new fork-owned path in `.forklift/registry.yaml` before relying on it.

| Feature | Description | Owned Paths |
| --- | --- | --- |
| ont_parity endpoint option | Per-endpoint ont_parity boolean (sorcery endpoint option, default no) gating every parity behavior; default preserves upstream behavior byte-for-byte. | `include/asterisk/res_pjsip.h`<br>`res/res_pjsip/pjsip_configuration.c`<br>`res/res_pjsip/pjsip_config.xml` |
| SDP parity (maxptime/fmtp/tel-event) | With ont_parity: no a=maxptime, no G729 annexb fmtp (no fmtp line when empty), single 8kHz telephone-event rtpmap at payload 97 with receive mapping registered on the instance. rtp_engine.c untouched. | `res/res_pjsip_sdp_rtp.c` |
| Header parity (message filter) | With ont_parity: Allow replaced with the ONT's 14-method list (only when already present), User-Agent replaced with 'MTK', Supported cut to 'replaces'. Reads parity via filter_module_tsx.id slot; the broken transport.id lookup is left unrepaired deliberately. | `res/res_pjsip/pjsip_message_filter.c` |
| Qualify OPTIONS shape | With ont_parity: qualify OPTIONS drops Contact/Route/User-Agent and rewrites From to the bare registrar-domain identity, matching the carrier ONT's SBC keepalive (sibling-subscriber reference; our own idle OPTIONS are unobservable through the mirror). | `res/res_pjsip/pjsip_options.c` |

## Verification Commands
- **Typecheck**: `make`
- **Test**: `make`
- **Lint**: `git diff --check`

## Divergences & Intentional Removals
**Divergences (upstream-owned, take upstream):**

None registered.

**Intentional removals (deleted on purpose):**

None registered.

## Fork Maintenance Situations
The person asking for work on this fork describes **what they want**, not how the harness works. Match their request to a situation below, read that procedure, and follow it. Never ask them which command to run, which registry field to fill, or which files a feature owns — that is the procedure's work, not theirs.

| They say something like | What you do | Where the procedure is |
| --- | --- | --- |
| "set this fork up", "make this repo fork-aware", "we are forking this project" | draft the registry, install the harness, and hand back the worklist of what still needs claiming | the `forklift-init` skill |
| "I just added a feature", "make sure my new code survives the next sync" | register the feature so the next rebase cannot drop it | the `forklift-maintain` skill, § *Register a feature* |
| "sync with upstream", "pull in upstream's changes", "rebase onto upstream" | size the conflict surface, rebase, resolve, gate, and push | the `sync-upstream` skill |
| "is the fork healthy", "what drifted", "does the registration still match the code" | audit the registration against the tree and report the findings | the `forklift-doctor` skill |
| "the rebase went wrong", "features got dropped", "the history is too tangled to rebase" | triage the history and rebuild it topically | the `forklift-maintain` skill, § *Rebuilding the history* |
<!-- GENERATED:FORKLIFT_END -->

## Repository Specific Notes

