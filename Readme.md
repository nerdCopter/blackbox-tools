# Blackbox flight data recorder decoder

[![Build](https://img.shields.io/github/actions/workflow/status/betaflight/blackbox-tools/nightly.yml?branch=master)](https://github.com/betaflight/blackbox-tools/actions/workflows/nightly.yml) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## Introduction

This tool allows you to convert flight data logs recorded by Cleanflight's Blackbox feature into CSV files (comma-separated values) for analysis.

You can download the latest executable versions of this tool for Mac or Windows from the "releases" tab above. If you're running Linux, you must build the tool from source (instructions are further down this page).

## Using the blackbox_decode tool

This tool converts a flight log binary ".TXT" file into CSV format. Typical usage (from the command line) would be like:

```bash
blackbox_decode LOG00001.TXT
```

That'll decode the log to `LOG00001.01.csv` and print out some statistics about the log. If you're using Windows, you can drag and drop your log files onto `blackbox_decode` and they'll all be decoded.

If your log file contains GPS data then a ".gpx" file will also be produced. This file can be opened in Google Earth or some other GPS mapping software for analysis. This feature is experimental.

Use the `--help` option to show more details:

```text
Blackbox flight log decoder by Nicholas Sherlock

Usage:
     blackbox_decode [options] <input logs>

Options:
   --help                   This page
   --index <num>            Choose the log from the file that should be decoded (or omit to decode all)
   --limits                 Print the limits and range of each field
   --stdout                 Write log to stdout instead of to a file
   --unit-amperage <unit>   Current meter unit (raw|mA|A), default is A (amps)
   --unit-frame-time <unit> Frame timestamp unit (us|s), default is us (microseconds)
   --unit-height <unit>     Height unit (m|cm|ft), default is cm (centimeters)
   --unit-rotation <unit>   Rate of rotation unit (raw|deg/s|rad/s), default is raw
   --unit-acceleration <u>  Acceleration unit (raw|g|m/s2), default is raw
   --unit-gps-speed <unit>  GPS speed unit (mps|kph|mph), default is mps (meters per second)
   --unit-vbat <unit>       Vbat unit (raw|mV|V), default is V (volts)
   --merge-gps              Merge GPS data into the main CSV log file instead of writing it separately
   --simulate-current-meter Simulate a virtual current meter using throttle data
   --sim-current-meter-scale   Override the FC's settings for the current meter simulation
   --sim-current-meter-offset  Override the FC's settings for the current meter simulation
   --simulate-imu           Compute tilt/roll/heading fields from gyro/accel/mag data
   --imu-ignore-mag         Ignore magnetometer data when computing heading
   --declination <val>      Set magnetic declination in degrees.minutes format (e.g. -12.58 for New York)
   --declination-dec <val>  Set magnetic declination in decimal degrees (e.g. -12.97 for New York)
   --debug                  Show extra debugging information
   --raw                    Don't apply predictions to fields (show raw field deltas)
```

## Building the tool
If you just want to download some prebuilt versions of these tools, head to the "releases" tab on the GitHub page. However, if you want to build your own binaries, or you're on Linux where we haven't provided binaries, please read on.

The `blackbox_decode` tool for turning binary flight logs into CSV doesn't depend on any libraries, so can be built by running `make obj/blackbox_decode`. You can add the resulting `obj/blackbox_decode` program to your system path to make it easier to run.

#### Ubuntu
You can get the tools required for building by entering these commands into the terminal:

```bash
sudo apt-get update
sudo apt-get install make gcc
```

Build blackbox_decode by running `make obj/blackbox_decode` (or build the tool by just running `make`).

#### MacOSX
The easiest way to build is to install the [Xcode development tool][], then install an environment like [Homebrew][] or [MacPorts][] onto your system.

Afterwards you can run `make` to build blackbox_decode.

[Xcode development tool]: https://itunes.apple.com/us/app/xcode/id497799835
[Homebrew]: http://brew.sh/
[MacPorts]: https://www.macports.org/

#### Windows
The tools can be built with Visual Studio Express 2013, just open up the solution in the `visual-studio/` folder.

## License

This project is licensed under GPLv3.

Both binary and source builds include IMU code from Baseflight https://github.com/multiwii/baseflight (GPLv3)