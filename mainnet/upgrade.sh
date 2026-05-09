#!/bin/bash

echo "Upgrading XDC Network Configuration Scripts"

cp .env .env.bak
cp .nodekey .nodekey.bak

if ! git pull; then
    echo ""
    echo "ERROR: git pull failed — there may be a merge conflict."
    echo ""
    echo "This usually happens when env.example has changed upstream."
    echo "To resolve:"
    echo "  1. Run 'git status' to see which files are conflicting."
    echo "  2. Read mainnet/README.md for a full description of every"
    echo "     env variable, port, and flag."
    echo "  3. Compare env.example (upstream) with your .env.bak"
    echo "     and add any new variables to your .env file."
    echo "  4. Resolve the conflict in env.example (or other files)"
    echo "     then run 'git add <file>' and 'git merge --continue'."
    echo "  5. Re-run this script once the conflict is resolved."
    echo ""
    echo "Your original .env has been preserved as .env.bak"
    echo "Your original .nodekey has been preserved as .nodekey.bak"
    exit 1
fi

echo "Upgrading Docker Images"
docker compose -f docker-compose.yml down
docker compose -f docker-compose.yml up -d
