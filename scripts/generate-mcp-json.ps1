<#
.SYNOPSIS
    Генерирует config\mcp.json из активных проектов.
.DESCRIPTION
    Сканирует projects\*\.env, читает порты, формирует mcp.json
    со всеми глобальными и проектными серверами.
#>

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

$servers = [ordered]@{}

# Глобальные серверы
$servers["1c-syntax-checker-mcp"] = @{ url = "http://localhost:8002/mcp"; connection_id = "1c_syntax_check_001" }
$servers["1c-help-mcp"]           = @{ url = "http://localhost:8003/mcp"; connection_id = "1c_help_search_001" }
$servers["1c-code-checker-mcp"]   = @{ url = "http://localhost:8007/mcp"; connection_id = "1c_code_checker_001" }
$servers["1c-ssl-mcp"]            = @{ url = "http://localhost:8008/mcp"; connection_id = "1c_ssl_search_001" }
$servers["1c-forms-mcp"]          = @{ url = "http://localhost:8011/mcp"; connection_id = "1c_forms_server_001" }
$servers["1c-templates-mcp"]      = @{ url = "http://localhost:8004/mcp"; connection_id = "1c_templates_search_001" }

# Проектные серверы
$projectsDir = Join-Path $root "projects"
Get-ChildItem $projectsDir -Directory | Where-Object { $_.Name -ne "_template" } | ForEach-Object {
    $envFile = Join-Path $_.FullName ".env"
    if (Test-Path $envFile) {
        $vars = @{}
        Get-Content $envFile | ForEach-Object {
            if ($_ -match "^\s*([^#][^=]+)=(.*)$") {
                $vars[$matches[1].Trim()] = $matches[2].Trim()
            }
        }

        $name = $vars["PROJECT_NAME"]
        if (-not $name) { $name = $_.Name }

        if ($vars["CODE_METADATA_PORT"]) {
            $servers["1c-code-metadata-$name-mcp"] = @{
                url = "http://localhost:$($vars['CODE_METADATA_PORT'])/mcp"
                connection_id = "1c_code_metadata_${name}_001"
            }
        }
        if ($vars["CLOUD_PORT"]) {
            $servers["1c-cloud-$name-mcp"] = @{
                url = "http://localhost:$($vars['CLOUD_PORT'])/mcp"
                connection_id = "1c_cloud_${name}_001"
            }
        }
        if ($vars["GRAPH_PORT"]) {
            $servers["1c-graph-metadata-$name-mcp"] = @{
                url = "http://localhost:$($vars['GRAPH_PORT'])/mcp"
                connection_id = "1c_graph_metadata_${name}_001"
            }
        }
    }
}

$config = [ordered]@{ mcpServers = $servers }
$json = $config | ConvertTo-Json -Depth 4

$outPath = Join-Path $root "config\mcp.json"
Set-Content -Path $outPath -Value $json -Encoding UTF8

Write-Host "mcp.json updated: $outPath" -ForegroundColor Green
Write-Host "Servers: $($servers.Count)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Install to Cursor:" -ForegroundColor Cyan
Write-Host '  .\config\install-mcp-config.ps1'
