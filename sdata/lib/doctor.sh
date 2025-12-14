# Doctor command for ii-niri
# Diagnoses and fixes common issues
# This script is meant to be sourced.

# shellcheck shell=bash

#####################################################################################
# Doctor Checks
#####################################################################################

doctor_check_passed=0
doctor_check_failed=0
doctor_check_warned=0

doctor_pass() {
    echo -e "${STY_GREEN}✓${STY_RST} $1"
    ((doctor_check_passed++)) || true
}

doctor_fail() {
    echo -e "${STY_RED}✗${STY_RST} $1"
    ((doctor_check_failed++)) || true
}

doctor_warn() {
    echo -e "${STY_YELLOW}!${STY_RST} $1"
    ((doctor_check_warned++)) || true
}

doctor_info() {
    echo -e "${STY_BLUE}ℹ${STY_RST} $1"
}

#####################################################################################
# Individual Checks
#####################################################################################

check_critical_files() {
    local target="${XDG_CONFIG_HOME}/quickshell/ii"
    local critical=(
        "shell.qml"
        "GlobalStates.qml"
        "modules/common/Config.qml"
        "modules/common/Appearance.qml"
        "modules/common/Directories.qml"
        "services/NiriService.qml"
        "services/Audio.qml"
        "services/Network.qml"
    )
    
    local missing=0
    for file in "${critical[@]}"; do
        if [[ ! -f "$target/$file" ]]; then
            doctor_fail "Missing critical file: $file"
            ((missing++)) || true
        fi
    done
    
    if [[ $missing -eq 0 ]]; then
        doctor_pass "All critical files present"
    fi
    
    return $missing
}

check_script_permissions() {
    local target="${XDG_CONFIG_HOME}/quickshell/ii/scripts"
    local fixed=0
    
    if [[ ! -d "$target" ]]; then
        doctor_warn "Scripts directory not found"
        return 0
    fi
    
    while IFS= read -r -d '' script; do
        if [[ ! -x "$script" ]]; then
            chmod +x "$script"
            ((fixed++)) || true
        fi
    done < <(find "$target" \( -name "*.sh" -o -name "*.fish" -o -name "*.py" \) -print0 2>/dev/null)
    
    if [[ $fixed -gt 0 ]]; then
        doctor_warn "Fixed permissions on $fixed script(s)"
    else
        doctor_pass "Script permissions OK"
    fi
    
    return 0
}

check_user_config() {
    local config_file="${XDG_CONFIG_HOME}/illogical-impulse/config.json"
    
    if [[ ! -f "$config_file" ]]; then
        doctor_warn "User config not found (will use defaults)"
        return 0
    fi
    
    # Validate JSON
    if command -v jq &>/dev/null; then
        if ! jq empty "$config_file" 2>/dev/null; then
            doctor_fail "User config is invalid JSON: $config_file"
            return 1
        fi
        doctor_pass "User config is valid JSON"
    else
        doctor_warn "jq not installed, cannot validate config JSON"
    fi
    
    return 0
}

check_orphan_files() {
    local target="${XDG_CONFIG_HOME}/quickshell/ii"
    local manifest="$target/.ii-manifest"
    
    if [[ ! -f "$manifest" ]]; then
        doctor_warn "No manifest file (run update to create)"
        return 0
    fi
    
    local orphans
    orphans=$(get_orphan_files "$target" "$manifest" 2>/dev/null | wc -l)
    
    if [[ $orphans -gt 0 ]]; then
        doctor_warn "$orphans orphan file(s) found (run update to clean)"
    else
        doctor_pass "No orphan files"
    fi
    
    return 0
}

check_dependencies() {
    local required_cmds=(
        "qs:quickshell"
        "niri:niri"
        "nmcli:NetworkManager"
        "wpctl:wireplumber"
        "jq:jq"
    )
    
    local missing=0
    for item in "${required_cmds[@]}"; do
        local cmd="${item%%:*}"
        local pkg="${item##*:}"
        
        if ! command -v "$cmd" &>/dev/null; then
            doctor_fail "Missing command: $cmd (install $pkg)"
            ((missing++))
        fi
    done
    
    if [[ $missing -eq 0 ]]; then
        doctor_pass "All required commands available"
    fi
    
    return $missing
}

