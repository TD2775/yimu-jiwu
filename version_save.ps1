# 一木记物 版本保存脚本
# 用法: .\version_save.ps1 <版本号> <说明>
# 示例: .\version_save.ps1 v1.0.1 "修复WebView搜索"

param(
    [Parameter(Mandatory=$true)] [string]$version,
    [Parameter(Mandatory=$false)] [string]$message = ""
)

$base = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. 备份代码到 versions/
$verDir = "$base\versions\$version"
New-Item -ItemType Directory -Force -Path $verDir | Out-Null
Copy-Item -Recurse -Force "$base\lib" -Destination "$verDir\lib"
Copy-Item -Force "$base\pubspec.yaml", "$base\analysis_options.yaml" -Destination "$verDir\"

# 2. 更新 pubspec.yaml 版本号
$pubspec = "$base\pubspec.yaml"
$content = Get-Content $pubspec -Raw
$content = $content -replace "version: .*", "version: $version"
$content | Set-Content $pubspec -Encoding UTF8 -NoNewline

# 3. 追加 VERSIONS.md
$date = Get-Date -Format "yyyy-MM-dd"
$entry = @"

## $version ($date)
- $message
"@
Add-Content -Path "$base\VERSIONS.md" -Value $entry

# 4. 复制 APK
$apk = "$base\build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    Copy-Item -Force $apk -Destination "$verDir\app-release.apk"
}

Write-Host "✅ 版本 $version 已保存"
Write-Host "   代码备份: $verDir\"
Write-Host "   VERSIONS.md 已更新"
