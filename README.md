# Flapple Bird

Flapple Bird - A de-make of Flappy Bird for the Apple II computer

![Flapple Gameplay Image](/assets/flapple_gameplay.png?raw=true "Flapple Bird Gameplay Image")

# Download
💾 **[Download Releases Here](https://github.com/digarok/flapple/releases)**

# How to run
You can download either disk image and run it with an emulator like [GSplus](https://github.com/digarok/gsplus) or transfer it to the respective media and run it on a real machine (recommended).  
- `flapple800.po` is the 3.5" ProDOS disk version (800KB)
- `flapple140.po` is the 5.25" ProDOS disk version (140KB)

It should automatically boot ProDOS and load the color version of Flapple Bird.  There is a Monochrome version of the game included on the disk.  To run it, quit with the `q` key, and from the ProDOS selector menu (Bitsy-Bye in 2020) run `fmono.system`.  

# How to build
This was originally written to compile on Merlin 8/16, but it's now maintained using [Merlin32](https://github.com/digarok/merlin32/).  

- Classic Merlin16+ on an Apple IIgs
  - Load Merlin, then `L`oad the file "flapple.s", finally hit OpenApple-A to assemble and it should build the "flap.system" file.
- Modern PC builds:
  - Assemble with `merlin32 src/flapple.s`
  - Make disks with `./make_po.sh`

Requires having `merlin32` and `cadius` commands available on your system.


