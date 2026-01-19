#!/bin/bash
############################################################################################
#
# sudo microk8s einable cis-hardening         # (core) Apply CIS K8s hardening
#                                        # https://canonical.com/microk8s/docs/how-to-cis-harden
#
############################################################################################
#shopt -o -s errexit    #—Terminates  the shell script  if a command returns an error code.
#shopt -o -s xtrace #—Displays each command before it’s executed.
shopt -o -s nounset #-No Variables without definition
#set -euo pipefail

target_dir="${1:-./}"
if [ ! -d "$target_dir" ]; then
  die "Directory not found: $target_dir"
fi

KUBECTL="sudo sudo microk8s kubectl "
die(){ echo "Error: $*" >&2; exit 1; }

retry() {
  local attempts=$1
  local delay=$2
  shift 2
  local count=0
  until "$@"; do
    exit_code=$?
    count=$((count + 1))
    if [ $count -ge $attempts ]; then
      echo "Command failed after $attempts attempts."
      return $exit_code
    fi
    echo "Command failed. Retrying in $delay seconds... ($count/$attempts)"
    sleep $delay
  done
  return 0
}

echo "Checking if sudo microk8s is installed..."
if ! command -v sudo microk8s &> /dev/null; then
  echo "Error: sudo microk8s is not installed. Please install sudo microk8s first."
  exit 1
fi

# Apply all YAML files in the target directory
mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort )
if [ "${#yamls[@]}" -eq 0 ]; then
  echo "No YAML files found in $target_dir"
fi

echo "Deleting previous installed resources (if any)..."
for f in "${yamls[@]}"; do
  echo "Applying $f"
  if ! retry 5 5 envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | ${KUBECTL} delete --ignore-not-found=true -f - ; then
    die "Failed to delete $f"
  fi
done

echo "Disabling cis-hardening if enabled..."
sudo sudo microk8s disable cis-hardening || true
sudo microk8s status --wait-ready

echo "Enabling cis-hardening # (core) Apply CIS K8s hardening ..."
sudo sudo microk8s enable cis-hardening

echo "Applying cis-hardening configuration..."
mapfile -t yamls < <(find "$target_dir" -maxdepth 1 -type f \( -iname "*.yaml" -o -iname "*.yml" \) | sort --reverse)
if [ "${#yamls[@]}" -eq 0 ]; then
  echo "No YAML files found in $target_dir"
fi

echo "Applying additional resources (if any)..."
for f in "${yamls[@]}"; do
  echo "Applying $f"
  if ! retry 5 5 envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${f} | ${KUBECTL} apply -f - ; then
    die "Failed to apply $f"
  fi
done

sudo sudo microk8s status --wait-ready

sudo sed -i '/vm.panic_on_oom/d' /etc/sysctl.conf
sudo sed -i '/vm.overcommit_memory/d' /etc/sysctl.conf
sudo sed -i '/kernel.panic/d' /etc/sysctl.conf
sudo sed -i '/kernel.panic_on_oops/d' /etc/sysctl.conf
sudo sed -i '/kernel.keys.root_maxkeys/d' /etc/sysctl.conf
sudo sed -i '/kernel.keys.root_maxbytes/d' /etc/sysctl.conf
sudo sed -i '/#CIS hardening configuration has been applied./d' /etc/sysctl.conf
sudo sed -i '/#Remember to enable this addon on nodes joining the custer./d' /etc/sysctl.conf

cat <<EOF | sudo tee -a  /etc/sysctl.conf
#CIS hardening configuration has been applied. All microk8s commands require sudo from now on.Note: You may need to set up these additional configs in /etc/sysctl.conf:
vm.panic_on_oom=0
vm.overcommit_memory=1
kernel.panic=10
kernel.panic_on_oops=1
kernel.keys.root_maxkeys=1000000
kernel.keys.root_maxbytes=25000000
#Remember to enable this addon on nodes joining the custer.
EOF

echo "cis-hardening setup complete."