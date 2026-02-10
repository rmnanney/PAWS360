#!/bin/bash
# PAWS360 Environment Configuration Validator
# Validates .env files and checks for required variables

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENV_FILE=".env"
REQUIRED_VARS=(
    "APP_ENV"
    "DB_HOST"
    "DB_NAME"
    "DB_USERNAME"
    "DB_PASSWORD"
    "JIRA_URL"
    "JIRA_PROJECT_KEY"
    "JIRA_EMAIL"
    "JIRA_API_KEY"
)

OPTIONAL_VARS=(
    "APP_DEBUG"
    "DB_PORT"
    "JWT_SECRET"
    "SAML_ENTITY_ID"
    "SMTP_HOST"
)

print_header() {
    echo -e "${BLUE}🔍 PAWS360 Environment Configuration Validator${NC}"
    echo "=================================================="
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_file_exists() {
    if [ ! -f "$ENV_FILE" ]; then
        print_error ".env file not found at $ENV_FILE"
        echo ""
        echo "Available templates:"
        ls -la .env.example* 2>/dev/null || echo "No templates found"
        echo ""
        echo "To create from template:"
        echo "  cp .env.example.local .env  # For local development"
        echo "  cp .env.example.dev .env    # For development server"
        echo "  cp .env.example.prod .env   # For production"
        exit 1
    fi
}

validate_required_vars() {
    echo ""
    echo "📋 Checking required variables..."

    local missing_vars=()
    local found_vars=()

    for var in "${REQUIRED_VARS[@]}"; do
        if grep -q "^${var}=" "$ENV_FILE" 2>/dev/null; then
            found_vars+=("$var")
        else
            missing_vars+=("$var")
        fi
    done

    # Show found variables
    for var in "${found_vars[@]}"; do
        print_success "Found: $var"
    done

    # Show missing variables
    for var in "${missing_vars[@]}"; do
        print_error "Missing: $var"
    done

    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo ""
        print_error "CRITICAL: ${#missing_vars[@]} required variables are missing!"
        return 1
    else
        print_success "All required variables present"
        return 0
    fi
}

validate_optional_vars() {
    echo ""
    echo "🔧 Checking optional variables..."

    local found_optional=()

    for var in "${OPTIONAL_VARS[@]}"; do
        if grep -q "^${var}=" "$ENV_FILE" 2>/dev/null; then
            found_optional+=("$var")
        fi
    done

    if [ ${#found_optional[@]} -gt 0 ]; then
        for var in "${found_optional[@]}"; do
            print_success "Found: $var"
        done
    else
        print_warning "No optional variables found"
    fi
}

check_security() {
    echo ""
    echo "🔒 Security checks..."

    # Check for default/weak passwords
    if grep -q "password.*123\|PASSWORD.*HERE\|your.*password" "$ENV_FILE" 2>/dev/null; then
        print_warning "Potential weak passwords detected - please update with strong passwords"
    else
        print_success "No obvious weak passwords found"
    fi

    # Check file permissions
    if [ -f "$ENV_FILE" ]; then
        perms=$(stat -c "%a" "$ENV_FILE" 2>/dev/null || stat -f "%A" "$ENV_FILE" 2>/dev/null)
        if [ "$perms" != "600" ]; then
            print_warning ".env file permissions are $perms (recommended: 600)"
        else
            print_success ".env file has correct permissions (600)"
        fi
    fi
}

check_environment_consistency() {
    echo ""
    echo "🌍 Environment consistency checks..."

    # Get APP_ENV value
    app_env=$(grep "^APP_ENV=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 || echo "")

    case $app_env in
        "development"|"dev")
            print_success "Environment: Development"
            # Check for development-specific settings
            if grep -q "APP_DEBUG=true" "$ENV_FILE" 2>/dev/null; then
                print_success "Debug mode enabled (appropriate for development)"
            fi
            ;;
        "production"|"prod")
            print_success "Environment: Production"
            # Check for production-specific security
            if grep -q "APP_DEBUG=false" "$ENV_FILE" 2>/dev/null; then
                print_success "Debug mode disabled (appropriate for production)"
            else
                print_warning "Debug mode should be disabled in production"
            fi
            ;;
        "staging"|"test")
            print_success "Environment: $app_env"
            ;;
        *)
            print_warning "Unknown APP_ENV value: $app_env"
            ;;
    esac
}

show_summary() {
    echo ""
    echo "📊 Summary"
    echo "=========="

    local total_vars=$(grep -c "^[A-Z_][A-Z0-9_]*=" "$ENV_FILE" 2>/dev/null || echo "0")
    local required_count=${#REQUIRED_VARS[@]}
    local optional_count=${#OPTIONAL_VARS[@]}

    echo "Total variables defined: $total_vars"
    echo "Required variables: $required_count"
    echo "Optional variables: $optional_count"

    if [ $total_vars -ge $required_count ]; then
        print_success "Configuration appears complete"
    else
        print_warning "Configuration may be incomplete"
    fi
}

show_help() {
    echo ""
    echo "💡 Usage:"
    echo "  $0                    # Validate default .env file"
    echo "  $0 /path/to/.env      # Validate specific file"
    echo ""
    echo "📚 For help with configuration:"
    echo "  cat docs/guides/environment-configuration-guide.md"
}

main() {
    print_header

    # Check if custom file specified
    if [ $# -gt 0 ]; then
        ENV_FILE="$1"
        echo "Validating: $ENV_FILE"
    else
        echo "Validating: $ENV_FILE (default)"
    fi

    check_file_exists

    local validation_passed=true

    if validate_required_vars; then
        echo ""
        print_success "Required variables validation: PASSED"
    else
        validation_passed=false
    fi

    validate_optional_vars
    check_security
    check_environment_consistency
    show_summary

    echo ""
    if [ "$validation_passed" = true ]; then
        print_success "🎉 Environment configuration validation: PASSED"
        echo ""
        echo "🚀 Your .env file is ready for use!"
        exit 0
    else
        print_error "❌ Environment configuration validation: FAILED"
        echo ""
        echo "🔧 Please fix the issues above and re-run validation"
        show_help
        exit 1
    fi
}

# Run main function
main "$@"