# Script PowerShell para destruir o Lab DevOps
$ErrorActionPreference = "Stop"

# Função para logging
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "✗ " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

Write-Warning "Destruindo laboratório DevOps..."
Write-Info "Todos os containers, redes e volumes serão removidos."

Set-Location lab-devops

# Parar e remover containers
Write-Info "Parando containers..."
docker compose down -v 2>$null

Write-Success "Containers removidos"

# Limpar volumes órfãos (opcional)
Write-Info "Limpando volumes não utilizados..."
docker volume prune -f 2>$null

Write-Success "Volumes limpos"

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "✅ LAB DEVOPS DESTRUÍDO COM SUCESSO!" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Para recriar o lab, execute: " -ForegroundColor Blue -NoNewline
Write-Host ".\subir_lab.ps1" -ForegroundColor White
Write-Host ""
