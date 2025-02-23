# Keeping all the previous code exactly the same until the git initialization part...

# Initialize Git repository if it doesn't exist
if (!(Test-Path ".git")) {
    Write-ColorOutput "Initializing Git repository..." -Color Cyan
    git init -b main  # Initialize with main as the default branch
    git add .
    git commit -m "Initial commit"
    Write-ColorOutput "Git repository initialized with main branch" -Color Green
}

# Add remote repository if not already added
if (!(git remote)) {
    Write-ColorOutput "Adding remote repository..." -Color Cyan
    git remote add origin $RemoteRepo
    Write-ColorOutput "Remote repository added" -Color Green
}

# Ensure we're on main branch
if (-not (git branch --list "main")) {
    Write-ColorOutput "Creating main branch..." -Color Cyan
    git checkout -b main
    Write-ColorOutput "Main branch created" -Color Green
}

# Create and switch to development branch if it doesn't exist
if (-not (Test-BranchExists "development")) {
    Write-ColorOutput "Creating development branch..." -Color Cyan
    git checkout -b development
    Write-ColorOutput "Development branch created" -Color Green
}
else {
    Write-ColorOutput "Development branch already exists. Skipping creation." -Color Yellow
}

# Create homologation branch if it doesn't exist
if (-not (Test-BranchExists "hom")) {
    Write-ColorOutput "Creating homologation branch..." -Color Cyan
    git checkout -b hom
    Write-ColorOutput "Homologation branch created" -Color Green
}
else {
    Write-ColorOutput "Homologation branch already exists. Skipping creation." -Color Yellow
}

# Create production branch if it doesn't exist
if (-not (Test-BranchExists "prod")) {
    Write-ColorOutput "Creating production branch..." -Color Cyan
    git checkout -b prod
    Write-ColorOutput "Production branch created" -Color Green
}
else {
    Write-ColorOutput "Production branch already exists. Skipping creation." -Color Yellow
}

# Update database connection and run migrations
Update-DbConnection
Run-Migrations

# Stage all changes
git add .

# Commit changes
git commit -m "Update database configuration and migrations"

# Push all branches to remote
Write-ColorOutput "Pushing branches to remote repository..." -Color Cyan
git push -u origin main
git push -u origin development
git push -u origin hom
git push -u origin prod

# Return to main branch
Write-ColorOutput "Returning to main branch..." -Color Cyan
git checkout main
Write-ColorOutput "Switched back to main branch" -Color Green

Write-ColorOutput "Deployment completed successfully!" -Color Green