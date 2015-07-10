#!/bin/bash
command -v cadius >/dev/null 2>&1 || { echo "I require CADIUS but it's not installed.  Aborting." >&2; exit 1; }


SRCFILES=(`ls src/*.s`)
SYSFILES=(`ls PRODOS.2.4.2//PRODOS src/*system`)
SRCDIR=src
BLDDIR=build/

DISK="flapple"
CADIUS="cadius"

if [ ! -d $BLDDIR ] ; then
  echo "Build directory for this platform doesn't exist so I will create it."
  mkdir -p $BLDDIR ; echo "Created: $BLDDIR"
fi

# need to autogen
cp src/_FileInformation.txt $BLDDIR

echo "Creating disk images"
$CADIUS createvolume ${DISK}800.po ${DISK}800 800KB >/dev/null
$CADIUS createvolume ${DISK}140.po ${DISK}140 140KB >/dev/null

#SYSTEM FILES
echo -n "Processing System files: "
COMMA=""
for f in ${SYSFILES[@]}; 
do
  FNAME=${f##*/}
  echo -n "$COMMA $FNAME"
  cp $f $BLDDIR/$FNAME 
  $CADIUS addfile ${DISK}800.po /${DISK}800/ $BLDDIR/$FNAME >/dev/null
  $CADIUS addfile ${DISK}140.po /${DISK}140/ $BLDDIR/$FNAME >/dev/null
  COMMA=","
done

#SOURCE FILES
echo ""
echo -n "Processing Source files: "
COMMA=""
for f in ${SRCFILES[@]}; 
do
  FNAME=${f##*/}
  echo -n "$COMMA $FNAME"
  cp $f $BLDDIR/$FNAME 
  echo "$FNAME=Type(04),AuxType(0000),VersionCreate(24),MinVersion(00),Access(E3)" > $BLDDIR/_FileInformation.txt
  $CADIUS sethighbit $BLDDIR/$FNAME >/dev/null
  $CADIUS addfile ${DISK}800.po /${DISK}800/ $BLDDIR/$FNAME >/dev/null
  $CADIUS addfile ${DISK}140.po /${DISK}140/ $BLDDIR/$FNAME >/dev/null
  COMMA=","
done


echo "Look, I'm no expert, but I think everything went pretty well.  (BUILD SUCCEEDED!!!)"
echo ""
exit
