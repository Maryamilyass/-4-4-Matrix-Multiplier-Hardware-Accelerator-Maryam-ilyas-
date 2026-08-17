# ModelSim/QuestaSim targets
VLOG ?= vlog
VSIM ?= vsim

VLOG_FLAGS = -sv -work work

.PHONY: all compile sim overflow clean

all: sim overflow

compile:
	vlib work
	$(VLOG) $(VLOG_FLAGS) src/matmul4x4_accel.sv verif/tb_matmul4x4_accel.sv verif/tb_overflow.sv

sim: compile
	$(VSIM) -c -do "run -all; quit -f" work.tb_matmul4x4_accel

overflow: compile
	$(VSIM) -c -do "run -all; quit -f" work.tb_overflow

clean:
	rm -rf work transcript vsim.wlf *.log
