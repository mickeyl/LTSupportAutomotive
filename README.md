# Introduction #

**LTSupportAutomotive** is a library for writing apps that communicate with vehicles using **OBD2** adapters. It also contains auxilliary classes, such as a *VIN decoder*, and a *BTLE characteristic(s) / `NSStream`* serial bridge.

Here is an overview of the most important classes:

### `LTOBD2Adapter` (abstract) ###

Represents an OBD2 adapter sending commands over input- and output-streams using a certain vehicle protocol. Concrete subclasses (e.g., `LBOBD2AdapterELM327` for ELM327-compatible chipsets, or `LTOBD2AdapterCaptureFile` for capture files) are available.

### `LTOBD2Command` (abstract) ###

Represents an OBD2 command. Concrete subclasses, e.g. for the well-known OBD2 PIDs are available.

### `LTOBD2Protocol` (abstract) ###

Represents a generic vehicle protocol. Concrete subclasses for protocols such as ISO14230-4 (CAN), ISO15765-4, ISO9141-2, or SAEJ1850 are available.

### `LTBTLESerialTransporter` ###

Represents a bridge between one or two BTLE characteristics and NSStream subclasses.

# How to use LTSupportAutomotive #

### CococaPods ###

Add this framework to your podfile:
```
pod 'LTSupportAutomotive', '~> 1.0'
```

### Carthage ###

If anyone wants to make this *carthage* aware, feel free to supply a pull request. I'm not using this package manager myself.

### Xcode subproject ###

You can also include LTSupportAutomotive as an Xcode subproject and link `LTSupportAutomotive.framework` to your executable.

# Examples #

`LTAutomotiveSupportDemo.xcodeproj` is a (pretty bare-bones) example project.

# Apps using this library #

* [OBD2 Expert](https://itunes.apple.com/de/app/cargo-objects-street-assistant/id1142156521?mt=8) (yours truly)
* [Cargo Objects Street Assistant](https://itunes.apple.com/de/app/cargo-objects-street-assistant/id1092020114?mt=8) (LAWA-Solutions GmbH)

Please drop us a note, if you are using this library as well.

# Supported Hardware #

This software should work with most ELM327-compatible hardware (including the behemoth of available *clones*). In general, I recommend the Bluetooth 4.0 devices, since they seems to have a much better quality compared to the WiFi adapters. Moreover, they're much more convenient as you don't have to switch the WiFi network. Note that since iOS is lacking the Bluetooth `rfcomm` protocol, this library will **not** work with Bluetooth 3.0 adapters.

I have tested this library myself with the following adapters (Note that none of these contain a *real* ELM327):

### BTLE (aka BLE, BluetoothSmart, or BT 4.0) ###
* Carista Bluetooth OBD2
* LELink Bluetooth Low Energy
* VGate iCar Pro BLE4.0 Dual

### WiFi ###
* NAVISKAUTO WIFI WLAN ELM327
* EXZA® SUPER Mini WiFi WLAN OBD 2

# Enhancements #

While this library can already be used for a lot of things, I'd like to see improvements in a bunch of areas, such as:

* Translations (I only have DE and EN atm.),
* Implementation of missing standardized PIDs,
* Addition of vendor-specific DTCs,
* Implementation of vendor-specific PIDs,
* Implementation of non-PID/direct communication with ECUs.

# How to contribute #

Please fork and open a pull-request. I'd also like to know about success stories or confirmation for additional compatible hardware (see above) working with this library.

# Thanks #

* LAWA Solutions GmbH
* Thomas Dankert

# License #

Copyright (c) 2016-2018 Dr. Michael 'Mickey' Lauer

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in the documentation of any redistributions of the template files themselves (but not in projects built using the templates).

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.