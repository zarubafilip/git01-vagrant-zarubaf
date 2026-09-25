#!/usr/bin/env bash
# Veřejný kontrolní záznam; nejde o nezfalšovatelný důkaz použití Vagrantu.
set -euo pipefail
fail() { printf 'Chyba: %s\n' "$*" >&2; exit 1; }
[[ $(uname -s) == Linux ]] || fail "Skript spusťte uvnitř Linux serveru přes vagrant ssh."
for cmd in systemd-detect-virt sha256sum date uname; do
    command -v "$cmd" >/dev/null 2>&1 || fail "Chybí příkaz $cmd. Požádejte vyučujícího o pomoc."
done
virt=$(systemd-detect-virt --vm 2>/dev/null) || fail "Virtuální stroj nebyl rozpoznán. Přihlaste se přes vagrant ssh; pokud už jste ve VM, obraťte se na vyučujícího."
[[ -n "$virt" && "$virt" != none ]] || fail "Virtuální stroj nebyl rozpoznán."
[[ -r /etc/os-release ]] || fail "Nelze přečíst /etc/os-release."
. /etc/os-release
[[ -r /proc/sys/kernel/random/uuid ]] || fail "Není dostupný generátor náhodného UUID."
IFS= read -r nonce < /proc/sys/kernel/random/uuid
[[ "$nonce" =~ ^[0-9a-f-]{36}$ ]] || fail "Nepodařilo se vytvořit náhodný identifikátor."
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
host=$(uname -n)
kernel=$(uname -r)
distro=${PRETTY_NAME:-${ID:-Linux}}
# SHA-256 se počítá z UTF-8 záznamu včetně posledního LF.
# Náhodné UUID zajistí nový kód při každém spuštění.
record=$(printf '%s\n' \
    'Úloha: git-vagrant / SPOŠ / 3. I / v1' \
    "Distribuce: $distro" \
    "Hostname: $host" \
    "Kernel: $kernel" \
    "Virtualizace: $virt" \
    "Čas UTC: $timestamp" \
    "Náhodné ID: $nonce")
digest=$(printf '%s\n' "$record" | sha256sum)
code="SPOS-3I-${digest%% *}"
printf '\nZkopírujte následující blok do části Moje řešení v README:\n\n'
printf '**Kontrolní kód:** `%s`\n\n' "$code"
printf '```text\n%s\n```\n' "$record"
printf '\nKód i záznam si ponechte spolu. Nové spuštění vytvoří nový kód.\n'
