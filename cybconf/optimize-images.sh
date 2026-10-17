#!/bin/bash
# Image Optimization Script for IEEE SWC 2026 Website
# Run this script to optimize all images in the assets directory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directories
ASSETS_DIR="assets/images_26"
SPONSOR_DIR="$ASSETS_DIR/sponsor"
IMAGES_DIR="$ASSETS_DIR/imgs"
PEOPLE_DIR="$ASSETS_DIR/people"

echo -e "${YELLOW}===================================${NC}"
echo -e "${YELLOW}IEEE SWC 2026 - Image Optimization${NC}"
echo -e "${YELLOW}===================================${NC}\n"

# Check dependencies
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    if ! command -v optipng &> /dev/null; then
        echo -e "${RED}✗ optipng not found${NC}"
        echo "Install with: brew install optipng"
        return 1
    fi
    echo -e "${GREEN}✓ optipng found${NC}"
    
    if ! command -v cwebp &> /dev/null; then
        echo -e "${RED}✗ cwebp not found${NC}"
        echo "Install with: brew install libwebp"
        return 1
    fi
    echo -e "${GREEN}✓ cwebp found${NC}\n"
    
    return 0
}

# Show current image sizes
show_sizes() {
    echo -e "${YELLOW}Current Image Sizes:${NC}"
    echo "Sponsor logos:"
    du -sh "$SPONSOR_DIR"/*.{png,jpg,jpeg,svg} 2>/dev/null | sort -h || echo "  No images found"
    echo ""
    echo "Hero images:"
    du -sh "$IMAGES_DIR"/*.{png,jpg,jpeg,webp} 2>/dev/null | sort -h || echo "  No images found"
    echo ""
    echo "People images:"
    du -sh "$PEOPLE_DIR"/*.{png,jpg,jpeg,webp} 2>/dev/null | sort -h || echo "  No images found"
    echo ""
}

# Optimize PNG files
optimize_pngs() {
    echo -e "${YELLOW}Optimizing PNG files...${NC}"
    
    local png_count=0
    local total_before=0
    local total_after=0
    
    for png_file in "$SPONSOR_DIR"/*.png "$IMAGES_DIR"/*.png "$PEOPLE_DIR"/*.png; do
        if [ -f "$png_file" ]; then
            local before=$(stat -f%z "$png_file" 2>/dev/null || stat -c%s "$png_file" 2>/dev/null)
            total_before=$((total_before + before))
            
            echo "  Optimizing: $(basename "$png_file")"
            optipng -o4 -quiet "$png_file"
            
            local after=$(stat -f%z "$png_file" 2>/dev/null || stat -c%s "$png_file" 2>/dev/null)
            total_after=$((total_after + after))
            
            local reduction=$((100 * (before - after) / before))
            echo "    Reduced by ${reduction}%"
            png_count=$((png_count + 1))
        fi
    done
    
    if [ $png_count -gt 0 ]; then
        local overall_reduction=$((100 * (total_before - total_after) / total_before))
        echo -e "${GREEN}✓ Optimized $png_count PNG files (overall: ${overall_reduction}% reduction)${NC}\n"
    else
        echo -e "${YELLOW}  No PNG files found${NC}\n"
    fi
}

# Convert images to WebP
convert_to_webp() {
    echo -e "${YELLOW}Converting images to WebP format...${NC}"
    
    local webp_count=0
    
    # Convert sponsor logos
    for img_file in "$SPONSOR_DIR"/*.{png,jpg,jpeg}; do
        if [ -f "$img_file" ]; then
            local basename="${img_file%.*}"
            local webp_file="$basename.webp"
            
            if [ ! -f "$webp_file" ]; then
                echo "  Converting: $(basename "$img_file")"
                cwebp -q 80 "$img_file" -o "$webp_file"
                webp_count=$((webp_count + 1))
            fi
        fi
    done
    
    # Convert people images with quality 80
    for img_file in "$PEOPLE_DIR"/*.{png,jpg,jpeg}; do
        if [ -f "$img_file" ]; then
            local basename="${img_file%.*}"
            local webp_file="$basename.webp"
            
            if [ ! -f "$webp_file" ]; then
                echo "  Converting: $(basename "$img_file")"
                cwebp -q 80 "$img_file" -o "$webp_file"
                webp_count=$((webp_count + 1))
            fi
        fi
    done
    
    # Convert hero images with quality 85
    for img_file in "$IMAGES_DIR"/*.{png,jpg,jpeg}; do
        if [ -f "$img_file" ]; then
            local basename="${img_file%.*}"
            local webp_file="$basename.webp"
            
            if [ ! -f "$webp_file" ]; then
                echo "  Converting: $(basename "$img_file")"
                cwebp -q 85 "$img_file" -o "$webp_file"
                webp_count=$((webp_count + 1))
            fi
        fi
    done
    
    if [ $webp_count -gt 0 ]; then
        echo -e "${GREEN}✓ Created $webp_count WebP files${NC}\n"
    else
        echo -e "${YELLOW}  No new WebP conversions needed${NC}\n"
    fi
}

# Generate responsive image sizes
generate_responsive() {
    echo -e "${YELLOW}Generating responsive image sizes...${NC}"
    
    # This would create smaller variants for mobile
    # Example for hero images
    for img_file in "$IMAGES_DIR"/*.webp; do
        if [ -f "$img_file" ]; then
            local basename="${img_file%.*}"
            
            # Uncomment to auto-generate sizes
            # (Note: requires ImageMagick)
            # convert "$img_file" -resize 1200x \( +clone -resize 800x \) \( +clone -resize 480x \) mpr:base
            
            echo "  Would generate: $(basename "$basename")-{1200,800,480}.webp"
        fi
    done
    
    echo -e "${YELLOW}  (Run manually when ready: requires ImageMagick)${NC}\n"
}

# Main execution
main() {
    if ! check_dependencies; then
        echo -e "${RED}Cannot continue without dependencies${NC}"
        exit 1
    fi
    
    show_sizes
    optimize_pngs
    convert_to_webp
    generate_responsive
    
    echo -e "${GREEN}===================================${NC}"
    echo -e "${GREEN}Image optimization complete!${NC}"
    echo -e "${GREEN}===================================${NC}\n"
    
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Test website locally: jekyll serve"
    echo "2. Verify images load correctly in browser"
    echo "3. Check performance: https://pagespeed.web.dev/"
    echo "4. Commit optimized images: git add assets/"
    echo ""
}

main
