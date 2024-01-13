vcom -93 -quiet -work  sim/mem ^
../system/src/mem/dpram.vhd ^
../system/src/mem/RamMLAB.vhd ^
../system/src/mem/Shiftreg.vhd ^
../../rtl/SyncFifo.vhd ^
../../rtl/SyncFifoFallThrough.vhd ^
../../rtl/SyncFifoFallThroughMLAB.vhd ^
../../rtl/SyncRam.vhd

vcom -2008 -quiet -work sim/n64 ^
../../rtl/functions.vhd ^
../../rtl/VI_package.vhd ^
../../rtl/VI_overlay.vhd ^
../../rtl/VI_videoout_async.vhd ^
../../rtl/VI_linefetch.vhd ^
../../rtl/VI_lineProcess.vhd ^
../../rtl/VI_filter_pen.vhd ^
../../rtl/VI_filter.vhd ^
../../rtl/VI_sqrt.vhd ^
../../rtl/VI_outProcess.vhd ^
../../rtl/VI_videoout.vhd ^
../../rtl/VI.vhd ^
../../rtl/RDP_package.vhd ^
../../rtl/RDP_command.vhd ^
../../rtl/RDP_raster_perspcorr.vhd ^
../../rtl/RDP_raster.vhd ^
../../rtl/RDP_TexCoordClamp.vhd ^
../../rtl/RDP_TexTile.vhd ^
../../rtl/RDP_TexSingle.vhd ^
../../rtl/RDP_TexFetch.vhd ^
../../rtl/RDP_FBread.vhd ^
../../rtl/RDP_DitherFetch.vhd ^
../../rtl/RDP_CombineColor.vhd ^
../../rtl/RDP_CombineAlpha.vhd ^
../../rtl/RDP_BlendColor.vhd ^
../../rtl/RDP_Zbuffer.vhd ^
../../rtl/RDP_DitherCalc.vhd ^
../../rtl/RDP_RGBACorrection.vhd ^
../../rtl/RDP_PerspCorr.vhd ^
../../rtl/RDP_pipeline.vhd ^
../../rtl/RDP.vhd ^
../../rtl/SDRamMux.vhd ^
../../rtl/DDR3Mux.vhd

vcom -2008 -quiet -work sim/tb ^
../system/src/tb/globals.vhd ^
../system/src/tb/ddrram_model.vhd ^
../system/src/tb/sdram_model.vhd ^
../system/src/tb/framebuffer.vhd ^
../system/src/tb/tb_savestates.vhd ^
src/tb/tb.vhd

