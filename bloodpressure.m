% BLOODPRESSURE - Calculates blood pressure based on the PPG signal.
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

% Load the signal processing package if we are running under Octave. It is
% required for the BUTTER and FINDPEAKS commands.
is_octave = exist('OCTAVE_VERSION', 'builtin');
if is_octave
    pkg load signal;
end

% Load the HHM reading.
[file , directory] = uigetfile('*.hhm', 'processecg');
if file == 0
    return
end
filename = strcat(directory, file);
reading = hhmbinread(filename, 2);

% Filter the baseline from the PPG signal (left hand, infrared light).
f_sampling = 500; % [Hz] Sampling rate of the reading.
f_baseline = 2; % [Hz] Maximal frequency of the baseline.
[B, A] = butter(3, f_baseline / f_sampling, 'high');
ppg = filtfilt(B, A, reading.ppgl_nir);

% Filter the periodic noise from the cuff pump motor.
f_pumpmotor = 3; % [Hz] Frequency of the cuff pump motor.
[B, A] = butter(3, f_pumpmotor / f_sampling, 'low');
pressure = filtfilt(B, A, reading.press);

% Find the point where waves practically disappear.
d_minimal = 100; % [AU] PPG difference under which it is considered flat.
t_interval = 1000; % [ms] The length of each period to check.
t_systolic = 0; % [mmHg] The systolic blood pressure calculated.
for i = 1:t_interval:(length(ppg) - t_interval)
    segment = ppg(i:i+t_interval);
    [lower, upper] = findminmax(segment);
    if (ppg(i + upper) - ppg(i + lower)) < d_minimal
        t_systolic = i + upper;
        break;
    end
end

% Draw the filtered PPG signals, cuff pressure, and found value.
figure;
hold on;
plot(ppg, 'b-');
plot(pressure, 'k-');
plot(t_systolic, pressure(t_systolic), 'rx', 'LineWidth', 5);
title('PPG Signal and Cuff Pressure');
legend('PPG', 'Cuff Pressure', 'Systolic Blood Pressure');
xlabel('Time [ms]');
ylabel('PPG [AU] or Pressure [mmHg]');

% Print the systolic blood pressure.
fprintf("Approximate systolic blood pressure: %.0f mmHg\n", pressure(t_systolic));
