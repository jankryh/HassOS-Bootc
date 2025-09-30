#!/bin/bash

# HassOS-Bootc Add-on Setup Script
set -e

echo "🏠 HassOS-Bootc Add-on Setup"
echo "============================="

# Function to install add-on
install_addon() {
    local addon=$1
    echo "Installing $addon..."
    
    case $addon in
        "zerotier")
            dnf install -y zerotier-one
            systemctl enable --now zerotier-one
            echo "ZeroTier installed. Run 'zerotier-cli join YOUR_NETWORK_ID' to join a network."
            ;;
        "mqtt")
            dnf install -y mosquitto mosquitto-clients
            systemctl enable --now mosquitto
            echo "Mosquitto MQTT broker installed and started."
            ;;
        "zigbee2mqtt")
            ./setup-zigbee2mqtt.sh
            ;;
        "influxdb")
            ./setup-influxdb.sh
            ;;
        "grafana")
            ./setup-grafana.sh
            ;;
        *)
            echo "Unknown add-on: $addon"
            exit 1
            ;;
    esac
}

# Main menu
echo "Available add-ons:"
echo "1. ZeroTier VPN"
echo "2. MQTT Broker (Mosquitto)"
echo "3. Zigbee2MQTT"
echo "4. InfluxDB"
echo "5. Grafana"
echo "6. All add-ons"

read -p "Select add-on (1-6): " choice

case $choice in
    1) install_addon "zerotier" ;;
    2) install_addon "mqtt" ;;
    3) install_addon "zigbee2mqtt" ;;
    4) install_addon "influxdb" ;;
    5) install_addon "grafana" ;;
    6) 
        install_addon "zerotier"
        install_addon "mqtt"
        install_addon "zigbee2mqtt"
        install_addon "influxdb"
        install_addon "grafana"
        ;;
    *) echo "Invalid choice" && exit 1 ;;
esac

echo "✅ Setup complete!"
