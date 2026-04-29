$ErrorActionPreference = "Stop"

$repoRoot = (git rev-parse --show-toplevel).Trim()
$raw = git -C $repoRoot ls-files -z
$tracked = ($raw -split "`0") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
$patterns = @(
  @{ Name = "Windows user profile path"; Regex = "[A-Za-z]:\\Users\\[^\\\r\n]+(?:\\[^\r\n]*)?" },
  @{ Name = "POSIX home path"; Regex = "/(?:Users|home)/[^/\r\n]+(?:/[^\r\n]*)?" },
  @{ Name = "GitHub token"; Regex = "ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}" },
  @{ Name = "OpenAI style key"; Regex = "sk-[A-Za-z0-9_-]{20,}" },
  @{ Name = "Private key block"; Regex = "-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----" }
)
$blockedExtensions = @(".env", ".pem", ".key", ".pfx", ".sqlite", ".db", ".dwg", ".slx", ".mat", ".log", ".xlog")
$findings = New-Object System.Collections.Generic.List[string]

foreach ($relative in $tracked) {
  $extension = [System.IO.Path]::GetExtension($relative).ToLowerInvariant()
  if ($blockedExtensions -contains $extension) {
    $findings.Add("Tracked sensitive/local artifact extension: $relative") | Out-Null
  }

  $full = Join-Path $repoRoot $relative
  if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
  $bytes = [System.IO.File]::ReadAllBytes($full)
  if ($bytes.Length -gt 2MB) { continue }
  $text = [System.Text.Encoding]::UTF8.GetString($bytes)
  foreach ($pattern in $patterns) {
    if ([regex]::IsMatch($text, $pattern.Regex)) {
      $findings.Add("$($pattern.Name): $relative") | Out-Null
    }
  }
}

if ($findings.Count -gt 0) {
  Write-Error ("Privacy check failed:`n" + ($findings -join "`n"))
}

Write-Output "Privacy check passed."
