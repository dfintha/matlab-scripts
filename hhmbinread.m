% HHMBINREAD - Reads the contents of a HHM binary reading.
%
% Supports both Mathworks MATLAB and GNU Octave, however performance on
% GNU Octave is notably worse.
%
% Inputs:
%   filename : The relative or full path to the file to read from.
%
% Outputs:
%   reading  : A structure containing the ECG, PPG, and pressure values.

function reading = hhmbinread(filename)
    file_id = fopen(filename,'r','b');
    if file_id == -1
        error('File Not Found');
    end

    if exist('OCTAVE_VERSION', 'builtin')
        reading.platform = 'octave';
        temp = fread(file_id, 'uint8=>uint16');
        buffer = zeros(fix(length(temp) * 2 / 3), 1);
        for i = 1:3:length(temp)
            buffer(fix(i / 3 * 2 + 1)) = ...
                bitor(bitshift(temp(i), 4), bitshift(temp(i + 1), -4));
            buffer(fix(i / 3 * 2 + 2)) = ...
                bitor(bitshift(temp(i + 1), 8), temp(i + 2));
        end
    else
        reading.platform = 'matlab';
        buffer = fread(file_id, 'bit12=>double');
    end

    index = find(buffer < 0);
    if (~isempty(index))
        buffer(index) = buffer(index) + 4096;
    end

    reading.ecg1 = buffer(1:8:end);
    reading.ecg2 = buffer(2:8:end);
    reading.press = buffer(3:8:end);
    reading.ppgl_red = buffer(4:8:end);
    reading.ppgl_red_dc = buffer(5:8:end);
    reading.ppgr_nir = buffer(6:8:end);
    reading.ppgr_nir_dc = buffer(7:8:end);
    reading.ppgl_nir = buffer(8:8:end);
