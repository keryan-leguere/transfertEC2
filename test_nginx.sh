#!/bin/bash

# Colors for formatting output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No color

echo -e "${GREEN}---- Nginx Reverse Proxy Test Script ----${NC}"

# 1. Check if Nginx is installed
if ! [ -x "$(command -v nginx)" ]; then
  echo -e "${RED}Nginx is not installed. Installing now...${NC}"
  sudo apt update
  sudo apt install nginx -y
else
  echo -e "${GREEN}Nginx is already installed.${NC}"
fi

# 2. Check Nginx configuration syntax
echo -e "${GREEN}Checking Nginx configuration syntax...${NC}"
sudo nginx -t

if [ $? -ne 0 ]; then
  echo -e "${RED}Nginx configuration has errors. Please check the configuration.${NC}"
  exit 1
else
  echo -e "${GREEN}Nginx configuration is correct.${NC}"
fi

# 3. Restart Nginx
echo -e "${GREEN}Restarting Nginx...${NC}"
sudo systemctl restart nginx

if [ $? -eq 0 ]; then
  echo -e "${GREEN}Nginx restarted successfully.${NC}"
else
  echo -e "${RED}Failed to restart Nginx. Please check for issues.${NC}"
  exit 1
fi

# 4. Get the public IP address
PUBLIC_IP=$(curl -s ifconfig.me)
if [[ -z "$PUBLIC_IP" ]]; then
  echo -e "${RED}Could not determine the public IP address.${NC}"
  exit 1
else
  echo -e "${GREEN}Public IP address is: $PUBLIC_IP${NC}"
fi

# 5. Test access to the application via public IP
echo -e "${GREEN}Testing access to http://$PUBLIC_IP...${NC}"
curl -s -o /dev/null -w "%{http_code}" http://$PUBLIC_IP > curl_output.txt

if grep -q "200" curl_output.txt; then
  echo -e "${GREEN}The server is accessible via http://$PUBLIC_IP.${NC}"
else
  echo -e "${RED}The server is not accessible via http://$PUBLIC_IP. Please check the reverse proxy setup or firewall settings.${NC}"
  exit 1
fi

# 6. Allow HTTP traffic on port 80 via UFW (optional)
if [ -x "$(command -v ufw)" ]; then
  echo -e "${GREEN}Checking if port 80 is allowed through the firewall...${NC}"
  UFW_STATUS=$(sudo ufw status | grep 'Nginx Full')

  if [[ -z "$UFW_STATUS" ]]; then
    echo -e "${RED}Port 80 is not allowed. Enabling port 80 for HTTP traffic...${NC}"
    sudo ufw allow 'Nginx Full'
    echo -e "${GREEN}Port 80 is now allowed.${NC}"
  else
    echo -e "${GREEN}Port 80 is already allowed.${NC}"
  fi
fi

# Cleanup
rm curl_output.txt

echo -e "${GREEN}---- Test Completed Successfully ----${NC}"

