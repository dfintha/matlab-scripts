% CURVEFIT - Fits a polynomial curve to a set of data.
%
% Supports both Mathworks MATLAB and GNU Octave.

function [x, y, c] = curvefit(x0, y0, p_degree, x_begin, x_end, x_step)
    c = polyfit(x0, y0, p_degree);
    x = linspace(x_begin, x_end, (x_end - x_begin) / x_step);
    y = polyval(c, x);
end
