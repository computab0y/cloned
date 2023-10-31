#!/bin/bash

QUAY_URL=$1
QUAY_USER=$2
QUAY_PASSWORD=$3
EMAIL=$4
DSO_ORG=$5
DSO_REPO=$6
ROBOT_ACCOUNT=$7
TOKEN=$8

## Step 1: Creating First User

echo "Creating Quay first user $QUAY_USER"
CMD=$(curl -X POST -k $QUAY_URL/api/v1/user/initialize -H "Content-Type:application/json" -d "{\"username\":\"${QUAY_USER}\",\"password\":\"$QUAY_PASSWORD\",\"email\":\"$EMAIL\",\"access_token\":true}")
echo $CMD
ERR='"Cannot initialize user in a non-empty database"'

if [[ $(echo "$CMD" | jq .message) == $ERR ]]; then
   echo $ERR
   exit 1

elif [[ $(echo "$CMD" | jq .access_token) ]]; then
   TOKEN=$(echo "$CMD" | jq .access_token | tr -d '"')
   echo "Access_token is $TOKEN"
fi

# Step 2: Creating DSO Org

echo "Creating DSO Org $DSO_ORG"
CMD2=$(curl -X POST -k $QUAY_URL/api/v1/organization/ -H "Content-Type:application/json" -H "Authorization: Bearer $TOKEN" -d "{\"name\":\"$DSO_ORG\"}")
echo $CMD2

## Step 3: Create first repo

echo "Creating repo $DSO_REPO"
CMD3=$(curl -X POST -k $QUAY_URL/api/v1/repository -H "Content-Type:application/json" -H "Authorization: Bearer $TOKEN" -d "{\"namespace\":\"$DSO_ORG\",\"repository\":\"$DSO_REPO\",\"description\":\"DSO Repo\",\"visibility\":\"private\"}")
echo $CMD3

## Step 4: Create robot account

echo "Creating Org Robot Account $ROBOT_ACCOUNT"
CMD4=$(curl -X PUT -k $QUAY_URL/api/v1/organization/$DSO_ORG/robots/$ROBOT_ACCOUNT -H "Content-Type:application/json" -H "Authorization: Bearer $TOKEN" -d "{\"description\":\"Org Robot Account\"}")
echo $CMD4 

## Step 5: Assign permission to robot account

echo "Adding Admin permission to $ROBOT_ACCOUNT"
CMD5=$(curl -X PUT -k $QUAY_URL/api/v1/repository/$DSO_ORG/$DSO_REPO/permissions/user/$DSO_ORG+$ROBOT_ACCOUNT -H "Content-Type:application/json" -H "Authorization: Bearer $TOKEN" -d "{\"role\":\"admin\"}" )
echo $CMD5
