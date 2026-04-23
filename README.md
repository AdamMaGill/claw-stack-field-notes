# CLAW Stack: Field Notes

Field notes, artifacts, and cheat sheet from the first production deployment of NemoClaw, DefenseClaw, and OpenShell. Scripts and configs that work. Version-tagged and kept current.

Full series: [adammagill.substack.com](https://adammagill.substack.com)

---

## Start Here

If you are building this stack, start with the artifacts below. Each one is referenced in the companion Substack post. When a vendor ships a fix that makes a workaround obsolete, it comes out of this list.

| Artifact | Description | Valid As Of | Post |
|---|---|---|---|
| [vps-hardening.sh](https://github.com/AdamMaGill/claw-stack-field-notes/blob/main/vps-hardening.sh) | VPS hardening from bare Ubuntu 24.04 - UFW, SSH, auditd, cloudflared, unattended-upgrades | Ubuntu 24.04, April 2026 | [Post 2](https://adammagill.substack.com/p/securing-the-foundation-before-ai) |

---

## Series Posts

| Post | Title | Link |
|---|---|---|
| 1 | Why I'm Running Alpha AI Security Software on a $5 VPS | [Read](https://adammagill.substack.com/p/why-im-running-alpha-ai-security) |
| 2 | Securing the Foundation Before AI Touches the Server | [Read](https://adammagill.substack.com/p/securing-the-foundation-before-ai) |
| 3 | First Contact: Getting NemoClaw Running When the Docs Assume You Have a GPU | [Read](https://adammagill.substack.com/p/first-contact-getting-nemoclaw-running) |

---

## Open Issues

Issues filed as a result of this work. Workarounds in this repo will be removed when these close.

| Issue | Repo | Status |
|---|---|---|
| [Host-side openclaw stub silently blinds DefenseClaw AIBOM scanner](https://github.com/NVIDIA/NemoClaw/issues/2303) | NemoClaw | Open |
| [COG-SOUL fires CRITICAL on legitimate NemoClaw workspace identity files](https://github.com/cisco-ai-defense/defenseclaw/issues/134) | DefenseClaw | Open |

---

## Stack Versions

Current tested stack as of April 2026.

| Component | Version |
|---|---|
| OpenShell | v0.0.24 |
| OpenClaw | v2026.4.9 |
| NemoClaw | main (post-v0.1.0) |
| DefenseClaw | v0.2.0 |
| OS | Ubuntu 24.04 LTS |
