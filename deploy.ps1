param(
    [Parameter(Mandatory=$true)]
    [string]$RemoteRepo,
    
    [Parameter(Mandatory=$true)]
    [string]$DbConnection
)

# Set working directory
Set-Location "C:\Users\icirino\l3\openApi8"

# Function to write colored output
function Write-ColorOutput {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to validate database connection string
function Test-DatabaseConnection {
    param (
        [string]$ConnectionString
    )
    
    try {
        # Identify database type and validate format
        if ($ConnectionString -match "Host=") {
            Write-ColorOutput "Database Type: PostgreSQL" -Color Green
            if ($ConnectionString -match "Host=.+;Database=.+;") {
                Write-ColorOutput "Connection string format is valid" -Color Green
                return $true
            }
        }
        elseif ($ConnectionString -match "Server=") {
            Write-ColorOutput "Database Type: SQL Server" -Color Green
            if ($ConnectionString -match "Server=.+;Database=.+;") {
                Write-ColorOutput "Connection string format is valid" -Color Green
                return $true
            }
        }

        Write-ColorOutput "Error: Invalid connection string format" -Color Red
        Write-ColorOutput "Must contain either:" -Color Yellow
        Write-ColorOutput "PostgreSQL: Host=server;Database=dbname;Username=user;Password=pass" -Color Yellow
        Write-ColorOutput "SQL Server: Server=server;Database=dbname;User Id=user;Password=pass" -Color Yellow
        return $false
    }
    catch {
        Write-ColorOutput "Error: Could not validate connection string" -Color Red
        Write-ColorOutput "Details: $($_.Exception.Message)" -Color Yellow
        return $false
    }
}

# Function to validate Git repository
function Test-GitRepository {
    param (
        [string]$RepoUrl
    )
    
    try {
        # Try to list the remote repo without actually cloning it
        $output = git ls-remote $RepoUrl 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        else {
            Write-ColorOutput "Error: Repository '$RepoUrl' is not accessible" -Color Red
            Write-ColorOutput "Please check if the repository exists and you have proper access rights" -Color Yellow
            return $false
        }
    }
    catch {
        Write-ColorOutput "Error: Could not validate repository" -Color Red
        Write-ColorOutput "Details: $($_.Exception.Message)" -Color Yellow
        return $false
    }
}

# Function to check existing connection string and prompt for update
function Should-UpdateConnectionString {
    $settingsPath = "appsettings.Development.json"
    if (-not (Test-Path $settingsPath)) {
        $settingsPath = "appsettings.json"
    }
    
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        
        if ((Get-Member -InputObject $settings -Name "ConnectionStrings" -MemberType Properties) -and 
            (Get-Member -InputObject $settings.ConnectionStrings -Name "Development" -MemberType Properties)) {
            
            $currentConnection = $settings.ConnectionStrings.Development
            if ($currentConnection -ne $DbConnection) {
                Write-ColorOutput "Existing connection string found:" -Color Yellow
                Write-Host "Current: $currentConnection"
                Write-Host "New: $DbConnection"
                
                $response = Read-Host "Do you want to update the connection string? (Y/N)"
                return $response -eq "Y" -or $response -eq "y"
            }
            Write-ColorOutput "Connection string is identical to existing one. Skipping update." -Color Yellow
            return $false
        }
    }
    return $true
}

# Function to check if a branch exists locally or remotely
function Test-BranchExists {
    param (
        [string]$BranchName
    )
    
    # Check local branch
    $localExists = git branch --list $BranchName
    if ($localExists) {
        return $true
    }
    
    # Check remote branch
    $remoteExists = git ls-remote --heads origin $BranchName
    if ($remoteExists) {
        return $true
    }
    
    return $false
}

# Initial validation
Write-ColorOutput "Performing initial validation..." -Color Cyan

# Validate database connection
Write-ColorOutput "Testing database connection..." -Color Cyan
if (-not (Test-DatabaseConnection -ConnectionString $DbConnection)) {
    Write-ColorOutput "Deployment cancelled due to database connection validation failure" -Color Red
    exit 1
}
Write-ColorOutput "Database connection validated successfully" -Color Green

# Validate Git repository
Write-ColorOutput "Testing Git repository access..." -Color Cyan
if (-not (Test-GitRepository -RepoUrl $RemoteRepo)) {
    Write-ColorOutput "Deployment cancelled due to Git repository validation failure" -Color Red
    exit 1
}
Write-ColorOutput "Git repository validated successfully" -Color Green

# Function to create .gitignore file
function Create-GitIgnore {
    if (Test-Path ".gitignore") {
        Write-ColorOutput ".gitignore already exists. Skipping creation." -Color Yellow
        return
    }

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
    Write-ColorOutput ".gitignore file created" -Color Green
}

# Function to update database connection string
function Update-DbConnection {
    if (-not (Should-UpdateConnectionString)) {
        Write-ColorOutput "Skipping connection string update" -Color Yellow
        return
    }

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
        Write-ColorOutput "Database connection string updated in $settingsPath" -Color Green
    }
    else {
        Write-ColorOutput "Error: No appsettings files found" -Color Red
        exit 1
    }
}

# Function to run database migrations
function Run-Migrations {
    Write-ColorOutput "Running database migrations..." -Color Cyan
    try {
        $output = dotnet ef database update 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Database migrations completed successfully" -Color Green
        }
        else {
            Write-ColorOutput "Error: Database migration failed" -Color Red
            Write-ColorOutput "Details: $output" -Color Yellow
            exit 1
        }
    }
    catch {
        Write-ColorOutput "Error: Database migration failed" -Color Red
        Write-ColorOutput "Details: $($_.Exception.Message)" -Color Yellow
        exit 1
    }
}

# Check if Git is installed
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-ColorOutput "Error: Git is not installed" -Color Red
    exit 1
}

Write-ColorOutput "All initial validations passed. Proceeding with deployment..." -Color Green

# Create .gitignore before initializing repository
Create-GitIgnore

# Initialize Git repository if it doesn't exist
if (!(Test-Path ".git")) {
    Write-ColorOutput "Initializing Git repository..." -Color Cyan
    git init
    git add .
    git commit -m "Initial commit"
    Write-ColorOutput "Git repository initialized" -Color Green
}

# Add remote repository if not already added
if (!(git remote)) {
    Write-ColorOutput "Adding remote repository..." -Color Cyan
    git remote add origin $RemoteRepo
    Write-ColorOutput "Remote repository added" -Color Green
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
git push -u origin development
git push -u origin hom
git push -u origin prod

Write-ColorOutput "Deployment completed successfully!" -Color Green