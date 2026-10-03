#Requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet('all', 'stylua', 'selene', 'analyze', 'build', 'docs', 'tests')]
    [string]$Check = 'all',
    [string[]]$Paths = @('src', 'dev')
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$rokitBin = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.rokit/bin'
$env:PATH = "$rokitBin$([IO.Path]::PathSeparator)$env:PATH"
$definitions = Join-Path $repoRoot 'scripts/luau-lsp/globalTypes.d.luau'

function Invoke-Tool([string]$Name, [string[]]$Arguments) {
    $extension = if ($IsWindows) { '.exe' } else { '' }
    $tool = Join-Path $rokitBin "$Name$extension"
    if (-not (Test-Path -LiteralPath $tool)) { throw "Missing Rokit tool $tool. Run rokit install." }
    & $tool @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Name failed with exit code $LASTEXITCODE." }
}

Push-Location $repoRoot
try {
    $checks = if ($Check -eq 'all') { @('stylua', 'selene', 'analyze', 'tests', 'build', 'docs') } else { @($Check) }
    foreach ($gate in $checks) {
        Write-Host "==> $gate"
        switch ($gate) {
            'tests' { Invoke-Tool 'lune' @('run', 'tests/lune/anatomy.spec.luau') }
            'stylua' { Invoke-Tool 'stylua' (@('--check') + $Paths) }
            'selene' { Invoke-Tool 'selene' @('src', 'dev') }
            'analyze' {
                if (-not (Test-Path -LiteralPath $definitions)) {
                    throw 'Run pwsh -NoProfile -File scripts/setup/fetch-roblox-types.ps1 first.'
                }
                Invoke-Tool 'rojo' @('sourcemap', 'dev.project.json', '-o', 'dev-sourcemap.json')
                Invoke-Tool 'luau-lsp' @('analyze', '--flag:LuauSolverV2=true', '--sourcemap=dev-sourcemap.json', "--definitions:@roblox=$definitions", 'src', 'dev')
            }
            'build' {
                New-Item -ItemType Directory -Force -Path '.verification' | Out-Null
                Invoke-Tool 'rojo' @('build', 'default.project.json', '-o', '.verification/anatomy.rbxm')
                Invoke-Tool 'rojo' @('build', 'dev.project.json', '-o', '.verification/anatomy-dev.rbxl')
            }
            'docs' {
                & npm run docs:build
                if ($LASTEXITCODE -ne 0) { throw "Documentation build failed with exit code $LASTEXITCODE." }
            }
        }
    }
    Write-Host 'All requested checks passed.'
} finally { Pop-Location }
