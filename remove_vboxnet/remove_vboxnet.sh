#!/bin/bash

for i in {0..127}
do
    echo "remove VBoxNet$i"
    VBoxManage hostonlyif remove vboxnet$i
done
