<#
.SYNOPSIS
    Одноразовый перезапуск стека с RESET_DATABASE / RESET_CACHE=true через временный compose-override.
.DESCRIPTION
    Не правит .env. После прогона выполните start-global.ps1 или start-project.ps1 без доп. файлов —
    контейнеры получат значения из подстановок compose (по умолчанию false).
.PARAMETER Global
    Глобальные сервисы: help_search, ssl_search, template_search.
.PARAMETER ProjectName
    Имя проекта (каталог в projects\). Профили metadata и/или graph задаются через -With.
.PARAMETER With
    Подмножество сервисов. Для -Global: Help, Ssl, Templates или All.
    Для проекта: CodeMetadata, Graph или All.
.EXAMPLE
    .\mcp-reset.ps1 -Global
    .\mcp-reset.ps1 -Global -With Ssl, Templates
    .\mcp-reset.ps1 -ProjectName buh -With CodeMetadata
    .\mcp-reset.ps1 -ProjectName buh -With Graph
    .\mcp-reset.ps1 -ProjectName buh -With All
#>

[CmdletBinding(DefaultParameterSetName = "Global")]
param(
    [Parameter(ParameterSetName = "Global")]
    [switch]$Global,

    [Parameter(ParameterSetName = "Project", Mandatory)]
    [string]$ProjectName,

    [ValidateSet("All", "CodeMetadata", "Graph", "Help", "Ssl", "Templates")]
    [string[]]$With = @("All")
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Write-TempOverride {
    param([string]$Content)
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("mcp-reset-{0}.yml" -f [Guid]::NewGuid().ToString("N"))
    [System.IO.File]::WriteAllText($path, $Content, $utf8NoBom)
    return $path
}

$rootEnv = Join-Path $root ".env"
if (-not (Test-Path $rootEnv)) {
    Write-Error "Не найден $rootEnv. Скопируйте .env.example в .env."
    exit 1
}

$yamlServices = [System.Text.StringBuilder]::new()
[void]$yamlServices.AppendLine("services:")

if ($PSCmdlet.ParameterSetName -eq "Global") {
    $doHelp = ("All" -in $With) -or ("Help" -in $With)
    $doSsl = ("All" -in $With) -or ("Ssl" -in $With)
    $doTpl = ("All" -in $With) -or ("Templates" -in $With)
    $invalid = $With | Where-Object { $_ -notin @("All", "Help", "Ssl", "Templates") }
    if ($invalid) {
        Write-Error "Для -Global допустимы только Help, Ssl, Templates, All. Указано: $($invalid -join ', ')"
        exit 1
    }
    if (-not ($doHelp -or $doSsl -or $doTpl)) {
        Write-Error "Укажите хотя бы один сервис (-With) или All."
        exit 1
    }
    if ($doHelp) {
        [void]$yamlServices.AppendLine("  help_search:")
        [void]$yamlServices.AppendLine("    environment:")
        [void]$yamlServices.AppendLine('      RESET_DATABASE: "true"')
        [void]$yamlServices.AppendLine('      RESET_CACHE: "true"')
    }
    if ($doSsl) {
        [void]$yamlServices.AppendLine("  ssl_search:")
        [void]$yamlServices.AppendLine("    environment:")
        [void]$yamlServices.AppendLine('      RESET_DATABASE: "true"')
        [void]$yamlServices.AppendLine('      RESET_CACHE: "true"')
    }
    if ($doTpl) {
        [void]$yamlServices.AppendLine("  template_search:")
        [void]$yamlServices.AppendLine("    environment:")
        [void]$yamlServices.AppendLine('      RESET_DATABASE: "true"')
        [void]$yamlServices.AppendLine('      RESET_CACHE: "true"')
    }

    $override = Write-TempOverride $yamlServices.ToString()
    try {
        Write-Host "Глобальный стек: перезапуск с RESET_*=true ..." -ForegroundColor Cyan
        docker compose `
            --project-name mcp-global `
            --env-file $rootEnv `
            -f (Join-Path $root "global\docker-compose.yml") `
            -f $override `
            up -d
    }
    finally {
        Remove-Item -LiteralPath $override -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Готово. Запустите снова .\start-global.ps1 — без override подставятся значения из .env." -ForegroundColor Green
}
else {
    $doCode = ("All" -in $With) -or ("CodeMetadata" -in $With)
    $doGraph = ("All" -in $With) -or ("Graph" -in $With)
    $invalid = $With | Where-Object { $_ -notin @("All", "CodeMetadata", "Graph") }
    if ($invalid) {
        Write-Error "Для проекта допустимы CodeMetadata, Graph, All. Указано: $($invalid -join ', ')"
        exit 1
    }
    if (-not ($doCode -or $doGraph)) {
        Write-Error "Укажите -With CodeMetadata и/или Graph или All."
        exit 1
    }

    $projectDir = Join-Path $root "projects\$ProjectName"
    if (-not (Test-Path $projectDir)) {
        Write-Error "Проект не найден: $projectDir"
        exit 1
    }
    $projectEnv = Join-Path $projectDir ".env"
    if (-not (Test-Path $projectEnv)) {
        Write-Error "Не найден $projectEnv"
        exit 1
    }
    $composeFile = Join-Path $projectDir "docker-compose.yml"

    if ($doCode) {
        [void]$yamlServices.AppendLine("  code_metadata:")
        [void]$yamlServices.AppendLine("    environment:")
        [void]$yamlServices.AppendLine('      RESET_DATABASE: "true"')
        [void]$yamlServices.AppendLine('      RESET_CACHE: "true"')
    }
    if ($doGraph) {
        [void]$yamlServices.AppendLine("  graph_metadata:")
        [void]$yamlServices.AppendLine("    environment:")
        [void]$yamlServices.AppendLine('      RESET_DATABASE: "true"')
    }

    $profileArgs = @()
    if ($doCode) {
        $profileArgs += "--profile"
        $profileArgs += "metadata"
    }
    if ($doGraph) {
        $profileArgs += "--profile"
        $profileArgs += "graph"
    }

    $override = Write-TempOverride $yamlServices.ToString()
    try {
        Write-Host "Проект '$ProjectName': перезапуск с RESET_*=true ..." -ForegroundColor Cyan
        docker compose `
            --project-name "mcp-$ProjectName" `
            --project-directory $projectDir `
            --env-file $rootEnv `
            --env-file $projectEnv `
            -f $composeFile `
            @profileArgs `
            -f $override `
            up -d
    }
    finally {
        Remove-Item -LiteralPath $override -Force -ErrorAction SilentlyContinue
    }
    $profiles = ($profileArgs | Where-Object { $_ -ne "--profile" }) -join ","
    Write-Host "Готово. Запустите снова .\start-project.ps1 -Name $ProjectName -Services $profiles" -ForegroundColor Green
}
