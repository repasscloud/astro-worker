# ADR 0003 — Adopt AGPL-3.0 and qualify distribution per channel

Accepted in [issue #1](https://github.com/repasscloud/astro-worker/issues/1).
Astro Worker uses AGPL-3.0-only. The prior MIT grant and notice are preserved
for previously published material. Repository history attributes the
application contributions to the owner and the workflow dependency updates
to Dependabot. Generated framework files and dependencies retain applicable
upstream terms and notices.

Evaluate Swiss Ephemeris under the [Astrodienst AGPL terms](https://www.astro.com/swisseph/swephinfo_e.htm).
Keep the replaceable calculation interface and validate native and browser
implementations independently. A Professional licence purchase is outside the
approved model.

## Official builds

Publish version 1.0.0 from a clean committed revision. Show the shortened
Git commit hash in About and release metadata. Native package counters use
separate numeric values. Publish a versioned Git tag and link each binary
to the full commit and complete machine-readable corresponding source for
that binary. Include build scripts, platform code, configuration templates,
resources and any required source for linked dependencies and generated
binaries. Preserve notices and keep private signing material outside
the repository. Verify that someone can obtain the source without buying
the package and build a modified version using their own credentials.

Review each channel's terms, signing, DRM, EULA, redistribution, source
availability, and any installation-information requirements against the
[AGPL text](https://www.gnu.org/licenses/agpl-3.0.en.html) before publication.
Pricing follows the [product requirements](../product/requirements.md).
Track unresolved channels separately in the release backlog.
