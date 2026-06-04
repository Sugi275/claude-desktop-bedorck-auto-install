# ============================================================
# claude-cowork-admin-install.ps1
# 管理者権限の PowerShell で実行
# ============================================================
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Start-Transcript -Path "$PSScriptRoot\claude-cowork-admin-install.log" -Append

# --- 仮想マシンプラットフォームの有効化 ---
$feature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
if ($feature.State -ne "Enabled") {
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
}

# --- AWS CLI v2 のインストール ---
if (-not (Test-Path "C:\Program Files\Amazon\AWSCLIV2\aws.exe")) {
    Write-Host "[AWS CLI] Downloading..."
    $awsInstaller = "$env:TEMP\AWSCLIV2.msi"
    $awsLog = "$env:WINDIR\Temp\AWSCLI-Install.log"
    Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile $awsInstaller -UseBasicParsing
    $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$awsInstaller`" /qn /norestart /L*v `"$awsLog`"" -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        Write-Host "[ERROR] AWS CLI install failed. Exit code: $($proc.ExitCode). Log: $awsLog" -ForegroundColor Red
        exit 1
    }
    Remove-Item $awsInstaller -Force -ErrorAction SilentlyContinue
    Write-Host "[AWS CLI] Installed." -ForegroundColor Green
} else {
    Write-Host "[AWS CLI] Already installed. Skipping." -ForegroundColor Cyan
}

# --- Git for Windows のインストール ---
if (-not (Test-Path "C:\Program Files\Git\bin\bash.exe")) {
    Write-Host "[Git] Downloading..."
    $gitVersion = "2.47.1"
    $gitInstaller = "$env:TEMP\Git-Setup.exe"
    Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v${gitVersion}.windows.1/Git-${gitVersion}-64-bit.exe" -OutFile $gitInstaller
    Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS" -Wait
    Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
    Write-Host "[Git] Installed." -ForegroundColor Green
} else {
    Write-Host "[Git] Already installed. Skipping." -ForegroundColor Cyan
}

# --- Node.js のインストール ---
if (-not (Test-Path "C:\Program Files\nodejs\node.exe")) {
    Write-Host "[Node.js] Downloading..."
    $nodeVersion = "22.15.0"
    $nodeInstaller = "$env:TEMP\node-setup.msi"
    Invoke-WebRequest -Uri "https://nodejs.org/dist/v${nodeVersion}/node-v${nodeVersion}-x64.msi" -OutFile $nodeInstaller
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$nodeInstaller`" /qn /norestart" -Wait
    Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
    Write-Host "[Node.js] Installed." -ForegroundColor Green
} else {
    Write-Host "[Node.js] Already installed. Skipping." -ForegroundColor Cyan
}

# --- Claude Desktop のインストール (MSIX / 全ユーザー) ---
if (-not (Get-AppxPackage -AllUsers | Where-Object { $_.Name -like '*Claude*' })) {
    Write-Host "[Claude Desktop] Downloading..."
    $claudeMsix = "$env:TEMP\Claude.msix"
    Invoke-WebRequest -Uri "https://claude.ai/api/desktop/win32/x64/msix/latest/redirect" -OutFile $claudeMsix
    Add-AppxProvisionedPackage -Online -PackagePath $claudeMsix -SkipLicense -Regions "all"
    Remove-Item $claudeMsix -Force -ErrorAction SilentlyContinue
    Write-Host "[Claude Desktop] Installed." -ForegroundColor Green
} else {
    Write-Host "[Claude Desktop] Already installed. Skipping." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "[DONE] All installations completed successfully." -ForegroundColor Green