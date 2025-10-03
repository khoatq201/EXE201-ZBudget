#!/bin/bash

TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2OGRkZWRiZjExNjg4YTQ4ZTZmYWQxMmQiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzU5Mzc0ODI1LCJleHAiOjE3NTk5Nzk2MjUsImF1ZCI6InpidWRnZXQtYXBwIiwiaXNzIjoiemJ1ZGdldC1hcGkifQ._RLgBQmj5zlpzK6KBCct-nsVkDpAcKo-J3cBHdl3TS0"

echo "Testing Dashboard Summary API..."
curl -s -X GET "http://localhost:3000/api/dashboard/summary?period=month" \
  -H "Authorization: Bearer ${TOKEN}" | jq .
