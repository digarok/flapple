php ../grlib/png2rle.php assets/flapple_logo_80x48.png flogo > src/flogo.s
echo Update src/flogo.s
echo "KFW" > src/kfw.s
../ozkfest2015/scripts/hexfmt.sh assets/kfest_dvamp.raw  >> src/kfw.s
echo "KFW_end = *-1" >> src/kfw.s
echo Update src/kfw.s

php ../grlib/png2stripesprite.php assets/kfest_banner_trans_14x48.png kfbanner

