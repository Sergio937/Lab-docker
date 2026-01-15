# Script PowerShell para subir o Lab DevOps
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

# Verificar dependências
Write-Info "Verificando dependências..."
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "Docker não encontrado. Por favor, instale o Docker primeiro."
    exit 1
}

if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "Docker Compose não encontrado. Por favor, instale o Docker Compose primeiro."
    exit 1
}

# Verificando estrutura do lab
Write-Info "Verificando estrutura do lab-devops..."

if (-not (Test-Path "lab-devops")) {
    Write-ErrorMsg "Diretório lab-devops não encontrado!"
    exit 1
}

if (-not (Test-Path "stacks")) {
    Write-ErrorMsg "Diretório stacks não encontrado!"
    exit 1
}

Set-Location lab-devops

if (-not (Test-Path "docker-compose.yaml")) {
    Write-ErrorMsg "Arquivo docker-compose.yaml não encontrado em lab-devops/"
    exit 1
}

if (-not (Test-Path "haproxy/haproxy.cfg")) {
    Write-ErrorMsg "Arquivo haproxy/haproxy.cfg não encontrado!"
    exit 1
}

if (-not (Test-Path "../stacks/traefik-stack.yaml")) {
    Write-ErrorMsg "Arquivo stacks/traefik-stack.yaml não encontrado!"
    exit 1
}

if (-not (Test-Path "../stacks/portainer-stack.yaml")) {
    Write-ErrorMsg "Arquivo stacks/portainer-stack.yaml não encontrado!"
    exit 1
}

Write-Success "Arquivos de configuração encontrados"

# Subindo infraestrutura
Write-Info "Subindo containers base..."
docker compose up -d

Write-Info "Aguardando Docker daemon no swarm1..."
$timeout = 60
$elapsed = 0
while ($true) {
    try {
        docker exec lab-swarm1 docker info | Out-Null
        break
    } catch {
        if ($elapsed -ge $timeout) {
            Write-ErrorMsg "Timeout aguardando swarm1"
            exit 1
        }
        Start-Sleep -Seconds 2
        $elapsed += 2
    }
}
Write-Success "Swarm1 está pronto"

Write-Info "Aguardando Docker daemon no swarm2..."
$elapsed = 0
while ($true) {
    try {
        docker exec lab-swarm2 docker info | Out-Null
        break
    } catch {
        if ($elapsed -ge $timeout) {
            Write-ErrorMsg "Timeout aguardando swarm2"
            exit 1
        }
        Start-Sleep -Seconds 2
        $elapsed += 2
    }
}
Write-Success "Swarm2 está pronto"

# Inicializando Swarm
Write-Info "Inicializando Swarm no swarm1..."
docker exec lab-swarm1 docker swarm init --advertise-addr 172.31.0.11 2>$null

$elapsed = 0
while ($true) {
    $swarmStatus = docker exec lab-swarm1 docker info | Select-String "Swarm: active"
    if ($swarmStatus) {
        break
    }
    if ($elapsed -ge $timeout) {
        Write-ErrorMsg "Timeout inicializando swarm"
        exit 1
    }
    Start-Sleep -Seconds 2
    $elapsed += 2
}
Write-Success "Swarm inicializado"

Write-Info "Conectando worker (swarm2)..."
$workerToken = docker exec lab-swarm1 docker swarm join-token -q worker
docker exec lab-swarm2 docker swarm join --token $workerToken 172.31.0.11:2377 2>$null
Write-Success "Worker conectado"

# Rede pública Traefik
Write-Info "Criando rede traefik-public..."
docker exec lab-swarm1 docker network create --driver overlay traefik-public 2>$null
Write-Success "Rede traefik-public criada"

# Subindo Traefik
Write-Info "Fazendo deploy do Traefik stack..."
$result = docker exec lab-swarm1 docker stack deploy -c /stacks/traefik-stack.yaml traefik
if ($LASTEXITCODE -eq 0) {
    Write-Success "Stack Traefik deployado"
} else {
    Write-ErrorMsg "Erro ao deployar stack Traefik"
    exit 1
}

Start-Sleep -Seconds 5

# Deploy Portainer
Write-Info "Fazendo deploy do Portainer stack..."
$result = docker exec lab-swarm1 docker stack deploy -c /stacks/portainer-stack.yaml portainer
if ($LASTEXITCODE -eq 0) {
    Write-Success "Stack Portainer deployado"
} else {
    Write-ErrorMsg "Erro ao deployar stack Portainer"
    exit 1
}

Write-Success "Portainer iniciado"

# Deploy Jenkins
Write-Info "Fazendo deploy do Jenkins stack..."
$result = docker exec lab-swarm1 docker stack deploy -c /stacks/jenkins-stack.yaml jenkins
if ($LASTEXITCODE -eq 0) {
    Write-Success "Stack Jenkins deployado"
} else {
    Write-ErrorMsg "Erro ao deployar stack Jenkins"
    exit 1
}

Write-Success "Jenkins iniciado"

# Deploy SonarQube
Write-Info "Fazendo deploy do SonarQube stack..."
$result = docker exec lab-swarm1 docker stack deploy -c /stacks/sonarqube-stack.yaml sonarqube
if ($LASTEXITCODE -eq 0) {
    Write-Success "Stack SonarQube deployado"
} else {
    Write-ErrorMsg "Erro ao deployar stack SonarQube"
    exit 1
}

Write-Success "SonarQube iniciado"

# Deploy Trivy
Write-Info "Fazendo deploy do Trivy stack..."
$result = docker exec lab-swarm1 docker stack deploy -c /stacks/trivy-stack.yaml trivy
if ($LASTEXITCODE -eq 0) {
    Write-Success "Stack Trivy deployado"
} else {
    Write-ErrorMsg "Erro ao deployar stack Trivy"
    exit 1
}

Write-Success "Trivy iniciado"

# Final
Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "✅ LAB DEVOPS CRIADO COM SUCESSO!" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Traefik Dashboard: " -ForegroundColor Blue -NoNewline
Write-Host "http://localhost:8081"
Write-Host "🌐 Jenkins (Traefik): " -ForegroundColor Blue -NoNewline
Write-Host "http://localhost:8080/jenkins"
Write-Host "🌐 Jenkins (HAProxy): " -ForegroundColor Blue -NoNewline
Write-Host "http://localhost:8082"
Write-Host "🌐 Stack Manager:     " -ForegroundColor Blue -NoNewline
Write-Host "http://localhost:5000"
Write-Host ""
Write-Host "💡 Acesso via Traefik na porta 8080 do HAProxy"
Write-Host ""
Write-Host "📋 Comandos úteis:" -ForegroundColor Blue
Write-Host "  • Ver logs:        docker compose logs -f"
Write-Host "  • Parar lab:       docker compose down"
Write-Host "  • Status swarm:    docker exec lab-swarm1 docker node ls"
Write-Host "  • Lista stacks:    docker exec lab-swarm1 docker stack ls"
Write-Host "  • Lista services:  docker exec lab-swarm1 docker service ls"
Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
