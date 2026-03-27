<#
.SYNOPSIS
    Запуск глобальных MCP-серверов.
.DESCRIPTION
    Поднимает глобальные контейнеры: syntax_check, help_search,
    code_checker, ssl_search, forms_server, template_search.
    Без параметра -Services запускаются все сервисы.
.PARAMETER Services
    Какие сервисы запускать. Допустимые значения:
    syntax_check, help_search, code_checker, ssl_search, forms_server, template_search.
    Без параметра — запускаются все.
.EXAMPLE
    .\start-global.ps1
    .\start-global.ps1 -Services syntax_check
    .\start-global.ps1 -Services syntax_check,help_search
#>

param(
    [ValidateSet("syntax_check", "help_search", "code_checker",
                 "ssl_search", "forms_server", "template_search")]
    [string[]]$Services
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

$envFile = Join-Path $root ".env"
if (-not (Test-Path $envFile)) {
    Write-Error "Не найден $envFile. Скопируйте .env.example в .env и заполните значения."
    exit 1
}

if ($Services) {
    $svcList = $Services -join ", "
    Write-Host "Запуск глобальных MCP-серверов [$svcList]..." -ForegroundColor Cyan

    docker compose `
        --project-name mcp-global `
        --env-file $envFile `
        -f (Join-Path $root "global\docker-compose.yml") `
        up -d @Services

    Write-Host "Глобальные серверы [$svcList] запущены." -ForegroundColor Green
} else {
    Write-Host "Запуск глобальных MCP-серверов..." -ForegroundColor Cyan

    docker compose `
        --project-name mcp-global `
        --env-file $envFile `
        -f (Join-Path $root "global\docker-compose.yml") `
        up -d

    Write-Host "Глобальные серверы запущены." -ForegroundColor Green
}
