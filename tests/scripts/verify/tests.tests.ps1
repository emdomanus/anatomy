#Requires -Version 7.0
# Tests scripts/verify/tests.ps1 on a generated project: a filter matching no test is refused, the
# runner finds *.spec.luau and *.tests.ps1 by suffix and nothing else, runs each in a process of its
# own, and keeps a failing test's own failure and exit code.
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$runner = Join-Path $repoRoot 'scripts/verify/tests.ps1'
$scratch = Join-Path $repoRoot '.verification/scriptTests/tests'
$project = Join-Path $scratch 'project'
$pwsh = (Get-Process -Id $PID).Path
if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }

function Write-ProjectFile([string]$Path, [string]$Text) {
	$full = Join-Path $project $Path
	New-Item -ItemType Directory -Force (Split-Path -Parent $full) | Out-Null
	Set-Content -LiteralPath $full -Value $Text -NoNewline
}

function Invoke-Runner([string]$Filter) {
	$output = & $pwsh -NoProfile -File $runner -ProjectRoot $project -Filter $Filter 2>&1 | Out-String
	[pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output }
}

try {
	# Each spec counts the times its process has loaded the shared counter: two specs in one process
	# would see 2.
	Write-ProjectFile 'tests/processCounter.fixture.luau' "local count = 0`nreturn function()`n`tcount += 1`n`treturn count`nend`n"
	foreach ($name in 'first', 'second') {
		Write-ProjectFile "tests/pass/$name.spec.luau" "assert(require(`"../processCounter.fixture`")() == 1, `"shared a process`")`nprint(`"PASS $name`")`n"
	}
	Write-ProjectFile 'tests/pass/third.tests.ps1' "Write-Host 'PASS third'`nexit 0`n"
	Write-ProjectFile 'tests/pass/helper.luau' "error(`"a fixture ran as a test`")`n"
	Write-ProjectFile 'tests/pass/timing.bench.luau' "error(`"a bench ran as a test`")`n"
	Write-ProjectFile 'tests/fail/broken.spec.luau' "error(`"intentional spec failure`")`n"
	Write-ProjectFile 'tests/fail/broken.tests.ps1' "Write-Host 'intentional script failure'`nexit 3`n"

	$none = Invoke-Runner 'tests/no-such-test'
	if ($none.ExitCode -eq 0 -or $none.Output -notmatch 'No test .* matches') { throw "A filter matching no test was not refused: $($none.Output)" }
	Write-Host 'PASS a filter matching no test is refused'

	$pass = Invoke-Runner 'tests/pass/'
	if ($pass.ExitCode -ne 0) { throw "The passing tests failed: $($pass.Output)" }
	foreach ($marker in 'PASS first', 'PASS second', 'PASS third') {
		if ($pass.Output -notmatch [regex]::Escape($marker)) { throw "Missing '$marker': $($pass.Output)" }
	}
	if ($pass.Output -match 'ran as a test') { throw "A file without a test suffix ran: $($pass.Output)" }
	Write-Host 'PASS specs and script tests are found by suffix and each runs in its own process'

	$spec = Invoke-Runner 'tests/fail/broken.spec'
	if ($spec.ExitCode -eq 0 -or $spec.Output -notmatch 'intentional spec failure') { throw "A failing spec lost its failure: $($spec.Output)" }
	Write-Host 'PASS a failing spec fails the run with its own message'

	$script = Invoke-Runner 'tests/fail/broken.tests'
	if ($script.ExitCode -ne 3 -or $script.Output -notmatch 'intentional script failure') {
		throw "A failing script test lost its exit code ($($script.ExitCode)): $($script.Output)"
	}
	Write-Host 'PASS a failing script test fails the run with its own exit code'
} finally {
	Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}
