#!/bin/bash

# PAWS360 CI/CD Build Script
# This script handles the build process for the CI/CD pipeline

set -e

echo "🚀 Starting PAWS360 CI/CD Build Process"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if we're in the right directory
if [ ! -f "pom.xml" ]; then
    print_error "pom.xml not found. Please run this script from the project root."
    exit 1
fi

print_status "Setting up build environment..."

# Set Maven options for CI
export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=256m"

# Clean previous builds
print_status "Cleaning previous builds..."
mvn clean

# Download dependencies
print_status "Downloading dependencies..."
mvn dependency:go-offline -B -q

# Run tests
print_status "Running tests..."
if mvn test -B; then
    print_status "✅ All tests passed!"
else
    print_error "❌ Tests failed!"
    exit 1
fi

# Build the application
print_status "Building application..."
if mvn package -DskipTests -B -q; then
    print_status "✅ Build successful!"
else
    print_error "❌ Build failed!"
    exit 1
fi

# Check if JAR files were created
if [ -f "target/*.jar" ]; then
    print_status "✅ JAR files created successfully"
    ls -la target/*.jar
else
    print_error "❌ No JAR files found in target directory"
    exit 1
fi

print_status "🎉 CI/CD Build completed successfully!"