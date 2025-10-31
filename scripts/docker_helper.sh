#!/bin/bash

# VarCAD-Lirical: Docker Build and Run Helper Script
# This script helps build and run the VarCAD-Lirical Docker container

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_NAME="varcad-lirical"
IMAGE_TAG="latest"
CONTAINER_NAME="varcad-lirical-container"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to display usage
show_usage() {
    cat << EOF
VarCAD-Lirical Docker Helper

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    build         Build the Docker image
    run           Run the Docker container
    exec          Execute a command in running container
    stop          Stop the running container
    remove        Remove the container
    clean         Clean up containers and images
    logs          Show container logs
    status        Show container status

Options:
    --tag TAG     Docker image tag (default: latest)
    --name NAME   Container name (default: varcad-lirical-container)

Examples:
    $0 build
    $0 run phenopacket -i patient1.json -o analysis1
    $0 exec bash
    $0 logs
    $0 clean

EOF
}

# Function to build Docker image
build_image() {
    log_info "Building Docker image: $IMAGE_NAME:$IMAGE_TAG"
    
    # Check if Dockerfile exists
    if [[ ! -f "$APP_DIR/Dockerfile" ]]; then
        log_error "Dockerfile not found at: $APP_DIR/Dockerfile"
        exit 1
    fi
    
    # Build the image
    cd "$APP_DIR"
    if docker build -t "$IMAGE_NAME:$IMAGE_TAG" .; then
        log_success "Docker image built successfully: $IMAGE_NAME:$IMAGE_TAG"
    else
        log_error "Failed to build Docker image"
        exit 1
    fi
}

# Function to run Docker container
run_container() {
    local args=("$@")
    
    log_info "Running Docker container: $CONTAINER_NAME"
    
    # Check if image exists
    if ! docker image inspect "$IMAGE_NAME:$IMAGE_TAG" &>/dev/null; then
        log_warn "Image $IMAGE_NAME:$IMAGE_TAG not found. Building..."
        build_image
    fi
    
    # Stop existing container if running
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        log_info "Stopping existing container..."
        docker stop "$CONTAINER_NAME" &>/dev/null || true
    fi
    
    # Remove existing container if exists
    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        log_info "Removing existing container..."
        docker rm "$CONTAINER_NAME" &>/dev/null || true
    fi
    
    # Prepare volume mounts
    local inputs_dir="$APP_DIR/examples/inputs"
    local outputs_dir="$APP_DIR/examples/outputs"
    
    # Create directories if they don't exist
    mkdir -p "$inputs_dir" "$outputs_dir"
    
    # Run the container
    local docker_cmd=(
        docker run
        --name "$CONTAINER_NAME"
        --rm
        -v "$inputs_dir:/app/examples/inputs"
        -v "$outputs_dir:/app/examples/outputs"
        "$IMAGE_NAME:$IMAGE_TAG"
        java -jar /opt/lirical/lirical-cli-2.2.0.jar
    )
    
    # Add user arguments
    if [[ ${#args[@]} -gt 0 ]]; then
        docker_cmd+=("${args[@]}")
    fi
    
    log_info "Command: ${docker_cmd[*]}"
    
    if "${docker_cmd[@]}"; then
        log_success "Container execution completed"
    else
        log_error "Container execution failed"
        exit 1
    fi
}

# Function to execute command in running container
exec_container() {
    local args=("$@")
    
    if [[ ${#args[@]} -eq 0 ]]; then
        args=("bash")
    fi
    
    log_info "Executing in container: ${args[*]}"
    
    if ! docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        log_error "Container $CONTAINER_NAME is not running"
        exit 1
    fi
    
    docker exec -it "$CONTAINER_NAME" "${args[@]}"
}

# Function to stop container
stop_container() {
    log_info "Stopping container: $CONTAINER_NAME"
    
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        docker stop "$CONTAINER_NAME"
        log_success "Container stopped"
    else
        log_warn "Container $CONTAINER_NAME is not running"
    fi
}

# Function to remove container
remove_container() {
    log_info "Removing container: $CONTAINER_NAME"
    
    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        docker rm -f "$CONTAINER_NAME"
        log_success "Container removed"
    else
        log_warn "Container $CONTAINER_NAME does not exist"
    fi
}

# Function to clean up
clean_up() {
    log_info "Cleaning up containers and images..."
    
    # Stop and remove container
    remove_container
    
    # Remove image
    if docker image inspect "$IMAGE_NAME:$IMAGE_TAG" &>/dev/null; then
        log_info "Removing image: $IMAGE_NAME:$IMAGE_TAG"
        docker rmi "$IMAGE_NAME:$IMAGE_TAG"
        log_success "Image removed"
    fi
    
    # Prune unused Docker resources
    log_info "Pruning unused Docker resources..."
    docker system prune -f
    
    log_success "Cleanup completed"
}

# Function to show logs
show_logs() {
    log_info "Showing logs for container: $CONTAINER_NAME"
    
    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        docker logs "$CONTAINER_NAME"
    else
        log_warn "Container $CONTAINER_NAME does not exist"
    fi
}

# Function to show status
show_status() {
    log_info "Container Status:"
    
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        echo -e "${GREEN}RUNNING${NC}"
        docker ps -f name="$CONTAINER_NAME"
    elif docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        echo -e "${YELLOW}STOPPED${NC}"
        docker ps -a -f name="$CONTAINER_NAME"
    else
        echo -e "${RED}NOT FOUND${NC}"
    fi
    
    log_info "Image Status:"
    if docker image inspect "$IMAGE_NAME:$IMAGE_TAG" &>/dev/null; then
        echo -e "${GREEN}EXISTS${NC}"
        docker images "$IMAGE_NAME"
    else
        echo -e "${RED}NOT FOUND${NC}"
    fi
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi
    
    local command="$1"
    shift
    
    # Parse global options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tag)
                IMAGE_TAG="$2"
                shift 2
                ;;
            --name)
                CONTAINER_NAME="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done
    
    case "$command" in
        "build")
            build_image
            ;;
        "run")
            run_container "$@"
            ;;
        "exec")
            exec_container "$@"
            ;;
        "stop")
            stop_container
            ;;
        "remove")
            remove_container
            ;;
        "clean")
            clean_up
            ;;
        "logs")
            show_logs
            ;;
        "status")
            show_status
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"