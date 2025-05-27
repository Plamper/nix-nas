#!/usr/bin/env bash

WG_PEERS="./hosts/cloudnix/peers.nix"
CLIENT_NAME=$1

if [ -z "$CLIENT_NAME" ]; then
  echo "usage ./add-wireguard-client.sh <client-name>"
  exit 1
fi

CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

# Determine the next available IP based on current entries in peers.nix
LAST_IP=$(grep -oE '10\.20\.0\.[0-9]+' "$WG_PEERS" | awk -F. '{print $4}' | sort -n | tail -n 1)
NEXT_IP=$((LAST_IP + 1))
CLIENT_IP="10.20.0.$NEXT_IP"

# Client-Konfigurationsdatei erstellen
CLIENT_CONFIG="$CLIENT_NAME.conf"
cat > $CLIENT_CONFIG <<EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP/24
DNS = 8.8.8.8

[Peer]
PublicKey = 45qWd/gUOc2xVUWK0jtrp3FD81qdwtVGDVRARcM3oQs=
Endpoint = 150.230.147.99:51820
AllowedIPs = 10.20.0.0/24
PersistentKeepalive = 25
EOF

# Add the new peer to peers.nix
awk -v entry="    {
      # $CLIENT_NAME
      publicKey = \"$CLIENT_PUBLIC_KEY\";
      allowedIPs = [ \"$CLIENT_IP/32\" ];
    }" '
    /wg-peers = \[/ { print; print entry; next }
    { print }
' "$WG_PEERS" > "${WG_PEERS}.tmp" && mv "${WG_PEERS}.tmp" "$WG_PEERS"

nixfmt $WG_PEERS

# # add rules to server
# deploy .#cloudnix

echo "Client $CLIENT_NAME was created. Config: $CLIENT_CONFIG"
echo "QR-Code:"
echo $CLIENT_CONFIG | qrencode -t ansiutf8 
