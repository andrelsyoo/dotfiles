#!/bin/bash

# Install Commitizen globally (it needs node which are on brew.sh)
npm install -g commitizen

# Initialize Commitizen in current project
commitizen init cz-conventional-changelog --save-dev --save-exact

# Verify installation
echo "Verifying installation..."
cz --version

echo "✅ Commitizen installed successfully!"
echo "Use 'git cz' or 'cz' to commit with commitizen"