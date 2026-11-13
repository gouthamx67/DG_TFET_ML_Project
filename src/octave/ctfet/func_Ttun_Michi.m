function [ Ttun_out, ltun_out, E_bh_out ] = func_Ttun_Michi( x, m_s,m_d, Eg_s, Eg_ch,Eg_d, X_s, X_ch,X_d, ...
                                                a, b, c, k, l, m, abs_efield, q, m0, h_quer,lch)
%Function to calculate the analytic Tunneling Generation Rate

%% Calculation of the tunneling length and the tunneling probability
    if l <= lch/2
        
        E_bh_min = 0.00001 * Eg_s; 
        
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
                E_bh = 1*abs_efield*ltun;
                if(E_bh<E_bh_min)
                    Ttun = exp(-(4/3) * (sqrt(2*q*m0*m_s)* (E_bh_min)^(3/2))/(100*h_quer*abs_efield));
                    disp('HBARMIN')
                else
                    Ttun = exp(-(4/3) * (sqrt(2*q*m0*m_s)* (abs_efield*ltun)^(3/2))/(100*h_quer*(abs_efield)));
                end
            end
        else
            Ttun = 1e-30;
            ltun = lch/2;
            E_bh = 1e-30;
        end
% Calculations for the drain-to-channel junction
    else
        
        E_bh_min = 0.00001 * Eg_d; 
        
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
                E_bh = abs_efield*ltun;
                if(E_bh<E_bh_min)
                    Ttun = exp(-(4/3) * (sqrt(2*q*m0*m_d)* (E_bh_min)^(3/2))/(100*h_quer*abs_efield));
                    disp('HBARMIN')
                else
                    Ttun = exp(-(4/3) * (sqrt(2*q*m0*m_d)* (abs_efield*ltun)^(3/2))/(100*h_quer*(abs_efield)));
                end
            end
        else
            Ttun = 1e-30;
            ltun = lch/2;
            E_bh = 1e-30;
        end
    end    
    
    Ttun_out = Ttun;
    ltun_out = ltun;
    E_bh_out = E_bh; 
end

