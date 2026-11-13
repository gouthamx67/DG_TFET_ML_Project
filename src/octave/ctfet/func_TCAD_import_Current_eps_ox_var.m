function [ x_TCAD,y_TCAD ] = func_TCAD_import_Current_eps_ox_var(V_const,V_sweep,type,eps_ox)
%% Function to import TCAD simulation data of the device current
%
% func_TCAD_import_Current(V_const,V_sweep,type)
%
% Inputs:
%--------------------------------------------------------------------------
% V_const - Constant voltage of the current sweep
% V_sweep - Voltage which is sweeped
% type    - type of current curve ('transfer'/'output') [string]
%--------------------------------------------------------------------------
%
% Outputs
%--------------------------------------------------------------------------
% x_TCAD - x-Data of the TCAD simulations
% y_TCAD - y-Data of the TCAD simulations
%--------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------
if(strcmp(type, 'transfer') && V_const <= 1) || (strcmp(type, 'output') && V_const <= 2 && V_const >=-1.4 )

    % Round the  constant voltage in order to avoid numerical problems
        V_const_temp = round(1000*V_const)/1000;
    % Generate fileName of the csv-file in dependency of the constant
    % voltage and type
        if(strcmp(type, 'transfer'))
            if (eps_ox/8.854e-14) < 4.0
                fileName = sprintf('../00_TCAD_Simulation_Data/Transfer_Curves_Parameter_Variation/eps_ox/transfer_curve_Vd_%.3fV_Vg_from_-2.00V_to_2.00V_eps_ox_%.1f.csv',V_const_temp,eps_ox/8.854e-14);            
            else
                fileName = sprintf('../00_TCAD_Simulation_Data/Transfer_Curves_Parameter_Variation/eps_ox/transfer_curve_Vd_%.3fV_Vg_from_-2.00V_to_2.00V_eps_ox_%.0f.csv',V_const_temp,eps_ox/8.854e-14);
            end
%             fileName = sprintf('../00_TCAD_Simulation_Data/Transfer_Curves/transfer_curve_Vd_%.3fV_Vg_from_-1.5V_to_2.5V.csv',V_const_temp);
        elseif (strcmp(type, 'output'))
            if V_const > 0 
%                fileName = sprintf('../00_TCAD_Simulation_Data/Output_Curves/output_curve_Vg_%.3fV_Vd_from_0V_to_2V.csv',V_const_temp);
               fileName = sprintf('../00_TCAD_Simulation_Data/Output_Curves/output_curve_Vg_%.3fV_Vd_from_0V_to_1.5V.csv',V_const_temp);
            else
%                fileName = sprintf('../00_TCAD_Simulation_Data/Output_Curves/output_curve_Vg_%.3fV_Vd_from_0V_to_1.6V.csv',V_const_temp); 
               fileName = sprintf('../00_TCAD_Simulation_Data/Output_Curves/output_curve_Vg_%.3fV_Vd_from_0V_to_1.5V.csv',V_const_temp);
            end
        end
    % Import data from csv data
        TCAD_Data = csvread(fileName,1,0);
    % Separate x-data containing V_sweep
        x_TCAD_int = TCAD_Data(:,1);
    % Separate y-data containing device current
    
        if(strcmp(type, 'transfer'))
            y_TCAD_int = TCAD_Data(:,2);
        elseif (strcmp(type, 'output'))
            y_TCAD_int = TCAD_Data(:,2);%*(4952/6422);
        end
    % Calculating the minimum value of V_sweep
        if min(V_sweep) >= x_TCAD_int(1)
            V_sweep_min = min(V_sweep);
        else
            V_sweep_min = x_TCAD_int(1);
        end
    % Calculating the maximum value of V_sweep
        if max(V_sweep) <= x_TCAD_int(end)
            V_sweep_max = max(V_sweep);
        else
            V_sweep_max = x_TCAD_int(end);
        end
    % Read out TCAD data from V_sweep_min to V_sweep_max
        if(length(V_sweep)==1)
            j = 1;
            for i = 1:length(x_TCAD_int)
               if(x_TCAD_int(i) >= (V_sweep-0.2) && x_TCAD_int(i) <= (V_sweep+0.2))
                  x_TCAD(j) = x_TCAD_int(i);
                  y_TCAD(j) = y_TCAD_int(i);
                  j = j + 1;
               end 
            end
        else
            j = 1;
            for i = 1:length(x_TCAD_int)
               if(x_TCAD_int(i) >= V_sweep_min && x_TCAD_int(i) <= V_sweep_max)
                  x_TCAD(j) = x_TCAD_int(i);
                  y_TCAD(j) = y_TCAD_int(i);
                  j = j + 1;
               end 
            end
        end
else
    disp('Bias out of Range!')
    x_TCAD = zeros(1,length(V_sweep));
    y_TCAD = zeros(1,length(V_sweep));
end
end

