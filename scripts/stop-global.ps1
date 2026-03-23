<#
.SYNOPSIS
    Остановка глобальных MCP-серверов.
#>

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

Write-Host "Остановка глобальных MCP-серверов..." -ForegroundColor Yellow

docker compose `
    --project-name mcp-global `
    -f (Join-Path $root "global\docker-compose.yml") `
    down

Write-Host "Глобальные серверы остановлены." -ForegroundColor Green
