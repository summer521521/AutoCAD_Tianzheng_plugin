$ErrorActionPreference = "Stop"
$root = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
$required = @(
  ".codex-plugin\plugin.json",
  ".mcp.json",
  "README.md"
)
foreach ($item in $required) {
  $path = Join-Path $root.Path $item
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Missing required file: $item"
  }
}
$null = Get-Content -Raw -LiteralPath (Join-Path $root.Path ".codex-plugin\plugin.json") | ConvertFrom-Json
$null = Get-Content -Raw -LiteralPath (Join-Path $root.Path ".mcp.json") | ConvertFrom-Json
Write-Output "Plugin structure check passed."
