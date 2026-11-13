function [xTA_ul] = func_xTA_ul(k,l,m,Vs,Vd,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,lch)
%% Function to calculate a x-position which describes the upper limit (ul)
% of the tunneling area (TA)
%
% func_xTA_ul(k,l,m,Vs,Vd,Phi_bi_s,Phi_bi_d,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,lch)
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
% xTA_ul    - upper limit of the tunneling area
%--------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------
% Calculations for the source-to-channel junction
    if l <= lch/2
        % Calculation of the conduction band in the channel at x=lch/2
            Ec_lch_2 = -(k/(lch/2-l)+m)+Eg_ch/2+X_s-X_ch;
        % Calculation of the conduction band in drain, where band bending
        % is zero
            Ec_de = -(Phi_bi_d+Vd)+Eg_d/2+X_s-X_d;
        % Checking whether the conduction band at x=lch/2 is greater than
        % conduction band in drain
            if Ec_de <= Ec_lch_2
                % Set upper limit to channel length
                xTA_ul = lch/2;
            else
                % Set upper limit to the x-position where conduction band
                % in channel equals conduction band in drain
                xTA_ul = l-k/(-(Phi_bi_d+Vd)+Eg_d/2-Eg_ch/2+X_ch-X_d+m);
            end
% Calculations for the drain-to-channel junction  
    else
        % Calculation of the valence band in the channel at x=lch/2
            Ev_lch_2 = -(k/(lch/2-l)+m)-Eg_ch/2+X_s-X_ch;
        % Calculation of the valence band in source, where band bending
        % is zero 
            Ev_se = -(Phi_bi_s+Vs)-Eg_s/2;            
        % Checking whether the valence band at x=lch/2 is smaller than
        % valence band in source
            if Ev_se >= Ev_lch_2
                % Set upper limit to zero
                xTA_ul = lch/2; 
            else
                % Set upper limit to the x-position where valence band
                % in channel equals valence band in source
                xTA_ul = l-k/(-(Phi_bi_s+Vs)-Eg_s/2+Eg_ch/2-X_s+X_ch+m);
            end
    end
%--------------------------------------------------------------------------
end

