function s = string(x)
% Compatibility shim for the THM-TFET MATLAB source, which uses string()
% for character selection. Octave represents characters directly.
s = x;
end
