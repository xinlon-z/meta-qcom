# meta-qcom CI KAS Configurations

[KAS](https://kas.readthedocs.io/) configuration fragments for building Yocto/OE images on
Qualcomm hardware. Files are composed with `:` separators; later files override earlier ones.

```sh
kas build ci/base.yml:ci/base.lock.yml:ci/ci.yml:ci/rb3gen2-core-kit.yml:ci/qcom-distro.yml
```

## File naming conventions

| Pattern | Meaning |
|---------|---------|
| `base.yml`, `base.lock.yml`, `ci.yml`, `world.yml` | Foundation — included by almost every build |
| `<board>.yml` | Selects a specific machine (e.g. `rb3gen2-core-kit.yml`) |
| `qcom-armv8a.yml`, `qcom-armv7a.yml` | Generic architecture targets |
| `qcom-distro[-<variant>].yml` | Full Qualcomm Linux distro stack and variants |
| `linux-qcom[-<variant>]-<ver>.yml` | Kernel recipe selector/pin |
| `mirror*.yml` | BitBake source/sstate mirror behaviour |
| `capsule*.yml` | UEFI FMP capsule image generation |
| `debug.yml`, `performance.yml` | One-shot build modifiers |

## Configuration reference

| Filename | Category | Description |
|----------|----------|-------------|
| `base.yml` | Base | Foundation for all builds. Adds oe-core, bitbake, meta-qcom layers; sets `distro: nodistro`; configures mirrors, flash image class, common local.conf settings. Default target: `core-image-base`. |
| `base.lock.yml` | Base | Pins exact git SHAs for all shared repos for reproducible builds. |
| `ci.yml` | Base | CI overlay: includes `mirror.yml`, sets `OEBasicHash` signatures, disables `rm_work`. |
| `world.yml` | Base | Builds `world` target scoped to `layer-qcom` packages. |
| `meta-arm.yml` | Layer | Adds `meta-arm` and `meta-arm-toolchain` layers. |
| `rb3gen2-core-kit.yml` | Board | `rb3gen2-core-kit` — Qualcomm Robotics RB3 Gen 2 Core Kit |
| `rb3gen2-core-kit-open-fw.yml` | Board | `rb3gen2-core-kit-open-fw` — RB3 Gen 2 with open-source firmware (includes `meta-arm.yml`) |
| `rb1-core-kit.yml` | Board | `rb1-core-kit` — Qualcomm Robotics RB1 Core Kit |
| `qcs9100-ride-sx.yml` | Board | `qcs9100-ride-sx` |
| `qcs8300-ride-sx.yml` | Board | `qcs8300-ride-sx` |
| `qcs615-ride.yml` | Board | `qcs615-ride` |
| `qcm6490-idp.yml` | Board | `qcm6490-idp` — QCM6490 IDP |
| `sm8750-mtp.yml` | Board | `sm8750-mtp` |
| `kaanapali-mtp.yml` | Board | `kaanapali-mtp` |
| `glymur-crd.yml` | Board | `glymur-crd` |
| `iq-8275-evk.yml` | Board (IQ EVK) | `iq-8275-evk` |
| `iq-9075-evk.yml` | Board (IQ EVK) | `iq-9075-evk` |
| `iq-615-evk.yml` | Board (IQ EVK) | `iq-615-evk` |
| `iq-x5121-evk.yml` | Board (IQ EVK) | `iq-x5121-evk` |
| `iq-x7181-evk.yml` | Board (IQ EVK) | `iq-x7181-evk` |
| `qcom-armv8a.yml` | Arch | Generic 64-bit ARMv8-A machine (no board BSP) |
| `qcom-armv7a.yml` | Arch | Generic 32-bit ARMv7-A machine (no board BSP) |
| `qcom-distro.yml` | Distro | Full Qualcomm Linux distro stack. Adds meta-qcom-distro, meta-oe, meta-multimedia, meta-virtualization, meta-audioreach, meta-selinux, meta-updater, meta-security. Targets: `qcom-multimedia-image`, `qcom-multimedia-proprietary-image`, `qcom-container-orchestration-image`. |
| `qcom-distro-catchall.yml` | Distro | `qcom-distro-catchall` — broad package coverage variant |
| `qcom-distro-selinux.yml` | Distro | `qcom-distro-selinux` — SELinux-enabled variant |
| `qcom-distro-kvm.yml` | Distro | `qcom-distro-kvm` — KVM/virtualisation variant |
| `qcom-distro-sota.yml` | Distro | `qcom-distro-sota` — OTA update variant via meta-updater/Uptane |
| `qcom-distro-multimedia-image.yml` | Distro | Restricts target to `qcom-multimedia-image` only |
| `linux-qcom-next.yml` | Kernel | Selects `linux-qcom-next` (upstream development branch) |
| `linux-qcom-next-rt.yml` | Kernel | Selects `linux-qcom-next-rt` (PREEMPT_RT, next branch) |
| `linux-qcom-6.18.yml` | Kernel | Pins `linux-qcom` at 6.18.x |
| `linux-qcom-rt-6.18.yml` | Kernel | Pins `linux-qcom-rt` (PREEMPT_RT) at 6.18.x |
| `linux-yocto-dev.yml` | Kernel | Selects `linux-yocto-dev` for Yocto compatibility testing |
| `u-boot-qcom.yml` | Bootloader | Selects `u-boot-qcom` recipe |
| `mirror.yml` | Mirror | Configures `SSTATE_MIRRORS` → sstate.yoctoproject.org (included by `ci.yml`) |
| `mirror-tarballs.yml` | Mirror | Sets `BB_GENERATE_MIRROR_TARBALLS = "1"` to populate a download mirror |
| `mirror-download-test.yml` | Mirror | Sets `BB_FETCH_PREMIRRORONLY = "1"` to validate a mirror is complete |
| `mirror-download-disable.yml` | Mirror | Removes `qli-mirrors` from `INHERIT` for clean upstream mirroring |
| `capsule.yml` | Feature | Enables UEFI FMP capsule image generation |
| `capsule-test-keys.yml` | Feature | Test PKI keys for capsule signing — **CI/dev only, not for production** |
| `debug.yml` | Modifier | Sets `DEBUG_BUILD = "1"` |
| `performance.yml` | Modifier | Appends `quiet` to kernel cmdline for timing measurements |

## Usage examples

```sh
# Minimal build
kas build ci/base.yml:ci/rb3gen2-core-kit.yml

# Standard CI build (locked revisions + CI overrides)
kas build ci/base.yml:ci/base.lock.yml:ci/ci.yml:ci/rb3gen2-core-kit.yml:ci/qcom-distro.yml

# With upstream development kernel
kas build ci/base.yml:ci/ci.yml:ci/rb3gen2-core-kit.yml:ci/qcom-distro.yml:ci/linux-qcom-next.yml

# PREEMPT_RT kernel + SELinux
kas build ci/base.yml:ci/ci.yml:ci/rb3gen2-core-kit.yml:ci/qcom-distro-selinux.yml:ci/linux-qcom-rt-6.18.yml

# Capsule image (test keys)
kas build ci/base.yml:ci/rb3gen2-core-kit.yml:ci/capsule.yml:ci/capsule-test-keys.yml
```

## test-keys/

Development PKI certificates for UEFI FMP capsule signing, referenced by `capsule-test-keys.yml`.
Contains `QcFMPRoot.cer`, `QcFMPCert.pem`, `QcFMPRoot.pub.pem`, and `QcFMPSub.pub.pem`.
**Must not be used in production.**
