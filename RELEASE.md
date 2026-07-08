# Release process

This describes how STIX-GSW releases are cut. There is no CI/CD for this — the whole process is manual and is normally run by the repo maintainer (see the "Who to contact" table in [README.md](README.md)) with push access to `master`.

## Prerequisites

- Push access to `master` (there is no branch protection on `master` — direct pushes for a release commit are the normal, expected path, not a workaround).
- [GitHub CLI](https://cli.github.com/) (`gh`) authenticated against this repo.
- No build or test step is required before releasing.

## Step-by-step checklist

Given a new version `vX.Y.Z`:

1. **Decide the version number.** There's no enforced SemVer contract — it's judged from the size/nature of the changes since the last tag (see "Versioning convention" below).
2. **Bump the version and metadata files in one commit:**
   - `stix/VERSION.txt` → `vX.Y.Z` (single line, read at runtime by `stix/idl/util/stx_gsw_version.pro`)
   - `.zenodo.json` → `"version": "vX.Y.Z"`
   - `CITATION.cff` → `version: vX.Y.Z` and `date-released: "<release date>"`

   Commit message: `Update VERSION.txt`, body: `New release vX.Y.Z`.
3. **Push the commit to `master`.**
4. **Tag and push:**
   ```
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```
   This creates a lightweight tag (no message/tagger of its own), consistent with every prior release tag in this repo.
5. **Write the release notes.** Historically this is a short hand-written paragraph highlighting what matters (new features, breaking changes, anything scientifically significant), followed by a closed-issues list where relevant, on top of GitHub's auto-generated PR list. Save it to a file, then:
   ```
   gh release create vX.Y.Z --title "Release of vX.Y.Z" -F <notes-file> --generate-notes
   ```
   `--generate-notes` appends the "What's Changed" (merged PRs) section and the `Full Changelog` compare link automatically; `-F`/`--notes` content is prepended above it.
6. **Verify:**
   - `gh release view vX.Y.Z` — check the published body/links.
   - Confirm Zenodo picked it up (see below) — usually within a couple of minutes.

## Versioning convention

Informal, not SemVer-enforced. Judge from the commit/PR content since the last tag: patch for bugfixes and small maintenance, minor for new capabilities, and use your judgment — there's no automated check.

## Metadata files to keep in sync

| File | Field(s) | Why |
|---|---|---|
| `stix/VERSION.txt` | version string | Source of truth read at runtime by `stx_gsw_version.pro` |
| `CITATION.cff` | `version`, `date-released` | Drives GitHub's "Cite this repository" button — directly user-facing |
| `.zenodo.json` | `version` | Repo-metadata correctness (see Zenodo note below — Zenodo doesn't strictly need this to be current) |

## Zenodo integration

The GitHub↔Zenodo integration is live: publishing a GitHub Release automatically archives it on Zenodo and mints a new version DOI under the concept DOI `10.5281/zenodo.6815762` (the one shown in the README badge), usually within a couple of minutes.

Zenodo derives `version`, `date`, and `related_identifiers` itself from the release/tag — it does **not** read those fields from `.zenodo.json` verbatim. It does consume `title`, `description`, `creators`, `license`, and `keywords` from `.zenodo.json`, so those need to be accurate.

To verify a new DOI was minted after releasing, query Zenodo's public API (no auth needed):
```
curl -s "https://zenodo.org/api/records?q=conceptdoi:10.5281/zenodo.6815762&all_versions=true"
```
Look for a record whose `metadata.version` matches the new tag.

## License

Current license: Apache-2.0 (as of the v0.6.2 release; earlier releases were archived under CC-BY-4.0 on Zenodo). If the license ever changes again, update `LICENSE`, `.zenodo.json`, and `CITATION.cff` together, and call it out explicitly in that release's notes.

## Distributing to SolarSoftware (SSW)

Publishing the GitHub Release does not by itself make the new version available to "standard" SSW/IDL users. A separate, manual, out-of-repo step pushes the code onto the STIX distribution server, from which SolarSoftware syncs it. This is run by whoever has access to that server (see "Who to contact" below) — there is no automation for it here, and server hostnames/paths are intentionally not written down in this public repo.

1. SSH into the STIX distribution server.
2. In your local clone of STIX-GSW there, fetch and check out the release tag — not just `git pull`, so you deploy exactly what was tagged rather than whatever `master` has moved to since:
   ```
   git fetch --all --tags
   git checkout vX.Y.Z
   ```
3. Create a new versioned folder under the SSW stix data directory and copy the `stix/` tree's contents into it:
   ```
   mkdir -p <ssw-stix-base>/vX.Y.Z
   rsync -a stix/ <ssw-stix-base>/vX.Y.Z/
   ```
4. Sanity-check the copy before going live: `cat <ssw-stix-base>/vX.Y.Z/VERSION.txt` should print `vX.Y.Z`.
5. Atomically repoint the `latest` symlink at the new folder:
   ```
   ln -sfn <ssw-stix-base>/vX.Y.Z <ssw-stix-base>/latest
   ```
   The `-n` matters — without it, if `latest` already resolves to a directory, `ln` creates the new link *inside* the old target instead of replacing `latest`.
6. Verify propagation:
   - `https://datacenter.stix.i4ds.net/pub/ssw/stix/latest/VERSION.txt` should update immediately.
   - `https://soho.nascom.nasa.gov/solarsoft/so/stix/VERSION.txt` (the official SSW mirror) typically follows within a day.
   - If the SOHO mirror hasn't updated after a day, it wasn't picked up properly — contact Säm Freeland (see README) to investigate.

## Who to contact

See the "Who to contact" table in [README.md](README.md) — domain owners listed there may want input on release-note wording for changes in their area. For SSW distribution/propagation issues specifically, that's Säm Freeland.
