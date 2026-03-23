<#
.SYNOPSIS
    Устанавливает mcp.json в конфигурацию Cursor.
.DESCRIPTION
    Копирует config\mcp.json в %APPDATA%\Cursor\User\globalStorage\mcp.json.
    Создаёт резервную копию существующего файла.
#>

$ErrorActionPreference = "Stop"

$source = Join-Path $PSScriptRoot "mcp.json"
$targetDir = Join-Path $env:APPDATA "Cursor\User\globalStorage"
$target = Join-Path $targetDir "mcp.json"

if (-not (Test-Path $source)) {
    Write-Error "Файл $source не найден"
    exit 1
}

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

if (Test-Path $target) {
    $backup = "$target.bak.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $target $backup
    Write-Host "Резервная копия: $backup" -ForegroundColor Yellow
}

Copy-Item $source $target -Force
Write-Host "mcp.json установлен: $target" -ForegroundColor Green
Write-Host "Перезапустите Cursor для применения изменений." -ForegroundColor Cyan
