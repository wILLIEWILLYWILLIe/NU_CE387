# ============================================================
# Makefile for FM Radio FPGA Simulation (Cadence Xcelium xrun)
# ============================================================
# Usage:
#   make fir         — FIR Channel Filter (I path, 20-tap)
#   make fir_lpr     — FIR L+R LPF (32-tap, decim=8)
#   make fir_bppilot — FIR BP Pilot (32-tap, decim=1)
#   make fir_bplmr   — FIR BP L-R (32-tap, decim=1)
#   make fir_hp      — FIR HP (32-tap, decim=1)
#   make fir_lmr     — FIR L-R LPF (32-tap, decim=8)
#   make demod       — FM Demodulator
#   make mult        — Multiply Pilot squaring
#   make mult_lmr    — Multiply L-R demod
#   make deemph      — De-emphasis IIR (Left)
#   make gain_test   — Gain/Volume (Left)
#   make add_sub_test— Add/Subtract (left_raw, right_raw)
#   make all         — run all testbenches
#   make clean       — remove xcelium artifacts
# ============================================================

SV_DIR  := ../sv
XFLAGS  := -sv -access +rwc -timescale 1ns/1ps -64bit
PKG         := $(SV_DIR)/fir_pkg.sv
QARCTAN_PKG := $(SV_DIR)/qarctan.sv

# Source files
FIR_SRC    := $(SV_DIR)/fir.sv
DEMOD_SRC  := $(SV_DIR)/demodulate.sv
MULT_SRC   := $(SV_DIR)/multiply.sv
DEEMPH_SRC := $(SV_DIR)/deemphasis.sv
GAIN_SRC   := $(SV_DIR)/gain.sv
ADDSUB_SRC := $(SV_DIR)/add_sub.sv
TOP_SRC    := $(SV_DIR)/fm_radio_top.sv

# Testbenches
FIR_TB         := $(SV_DIR)/fir_tb.sv
FIR_LPR_TB     := $(SV_DIR)/fir_lpr_tb.sv
FIR_BPPILOT_TB := $(SV_DIR)/fir_bppilot_tb.sv
FIR_BPLMR_TB   := $(SV_DIR)/fir_bplmr_tb.sv
FIR_HP_TB      := $(SV_DIR)/fir_hp_tb.sv
FIR_LMR_TB     := $(SV_DIR)/fir_lmr_tb.sv
DEMOD_TB       := $(SV_DIR)/demod_tb.sv
MULT_TB        := $(SV_DIR)/multiply_tb.sv
MULT_LMR_TB    := $(SV_DIR)/multiply_lmr_tb.sv
DEEMPH_TB      := $(SV_DIR)/deemphasis_tb.sv
GAIN_TB        := $(SV_DIR)/gain_tb.sv
ADDSUB_TB      := $(SV_DIR)/add_sub_tb.sv
TOP_TB         := $(SV_DIR)/fm_radio_top_tb.sv

# -------------------------------------------------------
.PHONY: all fir fir_lpr fir_bppilot fir_bplmr fir_hp fir_lmr \
        demod mult mult_lmr deemph gain_test add_sub_test top clean

all: fir fir_lpr fir_bppilot fir_bplmr fir_hp fir_lmr \
     demod mult mult_lmr deemph gain_test add_sub_test top

fir:
	xrun $(XFLAGS) $(PKG) $(FIR_SRC) $(FIR_TB)

fir_lpr:
	xrun $(XFLAGS) $(PKG) $(FIR_SRC) $(FIR_LPR_TB)

fir_bppilot:
	xrun $(XFLAGS) $(PKG) $(FIR_SRC) $(FIR_BPPILOT_TB)

fir_bplmr:
	xrun $(XFLAGS) $(PKG) $(FIR_SRC) $(FIR_BPLMR_TB)

fir_hp:
	xrun $(XFLAGS) $(PKG) $(FIR_SRC) $(FIR_HP_TB)

fir_lmr:
	xrun $(XFLAGS) $(PKG) $(FIR_SRC) $(FIR_LMR_TB)

demod:
	xrun $(XFLAGS) $(PKG) $(QARCTAN_PKG) $(DEMOD_SRC) $(DEMOD_TB)

mult:
	xrun $(XFLAGS) $(PKG) $(MULT_SRC) $(MULT_TB)

mult_lmr:
	xrun $(XFLAGS) $(PKG) $(MULT_SRC) $(MULT_LMR_TB)

deemph:
	xrun $(XFLAGS) $(PKG) $(DEEMPH_SRC) $(DEEMPH_TB)

gain_test:
	xrun $(XFLAGS) $(PKG) $(GAIN_SRC) $(GAIN_TB)

add_sub_test:
	xrun $(XFLAGS) $(PKG) $(ADDSUB_SRC) $(ADDSUB_TB)

top:
	xrun $(XFLAGS) $(PKG) $(QARCTAN_PKG) $(FIR_SRC) $(DEMOD_SRC) $(MULT_SRC) $(DEEMPH_SRC) $(GAIN_SRC) $(ADDSUB_SRC) $(TOP_SRC) $(TOP_TB)

# GUI
fir_gui:
	xrun $(XFLAGS) -gui $(PKG) $(FIR_SRC) $(FIR_TB)

demod_gui:
	xrun $(XFLAGS) -gui $(PKG) $(QARCTAN_PKG) $(DEMOD_SRC) $(DEMOD_TB)

clean:
	rm -rf xcelium.d INCA_libs xrun.log xrun.history waves.shm *.key
	@echo "Cleaned."
