$ErrorActionPreference = "Stop"

$winget = Get-Command "winget" -ErrorAction SilentlyContinue
if (-not $winget) {
    throw "winget was not found. Install App Installer from Microsoft Store or install dependencies manually."
}

$packages = @(
    @{ Id = "Python.Python.3.12"; Name = "Python 3.12" },
    @{ Id = "OpenJS.NodeJS.LTS"; Name = "Node.js LTS" },
    @{ Id = "Git.Git"; Name = "Git" },
    @{ Id = "JohnMacFarlane.Pandoc"; Name = "Pandoc" },
    @{ Id = "Google.Chrome"; Name = "Google Chrome" }
)

Write-Output "This script installs common dependencies with winget."
Write-Output "It may prompt for confirmation or administrator permission."
Write-Output "Packages:"
foreach ($package in $packages) {
    Write-Output ("- " + $package.Name + " (" + $package.Id + ")")
}

foreach ($package in $packages) {
    Write-Output ("installing=" + $package.Id)
    & $winget.Source install --id $package.Id --exact --accept-source-agreements --accept-package-agreements
}

Write-Output "done=true"
Write-Output "Restart PowerShell or the AI application if commands are still not detected in PATH."
