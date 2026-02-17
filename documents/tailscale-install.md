# Setting Up Tailscale on Ubuntu Server

Tailscale creates secure, authenticated connections without opening firewall ports - perfect for accessing your infrastructure remotely.

## Installation

Add Tailscale's package signing key and repository:

```bash
# Add Tailscale's package signing key and repository
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/$(lsb_release -cs).noarmor.gpg \
  | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null

curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/$(lsb_release -cs).tailscale-list \
  | sudo tee /etc/apt/sources.list.d/tailscale.list
```

Update package list and install:

```bash
sudo apt update
sudo apt install tailscale
```

## Connect to Your Network

Run the following command to connect. This will provide a URL to visit in your browser to authenticate:

```bash
sudo tailscale up
```

## Useful Options

For servers, you might want to add some additional flags:

```bash
# Accept routes from other devices and advertise this machine as an exit node
sudo tailscale up --accept-routes --advertise-exit-node

# Or advertise specific subnet routes (e.g., for accessing local network)
sudo tailscale up --advertise-routes=192.168.1.0/24
```

## Enable at Boot

Ensure Tailscale starts automatically when the server boots:

```bash
sudo systemctl enable --now tailscaled
```

## Verify Status

Check that Tailscale is running correctly:

```bash
tailscale status
tailscale ip -4  # Show your Tailscale IPv4 address
```

---

**Note:** Tailscale's zero-trust approach creates secure connections without opening firewall ports, making it ideal for accessing mining infrastructure and development systems remotely.