check_quickshell_loads() {
    doctor_info "Testing quickshell startup..."
    
    # Kill existing (suppress output)
    qs kill -c ii &>/dev/null || true
    sleep 0.3
    
    # Try to start with short timeout
    local output
    output=$(timeout 5 qs -c ii 2>&1) || true
    
    # Check for fatal errors (ignore common warnings)
    if echo "$output" | grep -E "^[[:space:]]*(ERROR|error:)" | grep -vE "(polkit|bluez|Hyprland)" | head -1 | grep -q .; then
        doctor_fail "Quickshell has errors on startup"
        echo "$output" | grep -E "(ERROR|error:)" | grep -vE "(polkit|bluez|Hyprland)" | head -3 | while read -r line; do
            echo "    $line"
        done
        return 1
    fi
    
    # If we got here without fatal errors, it's working
    doctor_pass "Quickshell loads successfully"
    return 0
}

check_niri_running() {
    if [[ -n "$NIRI_SOCKET" ]] && [[ -S "$NIRI_SOCKET" ]]; then
        doctor_pass "Niri compositor running"
        return 0
    fi
    
    doctor_warn "Niri not detected (some features won't work)"
    return 0
}

check_state_directories() {
    local dirs=(
        "${XDG_STATE_HOME}/quickshell/user"
        "${XDG_CACHE_HOME}/quickshell"
        "${XDG_CONFIG_HOME}/illogical-impulse"
    )
    
    local created=0
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            ((created++)) || true
        fi
    done
    
    if [[ $created -gt 0 ]]; then
        doctor_warn "Created $created missing directory(ies)"
    else
        doctor_pass "State directories exist"
    fi
    
    return 0
}

check_python_packages() {
    local req_file="${XDG_CONFIG_HOME}/quickshell/ii/requirements.txt"
    
    if [[ ! -f "$req_file" ]]; then
        doctor_warn "requirements.txt not found"
        return 0
    fi
    
    if ! command -v pip &>/dev/null && ! command -v pip3 &>/dev/null; then
        doctor_warn "pip not installed, cannot check Python packages"
        return 0
    fi
    
    local pip_cmd="pip3"
    command -v pip3 &>/dev/null || pip_cmd="pip"
    
    local missing=0
    while IFS= read -r pkg || [[ -n "$pkg" ]]; do
        # Skip comments and empty lines
        [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
        
        # Extract package name (before any version specifier)
        local pkg_name="${pkg%%[<>=]*}"
        
        if ! $pip_cmd show "$pkg_name" &>/dev/null; then
            ((missing++)) || true
        fi
    done < "$req_file"
    
    if [[ $missing -gt 0 ]]; then
        doctor_warn "$missing Python package(s) missing (run: pip install -r requirements.txt)"
    else
        doctor_pass "Python packages installed"
    fi
    
    return 0
}

#####################################################################################
# Main Doctor Function
#####################################################################################

run_doctor() {
    local fix_mode="${1:-false}"
    
    echo ""
    echo -e "${STY_CYAN}${STY_BOLD}ii-niri Doctor${STY_RST}"
    echo -e "${STY_FAINT}Checking your installation...${STY_RST}"
    echo ""
    
    # Reset counters
    doctor_check_passed=0
    doctor_check_failed=0
    doctor_check_warned=0
    
    # Run all checks
    check_dependencies
    check_critical_files
    check_script_permissions
    check_user_config
    check_state_directories
    check_orphan_files
    check_niri_running
    check_python_packages
    check_quickshell_loads
    
    # Summary
    echo ""
    echo -e "${STY_BOLD}Summary:${STY_RST}"
    echo -e "  ${STY_GREEN}Passed:${STY_RST}  $doctor_check_passed"
    echo -e "  ${STY_YELLOW}Warnings:${STY_RST} $doctor_check_warned"
    echo -e "  ${STY_RED}Failed:${STY_RST}   $doctor_check_failed"
    echo ""
    
    if [[ $doctor_check_failed -gt 0 ]]; then
        echo -e "${STY_RED}Some checks failed. Run ${STY_CYAN}./setup install${STY_RED} to fix.${STY_RST}"
        return 1
    elif [[ $doctor_check_warned -gt 0 ]]; then
        echo -e "${STY_YELLOW}Some warnings. Run ${STY_CYAN}./setup update${STY_YELLOW} to fix most issues.${STY_RST}"
        return 0
    else
        echo -e "${STY_GREEN}${STY_BOLD}All checks passed! ✓${STY_RST}"
        return 0
    fi
}
