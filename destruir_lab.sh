#!/bin/bash
set -e

# ===============================
# CORES E LOG
# ===============================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}ℹ ${NC}$1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error()   { echo -e "${RED}✗${NC} $1"; }

# ===============================
# VERIFICA SE LAB EXISTE
# ===============================
if ! docker ps -a | grep -q lab-swarm1; then
    log_warning "Lab não está em execução. Nada para destruir."
    exit 0
fi

# ===============================
# REMOVER STACKS
# ===============================
log_info "Removendo stacks do Swarm..."

STACKS=(traefik portainer jenkins sonarqube trivy)

for stack in "${STACKS[@]}"; do
    docker exec lab-swarm1 docker stack rm $stack 2>/dev/null || true
done

log_success "Stacks removidas"

# ===============================
# AGUARDAR REMOÇÃO DE SERVIÇOS
# ===============================
log_info "Aguardando limpeza de serviços..."
sleep 10

# ===============================
# SAIR DO SWARM
# ===============================
log_info "Removendo nodes do Swarm..."

docker exec lab-swarm2 docker swarm leave --force 2>/dev/null || true
docker exec lab-swarm1 docker swarm leave --force 2>/dev/null || true

log_success "Swarm removido"

# ===============================
# REMOVER REDES OVERLAY
# ===============================
log_info "Removendo redes overlay..."

docker exec lab-swarm1 docker network rm traefik-public 2>/dev/null || true
docker exec lab-swarm1 docker network rm devops-network 2>/dev/null || true

log_success "Redes removidas"

# ===============================
# DERRUBAR DOCKER COMPOSE BASE
# ===============================
log_info "Parando infraestrutura base..."

cd lab-devops
docker compose down -v

log_success "Infraestrutura base removida"

# ===============================
# LIMPEZA FINAL
# ===============================
log_success "LAB DEVOPS TOTALMENTE DESTRUÍDO 🧹"

echo ""
echo -e "${GREEN}=============================================="
echo "🔥 LAB REMOVIDO COM SUCESSO!"
echo -e "==============================================${NC}"
echo ""
