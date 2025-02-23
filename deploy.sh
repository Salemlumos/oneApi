#!/bin/bash

# Parameters
REMOTE_REPO=$1
DB_CONNECTION=$2

if [ -z "$REMOTE_REPO" ] || [ -z "$DB_CONNECTION" ]; then
    echo "Usage: ./deploy.sh <remote_repo_url> <database_connection_string>"
    exit 1
fi

# Set working directory
cd "C:\Users\icirino\l3\openApi8" || exit 1

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to create .gitignore file
create_gitignore() {
    cat > .gitignore << EOL
# .NET Core
*.swp
*.*~
project.lock.json
.DS_Store
*.pyc
nupkg/

# Visual Studio Code
.vscode

# User-specific files
*.suo
*.user
*.userosscache
*.sln.docstates

# Build results
[Dd]ebug/
[Dd]ebugPublic/
[Rr]elease/
[Rr]eleases/
x64/
x86/
build/
bld/
[Bb]in/
[Oo]bj/
[Oo]ut/
msbuild.log
msbuild.err
msbuild.wrn

# Visual Studio
.vs/
.vscode/
*.ncrunchsolution
*.ncrunchproject
_NCrunch_*
.*crunch*.local.xml

# NuGet Packages
*.nupkg
# The packages folder can be ignored because of Package Restore
**/[Pp]ackages/*
# except build/, which is used as an MSBuild target.
!**/[Pp]ackages/build/
# Uncomment if necessary however generally it will be regenerated when needed
#!**/[Pp]ackages/repositories.config
# NuGet v3's project.json files produces more ignorable files
*.nuget.props
*.nuget.targets

# User-specific files
*.rsuser
*.suo
*.user
*.userosscache
*.sln.docstates

# Rider
.idea/
*.sln.iml

# Entity Framework
*.jfm
*.dbmdl
*.mdf
*.ldf

# Sensitive files
appsettings.Development.json
appsettings.Production.json
*.secret.json
secrets.json

# Logs
*.log
logs/
Log/
EOL

    echo -e "${GREEN}.gitignore file created${NC}"
}

# Function to update database connection string
update_db_connection() {
    if [ -f "appsettings.json" ]; then
        sed -i "s|\"DefaultConnection\": \".*\"|\"DefaultConnection\": \"$DB_CONNECTION\"|" appsettings.json
        echo -e "${GREEN}Database connection string updated${NC}"
    else
        echo -e "${RED}Error: appsettings.json not found${NC}"
        exit 1
    fi
}

# Function to run database migrations
run_migrations() {
    echo "Running database migrations..."
    dotnet ef database update
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Database migrations completed successfully${NC}"
    else
        echo -e "${RED}Error: Database migration failed${NC}"
        exit 1
    fi
}

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: Git is not installed${NC}"
    exit 1
fi

# Create .gitignore before initializing repository
create_gitignore

# Initialize Git repository if it doesn't exist
if [ ! -d ".git" ]; then
    echo "Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit"
    echo -e "${GREEN}Git repository initialized${NC}"
fi

# Add remote repository if not already added
if ! git remote | grep -q "origin"; then
    echo "Adding remote repository..."
    git remote add origin $REMOTE_REPO
    echo -e "${GREEN}Remote repository added${NC}"
fi

# Create and switch to development branch
if ! git show-ref --verify --quiet refs/heads/development; then
    echo "Creating development branch..."
    git checkout -b development
    echo -e "${GREEN}Development branch created${NC}"
fi

# Create homologation branch if it doesn't exist
if ! git show-ref --verify --quiet refs/heads/hom; then
    echo "Creating homologation branch..."
    git checkout -b hom
    echo -e "${GREEN}Homologation branch created${NC}"
fi

# Create production branch if it doesn't exist
if ! git show-ref --verify --quiet refs/heads/prod; then
    echo "Creating production branch..."
    git checkout -b prod
    echo -e "${GREEN}Production branch created${NC}"
fi

# Update database connection and run migrations
update_db_connection
run_migrations

# Stage all changes
git add .

# Commit changes
git commit -m "Update database configuration and migrations"

# Push all branches to remote
echo "Pushing branches to remote repository..."
git push -u origin development
git push -u origin hom
git push -u origin prod

echo -e "${GREEN}Deployment completed successfully!${NC}"