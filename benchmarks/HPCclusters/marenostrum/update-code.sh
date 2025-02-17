echo -e "\033[1;33mNo connections are allowed from inside the cluster to the outside world."
echo -e "Instead, use the workaround described here:\033[0m https://www.bsc.es/supportkc/docs/dtmachines"
echo -e "\033[1;33mSet the mount point to a directory on your local machine:\033[0m"
echo -e "sshfs -o workaround=rename <yourHPCUser>@transfer1.bsc.es: <localDirectory>"
echo -e "\033[1;33mThen pull manually.\033[0m"
read -p "Press enter when the code is updated to continue."
echo "Continuing..."

