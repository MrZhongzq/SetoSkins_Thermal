#!/system/bin/sh
# CGI API for Seto Thermal WebUI (Magisk browser mode)
# Called by busybox httpd

echo "Content-Type: application/json"
echo "Access-Control-Allow-Origin: *"
echo ""

# Parse query string
ACTION=""
CMD=""
IFS='&' read -r -a PARAMS <<< "$QUERY_STRING"
for param in "${PARAMS[@]}"; do
    key="${param%%=*}"
    val="${param#*=}"
    # URL decode
    val=$(echo -e "$(echo "$val" | sed 's/+/ /g;s/%\([0-9a-fA-F][0-9a-fA-F]\)/\\x\1/g')")
    case "$key" in
        action) ACTION="$val" ;;
        cmd) CMD="$val" ;;
    esac
done

# Detect module directory
if [ -z "$MODDIR" ]; then
    MODDIR="/data/adb/modules/SetoSkins"
fi

case "$ACTION" in
    exec)
        if [ -n "$CMD" ]; then
            # Execute command and capture output
            STDOUT=$(eval "$CMD" 2>/tmp/seto_stderr)
            ERRNO=$?
            STDERR=$(cat /tmp/seto_stderr 2>/dev/null)
            rm -f /tmp/seto_stderr

            # Escape for JSON
            STDOUT=$(echo "$STDOUT" | sed 's/\\/\\\\/g;s/"/\\"/g;s/\t/\\t/g' | tr '\n' '\r' | sed 's/\r/\\n/g')
            STDERR=$(echo "$STDERR" | sed 's/\\/\\\\/g;s/"/\\"/g;s/\t/\\t/g' | tr '\n' '\r' | sed 's/\r/\\n/g')

            echo "{\"errno\":${ERRNO},\"stdout\":\"${STDOUT}\",\"stderr\":\"${STDERR}\"}"
        else
            echo '{"errno":1,"stdout":"","stderr":"No command provided"}'
        fi
        ;;
    *)
        echo '{"errno":1,"stdout":"","stderr":"Unknown action"}'
        ;;
esac
