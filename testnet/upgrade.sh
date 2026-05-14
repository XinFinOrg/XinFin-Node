#!/bin/sh
echo "Upgrading XDC Network Configuration Scripts"
cd testnet
cp start-apothem.sh start-apothem.sh.tmp || true
mv .env .env_tmp

git stash
if ! git pull; then
    echo ""
    echo "ERROR: git pull failed — there may be a merge conflict."
    echo ""
    echo "This usually happens when env.example has changed upstream."
    echo "To resolve:"
    echo "  1. Run 'git status' to see which files are conflicting."
    echo "  2. Read testnet/README.md for a full description of every"
    echo "     env variable, port, and flag."
    echo "  3. Compare env.example (upstream) with your .env_tmp"
    echo "     and add any new variables to your .env file."
    echo "  4. Resolve the conflict in env.example (or other files)"
    echo "     then run 'git add <file>' and 'git merge --continue'."
    echo "  5. Re-run this script once the conflict is resolved."
    echo ""
    echo "Your original .env has been preserved as .env_tmp"
    mv start-apothem.sh.tmp start-apothem.sh || true
    exit 1
fi

source .env_tmp
sed -i "s/NODE_NAME=XF_MasterNode/NODE_NAME=$NODE_NAME/" .env
sed -i "s/CONTACT_DETAILS=YOUR_EMAIL_ADDRESS/CONTACT_DETAILS=$CONTACT_DETAILS/" .env

bash docker-down.sh
mv xdcchain xdcchain-testnet || true
mv start-apothem.sh.tmp start-apothem.sh || true
bash docker-up.sh