<#
.SYNOPSIS
    Создаёт новый проект из шаблона.
.PARAMETER Name
    Имя нового проекта (латиницей, без пробелов).
.PARAMETER PortBase
    Базовый порт (8100, 8200, ... с шагом 100).
.EXAMPLE
    .\new-project.ps1 -Name erp -PortBase 8600
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [int]$PortBase
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

$projectDir = Join-Path $root "projects\$Name"
if (Test-Path $projectDir) {
    Write-Error "Проект '$Name' уже существует в $projectDir"
    exit 1
}

$templateDir = Join-Path $root "projects\_template"

Write-Host "Создание проекта '$Name' (PORT_BASE=$PortBase)..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path @(
    "$projectDir\data\report",
    "$projectDir\data\src",
    "$projectDir\volumes\code_metadata",
    "$projectDir\volumes\cloud_embeddings",
    "$projectDir\volumes\graph_neo4j"
) | Out-Null

New-Item -ItemType File -Force -Path "$projectDir\data\report\.gitkeep" | Out-Null
New-Item -ItemType File -Force -Path "$projectDir\data\src\.gitkeep" | Out-Null

Copy-Item (Join-Path $templateDir "docker-compose.yml") $projectDir

$envContent = @"
PROJECT_NAME=$Name

CODE_METADATA_PORT=$($PortBase)
CLOUD_PORT=$($PortBase + 1)
GRAPH_PORT=$($PortBase + 6)
NEO4J_BROWSER_PORT=$($PortBase + 74)
NEO4J_BOLT_PORT=$($PortBase + 87)
"@

Set-Content -Path (Join-Path $projectDir ".env") -Value $envContent -Encoding UTF8

Write-Host "Проект создан: $projectDir" -ForegroundColor Green
Write-Host ""
Write-Host "Следующие шаги:" -ForegroundColor Cyan
Write-Host "  1. Выгрузите данные из Конфигуратора:"
Write-Host "     - Отчёт из конфигурации → projects\$Name\data\report\"
Write-Host "     - Выгрузить в файлы     → projects\$Name\data\src\"
Write-Host "  2. Запустите: .\start-project.ps1 -Name $Name"
Write-Host "  3. Обновите mcp.json: .\generate-mcp-json.ps1"
