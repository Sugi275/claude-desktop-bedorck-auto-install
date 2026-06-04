# ============================================================
# claude-cowork-user-configure.ps1
# ユーザー権限で実行（GPO ログオンスクリプト or 手動）
# ============================================================

$ErrorActionPreference = "Stop"

Start-Transcript -Path "$PSScriptRoot\claude-cowork-user-configure.log" -Append

# ============================================================
# ★ 環境ごとに変更が必要な設定値
# ============================================================
$SsoStartUrl     = "https://xxxxxxxx.awsapps.com/start"  # ★ SSO ポータルの URL
$SsoAccountId    = "xxxxxxxxxxxx"                          # ★ AWS アカウント ID (12桁)
$SsoRoleName     = "ClaudeDesktopPermissionSet"            # ★ 付与する Permission Set 名
$SsoRegion       = "ap-northeast-1"                        # ★ SSO を構成しているリージョン
$ProfileRegion   = "ap-northeast-1"                        # ★ デフォルトリージョン
$ProfileName     = "ClaudeDesktopSSOProfile"               # ★ プロファイル名（レジストリ設定と合わせる）
$SessionName     = "ClaudeDesktopSSOSession"               # ★ セッション名（レジストリ設定と合わせる）
# ============================================================

# --- 環境変数 CLAUDE_CODE_GIT_BASH_PATH の設定 ---
$currentVal = [System.Environment]::GetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", [System.EnvironmentVariableTarget]::User)
if ($currentVal -ne "C:\Program Files\Git\bin") {
    [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", "C:\Program Files\Git\bin", [System.EnvironmentVariableTarget]::User)
}

# --- settings.json の作成 ---
$claudeDir = "$env:USERPROFILE\.claude"
$settingsPath = "$claudeDir\settings.json"
if (-not (Test-Path $settingsPath)) {
    if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }
    $settingsJson = @'
{
  "env": {
    "SHELL": "C:\\Program Files\\Git\\bin\\bash.exe"
  }
}
'@
    Set-Content -Path $settingsPath -Value $settingsJson -Encoding UTF8
}

# --- AWS CLI config の作成 ---
$awsDir     = "$env:USERPROFILE\.aws"
$configPath = "$awsDir\config"
if (-not (Test-Path $configPath)) {
    if (-not (Test-Path $awsDir)) { New-Item -ItemType Directory -Path $awsDir -Force | Out-Null }
    $awsConfig = @"
[profile $ProfileName]
sso_session = $SessionName
sso_account_id = $SsoAccountId
sso_role_name = $SsoRoleName
region = $ProfileRegion

[sso-session $SessionName]
sso_start_url = $SsoStartUrl
sso_region = $SsoRegion
sso_registration_scopes = sso:account:access
"@
    [System.IO.File]::WriteAllLines($configPath, $awsConfig, [System.Text.UTF8Encoding]::new($false))
    Write-Host "[AWS config] Created: $configPath" -ForegroundColor Green
} else {
    Write-Host "[AWS config] Already exists. Skipping." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "[AWS config] Content:" -ForegroundColor Cyan
Get-Content $configPath | Write-Host

Write-Host ""
Write-Host "[DONE] User configuration completed successfully." -ForegroundColor Green

Stop-Transcript