<#
.SYNOPSIS
    Запуск MCP-серверов для конкретной конфигурации 1С.
.PARAMETER Name
    Имя проекта (buh, zupreg, wms, testzup, roznica, unf).
.PARAMETER Services
    Какие сервисы запускать: metadata, cloud, graph.
    Шаблоны кода (template-search-mcp) поднимаются глобально — см. start-global.ps1.
.EXAMPLE
    .\start-project.ps1 -Name buh
    .\start-project.ps1 -Name buh -Services metadata,graph
    .\start-project.ps1 -Name buh -Services cloud
    .\start-project.ps1 -Name buh -Services graph
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
if (-not (Test-Path $projectDir)) {
    Write-Error "Проект '$Name' не найден в $projectDir"
    exit 1
}

$rootEnv = Join-Path $root ".env"
$projectEnv = Join-Path $projectDir ".env"
$composeFile = Join-Path $projectDir "docker-compose.yml"

if (-not (Test-Path $rootEnv)) {
    Write-Error "Не найден $rootEnv. Скопируйте .env.example в .env и заполните значения."
    exit 1
}

if (-not $Services) {
    $Services = @("metadata")
}

$profileArgs = @()
foreach ($svc in $Services) {
    $profileArgs += "--profile"
    $profileArgs += $svc
}

$svcList = $Services -join ", "
Write-Host "Запуск [$svcList] для '$Name'..." -ForegroundColor Cyan

docker compose `
    --project-name "mcp-$Name" `
    --project-directory $projectDir `
    --env-file $rootEnv `
    --env-file $projectEnv `
    -f $composeFile `
    @profileArgs `
    up -d

Write-Host "Серверы '$Name' [$svcList] запущены." -ForegroundColor Green
