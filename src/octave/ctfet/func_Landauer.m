%% Supply function of the Landauer formula

function [ Landauer ] = func_Landauer( Vs, Vd, Phi_bi_d,Phi_bi_s, k, l, m, Eg_s, Eg_d, X_s, X_d, lch, kb,T)

    % On-state
    if l < lch/2
        
        A_phi_landauer = 10;
        
        phi_lch_2 = k/(lch/2-l)+m;
        
        phi_de = (Phi_bi_d + Vd);
        
        phi_landauer = phi_de*(1-1/(log(1+exp(A_phi_landauer)))*log(1+exp(A_phi_landauer*(1-phi_lch_2/phi_de))));
        
        Ec_max = -phi_landauer + Eg_d/2 + X_s-X_d;
        
        Fermi_s = -Vs;
        Fermi_d = -Vd;
                    
        Landauer = log((1+exp(-(Ec_max-Fermi_s)/(kb*T)))/(1+exp(-(Ec_max-Fermi_d)/(kb*T))));
        
    % Ambipolar-state     
    else
                
        A_phi_landauer = 10;
        
        phi_lch_2 = k/(lch/2-l)+m;
        
        phi_se = (Phi_bi_s + Vs);
        
        phi_landauer = phi_se*(1-1/(log(1+exp(A_phi_landauer)))*log(1+exp(A_phi_landauer*(1-phi_lch_2/phi_se))));        
        
        Ev_min = -phi_landauer -Eg_s/2;
        
        Fermi_s = -Vs;
        Fermi_d = -Vd;
        
        Landauer = log( (1+exp(-(-Ev_min + Fermi_d  )/(kb*T))) / (1+exp(-(-Ev_min + Fermi_s  )/(kb*T))) );          
    end

end