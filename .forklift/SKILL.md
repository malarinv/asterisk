---
name: sync-upstream
description: Rebase asterisk (asterisk) fork/parity/24.0.0 against asterisk (upstream) upstream/24.0.0. Handles conflict resolution automatically for trivial cases and escalates semantic conflicts.
---
<!-- forklift v1 -->

# Sync Upstream (asterisk ← upstream)

Rebase `fork/parity/24.0.0` against `upstream/24.0.0` (upstream). This skill provides the knowledge you need to resolve conflicts correctly during the rebase.

## Script

```bash
git rebase upstream/24.0.0
```

Git operations run through the command above. You resolve conflicts using the decision tree below.

## Conflict Walk

Read a conflict from git's three-way index, not from the conflict-marker file: markers hide which side changed what and cannot show what the two sides share.

**Before the rebase starts**, reconcile the branch picture against what the registry claims — this is the macro intent every per-commit decision below serves:

```bash
git diff --stat upstream/24.0.0...parity/24.0.0
```

**Extract the three stages** of each conflicted path into a scratch directory (keep the extension — parsers key on it):

```bash
p=<conflicted-path>; ext=${p##*.}; d=$(mktemp -d)
git ls-files -u -- "$p"                 # which stages actually exist
git show :1:"$p" > "$d/base.$ext"       # common ancestor
git show :2:"$p" > "$d/ours.$ext"       # so-far-rebased series, starting from upstream
git show :3:"$p" > "$d/theirs.$ext"     # the fork commit being replayed
```

During a rebase the roles swap: `:2:` (ours) is the rebased series, `:3:` (theirs) is your feature commit.

**Missing stages.** For add/add, delete/modify and rename conflicts a stage is absent — `git ls-files -u` lists only the stages git holds. Read an absent stage as an empty file and take the decision tree's semantic branch (escalate); never reconstruct the missing side from marker text.

**Read each side against base:**

```bash
git diff --no-index --color=never "$d/base.$ext" "$d/ours.$ext"    # upstream's change
git diff --no-index --color=never "$d/base.$ext" "$d/theirs.$ext"  # the feature's change
```

`--no-index` exits 1 when the files differ — the normal case, not an error.

**Noise filter.** When `base → ours` differs from base only in whitespace or reformatting, the hunk is a formatter artifact, not a semantic clash: keep the feature's content from `:3:`, skip ESCALATE, and prove it by compiling. When `base → ours` carries a real change to a file listed in § Owned Symbols, it is a MERGE PATH conflict: take upstream's structure and graft the named symbols into it.

**Gate each paused commit.** After resolving one commit's conflicts and before `git rebase --continue`, run the protecting tests of every feature whose owned paths you just touched:

```bash
make <protecting_tests for the touched features>
```

A red test here names the resolution that broke the feature; waiting for the end-of-rebase suite attributes the break to dozens of commits.

## Post-Rebase Checklist

After all conflicts are resolved and compilation passes, perform these bookkeeping steps before force-pushing:

- **Converge the commit count and the generated docs in one step.** Run
  ```bash
  git rebase upstream/24.0.0 --rebaseline
  ```
  It records the fork's commit count in `.forklift/registry.yaml`, re-renders every generated
  artifact the registry describes (SKILL.md, `AGENT.md`, the fork-commits table in
  `.forklift/README.md`), and lands them as one atomic commit — the count it records is the value the
  range will have once that commit lands, so `forklift doctor` check 5 passes afterwards.
  Do **not** hand-edit `expected_fork_commit_count` and do **not** re-render into a second
  commit: the count is self-referencing, and a second render leaves the fork doc one behind.
  If you already committed something by hand, run `git rebase upstream/24.0.0 --rebaseline-only` — it
  converges the bookkeeping without fetching or rebasing.
- **Update feature registry.** If new files were added, removed, or moved, update `.forklift/registry.yaml` and re-run the rebaseline above (it re-renders).
- **Update divergence list.** If a previously divergent file is now owned by asterisk, update both lists.

## Feature Stack

These are asterisk-owned files. Conflicts here prefer ours unless upstream's change is semantic.

| Feature | Owned files |
|---------|------------|
| ont_parity endpoint option | `include/asterisk/res_pjsip.h`, `res/res_pjsip/pjsip_configuration.c`, `res/res_pjsip/pjsip_config.xml` |
| SDP parity (maxptime/fmtp/tel-event) | `res/res_pjsip_sdp_rtp.c` |
| Header parity (message filter) | `res/res_pjsip/pjsip_message_filter.c` |
| Qualify OPTIONS shape | `res/res_pjsip/pjsip_options.c` |

> **Note:** The § Owned Symbols table below is generally more current than this § Feature Stack, because new shared-file symbols are registered immediately while high-level feature rows may lag. After any feature merge, audit both tables.

## Owned Symbols in Shared Files

When a conflict occurs in a file shared with upstream, the Feature Stack tells you "prefer ours"
but doesn't tell you *which lines are ours*. This section lists the exact symbols each feature
owns inside shared files.

