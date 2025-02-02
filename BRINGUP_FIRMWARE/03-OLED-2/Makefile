PROJ = 03-OLED-2
PIN_DEF = pins.pcf
DEVICE = up5k

ICEPACK = icepack
ICETIME = icetime
ICEPROG = iceprog

SOURCE = my_top.v oled.v

SRCDIR=../../src


all: $(PROJ).bin

$(PROJ).json: $(SOURCE)
	yosys -p 'debug synth_ice40 -dsp -top my_top -json $@' $(SOURCE)

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --timing-allow-fail --randomize-seed --freq 25.125 --up5k --json $(PROJ).json --pcf $(PIN_DEF) --asc $@

%.bin: %.asc
	$(ICEPACK) $< $@

%.rpt: %.asc
	$(ICETIME) -d $(DEVICE) -mtr $@ $<

prog: $(PROJ).bin
	$(ICEPROG) -S $<
	#$(ICEPROG) $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo $(ICEPROG) -S $<

clean:
	rm -f $(PROJ).blif $(PROJ).json $(PROJ).asc $(PROJ).rpt $(PROJ).bin


IVERILOG_RUN=@iverilog -g2012 -pfileline=1  -grelative-include -o $(PROJECT)_design -D SIM -Winfloop tb.v oled.v &&        \
                         vvp   -n $(PROJECT)_design

sim: $(SOURCE) tb.v
	$(IVERILOG_RUN)

dump.vcd: $(SOURCE) tb.v
	$(IVERILOG_RUN)

view: dump.vcd config.gtkw
	gtkwave   dump.vcd config.gtkw

.SECONDARY:
.PHONY: all prog clean
