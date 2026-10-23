#requires -Version 5.1
# HEIC2Jpg：对应 Windows 原生 / Docker 适配入口。确认前不执行业务；-Check 只加载检查。
param([switch]$Check)
try {
    . (Join-Path $PSScriptRoot 'JobsTools.ps1')
    Invoke-JobsShTool -Tool 'HEIC2Jpg' -Check:$Check
    exit 0
} catch {
    Write-Host ('✖ ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
