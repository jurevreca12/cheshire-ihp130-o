# Copyright (c) 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author:  Philippe Sauter <phsauter@student.ethz.ch>

TECH_CELLS 	?= $(TECH_DIR)/sg13g2_stedwardell_typ_1p20V_25C.lib
TECH_MACROS	?= $(addprefix $(TECH_DIR)/,RM_IHPSG13_1P_64x64_c2_bm_bist_tc_1d20V_25C.lib \
										RM_IHPSG13_1P_256x64_c2_bm_bist_tc_1d20V_25C.lib \
										RM_IHPSG13_1P_1024x64_c2_bm_bist_tc_1d20V_25C.lib \
										plankton_typ_1p2V_3p3V_25C.lib) \
				$(IC_ROOT)/delay_line/generic_delay_D4_O1_3P000_CG0_mid.lib

TECH_CELL_TIEHI_CELL	:= sg13g2_tiehi
TECH_CELL_TIEHI_PIN 	:= L_HI
TECH_CELL_TIEHI 		:= $(TECH_CELL_TIEHI_CELL) $(TECH_CELL_TIEHI_PIN)

TECH_CELL_TIELO_CELL	:= sg13g2_tielo
TECH_CELL_TIELO_PIN 	:= L_LO
TECH_CELL_TIELO 		:= $(TECH_CELL_TIELO_CELL) $(TECH_CELL_TIELO_PIN)