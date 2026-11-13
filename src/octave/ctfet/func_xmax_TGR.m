function [xmax_out] = func_xmax_TGR(a,b,c,k,l,m,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,lch)
%% Function to calculate the x-position of the maximum TGR value. The 
% position xmax is calculated with the help of the first derivative of the
% tunneling length expression, set to zero and solved for x.
%
% func_xmax_TGR(a,b,c,k,l,m,Eg_s,Eg_ch,Eg_d,X_s,X_ch,X_d,lch)
%
% Inputs:
%--------------------------------------------------------------------------
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
% lch   - channel length
%--------------------------------------------------------------------------

%% Calculations
%--------------------------------------------------------------------------
% Calculations for the source-to-channel junction
    if l <= lch/2        
        % Simplification
        K1 = m - (Eg_ch/2 + X_s - X_ch) + b^2/(4*a) - c - Eg_s/2;
        % Part within the sqrt in the next simplification
        theta1_sqrt_int = (186624*a^4*k^8+442368*a^3*k^6*K1^3);                          
        % Check whether this part within sqrt is smaller than zero to avoid
        % imaginary results.
        if theta1_sqrt_int < 0
            % Set simplification theta1 to zero
            theta1 = 0;
        else
            % Calculate simplification theta1
            theta1 = -(432*a^2*k^4 + sqrt(theta1_sqrt_int))^(1/3);
        end
        % Calculate simplification theta2
        theta2 = (sqrt(3)*(-(k-4*K1*l)^3/K1^3+(12*(2*K1*l^2-k*l)*(k-4*K1*l))/K1^2-(8*(3*k*l^2-4*K1*l^3))/K1));
        % Calculate simplification theta3
        theta3 = (a*k*l-2*a*K1*l^2)/(a*K1)+(k-4*K1*l)^2/(2*K1^2)-(3*(2*K1*l^2-k*l))/K1;
        % Check whether theta1 is smaller than zero to avoid
        % imaginary results in the following sqrt
        if theta1 == 0
            % Set the sqrt part 1 to zero
            sqrt_part_1 = 0;
        else
            % Calculate next part within a sqrt
            sqrt_part_1_2 = theta1/(a*K1*(2)^(1/3)) - (48*k^2*2^(1/3))/(theta1)+ (3*k^2)/(K1^2);
            % Check whether this part is smaller than zero to avoid
            % imaginary results in the following sqrt
            if sqrt_part_1_2 < 0
                % Calulate sqrt_part_1
                sqrt_part_1 = -theta1/(12*a*K1*(2)^(1/3)) + (4*k^2*2^(1/3))/theta1;                
            else
                % Calulate sqrt_part_1
                sqrt_part_1 = -theta1/(12*a*K1*(2)^(1/3)) + (4*k^2*2^(1/3))/theta1 ...
                            + theta2/(2*sqrt( sqrt_part_1_2 ));
            end
        end
        % Check the calculated values to avoid imaginary results
        
        sqrt_part_2 = (theta1/(a*K1*(2)^(1/3)) - (48*k^2*2^(1/3))/(theta1) + (3*k^2)/(K1^2) );
        
        sqrt_part_1_1 = sqrt_part_1 + theta3;
        
        if sqrt_part_1 < theta3 || theta1 == 0 || sqrt_part_2 < 0
%         if sqrt_part_1 < theta3 || theta1 == 0 || sqrt_part_1_1 < 0
            % Set first part of xmax_TGR to zero
            xmax_part1 = 0;
        else
            % Calculate first part of the xmax_TGR
            xmax_part1 = sqrt(-theta1/(12*a*K1*(2)^(1/3)) + (4*k^2*2^(1/3))/theta1 ...
                        + theta2/(2*sqrt(theta1/(a*K1*(2)^(1/3)) - (48*k^2*2^(1/3))/(theta1) + (3*k^2)/(K1^2) ))...
                        + theta3 )/2;
        end
        % Check theta1 and sqrt_part_2 to avoid imaginary results
        if theta1 == 0 || sqrt_part_1_2 < 0
            % Set second part of xmax_TGR to zero
            xmax_part2 = 0;
        else
            % Calculating second part of xmax_TGR
            xmax_part2 = sqrt(sqrt_part_1_2)/(4*sqrt(3));
        end
        % Calculating third part of xmax_TGR
        xmax_part3 = -(k-4*K1*l)/(4*K1);
        % Sum up all three parts to xmax_TGR
        xmax = xmax_part1 + xmax_part2 + xmax_part3;
        
