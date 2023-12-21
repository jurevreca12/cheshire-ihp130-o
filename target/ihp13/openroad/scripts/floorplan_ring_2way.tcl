# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Authors:
# - Tobias Senti <tsenti@ethz.ch>
# - Jannis Schönleber <janniss@iis.ee.ethz.ch>
# - Philippe Sauter   <phsauter@ethz.ch>

# Floorplanning stage of the chip
# Macros mostly at the bottom and top with a few on the sides
# aranged to leave a large roughly circular center for logic

puts "Floorplan: Ring (2-way cache config)"

##########################################################################
# Mark all macros as unplaced
##########################################################################

set block [ord::get_db_block]
set insts [odb::dbBlock_getInsts $block]
foreach inst $insts {
  odb::dbInst_setPlacementStatus $inst "none"
}

##########################################################################
# RAM size
##########################################################################
# RM_IHPSG13_1P_1024x64_c2_bm_bist
# only for axi_llc_data_ways data macro
# set RamSize1024   [dbCellDim [dbInstCellName [dbGetInstByName $axi_data_0_high ]]]
set RamSize1024x64_W 784.48
set RamSize1024x64_H 336.46

# RM_IHPSG13_1P_256x64_c2_bm_bist
# all other macros
# set RamSize256   [dbCellDim [dbInstCellName [dbGetInstByName $cva6_icache_tag_0_low ]]]
set RamSize256x64_W 784.48
set RamSize256x64_H 118.78

set RamSize256x48_W 596.48
set RamSize256x48_H 118.78

set RamSize512x64_W 784.48
set RamSize512x64_H 191.34

set RamSize2048x64_W 784.48
set RamSize2048x64_H 626.7


##########################################################################
# Chip sizes and margins
##########################################################################
set chipW            6250.0
set chipH            5498.0
# thickness of annular ring for pads
set padMargin         310.0

# thickness of annular ring for power-ring
set floorMargin       110.0
# extra keepout annular ring inside floor (only applies to macros!)
set floorPaddingX       2.0
set floorPaddingY       5.0

set coreMargin        [expr $padMargin + $floorMargin]


# minimum macro-to-macro distance
set macroMargin        20.0
# halo around each macro
set haloBlockL         10.0
set haloBlockR         10.0
set haloBlockB         10.0
set haloBlockT         10.0

set floor_leftX       [expr $coreMargin + $floorPaddingX]
set floor_bottomY     [expr $coreMargin + $floorPaddingY]
set floor_rightX      [expr $chipW - $coreMargin - $floorPaddingX]
set floor_topY        [expr $chipH - $coreMargin - $floorPaddingY]
set floor_midpointX   [expr $floor_leftX + ($floor_rightX - $floor_leftX)/2]
set floor_midpointY   [expr $floor_bottomY + ($floor_topY - $floor_bottomY)/2]


##########################################################################
# Chip and Core Area
##########################################################################

puts "Rotated Floorplan"
initialize_floorplan -die_area "0 0 $chipW $chipH" \
                     -core_area "$coreMargin $coreMargin [expr $chipW-$coreMargin] [expr $chipH-$coreMargin]" \
                     -sites "CoreSite"
# ToDo: get sites from stdcell lef as union of all regex-matches "^\s*SITE\s+([0-9a-zA-Z_]+)\s*;\s*$"

##########################################################################
# Tracks 
##########################################################################
puts "Metal Tracks"
make_tracks Metal1    -x_offset 0 -x_pitch 0.48 -y_offset 0 -y_pitch 0.42
make_tracks Metal2    -x_offset 0 -x_pitch 0.48 -y_offset 0 -y_pitch 0.42
make_tracks Metal3    -x_offset 0 -x_pitch 0.48 -y_offset 0 -y_pitch 0.42
make_tracks Metal4    -x_offset 0 -x_pitch 0.48 -y_offset 0 -y_pitch 0.42
make_tracks Metal5    -x_offset 0 -x_pitch 0.48 -y_offset 0 -y_pitch 0.42
make_tracks TopMetal1 -x_offset 1.64 -x_pitch 3.28 -y_offset 1.64 -y_pitch 3.28
make_tracks TopMetal2 -x_offset 2.00 -x_pitch 4.00 -y_offset 2.00 -y_pitch 4.00


##########################################################################
# Pads/IOs 
##########################################################################
source src/basilisk_io.tcl


