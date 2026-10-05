#!/usr/bin/env bash
set -euo pipefail

result="./gpu-bus-ids.nix"

if ! command -v lspci >/dev/null 2>&1; then
  echo "lspci is not available. Run through: nix shell nixpkgs#pciutils -c bash $0" >&2
  exit 1
fi

mapfile -t gpu_lines < <(lspci -Dnn -d ::03xx)

# Match on PCI vendor IDs, not vendor names: a case-insensitive "ATI" also
# matches "Corporation" in the NVIDIA line, which once produced a file with
# the NVIDIA address in both fields.
amd_line="$(printf '%s\n' "${gpu_lines[@]}" | grep -F '[1002:' | head -n1 || true)"
nvidia_line="$(printf '%s\n' "${gpu_lines[@]}" | grep -F '[10de:' | head -n1 || true)"

if [[ -z "$amd_line" || -z "$nvidia_line" ]]; then
  echo "Could not find both AMD and NVIDIA display controllers." >&2
  printf '%s\n' "${gpu_lines[@]}" >&2
  exit 1
fi

to_nix_bus_id() {
  local address="$1"
  local domain bus device function

  IFS=':.' read -r domain bus device function <<< "$address"
  printf 'PCI:%d@%d:%d:%d' \
    "$((16#$bus))" \
    "$((16#$domain))" \
    "$((16#$device))" \
    "$((16#$function))"
}

amd_address="${amd_line%% *}"
nvidia_address="${nvidia_line%% *}"
amd_bus_id="$(to_nix_bus_id "$amd_address")"
nvidia_bus_id="$(to_nix_bus_id "$nvidia_address")"

cat > "$result" <<EOF_NIX
{
  # Detected from:
  # ${amd_line}
  # ${nvidia_line}
  amdgpuBusId = "${amd_bus_id}";
  nvidiaBusId = "${nvidia_bus_id}";
}
EOF_NIX
