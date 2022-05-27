% HHMBINREAD - Reads the contents of a HHM binary reading.
%
% The reading is scaled depending on the machine chosen to measure.
% Supports both Mathworks MATLAB and GNU Octave, however performance on
% GNU Octave is notably worse.
%
% Inputs:
%   filename : The relative or full path to the file to read from.
%   machine  : Number of the machine the reading was taken on. Can be
%              either 1 or 2 to perform scaling, otherwise this parameter
%              will be ignored.
%
% Outputs:
%   reading  : A structure containing the ECG, PPG, and cuff pressure
%              values.

function reading = hhmbinread(filename, machine)
    file_id = fopen(filename,'r','b');
    if file_id == -1
        error('File Not Found');
    end

    % On both platforms, we have to read 12-bit values. MATLAB has a
    % built-in way of doing so with the bitN precision specifier, but
    % Octave does not have this feature. As such, we have to manually read
    % the values byte-by-byte, convert them to 16-bit values (so the 12-bit
    % results will fit in them), and then use bitwise operators to create
    % two values from every three bytes. Note, that even though we only
    % convert the precision to unsigned 16-bit integers, the result will be
    % a double-precision floating-point number, since we initialize the
    % resulting vector with zeros().

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
    reading.machine = machine;

    if machine == 2
        reading.ecg1 = 3.3 / 4096 * (reading.ecg1 - 2048);
    elseif machine == 1
        reading.ecg1 = 3.3 / 8192 * (reading.ecg1 - 2048);
    end
