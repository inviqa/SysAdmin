#!/bin/sh
INVENTORY_FILE="inventory"
echo "[droplets]" > $INVENTORY_FILE
tugboat droplets | cut -d':' -f2  | cut -d',' -f1  >> $INVENTORY_FILE
