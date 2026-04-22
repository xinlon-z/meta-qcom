# meta-qcom CI KAS Configurations

This directory contains [KAS](https://kas.readthedocs.io/) YAML configuration files used to build Yocto Project images for Qualcomm platforms. KAS resolves layers, sets BitBake variables, and locks repository revisions — all in a single composable file per concern.

Builds are assembled by combining multiple files using KAS's `:` separator:

```sh
kas build ci/base.yml:ci/rb3gen2-core-kit.yml:ci/qcom-distro.yml
```

---

## File Categories

### Base / Lock

| File | Description |
|------|-------------|
| `base.yml` | Foundation for all builds. Pulls in `oe-core`, `bitbake`, and `meta-qcom`. Sets disk monitoring, CodeLinaro mirrors, QCOM image classes, and `nodistro` distro. |
| `base.lock.yml` | Pins exact git commits for all major components (`oe-core`, `bitbake`, `meta-arm`, `meta-openembedded`, `meta-virtualization`, `meta-audioreach`, `meta-selinux`, `meta-updater`, `meta-security`) for fully reproducible builds. |

### CI

| File | Description |
|------|-------------|
| `ci.yml` | CI-specific overrides. Includes `mirror.yml`, disables work directory cleanup (`rm_work`), enables firmware compression (`zst`). |

### Machine / Board Targets

Each file sets `machine:` and includes `base.yml`.

| File | Board |
|------|-------|
| `rb1-core-kit.yml` | Qualcomm RB1 Core Kit |
| `rb3gen2-core-kit.yml` | Qualcomm RB3 Gen 2 Core Kit |
| `rb3gen2-core-kit-open-fw.yml` | RB3 Gen 2 with open firmware (also includes `meta-arm.yml`) |
| `qcs615-ride.yml` | QCS615 RIDE |
| `qcs8300-ride-sx.yml` | QCS8300 RIDE-SX |
| `qcs9100-ride-sx.yml` | QCS9100 RIDE-SX |
| `qcm6490-idp.yml` | QCM6490 IDP |
| `iq-615-evk.yml` | IQ615 EVK |
| `iq-8275-evk.yml` | IQ8275 EVK |
| `iq-9075-evk.yml` | IQ9075 EVK |
| `iq-x5121-evk.yml` | IQX5121 EVK |
| `iq-x7181-evk.yml` | IQX7181 EVK |
| `kaanapali-mtp.yml` | Kaanapali MTP |
| `glymur-crd.yml` | Glymur CRD |
| `sm8750-mtp.yml` | SM8750 MTP |

> **Symlinks:** `qcs6490-rb3gen2-core-kit.yml` → `rb3gen2-core-kit.yml`, `qrb2210-rb1-core-kit.yml` → `rb1-core-kit.yml`

### Distro

| File | Description |
|------|-------------|
| `qcom-distro.yml` | Full distro stack: adds `meta-qcom-distro`, `meta-openembedded`, `meta-virtualization`, `meta-audioreach`, `meta-selinux`, `meta-updater`, `meta-security`. Builds `qcom-multimedia-image`, `qcom-multimedia-proprietary-image`, and `qcom-container-orchestration-image`. |
| `qcom-distro-catchall.yml` | Catch-all distro variant (`qcom-distro-catchall`) for broad board coverage. Includes `qcom-distro.yml`. |
| `qcom-distro-kvm.yml` | KVM/virtualisation variant (`qcom-distro-kvm`). Includes `qcom-distro.yml`. |
| `qcom-distro-multimedia-image.yml` | Restricts targets to `qcom-multimedia-image` only. Includes `qcom-distro.yml`. |
| `qcom-distro-selinux.yml` | SELinux-enabled variant (`qcom-distro-selinux`). Includes `qcom-distro.yml`. |
| `qcom-distro-sota.yml` | OTA update variant (`qcom-distro-sota`) via `meta-updater`. Includes `qcom-distro.yml`. |

### Kernel Source Overrides

These files override `PREFERRED_PROVIDER_virtual/kernel` (and optionally `PREFERRED_VERSION_virtual/kernel`). Combine with any board + distro config.

| File | Kernel |
|------|--------|
| `linux-qcom-6.18.yml` | Stable QCOM kernel 6.18.y |
| `linux-qcom-rt-6.18.yml` | Real-time QCOM kernel 6.18.y |
| `linux-qcom-next.yml` | QCOM development kernel (`linux-qcom-next`) |
| `linux-qcom-next-rt.yml` | Real-time development kernel (`linux-qcom-next-rt`) |
| `linux-yocto-dev.yml` | Generic Yocto development kernel |
| `u-boot-qcom.yml` | Selects the QCOM U-Boot bootloader (`PREFERRED_PROVIDER_virtual/bootloader`) |

### Architecture

| File | Description |
|------|-------------|
| `meta-arm.yml` | Adds `meta-arm` and `meta-arm-toolchain` layers for ARM toolchain support. |
| `qcom-armv7a.yml` | Generic 32-bit ARM machine (`qcom-armv7a`). Includes `base.yml`. |
| `qcom-armv8a.yml` | Generic 64-bit ARM machine (`qcom-armv8a`). Includes `base.yml`. |

### Mirror / Fetch

| File | Description |
|------|-------------|
| `mirror.yml` | Configures `SSTATE_MIRRORS` to use the Yocto Project shared-state cache — speeds up incremental builds. |
| `mirror-tarballs.yml` | Sets `BB_GENERATE_MIRROR_TARBALLS = "1"` to produce source tarballs during a build (used for populating a mirror). |
| `mirror-download-disable.yml` | Removes `qli-mirrors` from `INHERIT` — forces all sources to be fetched directly (used when generating a clean mirror). |
| `mirror-download-test.yml` | Sets `BB_FETCH_PREMIRRORONLY = "1"` — validates that every source can be satisfied from the configured premirror. |

### Build Options

| File | Description |
|------|-------------|
| `debug.yml` | Sets `DEBUG_BUILD = "1"` to compile with debug symbols. |
| `performance.yml` | Appends `quiet` to `KERNEL_CMDLINE_EXTRA` to reduce boot time. |
| `world.yml` | Sets the build target to `world` and restricts `EXCLUDE_FROM_WORLD` to non-`layer-qcom` packages. |

### UEFI Capsule / Firmware Signing

| File | Description |
|------|-------------|
| `capsule.yml` | Enables UEFI FMP capsule generation via `firmware-qcom-capsule`. |
| `capsule-test-keys.yml` | Points `CAPSULE_ROOT_CER`, `CAPSULE_CERT_PEM`, and related variables at the test PKI keys in `test-keys/`. **For development/CI only — not for production.** |

---

## Usage Examples

### Minimal board build

```sh
kas build ci/base.yml:ci/rb3gen2-core-kit.yml
```

### Full distro build

```sh
kas build ci/qcom-distro.yml:ci/rb3gen2-core-kit.yml
```

### CI build (preserves work dir, uses sstate mirror)

```sh
kas build ci/base.yml:ci/ci.yml:ci/rb3gen2-core-kit.yml:ci/qcom-distro.yml
```

### CI build with reproducible locked revisions

```sh
kas build ci/base.yml:ci/base.lock.yml:ci/ci.yml:ci/rb3gen2-core-kit.yml:ci/qcom-distro.yml
```

### Build with upstream development kernel

```sh
kas build ci/base.yml:ci/ci.yml:ci/rb3gen2-core-kit.yml:ci/qcom-distro.yml:ci/linux-qcom-next.yml
```

### Real-time kernel + SELinux

```sh
kas build ci/base.yml:ci/ci.yml:ci/rb3gen2-core-kit.yml:ci/qcom-distro-selinux.yml:ci/linux-qcom-rt-6.18.yml
```

### Capsule build with test keys

```sh
kas build ci/base.yml:ci/rb3gen2-core-kit.yml:ci/capsule.yml:ci/capsule-test-keys.yml
```

### Generate mirror tarballs

```sh
kas build ci/base.yml:ci/mirror-download-disable.yml:ci/mirror-tarballs.yml --runall fetch world
```

### Open an interactive KAS shell

```sh
kas shell ci/base.yml:ci/rb3gen2-core-kit.yml
# or via container:
kas-container shell ci/base.yml:ci/rb3gen2-core-kit.yml
```

---

## Helper Scripts

Scripts are designed to be invoked through the KAS shell environment. They accept two positional arguments: `REPO_DIR` (path to the meta-qcom checkout) and `WORK_DIR` (KAS workspace directory).

### `kas-shell-helper.sh`

Wrapper that launches a KAS shell and runs an arbitrary script inside it:

```sh
./ci/kas-shell-helper.sh ./ci/yocto-check-layer.sh
```

Creates (or reuses `$KAS_WORK_DIR`) an isolated workspace, then runs the target script via `kas shell ci/base.yml --command`.

### `kas-container-shell-helper.sh`

Same as `kas-shell-helper.sh` but uses `kas-container` (or the command in `$KAS_CONTAINER`). Converts the script path to a repo-relative path before passing it into the container where the repo is mounted at `/repo`.

### `yocto-check-layer.sh`

Validates the meta-qcom layer structure and dependencies using `yocto-check-layer`. Auto-discovers all machine names from `conf/machine/*.conf` and runs validation against each. Used in CI to catch missing layer dependencies before merge.

### `yocto-patchreview.sh`

Runs `patchreview.py` from oe-core to verify that all patches in the layer carry correct `Signed-off-by` and `Upstream-Status` tags. Exits non-zero on any violation.

### `yocto-pybootchartgui.sh`

Finds the most recent `buildstats` directory in the workspace and generates an SVG build timeline using oe-core's `pybootchartgui`. Output is written to a `buildchart/` directory. Useful for diagnosing slow builds.

### `schemacheck.py`

Validates LAVA test-job YAML files against the `lava_common` schema:

```sh
python3 ci/schemacheck.py path/to/lava-jobs/
```

Walks the directory tree, validates every `.yaml` file, and reports pass/fail for each. Returns a non-zero exit code if any file fails.

---

## test-keys/

Contains development PKI certificates for UEFI Firmware Management Protocol (FMP) capsule signing:

| File | Purpose |
|------|---------|
| `QcFMPRoot.cer` | Root certificate |
| `QcFMPCert.pem` | Intermediate signing certificate |
| `QcFMPRoot.pub.pem` | Root public key |
| `QcFMPSub.pub.pem` | Subordinate public key |

These keys are referenced by `capsule-test-keys.yml` and are intentionally insecure. **Do not use them in production images.** Production deployments require their own secure PKI infrastructure.
