function generate_chunk()
% Generate Id-Vg curves for a chunk of DG-TFET designs with the
% THM-TFET v1.2 compact model (THM University of Applied Sciences).
%
% Environment variables:
%   CHUNK_IN   CSV with header and columns:
%              device_id,lch_cm,tox_cm,tch_cm,eps_ox,Ns,Nd,Nch,NT
%   CHUNK_OUT  output CSV:
%              device_id,Vgs,Vds,Id_A_per_um,Ids_TAT,Ids_B2B

addpath('/work/src/octave/ctfet');
addpath('/work/src/octave');
warning('off', 'all');

in_file  = getenv('CHUNK_IN');
out_file = getenv('CHUNK_OUT');
D = dlmread(in_file, ',', 1, 0);
n = size(D, 1);

Vgs = (-0.4:0.02:1.5)';
Vds = [0.1 0.3 0.5];
npts = numel(Vgs) * numel(Vds);
rows = zeros(n * npts, 6);
idx = 0;

for i = 1:n
    [P, F, G] = setup_params(struct(), struct());
    P.lch    = D(i, 2);
    P.tox    = D(i, 3);
    P.tch    = D(i, 4);
    P.eps_ox = D(i, 5) * 8.854e-14;
    P.N_s    = D(i, 6);
    P.N_d    = D(i, 7);
    P.N_ch   = D(i, 8);
    F.N_ch   = D(i, 8);
    P.N_T    = D(i, 9);
    P.wch    = 1e-4;   % 1 um reference width -> Id is A/um

    for vd = Vds
        for k = 1:numel(Vgs)
            try
                r = func_TFET_verilog(Vgs(k), vd, 0, P, F, G);
                id  = r.Ids;
                it  = r.Ids_TAT;
                ib  = r.Ids_B2B;
            catch
                id = NaN; it = NaN; ib = NaN;
            end
            idx = idx + 1;
            rows(idx, :) = [D(i, 1), Vgs(k), vd, id, it, ib];
        end
    end

    if mod(i, 10) == 0
        fprintf('%d/%d designs\n', i, n);
        fflush(stdout);
    end
end

dlmwrite(out_file, rows(1:idx, :), 'precision', '%.12e');
fprintf('wrote %s (%d rows)\n', out_file, idx);
end