### res_pjsip.h (include/asterisk/res_pjsip.h)

| Feature | Symbol | Location | Description |
|---------|--------|----------|-------------|
| ont_parity | struct ast_sip_endpoint | Boolean: emit carrier-ONT wire shapes for this endpoint. |

### pjsip_message_filter.c (res/res_pjsip/pjsip_message_filter.c)

| Feature | Symbol | Location | Description |
|---------|--------|----------|-------------|
| filter_message_restrictions.ont_parity | struct filter_message_restrictions | Per-message parity flag copied from the endpoint in both outgoing supplements. |

### res_pjsip_sdp_rtp.c (res/res_pjsip_sdp_rtp.c)

| Feature | Symbol | Location | Description |
|---------|--------|----------|-------------|
| generate_fmtp_attr | static function | Signature extended with ont_parity; strips annexb and can suppress the whole line. |

### pjsip_options.c (res/res_pjsip/pjsip_options.c)

| Feature | Symbol | Location | Description |
|---------|--------|----------|-------------|

## Upstream Divergences (take upstream)

These upstream files exist but asterisk intentionally doesn't override them. Always take upstream:

> **WARNING:** The divergence list exists because these files are considered upstream-owned. If you add an asterisk feature that modifies one of these files, the feature will be silently lost on the next sync (the decision tree will "prefer upstream"). You must either:
> 1. Move the feature out of these files, or
> 2. Add the file to the Feature Stack registry and change the divergence list entry to note the dual ownership.

## Obsoleted Fixes

No upstream-obsoleted fixes are currently tracked.

## Intentional Removals (deleted vs upstream)

These upstream paths are intentionally absent from asterisk. `the sync runner --verify` fails if any other upstream file goes missing.

None registered.

## Escalation Format

When escalating, output exactly:

```
ESCALATE
file: <path>
reason: <one sentence: what upstream changed and which asterisk feature it affects>
upstream: <brief description of upstream's version>
ours: <brief description of asterisk's version>
question: adapt our feature to upstream's change, or drop the upstream change?
```

## After Resolution

Once all conflicts are resolved:

- **Verify no conflict markers remain:**
  ```bash
  git grep -n '<<<<<<<'
  ```

- **Run the type check (not just lint):**
  ```bash
  make
  ```
  This catches structural breakage (truncated objects, orphaned references) that lint misses. Ignore pre-existing errors in dependency directories or upstream-owned files.

- **Verify no commits were silently dropped:**
  ```bash
  git rev-list --count upstream/24.0.0..parity/24.0.0
  ```
  Compare against `expected_fork_commit_count` in the registry. Treat a moved
  number as a *symptom only*: it names no feature. When it moves, use the
  per-feature coverage and liveness results to find which capability actually
  stopped running.

- **Update .forklift/README.md § Last Sync Point.**

- **Push:**
  ```bash
  git push origin parity/24.0.0 --force-with-lease
  ```
  If the push fails with `remote: fatal: did not receive expected object <sha>`,
  see § Push Failure: Fork-Network Missing Objects below.

## Push Failure: Fork-Network Missing Objects

**Symptom:**
```
remote: fatal: did not receive expected object 2a0da9f7653a83fa51b38b36436aea2eb3dc7fe8
error: remote unpack failed: index-pack failed
```

**Root cause:** GitHub fork networks share an object database between the parent repo
and the fork. During push negotiation,
the fork advertises objects it can see through the alternate as `have`, so the client
builds a thin pack with deltas against those bases. But when `receive-pack` runs
server-side it looks up the bases in the *fork's own* object DB (which doesn't see
through the alternate during writes) and finds them missing → unpack failure.

Typically triggered after the parent repo is repacked, force-pushed, or GC'd in a way
that orphans objects from the fork's view but leaves stale `have` advertisements.

**Fix:** push each missing object as a temporary ref on origin, forcing the fork to
copy it into its own object database. Loop until the target push succeeds, then delete
the temp refs.

```bash
for i in $(seq 1 15); do
  out=$(git push origin parity/24.0.0 --force-with-lease 2>&1)
  missing=$(echo "$out" | grep -oE 'expected object [0-9a-f]{40}' | awk '{print $3}' | head -1)
  [ -z "$missing" ] && { echo "$out" | tail -3; break; }
  echo "Pinning missing object: $missing"
  git fetch upstream "$missing" 2>&1 | tail -1
  git push origin "$missing:refs/heads/_owns_${missing:0:8}" 2>&1 | tail -1
done

# Cleanup
refs=$(git ls-remote origin '_owns_*' | awk '{print $2}' | sed 's|refs/heads/||')
[ -n "$refs" ] && git push origin --delete $refs
```

Each iteration unblocks one delta base. Three to five iterations is typical for a
multi-week sync gap; sometimes only one. The temporary `_owns_<sha8>` branches are
harmless if forgotten but should be deleted when the push completes.
