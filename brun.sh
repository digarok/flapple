#!/bin/bash
merlin32 -V . src/flapple.s
if [ $? -ne 0 ]; then
  echo "Assembly Failed.  Exiting." ;  exit 1
fi


#second time with different build flags (MONO=1)
sed -i.bak "s/^MONO\(.*\)equ.*/MONO\1equ  1/g" src/flapple.s
merlin32 -V . src/flapple.s
if [ $? -ne 0 ]; then
  echo "Assembly Failed.  Exiting." ; exit 1
fi

#revert file to original state (MONO=0)
sed -i.bak "s/^MONO\(.*\)equ.*/MONO\1equ  0/g" src/flapple.s
rm src/flapple.s.bak

./make_po.sh
gsplus
