#!/bin/bash

#####################################################################
# zfs_pool_safety_analyzer.sh
#####################################################################
# Description:
#   Comprehensive ZFS pool analysis script designed to verify if a pool's
#   refquota can be safely removed or needs to be maintained.
#
# Purpose:
#   - Analyzes ZFS pool configuration for safety and performance
#   - Verifies RAIDZ2 configuration
#   - Checks disk size consistency
#   - Monitors pool health and performance metrics
#   - Provides recommendations for refquota management
#
# Usage:
#   ./zfs_pool_safety_analyzer.sh
#
# Requirements:
#   - Root privileges
#   - ZFS utilities installed
#   - Access to pool named 'data'
#
# Output:
#   - Pool configuration status
#   - Health check results
#   - Capacity analysis
#   - Performance metrics
#   - Disk configuration verification
#   - Specific recommendations for admins/support
#
# Note:
#   This script assumes the pool name is 'data'. For different pool names,
#   modify the script accordingly.
#
# Author: Robert Mašír
# Date: November 2024
# Version: 1.0
#####################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"
}

print_header "ZFS POOL DETAILED ANALYSIS"

# 1. Show Pool Configuration
echo -e "${BOLD}Full Pool Configuration:${NC}"
zpool status data
echo -e "\n${YELLOW}↑ Please review the above configuration manually for any warnings or errors${NC}"

# 2. Pool Health Check
print_header "Pool Health Check"
# Check last scrub time and status
scrub_info=$(zpool status data | grep -A1 "scan:" | tail -n2)
echo -e "${BOLD}Last Scrub:${NC}"
echo "$scrub_info"

# Check for any errors
errors=$(zpool status data | grep "errors:" | awk '{print $2" "$3}')
if [ "$errors" = "No known" ]; then
    echo -e "${GREEN}✓ No errors detected${NC}"
else
    echo -e "${RED}⚠ Errors found: $errors${NC}"
fi

# 3. Pool Capacity Check
print_header "Pool Capacity Check"
capacity=$(zpool list data -H -o capacity)
allocated=$(zpool list data -H -o allocated)
free=$(zpool list data -H -o free)

echo "Current capacity: $capacity"
echo "Space allocated: $allocated"
echo "Space free: $free"

if [[ ${capacity%\%} -gt 80 ]]; then
    echo -e "${YELLOW}⚠ Warning: Pool usage is above 80%${NC}"
fi

# 4. Performance Status
print_header "Performance Status"
echo -e "${BOLD}Read/Write/Checksum Errors:${NC}"
zpool status data | grep -E "READ|WRITE|CKSUM" | grep -v "0     0     0" || echo -e "${GREEN}✓ No disk errors detected${NC}"

# Add fragmentation check
frag=$(zpool list data -H -o frag)
echo -e "\n${BOLD}Pool Fragmentation:${NC} $frag"
if [[ ${frag%\%} -gt 50 ]]; then
    echo -e "${YELLOW}⚠ High fragmentation detected${NC}"
fi

# 5. RAIDZ2 Check
print_header "RAIDZ2 Configuration Verification"
pool_config=$(zpool status data)
raidz2_check=$(echo "$pool_config" | grep -E "raidz2|RAIDZ2")

if [ -z "$raidz2_check" ]; then
    echo -e "${RED}ERROR: RAIDZ2 not detected${NC}"
    echo -e "Current configuration:\n$(zpool status data | grep -A1 "config:" | tail -n +2)"
else
    echo -e "${GREEN}✓ RAIDZ2 configuration detected${NC}"
    echo -e "Configuration line: $raidz2_check"
fi

# 6. Enhanced Disk Size Check
print_header "Disk Size Analysis"

# Get disks using improved pattern matching
disks=($(zpool status data | grep -E '^\s+sd[a-z]' | awk '{print $1}'))
echo -e "Number of disks detected: ${#disks[@]}"

