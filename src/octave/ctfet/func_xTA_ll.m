function [xTA_ll_out] = func_xTA_ll(k,l,m,Vs,Vd,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,lch)
%% Function to calculate a x-position which describes the lower limit (ll)
% of the tunneling area (TA)
%
% func_xTA_ll(k,l,m,Vs,Vd,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,lch)
%
% Inputs:
%--------------------------------------------------------------------------
% k         - parameter of the potential approximation in channel
% l         - parameter of the potential approximation in channel
% m         - parameter of the potential approximation in channel
% Vs        - Source voltage
% Vd        - Drain voltage
% Phi_bi_s  - built-in voltage in source
% Phi_bi_d  - built-in voltage in drain
% Eg_s      - band gap in source
% Eg_ch     - band gap in channel
% Eg_d      - band gap in drain
% X_s       - electron affinity source
% X_ch      - electron affinity channel
% X_d       - electron affinity drain
% lch       - channel length
%--------------------------------------------------------------------------
%
% Outputs:
%--------------------------------------------------------------------------
% xTA_ll    - lower limit of the tunneling area
%--------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------
% Calculations for the source-to-channel junction
    if l <= lch/2
        % Calculating the lower limit which describes the x-position from
        % where B2B tunneling can occur. This is the position where the
        % conduction band in channel equals the valence band in source
        % where band bending is zero.
        xTA_ll = l -(k)/((-Phi_bi_s -Vs -Eg_s/2) - (Eg_ch/2 + X_s - X_ch) + m);
        % Checking whether the result is smaller or equal to l
        if xTA_ll <= l
            % Set lower limit to l + a small offset to avoid a divison by
            % zero
            xTA_ll_out = l + 1e-20;
        else
            % Set lower limit to the calculated value
            xTA_ll_out = xTA_ll;
        end
% Calculations for the drain-to-channel junction
    else
        % Calculating the lower limit which describes the x-position from
        % where B2B tunneling can occur. This is the position where the
        % valence band in channel equals the conduction band in drain
        % where band bending is zero.
        xTA_ll = l - k/(Phi_bi_d + Vd - m - (Eg_d/2 + Eg_ch/2 - X_d + X_ch)); 

        if xTA_ll >= l
            % Set lower limit to l - a small offset to avoid a divison by
            % zero
            xTA_ll_out = l-1e-20;           
        else
            % Set lower limit to the calculated value
            xTA_ll_out = xTA_ll;
        end
    end
%--------------------------------------------------------------------------    
end