% PROCESSECG - Plots the raw and processed ECG signals from a HHM file.
%
% Supports both Mathworks MATLAB and GNU Octave, however performance on
% GNU Octave is notably worse.

% Close all windows, clear all variables, and clear the command window.
close all;
clear;
clc;

% Load the signal processing package if we are running under Octave. It is
% required for the BUTTER and FINDPEAKS commands.
is_octave = exist('OCTAVE_VERSION', 'builtin');
if is_octave
    pkg load signal;
end

% Load the HHM reading.
[file , directory] = uigetfile('*.hhm');
if file == 0
    return
end
filename = strcat(directory, file);
reading = hhmbinread(filename);

% Draw the raw ECG signal.
figure;
plot(reading.ecg1);
grid minor;
title('Raw ECG Signal');
xlabel('Time [ms]');
ylabel('Voltage [mV]');
legend('ECG Signal');
plot_top = max(reading.ecg1) * 1.2;
plot_bottom = min(reading.ecg1) * 1.2;
axis([0, length(reading.ecg1), plot_bottom, plot_top]);

% Detach the DC component.
ecg = reading.ecg1 - mean(reading.ecg1);

% Detect the baseline.
f_sampling = 500; % [Hz] Sampling rate of the reading.
f_baseline = 2; % [Hz] Maximal frequency of baseline movement.
[B, A] = butter(3, f_baseline / f_sampling, 'low');
baseline = filtfilt(B, A, ecg);

% Smooth the signal with a LPF, and subtract the baseline from it.
f_lpf = 25; % [Hz] Low-pass filter frequency.
[B, A] = butter(3, f_lpf / f_sampling, 'low');
ecg = filtfilt(B, A, ecg) - baseline;

% Detect the R peaks.
min_rr = 250; % [ms] Refraction time (minimum between action potentials).
min_mv = 120; % [mV] Approximate minimal R peak voltage.
if is_octave
    ecg_r_find = max(ecg, 0);
else
    ecg_r_find = ecg;
end
[~, r_peaks] = findpeaks(ecg_r_find, ...
                         'MinPeakDistance', min_rr, ...
                         'MinPeakHeight', min_mv);

% Detect P waves.
p_waves = zeros(length(r_peaks) - 2, 1);
min_pr = 100; % [ms] Approximate minimal P-R distance.
min_rt = 200; % [ms] Approximate minimal R-T distance.
for i = 2:(length(r_peaks) - 1)
    start = r_peaks(i) + min_rt;
    finish = r_peaks(i + 1) - min_pr;
    [local_min, ~] = findminmax(ecg(start:finish));
    p_waves(i - 1) = fix(local_min + start);
end

% Plot the processed ECG signal with the detected R peaks and P waves.
figure;
plot(ecg, 'b-');
hold on;
grid minor;
plot(r_peaks, ecg(r_peaks), 'rx', 'LineWidth', 5);
plot(p_waves, ecg(p_waves), 'mx', 'LineWidth', 5);
title('Processed ECG Signal');
xlabel('Time [ms]');
ylabel('Voltage [mV]');
plot_top = max(ecg) * 1.2;
plot_bottom = min(ecg) * 1.2;
axis([0, length(ecg), plot_bottom, plot_top]);
legend('ECG Signal', 'R Peaks', 'P Waves');
