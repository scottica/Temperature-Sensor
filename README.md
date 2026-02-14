# Embedded Temperature Monitor & Live MATLAB Data Logger

## 📌 Overview
A real-time environmental monitoring system built in 8051 Assembly and MATLAB. This project interfaces with an analog LM335 temperature sensor, processes the data into Celsius values using a custom 32-bit integer math library, and outputs the data to an onboard LCD and a connected PC via RS-232 serial communication. A custom MATLAB script dynamically visualizes this serial data stream as a real-time strip chart.

## ✨ Key Features
* **Live Data Visualization (MATLAB):** Implemented a custom MATLAB `StripChart` function to capture the RS-232 serial stream and plot the temperature data dynamically, creating a real-time oscilloscope-like view of the thermal environment. 
* **12-bit Analog-to-Digital Conversion (ADC):** Accurately samples the ambient temperature voltage from the LM335 sensor using the N76E003's internal 12-bit SAR ADC. The sensor natively outputs +10mV/°K.
* **RS-232 Serial Communication:** Configured the microcontroller's Timer 1 to establish a 115200-baud asynchronous serial connection for continuous data logging to the host computer.
* **Custom 32-bit Math Library:** To avoid the massive overhead of floating-point operations on an 8-bit architecture, I integrated a custom 32-bit unsigned arithmetic library (`add32`, `sub32`, `mul32`, `div32`) to calculate the exact Celsius temperature natively using scaled integers.
* **Interactive UI & Alarm System:** Features a 3-mode hardware state machine allowing the user to view the live temperature, set an upper thermal alarm limit (triggering a physical LED warning), and track the maximum recorded temperature.

## ⚙️ Technical Implementation
* **Languages:** 8051 Assembly (Firmware), MATLAB (Host Software).
* **Hardware:** N76E003 Microcontroller, LM335 Precision Temperature Sensor, 16x2 Character LCD, Pushbuttons.
* **Math Logic:** The ADC voltage is converted to Celsius by scaling the 12-bit reading against a 5.0V reference, calculating the Kelvin value, and subtracting 27300 (273°K scaled by 100) using purely 32-bit integer operations. 

## 🚀 Usage
### Microcontroller Setup
1. Flash the compiled `.asm` code to the N76E003 microcontroller.
2. Ensure the LM335 sensor is connected to ADC input pin `P1.1`.
3. Connect the microcontroller's TX/RX lines to a PC using a serial-to-USB adapter.

### MATLAB Host Setup
1. Open MATLAB and ensure the serial port is configured to match your USB adapter at `115200` baud.
2. Run the `StripChart('Initialize', gca, 'Time')` command to prepare the plot window.
3. In a continuous loop reading from the serial port, call `StripChart('Update', hLine, yData)` passing the parsed serial temperature values to watch the live graph update!
