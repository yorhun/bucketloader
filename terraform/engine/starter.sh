#!/bin/sh

# Terraform Starter Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check if we're in the right directory
check_directory() {
    if [[ ! -f "main.tf" ]]; then
        print_error "Expected to find main.tf"
        exit 1
    fi
}

# Function to check for required files
check_required_files() {
    print_status "Checking required files..."
    
    # Check for .tfvars file
    if [[ ! -f "terraform.tfvars" ]]; then
        print_error "terraform.tfvars file not found!"
        print_error "Please create terraform.tfvars with your configuration"
        exit 1
    fi
    
    print_status "✅ Required files check passed"
}

# Function to initialize terraform if needed
init_terraform() {
    if [[ ! -d ".terraform" ]]; then
        print_status "Initializing Terraform..."
        terraform init
    else
        # Check if we need to upgrade providers
        print_status "Checking Terraform initialization..."
        if ! terraform init -upgrade -input=false > /dev/null 2>&1; then
            print_warning "Provider versions may need updating..."
            print_status "Upgrading Terraform providers..."
            terraform init -upgrade
        fi
    fi
}


# Function to apply test infrastructure
apply_test_infrastructure() {
    print_status "Applying infrastructure..."
    
    # Initialize if needed
    init_terraform
    
    if [[ -f "main.tf" ]]; then
        print_status "Creating and applying plan for main.tf..."
        terraform apply -auto-approve
        print_status "✅ Infrastructure deployed successfully"
    fi
    
}

# Function to show test outputs
show_test_outputs() {
    print_status "Showing test infrastructure outputs..."
    
    terraform output
    
    print_status "✅ Test outputs displayed"
}



# Function to show current configuration
show_config() {
    print_status "Current Terraform configuration:"
    echo ""
    
    if [[ -f "terraform.tfvars" ]]; then
        print_status "Variables from terraform.tfvars:"
        echo -e "${BLUE}$(cat terraform.tfvars)${NC}"
        echo ""
    fi
}

# Function to show help
show_help() {
    echo "Test Terraform Infrastructure Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  test     - Test Terraform configuration (default)"
    echo "  apply    - Apply test infrastructure"
    echo "  output   - Show test outputs"
    echo "  config   - Show current configuration"

    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 test"
    echo "  $0 apply"
    echo "  $0 output"
    echo "  $0 config"

    echo ""
    echo "Notes:"
    echo "  - Script automatically loads terraform.tfvars"
    echo "  - Ensure terraform.tfvars exists in the current directory"
    echo "  - Run from the terraform directory containing your .tf files"
}

# Main script logic
main() {
    case "${1:-test}" in
        test)
            print_header "Testing Terraform Configuration"
            check_directory
            check_required_files
            ;;
        apply)
            print_header "Applying Test Infrastructure"
            check_directory
            check_required_files
            apply_test_infrastructure
            ;;
        output)
            print_header "Showing Test Outputs"
            check_directory
            show_test_outputs
            ;;
        config)
            print_header "Current Configuration"
            check_directory
            show_config
            ;;

        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"