#!/bin/bash
# Usage: ./grade.sh /path/to/student_repo/projects/01
# Written through Gemini, who cites the Nand2Tetris authors. This script is designed to automate the grading of Nand2Tetris projects by running the appropriate simulator for each project and checking the output against expected results.

PROJECT_DIR=$1
PASSED=0
FAILED=0
TOTAL=0

if [ -z "$PROJECT_DIR" ]; then
    echo "Usage: ./grade.sh <path_to_project_directory>"
    exit 1
fi

# Clean trailing slashes and extract project number (e.g. "01", "07", "12")
# Search path segments (not just the trailing one) since some projects
# keep tests in subfolders, e.g. "4/mult" or "4/fill". Wowza, thanks Claude!
CLEAN_PATH="${PROJECT_DIR%/}"
PROJ_NUM=""
IFS='/' read -ra PATH_PARTS <<< "$CLEAN_PATH"
for part in "${PATH_PARTS[@]}"; do
    if [[ "$part" =~ ^[0-9]+$ ]]; then
        PROJ_NUM=$(printf "%02d" "$part")
    fi
done

# Determine the correct runner based on project number
case "$PROJ_NUM" in
    01|02|03|05)
        RUNNER="HardwareSimulator.bat"
        ;;
    07|08)
        RUNNER="VMEmulator.bat"
        ;;
    04|09|12)
        RUNNER="CPUEmulator.bat"
        ;;
    06|10|11)
        echo "Project $PROJ_NUM requires testing compiler/assembler outputs directly."
        exit 0
        ;;
    *)
        # Default fallback for custom or unlisted folders
        RUNNER="HardwareSimulator.bat"
        ;;
esac

cd "$CLEAN_PATH" || exit 1

echo "=========================================="
echo " Grading Nand2Tetris: Project $PROJ_NUM using $RUNNER"
echo "=========================================="

for testfile in *.tst; do
    [ -e "$testfile" ] || continue
    TOTAL=$((TOTAL + 1))
    
    # Run the appropriate simulator script and capture output
    OUTPUT=$("$RUNNER" "$testfile" 2>&1)
    
    if echo "$OUTPUT" | grep -q "Comparison ended successfully"; then
        echo -e "[\e[32mPASS\e[0m] $testfile"
        PASSED=$((PASSED + 1))
    else
        echo -e "[\e[31mFAIL\e[0m] $testfile"
        echo "$OUTPUT" | grep -i "comparison failure"
        FAILED=$((FAILED + 1))
    fi
done

echo "------------------------------------------"
echo "Score: $PASSED / $TOTAL passed."
echo "=========================================="