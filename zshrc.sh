#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error occurred during .zshrc setup. Exiting..."
    exit 1
}

# Append custom configurations to .zshrc file
echo "Adding custom configurations to .zshrc..."

# Aliases to change directories
echo 'alias ..="cd .."' >> ~/.zshrc
echo 'alias cd..="cd .."' >> ~/.zshrc
echo 'alias ...="cd ../../"' >> ~/.zshrc
echo 'alias ....="cd ../../../"' >> ~/.zshrc

# Aliases for ls commands
echo 'alias ll="ls -l"' >> ~/.zshrc
echo 'alias la="ls -Al"' >> ~/.zshrc
echo 'alias lt="ls -ltrh"' >> ~/.zshrc

# Aliases for copy and move commands
echo 'alias cp="cp -vi"' >> ~/.zshrc
echo 'alias mv="mv -vi"' >> ~/.zshrc

# Alias for rsync based copy with progress
echo 'alias cpv="rsync -avh --info=progress2"' >> ~/.zshrc

# Alias to edit .zshrc file
echo 'alias zshrc="vim ~/.zshrc"' >> ~/.zshrc

# Source the .zshrc file to apply changes
source ~/.zshrc || handle_error ".zshrc configuration"

echo "Configuration of .zshrc completed."
echo "Setting zsh as our default shell..."

chsh -s /usr/bin/zsh || handle_error "zsh configuration"

echo "zsh set as default shell successfully."
