PROJ = 01-BUTTONS
PIN_DEF = pins.pcf
DEVICE = up5k

ICEPACK = icepack
ICETIME = icetime
ICEPROG = iceprog

SOURCE = my_top.v spi.v

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


.SECONDARY:
.PHONY: all prog clean