##########################################################################
# Placing macros
##########################################################################
source scripts/floorplan_util.tcl


##########################################################################
# Macro paths
##########################################################################
puts "Macro Names"
source scripts/macros_2way.tcl

##########################################################################
# Placing 
##########################################################################
puts "Place Macros"
# routing channels between groups of side-by-side macros
set channelX   40.0
# routing channels between groups of macros on-top of eachother
# used to seperate the tags from the data caches
set channelY 1000.0

##########################################################################
# Place axi_llc_data_ways data macro
##########################################################################
# First group placed in top-left corner

# LLC Way-0
set X [expr $floor_leftX]
set Y [expr $floor_topY - $RamSize2048x64_H]
placeInstance $axi_data_0 $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $axi_data_0

# LLC Way-1
set X [expr $X + $RamSize2048x64_W + $channelX]
set Y [expr $floor_topY - $RamSize2048x64_H]
placeInstance $axi_data_1 $X $Y R0
addHaloToBlock $channelX $haloBlockB $haloBlockR $haloBlockT $axi_data_1

add_macro_blockage 0 $axi_data_0 $axi_data_1

# Second group placed in top-right corner

# LLC Way-3
set X [expr $floor_rightX - $RamSize2048x64_W]
set Y [expr $floor_topY - $RamSize2048x64_H]
placeInstance $axi_data_3 $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $axi_data_3

# LLC Way-2
set X [expr $X - $RamSize2048x64_W - $channelX]
set Y [expr $floor_topY - $RamSize2048x64_H]
placeInstance $axi_data_2 $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $channelX $haloBlockT $axi_data_2

add_macro_blockage 0 $axi_data_2 $axi_data_3

##########################################################################
# Place axi_llc_hit_miss_unit tag macro
##########################################################################
# Tags go in the top-middle

# left column
# axi_hitmiss_tag_0
set X [expr $floor_leftX + 2*$channelX + 2*$RamSize2048x64_W]
set Y [expr $floor_topY - $RamSize256x48_H]
placeInstance $axi_hitmiss_tag_0 $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $axi_hitmiss_tag_0

# axi_hitmiss_tag_1
set X [expr $X ]
set Y [expr $Y - $macroMargin - $RamSize256x48_H]
placeInstance $axi_hitmiss_tag_1 $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $axi_hitmiss_tag_1

# right column
# axi_hitmiss_tag_2
set X [expr $floor_rightX - 2*$channelX - 2*$RamSize2048x64_W - $RamSize256x48_W]
set Y [expr $floor_topY - $RamSize256x48_H]
placeInstance $axi_hitmiss_tag_2 $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $axi_hitmiss_tag_2

# axi_hitmiss_tag_3
set X [expr $X ]
set Y [expr $Y - $macroMargin - $RamSize256x48_H]
placeInstance $axi_hitmiss_tag_3 $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $axi_hitmiss_tag_3



# ##########################################################################
# Place data sram 
# ########################################################################## 
# L1-Data cache goes into the bottom-left corner

# cva6_wt_dcache_data_1_high
set X [expr $floor_leftX]
set Y [expr $floor_bottomY]
placeInstance $cva6_wt_dcache_data_1_high $X $Y R180
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $cva6_wt_dcache_data_1_high


# cva6_wt_dcache_data_0_high
set X [expr $X]
set Y [expr $Y + $macroMargin + $RamSize512x64_H]
placeInstance $cva6_wt_dcache_data_0_high $X $Y R180
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $cva6_wt_dcache_data_0_high


# cva6_wt_dcache_data_1_low
set X [expr $X + $RamSize512x64_W + $channelX]
set Y [expr $floor_bottomY]
placeInstance $cva6_wt_dcache_data_1_low $X $Y R180
addHaloToBlock $channelX $haloBlockB $haloBlockR $haloBlockT $cva6_wt_dcache_data_1_low

# cva6_wt_dcache_data_0_low
set X [expr $X]
set Y [expr $Y + $macroMargin + $RamSize512x64_H]
placeInstance $cva6_wt_dcache_data_0_low $X $Y R180
addHaloToBlock $channelX $haloBlockB $haloBlockR $haloBlockT $cva6_wt_dcache_data_0_low

add_macro_blockage 0 $cva6_wt_dcache_data_1_high $cva6_wt_dcache_data_0_low

