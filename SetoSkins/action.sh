#!/system/bin/sh
MODDIR=${0%/*}

# Detect root manager
if [ -n "$KSU" ] || [ -d /data/adb/ksu ]; then
    # KernelSU / SukiSU: WebUI is handled natively by the manager
    # This action.sh is a fallback - open in browser
    echo "Opening WebUI..."
    HTTPD_PORT=18735
    pkill -f "httpd.*${HTTPD_PORT}" 2>/dev/null
    sleep 0.3
    export MODDIR
    busybox httpd -p 127.0.0.1:${HTTPD_PORT} -h "$MODDIR/webroot" -c "$MODDIR/webroot/httpd.conf" 2>/dev/null
    am start -a android.intent.action.VIEW -d "http://127.0.0.1:${HTTPD_PORT}" >/dev/null 2>&1
    echo "WebUI: http://127.0.0.1:${HTTPD_PORT}"
else
    # Magisk: Start HTTP server and open browser
    HTTPD_PORT=18735

    # Kill any existing instance
    pkill -f "httpd.*${HTTPD_PORT}" 2>/dev/null
    sleep 0.3

    # Export MODDIR for CGI scripts
    export MODDIR

    # Ensure CGI script is executable
    chmod 755 "$MODDIR/webroot/cgi-bin/api.sh" 2>/dev/null

    # Start busybox httpd with CGI support
    busybox httpd -p 127.0.0.1:${HTTPD_PORT} -h "$MODDIR/webroot" -c "$MODDIR/webroot/httpd.conf" 2>/dev/null

    if [ $? -eq 0 ]; then
        # Open browser
        am start -a android.intent.action.VIEW -d "http://127.0.0.1:${HTTPD_PORT}" >/dev/null 2>&1
        echo "Seto Thermal WebUI opened"
        echo "URL: http://127.0.0.1:${HTTPD_PORT}"
        echo ""
        echo "The web server will auto-stop in 30 minutes."
        echo "To stop manually: pkill -f 'httpd.*${HTTPD_PORT}'"

        # Auto-stop after 30 minutes
        (sleep 1800 && pkill -f "httpd.*${HTTPD_PORT}") &
    else
        echo "Failed to start HTTP server."
        echo "Make sure busybox httpd is available."
    fi
fi
