#!/bin/bash

export DLC=/usr/dlc
export PFFILE=/home/sauge/code/progress/zeno/db/zeno1.pf
export PROPATH=/appl/dyntoolkit/src

$DLC/bin/mpro -pf $PFFILE -db /db/amduus/data/amduus.db -S 10000 -H localhost
