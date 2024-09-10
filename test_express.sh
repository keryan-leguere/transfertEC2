#!/bin/bash

# Colors for formatting output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No color

echo -e "${GREEN}---- Express App Testing Script ----${NC}"

# 1. Check if node is installed
if ! [ -x "$(command -v node)" ]; then
  echo -e "${RED}Error: Node.js is not installed.${NC}" >&2
  exit 1
else
  echo -e "${GREEN}Node.js is installed.${NC}"
fi

# 2. Start the Express server
echo -e "${GREEN}Starting your Express server...${NC}"

# Run the server in the background and save the PID to kill it later
node app.js & 
SERVER_PID=$!
sleep 2  # Wait for the server to start

# 3. Check if the server is running on localhost:3000
echo -e "${GREEN}Checking if the server is accessible on localhost:3000...${NC}"
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 > curl_output.txt

# If the HTTP status code is 200, the server is running fine
if grep -q "200" curl_output.txt; then
  echo -e "${GREEN}Server is running and accessible on localhost:3000.${NC}"
else
  echo -e "${RED}Server is not accessible on localhost:3000. Please check the app.js code.${NC}"
  kill $SERVER_PID
  exit 1
fi

# 4. Get the local IP address
LOCAL_IP=$(hostname -I | awk '{print $1}')
if [[ -z "$LOCAL_IP" ]]; then
  echo -e "${RED}Could not determine the local IP address.${NC}"
  kill $SERVER_PID
  exit 1
else
  echo -e "${GREEN}Local IP address is: $LOCAL_IP${NC}"
fi

# 5. Check if the server is accessible from the local network
echo -e "${GREEN}Checking if the server is accessible on $LOCAL_IP:3000...${NC}"
curl -s -o /dev/null -w "%{http_code}" http://$LOCAL_IP:3000 > curl_output.txt

if grep -q "200" curl_output.txt; then
  echo -e "${GREEN}Server is running and accessible on $LOCAL_IP:3000.${NC}"
else
  echo -e "${RED}Server is not accessible on $LOCAL_IP:3000. Please check network settings.${NC}"
  kill $SERVER_PID
  exit 1
fi

# 6. Get the public IP address
PUBLIC_IP=$(curl -s ifconfig.me)
if [[ -z "$PUBLIC_IP" ]]; then
  echo -e "${RED}Could not determine the public IP address.${NC}"
  kill $SERVER_PID
  exit 1
else
  echo -e "${GREEN}Public IP address is: $PUBLIC_IP${NC}"
fi

# 7. Instructions to check port forwarding
echo -e "${GREEN}---- Port Forwarding Instructions ----${NC}"
echo -e "${GREEN}1. Ensure port forwarding is set up on your router for port 3000 to $LOCAL_IP.${NC}"
echo -e "${GREEN}2. To check if your public IP is accessible externally on port 3000, go to http://$PUBLIC_IP:3000 in a browser on a device outside your network.${NC}"
echo -e "${GREEN}3. You can also use a service like 'canyouseeme.org' to check if port 3000 is open.${NC}"

# 8. Check if the firewall is active and allow port 3000 if needed
if [ -x "$(command -v ufw)" ]; then
  FIREWALL_STATUS=$(sudo ufw status | grep -i "active")
  
  if [[ ! -z "$FIREWALL_STATUS" ]]; then
    echo -e "${GREEN}Firewall is active. Checking if port 3000 is allowed...${NC}"
    PORT_STATUS=$(sudo ufw status | grep "3000")

    if [[ -z "$PORT_STATUS" ]]; then
      echo -e "${RED}Port 3000 is not open. Opening port 3000...${NC}"
      sudo ufw allow 3000
      echo -e "${GREEN}Port 3000 is now allowed.${NC}"
    else
      echo -e "${GREEN}Port 3000 is already allowed.${NC}"
    fi
  else
    echo -e "${GREEN}Firewall is inactive, no need to open port 3000.${NC}"
  fi
else
  echo -e "${RED}UFW firewall is not installed, skipping firewall checks.${NC}"
fi

# Cleanup and kill the server
echo -e "${GREEN}Cleaning up and stopping the server...${NC}"
kill $SERVER_PID
rm curl_output.txt

echo -e "${GREEN}---- Test Completed Successfully ----${NC}"

