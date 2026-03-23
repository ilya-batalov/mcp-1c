<#
.SYNOPSIS
    Остановка MCP-серверов для конкретной конфигурации 1С.
.PARAMETER Name
    Имя проекта (buh, zupreg, testzup, roznica, unf).
.PARAMETER Services
    Какие сервисы остановить: metadata, cloud, graph.
    Без параметра — останавливаются все контейнеры проекта.
.EXAMPLE
    .\stop-project.ps1 -Name buh
    .\stop-project.ps1 -Name buh -Services graph
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [ValidateSet("metadata", "cloud", "graph")]
    [string[]]$Services
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

$projectDir = Join-Path $root "projects\$Name"
$composeFile = Join-Path $projectDir "docker-compose.yml"
$rootEnv = Join-Path $root ".env"
$projectEnv = Join-Path $projectDir ".env"

if (-not (Test-Path $projectDir)) {
    Write-Error "Проект '$Name' не найден в $projectDir"
    exit 1
}

if (-not $Services) {
    Write-Host "Остановка всех серверов '$Name'..." -ForegroundColor Yellow
    docker compose `
        --project-name "mcp-$Name" `
        --project-directory $projectDir `
        -f $composeFile `
        down
} else {
    $profileArgs = @()
    foreach ($svc in $Services) {
        $profileArgs += "--profile"
        $profileArgs += $svc
    }

    $svcList = $Services -join ", "
    Write-Host "Остановка [$svcList] для '$Name'..." -ForegroundColor Yellow

    docker compose `
        --project-name "mcp-$Name" `
        --project-directory $projectDir `
        --env-file $rootEnv `
        --env-file $projectEnv `
        -f $composeFile `
        @profileArgs `
        down
}

Write-Host "Серверы '$Name' остановлены." -ForegroundColor Green
