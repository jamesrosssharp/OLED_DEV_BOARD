02-OLED
=======

- Implement a simple SPI core to pass through commands to OLED

Command format from host to iCE40:

| 15 - 11 | 10    | 9   | 8  | 7 - 0 |
--------------------------------------
|   x     | RES# | C#/D | 0  | <data>|

Upper byte sets control lines, lower byte is transmitted
