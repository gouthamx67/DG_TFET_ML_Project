function [value] = func_LambertW_Taylor(z)

if z == 0
   f11 = 1;
else
    f11 = 0;
end;

tmp = log(f11+z);

if tmp > 0
    w = tmp - log(tmp);
else
    w = sqrt(2 * (exp(1) * z + 1)) -1;
end;

for k = 1:1:32
    c1 = exp(w);
    c2 = w*c1 - z;
    if w ~= 1
        f12 = 1;
    else
        f12 = 0;
    end;
    w1 = w + f12;
    dw = c2 / (c1 * w1 - ((w+2) * (c2 / w1))/2 );
    w = w - dw;
end;

value = w;
end

