#!/bin/bash

# ==============================================
# ===   ActiveDev-Claimer - Setup Assistant  ===
# ==============================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# ----------------------------------------------
# OS Compatibility Check
# ----------------------------------------------
if [[ "$OSTYPE" != "darwin"* ]] && { [[ "$OSTYPE" != "linux-gnu"* ]] || ! command -v apt &> /dev/null; }; then
    echo -e "\n${RED}❌ Unsupported OS - This script only works on Debian/Ubuntu and macOS${NC}"
    exit 1
fi

# ----------------------------------------------
# Install Ruby
# ----------------------------------------------
install_ruby() {
    # Debian/Ubuntu
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "\n${YELLOW}📦 Installing dependencies (Debian/Ubuntu)...${NC}"
        sudo apt update && sudo apt install -y ruby ruby-dev build-essential libffi-dev pkg-config

    # macOS
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "\n${YELLOW}🍎 Checking Ruby environment...${NC}"
        
        # Function to install Homebrew
        install_homebrew() {
            echo -e "${YELLOW}📦 Homebrew is not installed. Installing Homebrew...${NC}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
            source ~/.zshrc
            echo -e "${GREEN}✅ Homebrew installed successfully.${NC}"
        }
        
        # Function to install Ruby via Homebrew
        install_ruby_with_homebrew() {
            echo -e "${YELLOW}🔄 Installing the latest version of Ruby via Homebrew...${NC}"
            brew install ruby
            
            # Ensure Homebrew Ruby is prioritized in PATH
            brew_ruby_path=$(brew --prefix ruby)/bin
            echo "export PATH=\"$brew_ruby_path:\$PATH\"" >> ~/.zshrc
            source ~/.zshrc
            
            # Verify installation
            if ! command -v ruby &> /dev/null; then
                echo -e "${RED}❌ Failed to install Ruby! Please install it manually.${NC}"
                exit 1
            fi
            
            new_version=$(ruby -v | awk '{print $2}' | cut -d 'p' -f 1)
            echo -e "${GREEN}✅ Ruby $new_version installed successfully via Homebrew.${NC}"
        }
        
        # Check if Ruby is already the latest version
        current_ruby_version=$(ruby -v | awk '{print $2}' | cut -d 'p' -f 1)
        required_ruby_version="3.4.0"
        
        if [[ "$(printf '%s\n' "$required_ruby_version" "$current_ruby_version" | sort -V | head -n1)" != "$required_ruby_version" ]]; then
            echo -e "${RED}❌ Ruby version $current_ruby_version is too old. Minimum required version is $required_ruby_version${NC}"
            echo -e "${YELLOW}🛠️  The bot may not work properly with the native macOS Ruby version.${NC}"
            echo -e "${YELLOW}🛠️  Do you want to install the latest version of Ruby via Homebrew? (Y/N):${NC}"
            
            read -p "Your choice (Y/N): " install_choice
            
            if [[ "$install_choice" =~ ^[Yy]$ ]]; then
                # Check if Homebrew is installed
                if ! command -v brew &> /dev/null; then
                    install_homebrew
                fi
                
                # Install Ruby via Homebrew
                install_ruby_with_homebrew
                
                # Verify the new Ruby version
                new_version=$(ruby -v | awk '{print $2}' | cut -d 'p' -f 1)
                if [[ "$(printf '%s\n' "$required_ruby_version" "$new_version" | sort -V | head -n1)" != "$required_ruby_version" ]]; then
                    echo -e "${RED}❌ Ruby version $new_version is still too old after installation attempt.${NC}"
                    echo -e "${YELLOW}💡 Try running the following commands to fix the PATH:${NC}"
                    echo -e "1. Add Homebrew Ruby to your PATH:"
                    echo -e "   echo 'export PATH=\"$(brew --prefix ruby)/bin:\$PATH\"' >> ~/.zshrc"
                    echo -e "2. Reload your shell:"
                    echo -e "   source ~/.zshrc"
                    echo -e "3. Verify the Ruby version:"
                    echo -e "   ruby -v"
                    exit 1
                fi
            else
                echo -e "${YELLOW}🚫 Skipping Ruby update. Note: The bot may not work properly with the native macOS Ruby version.${NC}"
            fi
        else
            echo -e "${GREEN}✅ Ruby $current_ruby_version is up-to-date.${NC}"
        fi
        
        # Ensure Homebrew Ruby is in PATH
        export PATH="$(brew --prefix ruby)/bin:$PATH"
        [[ -s ~/.zshrc ]] && source ~/.zshrc
    fi
}

