#!/bin/bash

# Install Commitizen globally (it needs node which are on brew.sh)
npm install -g commitizen

# Install the conventional changelog adapter globally
npm install -g cz-conventional-changelog

# Create global Commitizen config
echo '{ "path": "cz-conventional-changelog" }' > ~/.czrc

# Verify installation
echo "Verifying installation..."
cz --version

echo "✅ Commitizen installed and configured globally!"
echo "Now you can use 'git cz' or 'cz' in any Git repository"