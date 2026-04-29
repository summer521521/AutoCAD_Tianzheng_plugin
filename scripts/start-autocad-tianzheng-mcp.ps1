param(
  [switch]$Check
)

$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
  [Console]::Error.WriteLine($Message)
  exit 1
}

function Assert-Path([string]$Name, [string]$PathValue, [string]$PathType) {
  if ([string]::IsNullOrWhiteSpace($PathValue)) {
    Fail "$Name is not set."
  }
  if (-not (Test-Path -LiteralPath $PathValue -PathType $PathType)) {
    Fail "$Name does not exist: $PathValue"
  }
}

$mcpRoot = $env:AUTOCAD_TIANZHENG_MCP_ROOT
Assert-Path "AUTOCAD_TIANZHENG_MCP_ROOT" $mcpRoot "Container"

$serverPath = Join-Path $mcpRoot "src\server.py"
Assert-Path "AUTOCAD_TIANZHENG_MCP_ROOT\src\server.py" $serverPath "Leaf"

$pythonExe = $env:AUTOCAD_TIANZHENG_PYTHON
if ([string]::IsNullOrWhiteSpace($pythonExe)) {
  $pythonExe = Join-Path $mcpRoot ".venv\Scripts\python.exe"
}
Assert-Path "AUTOCAD_TIANZHENG_PYTHON" $pythonExe "Leaf"

if (-not [string]::IsNullOrWhiteSpace($env:AUTOCAD_EXE)) {
  Assert-Path "AUTOCAD_EXE" $env:AUTOCAD_EXE "Leaf"
}

if (-not [string]::IsNullOrWhiteSpace($env:TIANZHENG_ROOT)) {
  Assert-Path "TIANZHENG_ROOT" $env:TIANZHENG_ROOT "Container"
}

if ($Check) {
  Write-Output "OK: AUTOCAD_TIANZHENG_MCP_ROOT"
  Write-Output "OK: AUTOCAD_TIANZHENG_PYTHON"
  if (-not [string]::IsNullOrWhiteSpace($env:AUTOCAD_EXE)) { Write-Output "OK: AUTOCAD_EXE" }
  if (-not [string]::IsNullOrWhiteSpace($env:TIANZHENG_ROOT)) { Write-Output "OK: TIANZHENG_ROOT" }
  Write-Output "OK: AutoCAD Tianzheng MCP wrapper paths are valid."
  exit 0
}

& $pythonExe $serverPath
if ($LASTEXITCODE -ne $null) {
  exit $LASTEXITCODE
}
