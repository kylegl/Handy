param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Transcript
)

# PROTOTYPE: first offer the transcript to the WSL Herdr router. If it reports
# "not handled" (75), preserve Handy's normal focused-window paste behavior.
$ErrorActionPreference = "Stop"
$router = "/home/linkdevk/repos/handy-herdr/integrations/herdr-recording-router/router.py"

$start = New-Object System.Diagnostics.ProcessStartInfo
$start.FileName = "wsl.exe"
$start.Arguments = "-d Ubuntu-20.04 -- python3 $router deliver"
$start.UseShellExecute = $false
$start.RedirectStandardInput = $true
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
$start.CreateNoWindow = $true

$process = [System.Diagnostics.Process]::Start($start)
$process.StandardInput.Write($Transcript)
$process.StandardInput.Close()
$process.WaitForExit()

if ($process.ExitCode -eq 0) {
  exit 0
}
if ($process.ExitCode -ne 75) {
  $stderr = $process.StandardError.ReadToEnd()
  Write-Error "Herdr recording router failed: $stderr"
  exit $process.ExitCode
}

$previousClipboard = $null
$hadClipboard = $false
try {
  $previousClipboard = Get-Clipboard -Raw
  $hadClipboard = $true
}
catch {}

try {
  Set-Clipboard -Value $Transcript
  Start-Sleep -Milliseconds 60
  $shell = New-Object -ComObject WScript.Shell
  $shell.SendKeys('^v')
  Start-Sleep -Milliseconds 80
  $shell.SendKeys('{ENTER}')
  Start-Sleep -Milliseconds 100
}
finally {
  if ($hadClipboard) {
    try { Set-Clipboard -Value $previousClipboard } catch {}
  }
}
