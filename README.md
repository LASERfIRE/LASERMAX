# LASERMAX

Version 1.30 31-Jan-1999

This is the original Amiga version of my LASER controller software which I have released here for historical value.

The software used the Amiga's sound hardware (that is modified to allow for a DC offset by bypassing the AC coupling capacitors) to drive X/Y scanners (via the "build it yourself" DC amp). Instructions for the sound hardware modification are found in the user manual. The original scans of my hand drawn DC amp circuit and parts list, along with the user manual are included in the release zip.

If you do not have an Amiga 1200 or Amiga 3000 to run it (like me), it can still be run on the [WinUAE](https://www.winuae.net/download/) Amiga emulator for Windows.
The stereo sound output from the software used to drive X/Y scanners is also emulated, and therefore could still be used to drive real X/Y scanners. Modifying a PC sound card for DC offset and building the DC amp circuit is left up to you, but should be possible.

Here are some basic steps to setup the WinUAE emulator. I recommend running my LASER controller software on an emulated Amiga 3000. After downloading and installing the emulator, you will first need to get the "A3000 Kickstart v3.1 r40.068" ROM file and Workbench v3.1 disk ".adf" files (Workbench, Extras, Fonts, Storage, Locale and Install). Set the emulator using the "QuickStart" option (found in Settings) to Model "A3000" and Configuration to "3.1 ROM, 2MB Chip + 8 MB Fast". Under "Chipset" make sure "Cycle-exact (Full)" and "Cycle-exact (DMA/Memory accesses)" are both enabled. I recommend installing Workbench v3.1 to a virtual Hard drive by using the Workbench Install disk from within the emulator. See the [WinUAE](https://www.winuae.net/) web site for more details and where to get the ROM and disk files.

Once you have a working emulated Amiga 3000, you can install my software with the next few steps. First, download and unzip the release file from "Releases". Next, setup a (second) virtual Hard drive in the emulator by clicking on the "Add Directory or Archive..." button found under "CD & Hard drives". Set the "Device name" to "DH1" and "Volume label" to "LASER". Now click the "Select Directory" button and browse to the "LASERMAX130" directory within the unzipped release folder. Click on "OK" when done. Before starting the emulation, save the new configuration with the "Save As..." button found under "Configurations". Next time you start the emulator be sure to load this configuration first by selecting the configuration name and then "Load". Go ahead and start the emulation. If all went well, you should see a "disk" icon labeled "LASER" on Workbench. Open this by double clicking on the icon.

From here you can follow the same install instructions from the original "ReadMe.text" file included in the zip, but here are some more detailed steps in case you have forgotten how to use the Amiga OS (like me).

By default, the Amiga OS will only show files that have matching ".info" data files. To see all files in the "LASER" window, open the menu (hold down the right mouse button) and select "Window" -> "Show" -> "All Files" (if not already enabled). First, you need to copy the file "reqtools.library" from the "LASER" folder to the "Libs" folder in "Workbench". Open "Workbench" and enable "All Files" for this window too so that you can see the "Libs" folder. Then drag and drop the "reqtools.library" file into the "Libs" folder.

The final step is to add the text line "Assign >NIL: LASERMAX: LASER:LASERMAX" to the "Startup-Sequence" text file found in the "S" directory. To do this, open the "Tools" folder found in "Workbench" and double click on text editor called "MEmacs". Select "Read-file" from the menu and type the filename "S:Startup-Sequence" to open it. Add the line "Assign >NIL: LASERMAX: LASER:LASERMAX" by typing it just under where the existing "Assign >NIL: ...." lines are. Save the modified file by selecting "Save-file" from the menu and then "Quit". Now restart the emulator for the changes to take effect.

That's it! You can now play with your new LASER controller software by opening the "LASERMAX" folder and double clicking on the "LASERMAX" icon. The first step to do from within the software is to load a configuration file. Select "Get config" from the menu and Load the "HiSpeedA3000.config" file. This will load up some sequences on the sequence buttons for you to play with.

The original user manual has been converted to pdf and can be found in the release zip. Please ignore the "Shareware" notices - it is now provided for free.

I have included the source code on this release. Unfortunately, I no longer have the "GadToolBox" generated source code file ("Laser.s") that is needed to recompile it. Note that the software was hand written in 68020 assembler!

Enjoy.
