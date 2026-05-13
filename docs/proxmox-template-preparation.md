# Proxmox Cloud-Init Template Preparation

Properly prepared templates avoid three common cloning problems:
- All cloned VMs inheriting the template's IP (baked-in netplan config)
- All cloned VMs getting 512 MB RAM (Terraform hardware config not applied)
- Terraform hanging for minutes waiting for the QEMU guest agent

---

## Building a Clean Template from Scratch

Start from an Ubuntu 24.04 cloud image or a fresh VM install. Before converting to template, run the following inside the VM:

```bash
# 1. Install and enable the QEMU guest agent
#    Required for Terraform (bpg/proxmox) to apply hardware config and cloud-init
sudo apt update && sudo apt install -y qemu-guest-agent
sudo systemctl enable qemu-guest-agent

# 2. Remove any static netplan config — cloud-init must own networking
sudo rm -f /etc/netplan/*.yaml /etc/netplan/*.yml

# 3. Reset cloud-init so it runs fully on first boot of each clone
sudo cloud-init clean --logs

# 4. Clear the machine-id — each clone must generate its own
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id   # symlink or file depending on distro

# 5. Shut down cleanly
sudo poweroff
```

Then in Proxmox, convert the VM to a template:
```bash
qm template <VMID>
```

### What each step prevents

| Step | Skipping it causes |
|---|---|
| `qemu-guest-agent` | Terraform hangs indefinitely; memory/CPU config never applied |
| Remove netplan | All clones inherit the template's static IP |
| `cloud-init clean` | Cloud-init skips reconfiguration (sees existing instance-id) |
| Truncate `machine-id` | DHCP may hand out duplicate leases across clones |

---

## Fixing a Template That Already Has Baked-In Config

Templates cannot be started, so use `virt-customize` on the **Proxmox host** to patch the disk offline.

### Step 1 — Find the template disk path

SSH into the Proxmox host, then:

```bash
qm config <TEMPLATE_VMID> | grep -E '^scsi|^virtio|^ide'
# Example output: scsi0: local-lvm:vm-9000-disk-0,size=20G

pvesm path local-lvm:vm-9000-disk-0   # prints the full block device path
# For directory storage: /var/lib/vz/images/<VMID>/vm-<VMID>-disk-0.raw
```

### Step 2 — Patch the disk with `virt-customize`

```bash
apt install -y libguestfs-tools

DISK=$(pvesm path local-lvm:vm-9000-disk-0)   # adjust to your disk

virt-customize -a "$DISK" \
  --install qemu-guest-agent \
  --run-command 'systemctl enable qemu-guest-agent' \
  --run-command 'cloud-init clean --logs' \
  --truncate /etc/machine-id \
  --delete /var/lib/dbus/machine-id \
  --run-command 'rm -f /etc/netplan/50-cloud-init.yaml /etc/netplan/00-installer-config.yaml'
```

`virt-customize` modifies the disk image without booting the VM, so it works on templates directly.

### Alternative — Convert template to VM, fix, convert back

If `virt-customize` is not available or the disk format isn't supported:

```bash
# Convert template back to a regular VM
# In the Proxmox UI: right-click template → More → Convert to VM
# Or via CLI on older Proxmox versions: qm template <VMID> --revert

# Start the VM, SSH in, run the cleanup commands from the "clean template" section above

# Shut it down, then re-template
qm template <VMID>
```

---

## Verifying the Template Is Clean

After patching, clone a test VM and confirm:

```bash
# From the cloned VM
cat /etc/machine-id                  # should be non-empty and unique per clone
cloud-init status --wait             # should complete without errors
ip a                                 # should show the IP from your Terraform/cloud-init config
systemctl status qemu-guest-agent   # should be active (running)
```
