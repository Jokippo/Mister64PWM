vcom -93 -quiet -work  sim/mem ^
../system/src/mem/dpram.vhd ^
../../rtl/SyncFifoFallThrough.vhd ^
../system/src/mem/RamMLAB.vhd

vcom -93 -quiet -work sim/n64 ^
../system/src/mem/dpram.vhd

vcom -2008 -quiet -work sim/n64 ^
../../rtl/functions.vhd ^
../../rtl/SDRamMux.vhd ^
../../rtl/Gamepad.vhd ^
../../rtl/pif_cic6105.vhd ^
../../rtl/pifrom_ntsc_fast.vhd ^
../../rtl/PIF.vhd

vcom -2008 -quiet -work sim/tb ^
../system/src/tb/globals.vhd ^
../system/src/tb/sdram_model.vhd ^
src/tb/tb.vhd

