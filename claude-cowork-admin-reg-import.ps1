# ============================================================
# claude-cowork-admin-reg-import.ps1
# 管理者権限の PowerShell で実行
# ============================================================
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Start-Transcript -Path "$PSScriptRoot\claude-cowork-admin-reg-import.log" -Append

$originalUser = (Get-WmiObject Win32_Process -Filter "name='explorer.exe'").GetOwner().User

$sid = (New-Object System.Security.Principal.NTAccount($originalUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

(Get-Content "C:\ClaudeDesktopScript\Claude.reg") -replace "HKEY_CURRENT_USER", "HKEY_USERS\$sid" | Set-Content "C:\ClaudeDesktopScript\Claude_hku.reg" -Encoding Unicode

reg import "C:\ClaudeDesktopScript\Claude_hku.reg"

Write-Host ""
Write-Host "[VERIFY] Checking imported registry keys..." -ForegroundColor Cyan
reg query "HKEY_USERS\$sid\SOFTWARE\Policies\Claude"
Write-Host ""
Write-Host "[DONE] Registry import completed." -ForegroundColor Green

Stop-Transcript
