<#
.SYNOPSIS
    Резервное копирование векторных БД и данных Neo4j.
.PARAMETER Path
    Путь для сохранения архива (по умолчанию: E:\MCP\backups\).
.EXAMPLE
    .\backup.ps1
    .\backup.ps1 -Path D:\backups
#>

param(
    [string]$Path
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

if (-not $Path) {
    $Path = Join-Path $root "backups"
}

New-Item -ItemType Directory -Force -Path $Path | Out-Null

$date = Get-Date -Format "yyyyMMdd_HHmmss"
$archivePath = Join-Path $Path "mcp_backup_$date.zip"

Write-Host "Создание резервной копии..." -ForegroundColor Cyan

$sources = @()

$globalVolumes = Join-Path $root "global\volumes"
if (Test-Path $globalVolumes) { $sources += $globalVolumes }

Get-ChildItem (Join-Path $root "projects") -Directory | Where-Object { $_.Name -ne "_template" } | ForEach-Object {
    $vol = Join-Path $_.FullName "volumes"
    if (Test-Path $vol) { $sources += $vol }
}

if ($sources.Count -eq 0) {
    Write-Host "Нет данных для бэкапа." -ForegroundColor Yellow
    exit 0
}

Compress-Archive -Path $sources -DestinationPath $archivePath -Force

$sizeMB = [math]::Round((Get-Item $archivePath).Length / 1MB, 2)
Write-Host "Бэкап создан: $archivePath ($sizeMB MB)" -ForegroundColor Green