# ----------------------------------------------
# System Checks
# ----------------------------------------------
echo -e "\n${YELLOW}⚙️  Detecting system configuration...${NC}"

# Ruby check and version verification
if ! command -v ruby &> /dev/null; then
    echo -e "${RED}❌ Ruby not found!${NC}"
    install_ruby
else
    ruby_version=$(ruby -v | awk '{print $2}' | cut -d 'p' -f 1)
    min_required_version="3.4.0"
    
    # Version comparison function
    version_lt() {
        local v1=$1
        local v2=$2
        
        # Extract version components
        local v1_components=(${v1//./ })
        local v2_components=(${v2//./ })
        
        # Compare major
        if (( v1_components[0] < v2_components[0] )); then
            return 0  # true, v1 < v2
        elif (( v1_components[0] > v2_components[0] )); then
            return 1  # false, v1 > v2
        fi
        
        # Compare minor
        if (( v1_components[1] < v2_components[1] )); then
            return 0  # true, v1 < v2
        elif (( v1_components[1] > v2_components[1] )); then
            return 1  # false, v1 > v2
        fi
        
        # Compare patch
        if (( v1_components[2] < v2_components[2] )); then
            return 0  # true, v1 < v2
        fi
        
        return 1  # false, v1 >= v2
    }
    
    if version_lt "$ruby_version" "$min_required_version"; then
        echo -e "${RED}❌ Ruby version $ruby_version is too old. Minimum required version is $min_required_version${NC}"
        install_ruby
    else
        echo -e "${GREEN}✅ Ruby $(ruby -v) is sufficient${NC}"
    fi
fi

# ----------------------------------------------
# Verify Ruby Version After Installation
# ----------------------------------------------
current_ruby_version=$(ruby -v | awk '{print $2}' | cut -d 'p' -f 1)
min_required_version="3.4.0"

if version_lt "$current_ruby_version" "$min_required_version"; then
    echo -e "${RED}❌ Ruby version $current_ruby_version is still too old after installation attempt.${NC}"
    echo -e "${RED}❌ Please manually ensure you're using Ruby $min_required_version or later.${NC}"
    echo -e "${YELLOW}💡 Try running: source ~/.rvm/scripts/rvm && rvm use --default${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Using Ruby $current_ruby_version${NC}"
fi

# ----------------------------------------------
# Project Setup
# ----------------------------------------------
cd "$PROJECT_ROOT"

# Install Bundler
if ! command -v bundle &> /dev/null; then
    echo -e "\n${YELLOW}📦 Installing Bundler...${NC}"
    gem install bundler --user-install
    
    # Ensure PATH includes gem binaries
    if command -v rvm &> /dev/null; then
        source_rvm
    else
        export PATH="$(ruby -e 'puts Gem.user_dir')/bin:$PATH"
    fi
else
    echo -e "${GREEN}✅ Bundler $(bundle -v) is already installed${NC}"
fi

# Install dependencies
echo -e "\n${YELLOW}🧩 Installing gems...${NC}"
bundle config set --local path 'vendor/bundle'
bundle install

# ----------------------------------------------
# Launch Bot
# ----------------------------------------------
echo -e "\n${GREEN}✅ All systems ready!${NC}"
echo -e "${YELLOW}🚀 Starting Discord bot...${NC}\n"
cd src
bundle exec ruby bot.rb