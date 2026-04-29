#!/bin/bash

# Flutter Expert Analysis Script
# Comprehensive local code analysis before pushing to remote

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔍 Flutter Expert Code Analysis"
echo "==============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ISSUES=0
WARNINGS=0

# Function to report status
report_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        ISSUES=$((ISSUES + 1))
    fi
}

warn_status() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

# 1. Flutter Analysis
echo "1️⃣  Running Flutter Analysis..."
if flutter analyze --no-fatal-infos --suppress-analytics > /tmp/flutter_analysis.txt 2>&1; then
    report_status 0 "Static analysis passed"
else
    report_status 1 "Static analysis found issues (see details below)"
    cat /tmp/flutter_analysis.txt | head -20
fi
echo ""

# 2. Dart Format Check
echo "2️⃣  Checking Code Format..."
if dart format --set-exit-if-changed --output=none lib/ test/ > /tmp/dart_format.txt 2>&1; then
    report_status 0 "Code formatting is correct"
else
    report_status 1 "Code formatting issues found"
    warn_status "Run: dart format lib/ test/"
    cat /tmp/dart_format.txt | head -10
fi
echo ""

# 3. Code Metrics
echo "3️⃣  Running Code Metrics (SOLID & Complexity)..."
if dcm analyze lib/ --reporter=console > /tmp/dcm_analysis.txt 2>&1; then
    report_status 0 "Code metrics analysis passed"
else
    # DCM exits with non-zero if issues found, but that's ok
    warn_status "Code metrics found suggestions (see details below)"
    cat /tmp/dcm_analysis.txt | head -30
fi
echo ""

# 4. Dependency Validation
echo "4️⃣  Validating Dependencies..."
if dependency_validator > /tmp/deps.txt 2>&1; then
    report_status 0 "Dependency validation passed"
else
    report_status 1 "Dependency validation failed"
    cat /tmp/deps.txt
fi
echo ""

# 5. SOLID Principles Check
echo "5️⃣  Checking SOLID Principles..."
SOLID_ISSUES=0

# Check file sizes (SRP)
echo "   📋 Single Responsibility Principle:"
LARGE_FILES=$(find lib -name "*.dart" -type f -exec wc -l {} \; | awk '$1 > 300 {print}' | wc -l)
if [ "$LARGE_FILES" -eq 0 ]; then
    echo "      ✅ No excessively large files"
else
    echo "      ⚠️  Found $LARGE_FILES files larger than 300 lines"
    find lib -name "*.dart" -type f -exec wc -l {} \; | awk '$1 > 300 {print $2 " (" $1 " lines)"}'
    SOLID_ISSUES=$((SOLID_ISSUES + 1))
fi

# Check for abstract classes (OCP)
echo "   📋 Open/Closed Principle:"
ABSTRACT_COUNT=$(grep -r "abstract class" lib/ --include="*.dart" 2>/dev/null | wc -l || echo "0")
if [ "$ABSTRACT_COUNT" -gt 0 ]; then
    echo "      ✅ Found $ABSTRACT_COUNT abstract classes for extension"
else
    echo "      ℹ️  Consider using abstract classes for extensibility"
fi

# Check for mixins (ISP)
echo "   📋 Interface Segregation Principle:"
MIXIN_COUNT=$(grep -r "mixin" lib/ --include="*.dart" 2>/dev/null | wc -l || echo "0")
if [ "$MIXIN_COUNT" -gt 0 ]; then
    echo "      ✅ Found $MIXIN_COUNT mixins for interface segregation"
else
    echo "      ℹ️  Consider using mixins for interface segregation"
fi

# Check for DI (DIP)
echo "   📋 Dependency Inversion Principle:"
DI_COUNT=$(grep -r "Riverpod\|Provider\|GetIt\|get_it" lib/ --include="*.dart" 2>/dev/null | wc -l || echo "0")
if [ "$DI_COUNT" -gt 0 ]; then
    echo "      ✅ Found dependency injection patterns"
else
    echo "      ⚠️  Consider using dependency injection patterns"
    SOLID_ISSUES=$((SOLID_ISSUES + 1))
fi

if [ "$SOLID_ISSUES" -eq 0 ]; then
    report_status 0 "SOLID principles check"
else
    warn_status "SOLID principles: $SOLID_ISSUES areas to improve"
fi
echo ""

# 6. Project Structure Check
echo "6️⃣  Checking Project Structure..."
STRUCTURE_OK=true

# Check for snake_case files
echo "   📋 File Naming Conventions:"
INVALID_NAMES=$(find lib -name "*.dart" | grep -E '[A-Z].*\.dart$' | wc -l || echo "0")
if [ "$INVALID_NAMES" -eq 0 ]; then
    echo "      ✅ All Dart files use snake_case naming"
else
    echo "      ⚠️  Found $INVALID_NAMES files not following snake_case"
    find lib -name "*.dart" | grep -E '[A-Z].*\.dart$' | head -5
    STRUCTURE_OK=false
fi

# Check directory structure
echo "   📋 Architecture Directories:"
DIRS_FOUND=0
for dir in models views providers services utils widgets; do
    if [ -d "lib/$dir" ]; then
        DIRS_FOUND=$((DIRS_FOUND + 1))
    fi
done
echo "      ℹ️  Found $DIRS_FOUND/6 expected architecture directories"

if [ "$STRUCTURE_OK" = true ]; then
    report_status 0 "Project structure check"
else
    warn_status "Project structure: Fix naming conventions"
fi
echo ""

# Summary
echo "==============================="
echo "📊 Analysis Summary"
echo "==============================="

if [ "$ISSUES" -eq 0 ]; then
    echo -e "${GREEN}✅ All critical checks passed!${NC}"
    if [ "$WARNINGS" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  $WARNINGS warnings to address${NC}"
    fi
    echo ""
    echo "Ready to commit and push! 🚀"
    exit 0
else
    echo -e "${RED}❌ Found $ISSUES critical issues to fix${NC}"
    echo ""
    echo "Please fix the issues above before pushing."
    exit 1
fi
