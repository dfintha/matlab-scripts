% FINDMINMAX - Returns the location of the local minimum and maximum.
%
% If multiple maxima or minima are present, returns the first one to be
% found. Supports both Mathworks MATLAB and GNU Octave.
%
% Inputs:
%   range    : The range (vector) to search in.
%
% Outputs:
%   imin     : The index of the local minimum of the values.
%   imax     : The index of the local maximum of the values.

function [imin, imax] = findminmax(range)
    if isempty(range)
        imin = 0;
        imax = 0;
    else
        imin = find(range == min(range));
        if length(imin) > 1
            imin = imin(1);
        end

        imax = find(range == max(range));
        if length(imax) > 1
            imax = imax(1);
        end
    end
end
