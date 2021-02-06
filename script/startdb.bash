#!/bin/bash

export DLC=/usr/dlc
export PFFILE=/home/sauge/code/progress/zeno/db/zeno1.pf

$DLC/bin/proserve -pf $PFFILE 
$DLC/bin/proserve -db /home/db/amduus/data/amduus.db -S 10000 -H localhost

