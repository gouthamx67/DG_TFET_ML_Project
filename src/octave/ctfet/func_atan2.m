function [ theta ] = func_atan2(x,y)
%Function to calculate the arctangent for 2 expressions with phase angle
%correction
%
% fun_atan2(x,y)
%
% Inputs:
%-------------------------------------------------------------------------------
% x - x-value of the cartesian coordinates; Real part of the complex plane  
% y - y-value of the cartesian coordinates; Imaginary part of the complex plane  
%-------------------------------------------------------------------------------

%% Calculation of the arctangent solution with corrected phase angle
%--------------------------------------------------------------------------
    if (x > 0)
        theta = atan(y/x);
    elseif ((x < 0) && (y >= 0) )
        theta = atan(y/x) + pi;
    elseif ((x < 0) && (y < 0) )
        theta = atan(y/x) - pi;
    elseif ((x == 0) && (y > 0) )
        theta = pi/2;
    elseif ((x == 0) && (y < 0) )
        theta = -pi/2;
    else
        theta = 0;
    end
%--------------------------------------------------------------------------    
end

