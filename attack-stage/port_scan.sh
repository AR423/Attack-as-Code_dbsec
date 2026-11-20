#!/bin/bash
# Usage: ./port_scan.sh <host>
# Scans for the Postgres port and grabs service/version info.

HOST="${1:-localhost}"
OUTPUT="attack-stage/results/port_scan_result.txt"

echo "=== Port/Service Scan against $HOST ===" | tee "$OUTPUT"
nmap -Pn -p 5432 -sV "$HOST" | tee -a "$OUTPUT"

if grep -q "5432/tcp open" "$OUTPUT"; then
    echo "FINDING: Port 5432 (PostgreSQL) is open and reachable." | tee -a "$OUTPUT"
else
    echo "No open Postgres port detected." | tee -a "$OUTPUT"
fi
