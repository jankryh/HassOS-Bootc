#!/bin/bash

# HACS Installation Script for HassOS-Bootc
set -e

echo "🏠 HACS (Home Assistant Community Store) Installation"
echo "====================================================="

# Function to install HACS
install_hacs() {
    echo "Installing HACS..."
    
    # Create custom components directory
    mkdir -p /var/lib/home-assistant/custom_components
    
    # Method selection
    echo "Select installation method:"
    echo "1. Automatic download (recommended)"
    echo "2. Git clone"
    echo "3. Manual download"
    
    read -p "Choose method (1-3): " method
    
    case $method in
        1)
            echo "Downloading HACS automatically..."
            cd /var/lib/home-assistant/custom_components
            curl -fsSL https://get.hacs.xyz | bash -
            ;;
        2)
            echo "Cloning HACS from Git..."
            cd /var/lib/home-assistant/custom_components
            git clone https://github.com/hacs/integration.git hacs
            ;;
        3)
            echo "Manual download..."
            cd /var/lib/home-assistant/custom_components
            wget https://github.com/hacs/integration/releases/latest/download/hacs.zip
            unzip hacs.zip
            rm hacs.zip
            ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
    
    # Set permissions
    chmod -R 755 /var/lib/home-assistant/custom_components/hacs
    
    echo "✅ HACS installed successfully!"
}

# Function to update systemd service
update_systemd_service() {
    echo "Updating Home Assistant systemd service..."
    
    # Check if custom components volume is already mounted
    if grep -q "custom_components" /etc/systemd/system/home-assistant.service; then
        echo "Custom components volume already configured."
    else
        echo "Adding custom components volume to systemd service..."
        
        # Backup original service file
        cp /etc/systemd/system/home-assistant.service /etc/systemd/system/home-assistant.service.backup
        
        # Add volume mount
        sed -i '/--volume.*config:/a\  --volume /var/lib/home-assistant/custom_components:/config/custom_components:Z \\' /etc/systemd/system/home-assistant.service
        
        echo "✅ Systemd service updated!"
    fi
}

# Function to restart Home Assistant
restart_home_assistant() {
    echo "Restarting Home Assistant..."
    systemctl restart home-assistant
    
    echo "Waiting for Home Assistant to start..."
    sleep 10
    
    # Check if Home Assistant is running
    if systemctl is-active --quiet home-assistant; then
        echo "✅ Home Assistant restarted successfully!"
    else
        echo "❌ Home Assistant failed to start. Check logs:"
        echo "journalctl -u home-assistant -f"
        exit 1
    fi
}

# Function to show next steps
show_next_steps() {
    echo ""
    echo "🎉 HACS Installation Complete!"
    echo "=============================="
    echo ""
    echo "Next steps:"
    echo "1. Go to Home Assistant web interface: http://<your-ip>:8123"
    echo "2. Navigate to Configuration → Integrations"
    echo "3. Click 'Add Integration' and search for 'HACS'"
    echo "4. Follow the setup wizard"
    echo "5. You'll need a GitHub Personal Access Token:"
    echo "   - Go to: https://github.com/settings/tokens"
    echo "   - Generate token with 'repo' and 'read:org' scopes"
    echo ""
    echo "Popular HACS integrations to try:"
    echo "- Apple TV, Google Home, Spotify, Ring, Nest, Tesla"
    echo ""
    echo "Popular HACS themes:"
    echo "- iOS Dark Mode, Material Design, Slate, Clear, Nord"
    echo ""
    echo "Popular HACS cards:"
    echo "- Mini Graph Card, Button Card, Card Mod, Auto Entities"
    echo ""
}

# Main execution
main() {
    install_hacs
    update_systemd_service
    restart_home_assistant
    show_next_steps
}

# Run main function
main
