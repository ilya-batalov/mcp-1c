<#
.SYNOPSIS
    Запуск глобальных MCP-серверов.
.DESCRIPTION
    Поднимает глобальные контейнеры: syntax_check, help_search,
    code_checker, ssl_search, forms_server, template_search.
#>

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

$envFile = Join-Path $root ".env"
if (-not (Test-Path $envFile)) {
    Write-Error "Не найден $envFile. Скопируйте .env.example в .env и заполните значения."
    exit 1
}

Write-Host "Запуск глобальных MCP-серверов..." -ForegroundColor Cyan

docker compose `
    --project-name mcp-global `
    --env-file $envFile `
    -f (Join-Path $root "global\docker-compose.yml") `
    up -d

Write-Host "Глобальные серверы запущены." -ForegroundColor Green
