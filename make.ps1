# .NET 10 Project Utility Scripts
# Run from project root: .\make.ps1 <target>

param(
    [Parameter(Position=0)]
    [string]$Target = "help",

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Args
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$SrcDir = Join-Path $ProjectRoot "src"
$ApiProject = Join-Path $SrcDir "Playground\FSH.Starter.Api\FSH.Starter.Api.csproj"
$AppHostProject = Join-Path $SrcDir "Playground\FSH.Starter.AppHost\FSH.Starter.AppHost.csproj"
$MigrationsProject = Join-Path $SrcDir "Playground\FSH.Starter.Migrations.PostgreSQL\FSH.Starter.Migrations.PostgreSQL.csproj"
$ClientsDir = Join-Path $ProjectRoot "clients\admin"
$TestDir = Join-Path $SrcDir "Tests"

function Get-Help {
    Write-Host "Usage: .\make.ps1 <target> [options]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Development:" -ForegroundColor Yellow
    Write-Host "  .\make.ps1 run-api        - Run API (http://localhost:8080)"
    Write-Host "  .\make.ps1 run-apihost   - Run AppHost (Aspire)"
    Write-Host "  .\make.ps1 run-ui        - Run UI (http://localhost:3000)"
    Write-Host ""
    Write-Host "Build:" -ForegroundColor Yellow
    Write-Host "  .\make.ps1 build         - Build solution"
    Write-Host "  .\make.ps1 build-api    - Build API (Release)"
    Write-Host "  .\make.ps1 rebuild      - Clean and build"
    Write-Host ""
    Write-Host "Clean:" -ForegroundColor Yellow
    Write-Host "  .\make.ps1 clean        - Clean bin/obj"
    Write-Host "  .\make.ps1 clean-all    - Clean all including tests"
    Write-Host ""
    Write-Host "Database:" -ForegroundColor Yellow
    Write-Host "  .\make.ps1 migrate name=<Name>    - Create migration"
    Write-Host "  .\make.ps1 migrate-run          - Apply migrations"
    Write-Host "  .\make.ps1 migrate-list       - List migrations"
    Write-Host ""
    Write-Host "Code Generation:" -ForegroundColor Yellow
    Write-Host "  .\make.ps1 nswag              - Regenerate OpenAPI client"
    Write-Host ""
    Write-Host "Linting:" -ForegroundColor Yellow
    Write-Host "  .\make.ps1 lint              - Run UI linting"
    Write-Host ""
    Write-Host "Publish:" -ForegroundColor Yellow
    Write-Host "  .\make.ps1 publish-api   - Publish to ./publish/api"
    Write-Host "  .\make.ps1 publish-iis  - Publish to IIS"
    Write-Host ""
    Write-Host "Test:" -ForegroundColor Yellow
    Write-Host "  .\make.ps1 test         - Run all tests"
    Write-Host "  .\make.ps1 test-unit   - Run unit tests"
    Write-Host ""
    Write-Host "Utilities:" -ForegroundColor Yellow
    Write-Host "  .\make.ps1 info       - Show environment info"
    Write-Host "  .\make.ps1 add-tools  - Install required .NET tools"
    Write-Host "  .\make.ps1 install   - Install UI dependencies"
}

function Invoke-RunApi {
    Write-Host "Running API at http://localhost:8080..." -ForegroundColor Green
    dotnet run --project $ApiProject --configuration Debug
}

function Invoke-RunApiHost {
    Write-Host "Running AppHost..." -ForegroundColor Green
    dotnet run --project $AppHostProject --configuration Debug
}

function Invoke-RunUi {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    Push-Location $ClientsDir
    pnpm install
    Write-Host "Running UI at http://localhost:3000..." -ForegroundColor Green
    pnpm dev
    Pop-Location
}

function Invoke-Build {
    Write-Host "Building solution..." -ForegroundColor Green
    dotnet build $ApiProject --verbosity minimal
}

function Invoke-Rebuild {
    Write-Host "Cleaning..." -ForegroundColor Yellow
    Remove-BinObj
    Write-Host "Building..." -ForegroundColor Yellow
    Invoke-Build
}

function Remove-BinObj {
    Get-ChildItem -Path $SrcDir -Directory -Recurse -Include "bin","obj" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $TestDir -Directory -Recurse -Include "bin","obj" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

function Invoke-Test {
    $slnx = Join-Path $SrcDir "FSH.Starter.slnx"
    dotnet test $slnx --verbosity minimal
}

function Invoke-TestUnit {
    $testProject = Join-Path $TestDir "Generic.Tests\Generic.Tests.csproj"
    dotnet test $testProject --verbosity minimal
}

function Get-MigrationName {
    param([string]$Name)
    if ([string]::IsNullOrEmpty($Name)) {
        Write-Host "Error: Migration name is required" -ForegroundColor Red
        Write-Host "Usage: .\make.ps1 migrate name=YourMigrationName" -ForegroundColor Cyan
        exit 1
    }
    return $Name
}

function Invoke-Migrate {
    $name = Get-MigrationName -Name $Args[0]
    Write-Host "Creating migration: $name" -ForegroundColor Green
    dotnet ef migrations add $name --project $MigrationsProject --startup-project $ApiProject
}

function Invoke-MigrateRun {
    Write-Host "Applying migrations..." -ForegroundColor Green
    dotnet ef database update --project $MigrationsProject --startup-project $ApiProject
}

function Get-MigrationList {
    dotnet ef migrations list --project $MigrationsProject --startup-project $ApiProject
}

function Invoke-PublishApi {
    $outDir = Join-Path $ProjectRoot "publish\api"
    Write-Host "Publishing to $outDir..." -ForegroundColor Green
    dotnet publish $ApiProject --configuration Release --output $outDir
}

function Invoke-PublishIis {
    $outDir = Join-Path $ProjectRoot "publish\iis"
    Write-Host "Publishing to $outDir..." -ForegroundColor Green
    dotnet publish $ApiProject --configuration Release --output $outDir -p:PublishProfile=IIS
}

function Invoke-Nswag {
    Write-Host "Generating API client..." -ForegroundColor Green
    Push-Location $ClientsDir
    pnpm generate
    Pop-Location
}

function Get-Info {
    Write-Host "Environment Info:" -ForegroundColor Cyan
    Write-Host "  .NET SDK: $(dotnet --version)"
    Write-Host "  Node: $(node --version)"
    Write-Host "  pnpm: $(pnpm --version)"
    Write-Host "  Project: $ApiProject"
}

function Add-Tools {
    Write-Host "Installing .NET tools..." -ForegroundColor Green
    try { dotnet tool install --global dotnet-ef } catch { Write-Host "dotnet-ef already installed" -ForegroundColor Gray }
    try { dotnet tool install --global dotnet-format } catch { Write-Host "dotnet-format already installed" -ForegroundColor Gray }
}

function Invoke-InstallDependencies {
    Write-Host "Installing UI dependencies..." -ForegroundColor Green
    Push-Location $ClientsDir
    pnpm install
    Pop-Location
    Write-Host "Dependencies installed" -ForegroundColor Green
}

switch ($Target) {
    "help"       { Get-Help }
    "run-api"   { Invoke-RunApi }
    "run-apihost" { Invoke-RunApiHost }
    "run-ui"    { Invoke-RunUi }
    "build"     { Invoke-Build }
    "build-api" {
        Write-Host "Building API (Release)..." -ForegroundColor Green
        dotnet build $ApiProject --configuration Release --verbosity minimal
    }
    "rebuild"   { Invoke-Rebuild }
    "clean"     { Remove-BinObj; Write-Host "Cleaned bin/obj folders" -ForegroundColor Green }
    "clean-all"  { Remove-BinObj; Write-Host "Cleaned all folders" -ForegroundColor Green }
    "test"      { Invoke-Test }
    "test-unit" { Invoke-TestUnit }
    "migrate"   { Invoke-Migrate }
    "migrate-run" { Invoke-MigrateRun }
    "migrate-list" { Get-MigrationList }
    "publish-api" { Invoke-PublishApi }
    "publish-iis" { Invoke-PublishIis }
    "nswag"     { Invoke-Nswag }
    "info"      { Get-Info }
    "add-tools" { Add-Tools }
    "install"   { Invoke-InstallDependencies }
    default {
        Write-Host "Unknown target: $Target" -ForegroundColor Red
        Write-Host "Run '.\make.ps1 help' for available targets" -ForegroundColor Cyan
        exit 1
    }
}