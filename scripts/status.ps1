<#
.SYNOPSIS
    Показывает статус всех MCP-контейнеров.
#>

Write-Host "`n══ MCP-контейнеры ══`n" -ForegroundColor Cyan

docker ps --filter "name=mcp_" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

$stopped = docker ps -a --filter "name=mcp_" --filter "status=exited" --format "{{.Names}}"
if ($stopped) {
    Write-Host "`nОстановленные:" -ForegroundColor Yellow
    $stopped | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}
