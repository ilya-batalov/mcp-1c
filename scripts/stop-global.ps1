<#
.SYNOPSIS
    Остановка глобальных MCP-серверов.
.DESCRIPTION
    Без параметра -Services останавливаются все глобальные контейнеры (down).
    С параметром -Services — только указанные (остальные продолжают работать).
.PARAMETER Services
    Какие сервисы остановить. Допустимые значения:
    syntax_check, help_search, code_checker, ssl_search, forms_server, template_search.
    Без параметра — останавливаются все.
.EXAMPLE
    .\stop-global.ps1
    .\stop-global.ps1 -Services ssl_search
    .\stop-global.ps1 -Services help_search,template_search
#>

param(
    [ValidateSet("syntax_check", "help_search", "code_checker",
                 "ssl_search", "forms_server", "template_search")]
    [string[]]$Services
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$composeFile = Join-Path $root "global\docker-compose.yml"

if ($Services) {
    $svcList = $Services -join ", "
    Write-Host "Остановка глобальных MCP-серверов [$svcList]..." -ForegroundColor Yellow

    docker compose `
        --project-name mcp-global `
        -f $composeFile `
        stop @Services

    docker compose `
        --project-name mcp-global `
        -f $composeFile `
        rm -f @Services

    Write-Host "Глобальные серверы [$svcList] остановлены." -ForegroundColor Green
} else {
    Write-Host "Остановка глобальных MCP-серверов..." -ForegroundColor Yellow

    docker compose `
        --project-name mcp-global `
        -f $composeFile `
        down

    Write-Host "Глобальные серверы остановлены." -ForegroundColor Green
}
