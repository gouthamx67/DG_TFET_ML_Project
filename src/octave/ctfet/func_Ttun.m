function [ Ttun_out, ltun_out, E_bh_out ] = func_Ttun( x, m_s, m_d, a, b, c, k, l, m, Eg_s, ...
                                Eg_ch, Eg_d,X_s, X_ch, X_d, q, m0, h_quer,lch)
%% Function to calculate the tunneling probability for a specific x,y-
% position using the WKB approximation.
%
% fun_Ttun(x,m_s,m_d,a,b,c,k,l,m,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,q,m0,h_bar,lch)
%
% Inputs:
%--------------------------------------------------------------------------
% x     - specific x-position
% m_s   - effective mass of the carriers at the source-to-channel junction
% m_d   - effective mass of the carriers at the drain-to-channel junction
% a     - parameter of the potential approximation in source/drain
% b     - parameter of the potential approximation in source/drain
% c     - parameter of the potential approximation in source/drain
% k     - parameter of the potential approximation in channel
% l     - parameter of the potential approximation in channel
% m     - parameter of the potential approximation in channel
% Eg_s  - band gap source
% Eg_ch - band gap channel
% Eg_d  - band gap drain
% X_s   - electron affinity source
% X_ch  - electron affinity channel
% X_d   - electron affinity drain
% q     - elementary charge
% m0    - electron rest mass
% h_bar - reduced Planck constant
% lch   - channel length
%--------------------------------------------------------------------------
%
% The height of the triangular energy barrier is calculated with the area 
% under the closed-form solution of the band structure.
%
% The y-dependency is considered in the potential approximation with the
% parameter a,b,c,k,l,m
%
% The parameter l is used distinguish the source-to-channel junction
% (on-state) and the drain-to-channel-junction (ambipolar-state).

%% Calculation of the tunneling length and the tunneling probability
%--------------------------------------------------------------------------
% Calculations for the source-to-channel junction
    if l <= lch/2
        % Simplification to calculate the tunneling length ltun
        K1 = m - (Eg_ch/2 + X_s - X_ch) + b^2/(4*a) - c - Eg_s/2;        

        % Check whether the expression in the sqrt is negatative:
        % if the expression >=0 --> Calculate ltun & Ttun,
        % otherwise --> Ttun = 0!
        if((k/(a*(x-l))+K1/a)>=0)
            % Calculation of the tunneling length ltun
            ltun = x + b/(2*a) - sqrt(k/(a*(x-l))+K1/a);
            if ltun < 0
                Ttun = 1e-30;
                ltun = lch/2;
                E_bh = 1e-30;
            else            
                % Calculation of the energy offset in the channel to consider
                % only positive "areas" in calculation of the area A1
                E_offset_ch = - k/(x-l)-m + (Eg_ch/2 + X_s - X_ch);

                % Calculation of the area within source
                A1_sd = a/3*(x-ltun)^3 + b/2*(x-ltun)^2 +(c-Eg_s/2)*(x-ltun) + E_offset_ch*(x-ltun);
                % Calculation of the area within channel
                A1_ch = k*log(l/(l-x)) + ((Eg_ch/2 + X_s - X_ch)-m)*x - E_offset_ch*x;
                
%                 disp('A1_sd =')
%                 disp(A1_sd)
%                 disp('A1_ch =')
%                 disp(A1_ch)
                
                
                % Summation results in the area to calculate the height of the
                % energy barrier
                A1 = A1_sd + A1_ch;

                % Calculating the energy barrier height E_bh
                E_bh = 2*abs(A1)/ltun;              

%                 disp('E_bh =')
%                 disp(E_bh)
%                 disp('ltun =')
%                 disp(ltun)
                % Calculation of the tunneling probability Ttun
                Ttun = exp(-4/3 * sqrt((2*m0*m_s)/(100^2*h_quer^2)) * ltun *sqrt(q*E_bh));
                
                
%                 Ttun = exp();
                
            end
        else
            Ttun = 1e-30;
            ltun = lch/2;
            E_bh = 1e-30;
        end
% Calculations for the drain-to-channel junction
    else
        % Simplification to calculate the tunneling length ltun
        K1 = m + Eg_ch/2 + X_ch - X_d + b^2/(4*a) - c + Eg_d/2;
        K1 = m + Eg_ch/2 + b^2/(4*a) - c + Eg_d/2;
%         K1 = m  + b^2/(4*a) - c + Eg_d/2 ;

        % Check whether the expression in the sqrt is negatative:
        % if the expression >=0 --> Calculate ltun & Ttun,
        % otherwise --> Ttun = 0!
        if((k/(a*(x-l))+K1/a)>=0)
            % Calculation of the tunneling length ltun
            ltun = lch-x - b/(2*a) - sqrt(k/(a*(x-l))+K1/a)-lch;            
            % Checking whether ltun is < 0
            if ltun < 0 
                Ttun = 1e-30;
                ltun = lch/2;
                E_bh = 1e-30;
            else
                % Calculation of the energy offset in the channel to consider
                % only negative "areas" in calculation of the area A1
                E_offset_ch = - k/(x-l)-m - Eg_ch/2 + X_s - X_ch;

                % Calculation of the area within channel
                A1_ch = k*log((l-x)/(l-lch)) + m*(x-lch) - (-Eg_ch+X_s-X_ch)*(x-lch) + E_offset_ch*(x-lch);
                
                A1_ch1 = k*log((l-x)/(l-lch)) + (-m + X_s - X_ch - Eg_ch/2)*(lch-x);

                % Calculation of the area within drain
                A1_sd = a/3*(lch^3-(x+ltun)^3) + b/2*(lch^2 - (x+ltun)^2) + c*(lch-(x+ltun))...
                        -(-Eg_d/2 + X_s - X_d)*(lch-(x+ltun)) + E_offset_ch*(lch-(x+ltun));
                    
                A1_sd1 = a/3*(lch^3 - (x+ltun)^3) + b/2*(lch^2 - (x+ltun)^2) - (-c + X_s - X_d -Eg_d/2)*(lch - (x+ltun));
                
                A1_offset = - (-(k/(x-l) + m ) +X_s -X_ch -Eg_ch/2 ) * ltun;

                % Summation results in the area to calculate the height of the
                % energy barrier
                A1 = abs(A1_ch) + abs(A1_sd);
                
                A11 = abs(A1_ch1 + A1_sd1 + A1_offset);

                % Calculating the energy barrier height E_bh
                E_bh = 2*A11/ltun;
                % Calculation of the tunneling probability Ttun
                Ttun = exp(-4/3 * sqrt((2*m0*m_d)/(100^2*h_quer^2)) * ltun *sqrt(q*E_bh));
            end
        else
            Ttun = 1e-30;
            ltun = lch/2;
            E_bh = 1e-30;
        end
    end    
% Handover the tunneling probability
    Ttun_out = Ttun;
    ltun_out = ltun;
    E_bh_out = E_bh;
%--------------------------------------------------------------------------
end

