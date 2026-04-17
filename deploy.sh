#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored output
print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

print_info() {
  echo -e "${YELLOW}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
  print_info "Checking prerequisites..."

  if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
  fi
  print_success "Docker is installed"

  if ! command -v docker-compose &> /dev/null; then
    print_error "docker-compose is not installed. Please install docker-compose first."
    exit 1
  fi
  print_success "docker-compose is installed"
}

# Setup environment file
setup_env() {
  print_info "Setting up environment..."

  if [ ! -f "$SCRIPT_DIR/.env" ]; then
    print_info "Creating .env file from .env.example..."
    cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
    print_success ".env file created"
    print_error "Please edit .env file with your configuration and run the script again."
    exit 1
  else
    print_success ".env file already exists"
  fi
}

# Build and start services
start_services() {
  print_info "Building and starting services..."

  cd "$SCRIPT_DIR"
  
  if docker-compose up --build -d; then
    print_success "Services started successfully"
  else
    print_error "Failed to start services"
    exit 1
  fi
}

# Wait for PostgreSQL to be ready
wait_for_postgres() {
  print_info "Waiting for PostgreSQL to be ready (max 30 seconds)..."

  local max_attempts=30
  local attempt=0

  while [ $attempt -lt $max_attempts ]; do
    if docker-compose exec -T postgres pg_isready -U ${DB_USER:-aeuser} > /dev/null 2>&1; then
      print_success "PostgreSQL is ready"
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 1
  done

  print_error "PostgreSQL did not become ready in time"
  exit 1
}

# Run migrations
run_migrations() {
  print_info "Running database migrations..."

  if docker-compose exec -T backend node -e "require('./config/database').runMigrations()" > /dev/null 2>&1; then
    print_success "Migrations completed"
  else
    print_error "Migration failed. This is expected if runMigrations is not implemented yet."
    print_info "Skipping migrations..."
  fi
}

# Run seed data
run_seed() {
  print_info "Running database seed..."

  if docker-compose exec -T backend node -e "require('./config/database').runSeed()" > /dev/null 2>&1; then
    print_success "Seed data loaded"
  else
    print_error "Seed data loading failed. This is expected if runSeed is not implemented yet."
    print_info "Skipping seed data..."
  fi
}

# Print success message
print_success_message() {
  echo ""
  print_success "ActivEducation deployment completed!"
  echo ""
  echo -e "${GREEN}Services are running:${NC}"
  echo "  Frontend:  http://localhost"
  echo "  API:       http://localhost/api/v1"
  echo "  Health:    http://localhost/api/v1/health"
  echo ""
  echo -e "${GREEN}Docker services:${NC}"
  echo "  Backend:   activeducation-backend (port 3001)"
  echo "  Frontend:  activeducation-frontend (port 80)"
  echo "  Database:  activeducation-postgres (port 5432)"
  echo "  Cache:     activeducation-redis (port 6379)"
  echo ""
  echo -e "${YELLOW}Useful commands:${NC}"
  echo "  docker-compose logs -f backend     # View backend logs"
  echo "  docker-compose logs -f frontend    # View frontend logs"
  echo "  docker-compose ps                  # View running services"
  echo "  docker-compose down                # Stop all services"
  echo ""
}

# Main execution
main() {
  echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║   ActivEducation Deployment Script     ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
  echo ""

  check_prerequisites
  setup_env
  start_services
  wait_for_postgres
  run_migrations
  run_seed
  print_success_message
}

# Run main function
main
