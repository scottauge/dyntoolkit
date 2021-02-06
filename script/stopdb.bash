#!/bin/bash

export DLC=/usr/dlc
export PFFILE=/home/sauge/code/progress/zeno/db/zeno1.pf

$DLC/bin/proshut -by -pf $PFFILE 
$DLC/bin/proshut -by -db /home/db/amduus/data/amduus.db -S 10000 -H localhost

