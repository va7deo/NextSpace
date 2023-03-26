
# SNK68000 The Next Space FPGA Implementation

FPGA compatible core of SNK's The Next Space (A8004 based) arcade hardware for [**MiSTerFPGA**](https://github.com/MiSTer-devel/Main_MiSTer/wiki) written by [**Darren Olafson**](https://twitter.com/Darren__O) and verified against and authentic The Next Space (A8004-1) PCB purchased by [**atrac17**](https://github.com/atrac17).

The intent is for this core to be a 1:1 playable implementation of The Next Space (A8004-1) arcade hardware. Currently in **beta state**, this core is in active development with assistance from [**atrac17**](https://github.com/atrac17).

<br>
<p align="center">
<img width="" height="" src="FILLME">
</p>

## Supported Games

| Title | PCB<br>Number | Status  | Released |
|-------|---------------|---------|----------|
| [**The Next Space**](https://en.wikipedia.org/wiki/Gang_Wars_(video_game)) | A8004-1 (TNS)      | Implemented | **Yes** |
| [**Paddle Mania**](https://snk.fandom.com/wiki/Super_Champion_Baseball)    | ALPHA68K-96-I (PM) | Implemented | **Yes** |

## External Modules

|Name| Purpose | Author |
|----|---------|--------|
| [**fx68k**](https://github.com/ijor/fx68k)                      | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Jorge Cwik     |
| [**t80**](https://opencores.org/projects/t80)                   | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)           | Daniel Wallner |
| [**jtopl2**](https://github.com/jotego/jtopl)                   | [**Yamaha OPL 2**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)      | Jose Tejada    |
| [**yc_out**](https://github.com/MikeS11/MiSTerFPGA_YC_Encoder)  | [**Y/C Video Module**](https://en.wikipedia.org/wiki/S-Video)          | Mike Simone    |

# Known Issues / Tasks

W.I.P

# PCB Check List

### Clock Information

H-Sync      | V-Sync      | Source           | PCB<br>Number  |
------------|-------------|------------------|----------------|
15.625kHz   | 59.185606Hz | [**AD**](FILLME) | A8004-1 (TNS)  |

### Crystal Oscillators

Location        | PCB<br>Number | Freq (MHz) | Use          |
|---------------|---------------|------------|--------------|
24MHz           | A8004-1 (TNS) | 24.000     |              |
4MHz            | A8004-1 (TNS) | 4.000      |              |
18MHz           | A8004-1 (TNS) | 18.000     |              |

**Pixel clock:** 6.00 MHz

**Estimated geometry:**

    383 pixels/line
  
    263 pixels/line

### Main Components

Location | PCB<br>Number | Chip | Use |
---------|---------------|------|-----|
15-L     | A8004-1 (TNS)  | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Main CPU  |
Z80A     | A8004-1 (TNS)  | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)           | Sound CPU |
YM3812   | A8004-1 (TNS)  | [**Yamaha YM3812**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)     | OPL-2     |

### Custom Components

Location | PCB<br>Number | Chip | Use |
---------|---------------|------|-----|
SNKCLK   | A8004-1 (TNS) | [**SNK CLK**](https://github.com/va7deo/alpha68k/blob/main/doc/ALPHA-68K96V/ALPHA68K-96V_Schematics.pdf) | Counter |
SNK I/O  | A8004-1 (TNS) | [**SNK I/O**](https://github.com/va7deo/SNK68/blob/main/doc/Custom%20Components/SNK_IO.jpg)              | Controls |

# Core Features

### Native Y/C Output

- Native Y/C ouput is possible with the [**analog I/O rev 6.1 pcb**](https://github.com/MiSTer-devel/Main_MiSTer/wiki/IO-Board). Using the following cables, [**HD-15 to BNC cable**](https://www.amazon.com/StarTech-com-Coax-RGBHV-Monitor-Cable/dp/B0033AF5Y0/) will transmit Y/C over the green and red lines. Choose an appropriate adapter to feed [**Y/C (S-Video)**](https://www.amazon.com/MEIRIYFA-Splitter-Extension-Monitors-Transmission/dp/B09N19XZJQ) to your display.

### H/V Adjustments

- There are two H/V toggles, H/V-sync positioning adjust and H/V-sync width adjust. Positioning will move the display for centering on CRT display. The sync width adjust can be used to for sync issues (rolling) without modifying the video timings.

### Scandoubler Options

- Additional toggle to enable the scandoubler without changing ini settings and new scanline option for 100% is available, this draws a black line every other frame. Below is an example.

<table><tr><th>Scandoubler Fx</th><th>Scanlines 25%</th><th>Scanlines 50%</th><th>Scanlines 75%</th><th>Scanlines 100%</th><tr><td><br> <p align="center"><img width="128" height="112" src="FILLME"></td><td><br> <p align="center"><img width="128" height="112" src="FILLME"></td><td><br> <p align="center"><img width="128" height="112" src="FILLME"></td><td><br> <p align="center"><img width="128" height="112" src="FILLME"></td><td><br> <p align="center"><img width="128" height="112" src="FILLME"></td></tr></table>

# Controls

- The service menu is accessed by toggling a dipswitch for all supported titles. Paddle Mania supports co-op two player versus the CPU opponents or up to four player versus.

<br>

<table><tr><th>Game</th><th>Joystick</th><th>Service Menu</th><th>Control Type</th></tr><tr><td><p align="center">Gang Wars</p></td><td><p align="center">8-Way</p></td><td><p align="center"><br><img width="128" height="112" src="FILLME"></td><td><p align="center">Co-Op</td><tr><td><p align="center">Paddle<br>Mania</p></td><td><p align="center">8-Way</p></td><td><p align="center"><br><img width="128" height="112" src="FILLME"></td><td><p align="center">Co-Op / VS</td></table>

<br>
<br>

### Keyboard Handler

- Keyboard inputs mapped to mame defaults for the following functions. Player 3 and Player 4 input keys are not mapped, only Player 3 / Player 4 start buttons.

<br>

|Services|Coin/Start|
|--|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>Test</td><td>F2</td></tr><tr><td>Reset</td><td>F3</td></tr><tr><td>Service</td><td>9</td></tr><tr><td>Pause</td><td>P</td></tr> </table> | <table><tr><th>Functions</th><th>Keymap</th><tr><tr><td>P1 Start</td><td>1</td></tr><tr><td>P2 Start</td><td>2</td></tr><tr><td>P1 Coin</td><td>5</td></tr><tr><td>P2 Coin</td><td>6</td></tr> </table>|

|Player 1|Player 2|
|--|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P1 Up</td><td>Up</td></tr><tr><td>P1 Down</td><td>Down</td></tr><tr><td>P1 Left</td><td>Left</td></tr><tr><td>P1 Right</td><td>Right</td></tr><tr><td>P1 Bttn 1</td><td>L-Ctrl</td></tr><tr><td>P1 Bttn 2</td><td>L-Alt</td></tr><tr><td>P1 Bttn 3</td><td>Space</td></tr> </table> | <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P2 Up</td><td>R</td></tr><tr><td>P2 Down</td><td>F</td></tr><tr><td>P2 Left</td><td>D</td></tr><tr><td>P2 Right</td><td>G</td></tr><tr><td>P2 Bttn 1</td><td>A</td></tr><tr><td>P2 Bttn 2</td><td>S</td></tr><tr><td>P2 Bttn 3</td><td>Q</td></tr> </table>|

|Player 3|Player 4|
|--|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P3 Bttn 1</td><td>**N/A**</td></tr><tr><td>P3 Bttn 2</td><td>**N/A**</td></tr><tr><td>P3 Bttn 3</td><td>**N/A**</td></tr><tr><td>P3 Start</td><td>3</td></tr> </table> | <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P4 Bttn 1</td><td>**N/A**</td></tr><tr><td>P4 Bttn 2</td><td>**N/A**</td></tr><tr><td>P4 Bttn 3</td><td>**N/A**</td></tr><tr><td>P4 Start</td><td>4</td></tr> </table>|

# Support

Please consider showing support for this and future projects via [**Darren's Ko-fi**](https://ko-fi.com/darreno) and [**atrac17's Patreon**](https://www.patreon.com/atrac17). While it isn't necessary, it's greatly appreciated.

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.
