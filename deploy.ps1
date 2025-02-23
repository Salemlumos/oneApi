param(
    [Parameter(Mandatory=$true)]
    [string]$RemoteRepo,
    
    [Parameter(Mandatory=$true)]
    [string]$DbConnection
)

# Set working directory
Set-Location "C:\Users\icirino\l3\openApi8"

# Colors for output
$Green = "\033[0;32m"
$Yellow = "\033[1;33m"
$Red = "\033[0;31m"
$NC = "\033[0m"

# Function to create .gitignore file
function Create-GitIgnore {
    $gitignoreContent = @"
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
appsettings.Production.json
*.secret.json
secrets.json

# Logs
*.log
logs/
Log/
"@

    Set-Content -Path ".gitignore" -Value $gitignoreContent
    Write-Host "${Green}.gitignore file created${NC}"
}

# Function to update database connection string
function Update-DbConnection {
    # First check for appsettings.Development.json
    $settingsPath = "appsettings.Development.json"
    if (-not (Test-Path $settingsPath)) {
        $settingsPath = "appsettings.json"
    }
    
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        
        # Check if ConnectionStrings exists, if not create it
        if (-not (Get-Member -InputObject $settings -Name "ConnectionStrings" -MemberType Properties)) {
            $settings | Add-Member -Name "ConnectionStrings" -Value ([PSCustomObject]@{}) -MemberType NoteProperty
        }
        
        # Add or update Development connection
        if (-not (Get-Member -InputObject $settings.ConnectionStrings -Name "Development" -MemberType Properties)) {
            $settings.ConnectionStrings | Add-Member -Name "Development" -Value $DbConnection -MemberType NoteProperty
        } else {
            $settings.ConnectionStrings.Development = $DbConnection
        }

        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
        Write-Host "${Green}Database connection string updated in $settingsPath${NC}"
    }
    else {
        Write-Host "${Red}Error: No appsettings files found${NC}"
        exit 1
    }
}

# Function to run database migrations
function Run-Migrations {
    Write-Host "Running database migrations..."
    dotnet ef database update
    if ($LASTEXITCODE -eq 0) {
        Write-Host "${Green}Database migrations completed successfully${NC}"
    }
    else {
        Write-Host "${Red}Error: Database migration failed${NC}"
        exit 1
    }
}

# Check if Git is installed
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "${Red}Error: Git is not installed${NC}"
    exit 1
}

# Create .gitignore before initializing repository
Create-GitIgnore

# Initialize Git repository if it doesn't exist
if (!(Test-Path ".git")) {
    Write-Host "Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit"
    Write-Host "${Green}Git repository initialized${NC}"
}

# Add remote repository if not already added
if (!(git remote)) {
    Write-Host "Adding remote repository..."
    git remote add origin $RemoteRepo
    Write-Host "${Green}Remote repository added${NC}"
}

# Create and switch to development branch
if (!(git branch --list development)) {
    Write-Host "Creating development branch..."
    git checkout -b development
    Write-Host "${Green}Development branch created${NC}"
}

# Create homologation branch if it doesn't exist
if (!(git branch --list hom)) {
    Write-Host "Creating homologation branch..."
    git checkout -b hom
    Write-Host "${Green}Homologation branch created${NC}"
}

# Create production branch if it doesn't exist
if (!(git branch --list prod)) {
    Write-Host "Creating production branch..."
    git checkout -b prod
    Write-Host "${Green}Production branch created${NC}"
}

# Update database connection and run migrations
Update-DbConnection
Run-Migrations

# Stage all changes
git add .

# Commit changes
git commit -m "Update database configuration and migrations"

# Push all branches to remote
Write-Host "Pushing branches to remote repository..."
git push -u origin development
git push -u origin hom
git push -u origin prod

Write-Host "${Green}Deployment completed successfully!${NC}"