if [ ${#disks[@]} -eq 0 ]; then
    echo -e "${RED}ERROR: No disks found${NC}"
    echo "Details: Failed to detect disks in the pool"
    exit 1
fi

# Create arrays for disk details
declare -a disk_sizes
declare -a disk_models
declare -a disk_names

echo -e "\n${BOLD}Individual Disk Details:${NC}"
for disk in "${disks[@]}"; do
    # Get size in bytes
    size=$(lsblk -b -d -n -o SIZE "/dev/$disk" 2>/dev/null)
    # Get disk model
    model=$(lsblk -d -n -o MODEL "/dev/$disk" 2>/dev/null)
    
    if [ ! -z "$size" ]; then
        disk_sizes+=($size)
        disk_names+=($disk)
        echo -e "Disk: ${BOLD}/dev/$disk${NC}"
        echo "  → Size: $(numfmt --to=iec-i --suffix=B $size)"
        echo "  → Model: ${model:-Unknown}"
    else
        echo -e "${RED}ERROR: Failed to get size for disk /dev/$disk${NC}"
        echo "Device might not be accessible"
    fi
done

# Check for size mismatches
print_header "Disk Size Comparison"

reference_size=${disk_sizes[0]}
size_mismatch=false

# Compare all sizes with the first disk
for ((i=1; i<${#disk_sizes[@]}; i++)); do
    if [ "${disk_sizes[$i]}" != "$reference_size" ]; then
        size_mismatch=true
        break
    fi
done

if [ "$size_mismatch" = true ]; then
    echo -e "${RED}ERROR: Disk size mismatch detected${NC}"
    echo -e "Disk sizes found:"
    for ((i=0; i<${#disk_sizes[@]}; i++)); do
        echo "Disk ${disk_names[$i]}: $(numfmt --to=iec-i --suffix=B ${disk_sizes[$i]})"
    done
else
    echo -e "${GREEN}✓ All disks are of identical size: $(numfmt --to=iec-i --suffix=B $reference_size)${NC}"
fi

# 7. Quota Analysis
print_header "Quota Analysis"

current_refquota=$(zfs get refquota data -H -p | awk '{print $3}')
total_size=$(zpool get size data -H -p | awk '{print $3}')

if [ "$current_refquota" = "none" ]; then
    echo -e "${YELLOW}No refquota currently set${NC}"
else
    percentage=$(echo "scale=2; $current_refquota * 100 / $total_size" | bc)
    echo "Current refquota: $(numfmt --to=iec-i --suffix=B $current_refquota)"
    echo "Pool total size: $(numfmt --to=iec-i --suffix=B $total_size)"
    echo "Quota percentage: $percentage%"
fi

# 8. Final Recommendations
print_header "FINAL RECOMMENDATIONS"

issues=0
recommendations=""

# Check all conditions
if [ "$size_mismatch" = true ]; then
    ((issues++))
    recommendations+="\n• WARNING: Disk size mismatch detected"
fi
if [ -z "$raidz2_check" ]; then
    ((issues++))
    recommendations+="\n• WARNING: RAIDZ2 configuration not confirmed"
fi
if [[ ${capacity%\%} -gt 80 ]]; then
    recommendations+="\n• NOTE: Pool usage is high ($capacity)"
fi
if [[ ${frag%\%} -gt 50 ]]; then
    recommendations+="\n• NOTE: High fragmentation ($frag)"
fi
if [ "$errors" != "No known" ]; then
    ((issues++))
    recommendations+="\n• WARNING: Pool errors detected"
fi

if [ $issues -gt 0 ]; then
    echo -e "${RED}${BOLD}⚠ KEEP QUOTA PROTECTION ENABLED${NC}"
    echo -e "\nReasons:$recommendations"
    
    echo -e "\n${BOLD}Recommended Action:${NC}"
    echo "Maintain current quota or set to 95% of pool size:"
    echo "zfs set refquota=$((total_size * 95 / 100)) data"
else
    echo -e "${GREEN}${BOLD}✓ SAFE TO REMOVE QUOTA${NC}"
    echo -e "\nConfirmed conditions:"
    echo "• All disks are identical in size: $(numfmt --to=iec-i --suffix=B $reference_size)"
    echo "• RAIDZ2 configuration confirmed with ${#disks[@]} disks"
    echo "• Pool is healthy with no errors"
    echo "• Current capacity: $capacity"
    echo "• Fragmentation: $frag"
    
    echo -e "\n${BOLD}Recommended Action:${NC}"
    echo "Remove quota: zfs set refquota=none data"
    
    echo -e "\n${YELLOW}Alternative (Conservative Approach):${NC}"
    echo "If you prefer to maintain a safety margin:"
    echo "zfs set refquota=$((total_size * 95 / 100)) data"
fi

echo -e "\n${BOLD}Note for L2 Support:${NC}"
echo "1. Review the full output above, especially any RED or YELLOW warnings"
echo "2. Confirmed RAIDZ2 with ${#disks[@]} disks (sdc through sdg)"
echo "3. Check pool health indicators:"
echo "   - Last scrub status"
echo "   - Current capacity: $capacity"
echo "   - Fragmentation: $frag"
echo "   - Error status: $errors"
echo "4. If all checks pass (no red errors), it's safe to proceed with recommended action"
echo "5. Document your findings and action taken in the ticket"
