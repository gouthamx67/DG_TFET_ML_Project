function [lambda] = func_lambda(y,lambda_fit,eps_ch,eps_ox,tch,tox)
%% Function to calculate the screening length
%
% func_lambda(y,lambda_fit,eps_ch,eps_ox,tch,tox)
%
% Inputs:
%--------------------------------------------------------------------------
% y          - y-position within the channel
% lambda_fit - Fit-Factor of the screening length in source/drain region
% eps_ch     - Permittivity channel
% eps_ox     - Permittivity gate oxide
% tch        - channel thickness
% tox        - gate oxide thickness
%--------------------------------------------------------------------------

%% Calulations
%--------------------------------------------------------------------------
% Defining the limitations of the screening length for the handover
% y-position
    ymax = tch/2 + sqrt(tch^2/4 + (eps_ch*tox*tch)/(eps_ox));
    ymin = tch/2 - sqrt(tch^2/4 + (eps_ch*tox*tch)/(eps_ox));

% Calculating the screening length in dependency of ymax & ymin
    if(y <= ymax && y >= ymin)
        lambda = lambda_fit * sqrt((eps_ch*tox*tch)/(2*eps_ox)*...
                 (1 + (eps_ox*y)/(eps_ch*tox)-(eps_ox*y^2)/(eps_ch*tox*tch)));
    else
        lambda = lambda_fit * sqrt((eps_ch*tox*tch)/(2*eps_ox)*...
                (1 + (eps_ox*tch)/(eps_ch*tox)-(eps_ox*tch^2)/(eps_ch*tox*tch)));
    end
%--------------------------------------------------------------------------
end