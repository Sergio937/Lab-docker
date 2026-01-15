#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo ""
echo -e "${RED}💥 DESTRUINDO LAB DEVOPS...${NC}"
echo ""

# ---------------------------
# Desmontando Swarm
# ---------------------------
log_info "Desmontando cluster Swarm..."
docker exec lab-swarm2 docker swarm leave --force 2>/dev/null && log_success "Worker desconectado" || log_warning "Worker já estava desconectado"
docker exec lab-swarm1 docker swarm leave --force 2>/dev/null && log_success "Manager desconectado" || log_warning "Manager já estava desconectado"

# ---------------------------
# Removendo volumes
# ---------------------------
log_info "Removendo volumes do Swarm..."
docker exec lab-swarm1 docker volume rm traefik_traefik_data 2>/dev/null && log_success "Volume traefik removido" || true
docker exec lab-swarm1 docker volume rm portainer_portainer_data 2>/dev/null && log_success "Volume portainer removido" || true
docker exec lab-swarm1 docker volume rm jenkins_jenkins_data 2>/dev/null && log_success "Volume jenkins removido" || true

# Remover todos os volumes órfãos do Swarm
log_info "Removendo volumes órfãos do Swarm..."
docker exec lab-swarm1 docker volume prune -f 2>/dev/null || true

# ---------------------------
# Parando e removendo containers
# ---------------------------
log_info "Parando e removendo containers do lab..."
cd lab-devops 2>/dev/null || cd "$(dirname "$0")/lab-devops" 2>/dev/null || true

if [ -f "docker-compose.yaml" ]; then
    docker compose down 2>/dev/null && log_success "Containers removidos" || log_warning "Erro ao remover containers"
else
    log_warning "docker-compose.yaml não encontrado, removendo containers manualmente..."
    docker stop lab-haproxy lab-swarm1 lab-swarm2 2>/dev/null || true
    docker rm -f lab-haproxy lab-swarm1 lab-swarm2 2>/dev/null || true
fi

cd ..

# ---------------------------
# Limpeza de recursos órfãos
# ---------------------------
log_info "Limpando recursos órfãos do Docker..."
docker volume prune -f 2>/dev/null && log_success "Volumes órfãos removidos" || true
docker network prune -f 2>/dev/null && log_success "Redes órfãs removidas" || true
docker container prune -f 2>/dev/null && log_success "Containers órfãos removidos" || true

# ---------------------------
# Final
# ---------------------------
echo ""
echo -e "${GREEN}=============================================="
echo "✅ LAB DEVOPS LIMPO COM SUCESSO!"
echo -e "==============================================${NC}"
echo ""
echo -e "${BLUE}Recursos removidos:${NC}"
echo "  ✓ Stacks do Swarm (Traefik, Portainer, Jenkins)"
echo "  ✓ Cluster Swarm desmontado"
echo "  ✓ Containers (haproxy, swarm1, swarm2)"
echo "  ✓ Volumes e redes"
echo ""
echo -e "${GREEN}Arquivos de configuração preservados:${NC}"
echo "  • lab-devops/"
echo "  • stacks/"
echo ""
echo -e "${YELLOW}Para recriar o lab, execute:${NC}"
echo "  bash subir_lab.sh"
echo ""
echo -e "${GREEN}==============================================${NC}"
