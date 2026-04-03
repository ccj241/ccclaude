# CCClaude Project Initializer (PowerShell)
# Usage: /path/to/CCClaude/init.ps1 [-ProjectDir <path>]
#
# Sets up CCClaude harness in a target project by creating the directory
# structure and copying/linking shared resources.

param(
    [string]$ProjectDir = "."
)

$ErrorActionPreference = "Stop"

$ProjectDir = (Resolve-Path $ProjectDir).Path
$HarnessDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "CCClaude Initializer" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host "Harness:  $HarnessDir"
Write-Host "Project:  $ProjectDir"
Write-Host ""

# Verify harness directory
if (-not (Test-Path "$HarnessDir\CLAUDE.md")) {
    Write-Error "Cannot find CCClaude harness at $HarnessDir"
    exit 1
}

# Step 1: Create directory structure
Write-Host "[1/6] Creating directory structure..." -ForegroundColor Yellow
$dirs = @(
    ".claude\commands",
    "rules\common",
    "rules\_project",
    "skills\common",
    "skills\_project",
    "profiles\common",
    "profiles\_project"
)
foreach ($dir in $dirs) {
    $fullPath = Join-Path $ProjectDir $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    }
}

# Step 2: Copy shared rules
Write-Host "[2/6] Copying shared rules..." -ForegroundColor Yellow
$ruleFiles = Get-ChildItem -Path "$HarnessDir\rules\common" -Filter "*.md" -ErrorAction SilentlyContinue
foreach ($file in $ruleFiles) {
    $target = Join-Path $ProjectDir "rules\common\$($file.Name)"
    if (-not (Test-Path $target)) {
        Copy-Item $file.FullName $target
        Write-Host "  Copied: rules/common/$($file.Name)"
    } else {
        Write-Host "  Exists: rules/common/$($file.Name) (skipped)"
    }
}

# Step 3: Copy shared skills
Write-Host "[3/6] Copying shared skills..." -ForegroundColor Yellow
$skillDirs = Get-ChildItem -Path "$HarnessDir\skills\common" -Directory -ErrorAction SilentlyContinue
foreach ($dir in $skillDirs) {
    $target = Join-Path $ProjectDir "skills\common\$($dir.Name)"
    if (-not (Test-Path $target)) {
        Copy-Item -Recurse $dir.FullName $target
        Write-Host "  Copied: skills/common/$($dir.Name)"
    } else {
        Write-Host "  Exists: skills/common/$($dir.Name) (skipped)"
    }
}

# Step 4: Copy commands
Write-Host "[4/6] Copying commands..." -ForegroundColor Yellow
$cmdFiles = Get-ChildItem -Path "$HarnessDir\commands" -Filter "*.md" -ErrorAction SilentlyContinue
foreach ($file in $cmdFiles) {
    $target = Join-Path $ProjectDir ".claude\commands\$($file.Name)"
    if (-not (Test-Path $target)) {
        Copy-Item $file.FullName $target
        Write-Host "  Copied: .claude/commands/$($file.Name)"
    } else {
        Write-Host "  Exists: .claude/commands/$($file.Name) (skipped)"
    }
}

# Step 5: Copy shared profiles
Write-Host "[5/6] Copying shared profiles..." -ForegroundColor Yellow
$profileFiles = Get-ChildItem -Path "$HarnessDir\profiles\common" -File -ErrorAction SilentlyContinue
foreach ($file in $profileFiles) {
    $target = Join-Path $ProjectDir "profiles\common\$($file.Name)"
    if (-not (Test-Path $target)) {
        Copy-Item $file.FullName $target
        Write-Host "  Copied: profiles/common/$($file.Name)"
    } else {
        Write-Host "  Exists: profiles/common/$($file.Name) (skipped)"
    }
}

# Step 6: Generate CLAUDE.md from template if it does not exist
Write-Host "[6/6] Setting up CLAUDE.md..." -ForegroundColor Yellow
$claudeMd = Join-Path $ProjectDir "CLAUDE.md"
if (-not (Test-Path $claudeMd)) {
    $projectName = Split-Path $ProjectDir -Leaf
    $template = Get-Content "$HarnessDir\templates\CLAUDE.md.template" -Raw
    $content = $template -replace '\{Project Name\}', $projectName
    Set-Content -Path $claudeMd -Value $content -Encoding UTF8
    Write-Host "  Created: CLAUDE.md (from template)"
} else {
    Write-Host "  Exists: CLAUDE.md (skipped)"
}

# Create .gitkeep files in _project directories
"" | Set-Content (Join-Path $ProjectDir "rules\_project\.gitkeep")
"" | Set-Content (Join-Path $ProjectDir "skills\_project\.gitkeep")
"" | Set-Content (Join-Path $ProjectDir "profiles\_project\.gitkeep")

Write-Host ""
Write-Host "CCClaude initialized successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Edit CLAUDE.md to describe your project"
Write-Host "  2. Add project-specific rules in rules/_project/"
Write-Host "  3. Add project-specific skills in skills/_project/"
Write-Host "  4. Start with: /plan <your feature description>"