%         disp('xmax_part1 =')
%         disp(xmax_part1)
%         disp('xmax_part2 =')
%         disp(xmax_part2)
%         disp('xmax_part3 =')
%         disp(xmax_part3)
        
        
        % Checking whether xmax is smaller or equal to l or smaller or
        % equal to zero
        if xmax <= l || xmax <= 0
            % Set xmax to 1e-20 to avoid division by zero
            xmax = 1e-20;
        end
        % Checking whether xmax is bigger than lch/2 
        if xmax > lch/2
            % Handover xmax in the middle of the channel
            xmax_out = lch/2 - 1e-20;
        else
            % Handover calculated xmax value
            xmax_out = xmax;
        end

% Calculations for the drain-to-channel junction
    else
        % Simplification
        K1 = m + Eg_ch/2 + X_ch - X_d + b^2/(4*a) - c + Eg_d/2;
        K1 = m + Eg_ch/2 + b^2/(4*a) - c + Eg_d/2;
        % Part within the sqrt in the next simplification
        theta1_sqrt_int = (186624*a^4*k^8 + 442368*a^3*k^6*K1^3);
        % Check whether this part within sqrt is smaller than zero to avoid
        % imaginary results.
        if theta1_sqrt_int < 0
            % Set simplification theta1 to zero
            theta1 = 0;
        else
            % Calculate simplification theta1
            theta1 = -(432*a^2*k^4 + sqrt(186624*a^4*k^8+442368*a^3*k^6*K1^3))^(1/3);
%             theta1 = (-432*a^2*k^4 + sqrt(186624*a^4*k^8+442368*a^3*k^6*K1^3))^(1/3);
%             theta1 = nthroot((432*a^2*k^4 + sqrt(186624*a^4*k^8+442368*a^3*k^6*K1^3)),3);
        end
        % Calculate simplification theta2
        theta2 = (sqrt(3)*(-(k-4*K1*l)^3/K1^3+(12*(2*K1*l^2-k*l)*(k-4*K1*l))/K1^2-(8*(3*k*l^2-4*K1*l^3))/K1));
        % Calculate simplification theta3
        theta3 = (a*k*l-2*a*K1*l^2)/(a*K1)+(k-4*K1*l)^2/(2*K1^2)-(3*(2*K1*l^2-k*l))/K1;
        % Check whether theta1 is smaller than zero to avoid
        % imaginary results in the following sqrt
        if theta1 == 0
            % Set the sqrt part 1 to zero
            sqrt_part_1 = 0;
        else                
            % Calculate next part within a sqrt
            sqrt_part_1_2 = theta1/(a*K1*(2)^(1/3)) - (48*k^2*2^(1/3))/(theta1)+ (3*k^2)/(K1^2);
            % Check whether this part is smaller than zero to avoid
            % imaginary results in the following sqrt
            if sqrt_part_1_2 < 0
                % Calulate sqrt_part_1
                sqrt_part_1 = -theta1/(12*a*K1*(2)^(1/3)) + (4*k^2*2^(1/3))/theta1;                
            else
                % Calulate sqrt_part_1
                sqrt_part_1 = -theta1/(12*a*K1*(2)^(1/3)) + (4*k^2*2^(1/3))/theta1 ...
                            - theta2/(2*sqrt( sqrt_part_1_2 ));
            end
        end
        % Check the calculated values to avoid imaginary results
        if sqrt_part_1 < theta3 || theta1 == 0
            % Set first part of xmax_TGR to zero
            xmax_part1 = 0;
        else
            % Calculate first part of xmax_TGR
            xmax_part1 = sqrt(sqrt_part_1 + theta3 )/2;
        end
        % Check theta1 and sqrt_part_2 to avoid imaginary results
        if theta1 == 0
            % Set second part of xmax_TGR to zero
            xmax_part2 = 0;
        else
            % Calculating second part of xmax_TGR
            xmax_part2 = sqrt(theta1/(a*K1*2^(1/3)) - (48*k^2*2^(1/3))/theta1 + (3*k^2)/(K1^2))/(4*sqrt(3));
        end
        % Calculating third part of xmax_TGR
        xmax_part3 = -(k-4*K1*l)/(4*K1);
        % Sum up all three parts to xmax_TGR
        xmax = (-xmax_part1 - xmax_part2 + xmax_part3);
        % Checking whether xmax is bigger or equal to l or bigger or
        % equal to lch
        if xmax >= l || xmax >= lch
            % Set xmax to lch-1e-20 to avoid numerical problems
            xmax = lch - 1e-20 ;
        end
        % Checking whether xmax is smaller or equal to lch/2 
        if xmax <= lch/2
            % Handover xmax in the middle of the channel
            xmax_out = lch/2 + 1e-20;
        else
            % Handover calculated xmax value
            xmax_out = xmax;
        end
    end
%--------------------------------------------------------------------------    
end