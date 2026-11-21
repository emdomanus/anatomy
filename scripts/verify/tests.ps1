#Requires -Version 7.0
# Runs Anatomy's tests: every *.spec.luau under tests/ in Lune, and every *.tests.ps1 (the scripts'
# tests) in PowerShell, each file in a process of its own. -Filter keeps only the tests whose
# repository-relative path contains it. -ProjectRoot runs another tree's tests; the scripts' own tests
# use it on generated trees. Lune resolves from the user's Rokit bin folder, as rokit.toml pins it.
[CmdletBinding()]
param([string]$Filter, [string]$ProjectRoot = (Join-Path $PSScriptRoot '../..'))

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$suffixes = @('.spec.luau', '.tests.ps1')
$tests = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'tests') -Recurse -File |
	Where-Object { $name = $_.Name; @($suffixes | Where-Object { $name.EndsWith($_) }).Count -gt 0 } |
	ForEach-Object { [IO.Path]::GetRelativePath($repoRoot, $_.FullName).Replace('\', '/') } |
	Where-Object { -not $Filter -or $_.Contains($Filter) } |
	Sort-Object)
if ($tests.Count -eq 0) {
	throw "No test ($($suffixes -join ', ')) under tests/ matches '$Filter'."
}

$rokitBin = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.rokit/bin'
$lune = @('lune.exe', 'lune') | ForEach-Object { Join-Path $rokitBin $_ } |
	Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $lune) {
	throw "Rokit-managed 'lune' was not found in '$rokitBin'. Run 'rokit install' from the repository root."
}
$pwsh = (Get-Process -Id $PID).Path

Push-Location $repoRoot
try {
	foreach ($test in $tests) {
		Write-Host "--- $test"
		if ($test.EndsWith('.tests.ps1')) {
			& $pwsh -NoProfile -File $test
		} else {
			& $lune 'run' $test
		}
		if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
	}
	exit 0
} finally {
	Pop-Location
}
