function[result] =fun_charge(Vg,Vd,Vs,V0_gd,V0_gs,tch,cox1,lch,Xb,wch,a,Qi0,Type,Ids)

mue_n = 1417;
mue_p = 470.5;
Vt = 0.0258;
% nch = 1.4500e+10;


% % for i=1:1:length(Vg)
% %  Ids(i) =abs( fun_TFET_device( Vg(i), Vd,Vs))*1e5;
% % end

 
if Type == -1
      Rch = ((lch-Xb)/(mue_p*Qi0*wch)); 
 else
      Rch = ((lch-Xb)/(mue_n*Qi0*wch));
end


%dV = Ids*Rch; %*1e-6;
dV = 0;
Qd_junction  = wch*cox1*a*Vt*func_LambertW_Taylor((Qi0/(cox1*a*Vt))*exp((cox1*(Vg-Vd- V0_gd)+Qi0)/(a*cox1*Vt)));  %[As/cm]  
Qs_junction  = -wch*cox1*a*Vt*func_LambertW_Taylor((Qi0/(cox1*a*Vt))*exp((cox1*(-Vg+Vs - V0_gs)+Qi0)/(a*cox1*Vt)));  %[As/cm]  

Qd_barrier = wch*cox1*a*Vt*func_LambertW_Taylor((Qi0/(cox1*a*Vt))*exp((cox1*(Vg-Vd+dV- V0_gd)+Qi0)/(a*cox1*Vt)));
Qs_barrier = -wch*cox1*a*Vt*func_LambertW_Taylor((Qi0/(cox1*a*Vt))*exp((cox1*(-Vg+Vs-dV- V0_gs)+Qi0)/(a*cox1*Vt)));

%% charge average in the channel
Qch_on = (0.50*Qd_barrier+0.50*Qd_junction)*(lch-Xb);
Qch_ambi = (0.50*Qs_barrier+0.50*Qs_junction)*(lch-Xb);   

result.Qch_on = Qch_on;
result.Qch_ambi = Qch_ambi;
end