##########################################################################
# Place cva6_wt_dcache_tag
##########################################################################
# L1 Data tags go in bottom-left, above the data

# cva6_wt_dcache_tag_1_low
set X [expr $X + $RamSize512x64_W + $channelX]
set Y [expr $floor_bottomY]
placeInstance $cva6_wt_dcache_tag_1_low $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $cva6_wt_dcache_tag_1_low

# cva6_wt_dcache_tag_1_high
set X [expr $X ]
set Y [expr $Y + $macroMargin + $RamSize256x48_H]
placeInstance $cva6_wt_dcache_tag_1_high $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $cva6_wt_dcache_tag_1_high

# cva6_wt_dcache_tag_0_low
set X [expr $X ]
set Y [expr $Y + $macroMargin + $RamSize256x48_H]
placeInstance $cva6_wt_dcache_tag_0_low $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $cva6_wt_dcache_tag_0_low

# cva6_wt_dcache_tag_0_high
set X [expr $X ]
set Y [expr $Y + $macroMargin + $RamSize256x48_H]
placeInstance $cva6_wt_dcache_tag_0_high $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $cva6_wt_dcache_tag_0_high


##########################################################################
# Place cva6_icache_data
##########################################################################
# L1-Instruction cache goes into the bottom-right corner

# cva6_icache_data_3_high
set X [expr $floor_rightX - $RamSize512x64_W]
set Y [expr $floor_bottomY]
placeInstance $cva6_icache_data_1_high $X $Y R180
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $cva6_icache_data_1_high

# cva6_icache_data_0_high
set X [expr $X ]
set Y [expr $Y + $macroMargin + $RamSize512x64_H]
placeInstance $cva6_icache_data_0_high $X $Y R180
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $cva6_icache_data_0_high

# cva6_icache_data_3_low
set X [expr $X - $RamSize512x64_W - $channelX]
set Y [expr $floor_bottomY]
placeInstance $cva6_icache_data_1_low $X $Y R180
addHaloToBlock $haloBlockL $haloBlockB $channelX $haloBlockT $cva6_icache_data_1_low

# cva6_icache_data_0_low
set X [expr $X ]
set Y [expr $Y + $macroMargin + $RamSize512x64_H]
placeInstance $cva6_icache_data_0_low $X $Y R180
addHaloToBlock $haloBlockL $haloBlockB $channelX $haloBlockT $cva6_icache_data_0_low

add_macro_blockage $macroMargin $cva6_icache_data_1_low $cva6_icache_data_0_high

##########################################################################
# Place cva6_icache_tag
##########################################################################
# L1 Instruction tags go in bottom-right, above the data

# cva6_icache_tag_0_low
set X [expr $X - $RamSize256x48_W - $channelX]
set Y [expr $floor_bottomY]
placeInstance $cva6_icache_tag_0_low $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $cva6_icache_tag_0_low

# cva6_icache_tag_0_high
set X [expr $X ]
set Y [expr $Y + $macroMargin + $RamSize256x48_H]
placeInstance $cva6_icache_tag_0_high $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $cva6_icache_tag_0_high

# cva6_icache_tag_1_low
set X [expr $X ]
set Y [expr $Y + $macroMargin + $RamSize256x48_H]
placeInstance $cva6_icache_tag_1_low $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $cva6_icache_tag_1_low

# cva6_icache_tag_1_high
set X [expr $X ]
set Y [expr $Y + $macroMargin + $RamSize256x48_H]
placeInstance $cva6_icache_tag_1_high $X $Y R0
addHaloToBlock $haloBlockL $haloBlockB $haloBlockR $haloBlockT $cva6_icache_tag_1_high

# the blockages on-top of the macro blocks do not remove the std-cell rows between them
# when using pdngen, so we cut them manually with an extra X-halo
cut_rows -halo_width_y 10 -halo_width_x 20


##########################################################################
# Place delay lines
##########################################################################
# delay lines after cut since they are essentially multi-row standard cells

if { ![info exists ::env(HYPER_CONF)] || $::env(HYPER_CONF) ne "NO_HYPERBUS"} {
  set X [expr $coreMargin]
  # 420u to core bottom, 8 tracks further in is first power stripe, 785 cell-rows above first
  placeInstance $delay_line_rx $X [expr $coreMargin + 8*0.42 + 3.78*785] R0

  placeInstance $delay_line_tx $X [expr $coreMargin + 8*0.42 + 3.78*800] R0
}