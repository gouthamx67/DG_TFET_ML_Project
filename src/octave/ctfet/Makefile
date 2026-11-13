APP = main
MFILES = func_atan2.m func_center_potential.m func_ds.m func_efield_abs_Michi.m func_erf.m func_fermi_int.m \
         func_gamma_verilog.m fun_charge.m func_Jy_y_B2B.m func_Jy_y_TAT.m func_lambda.m func_LambertW_Taylor.m \
         func_Landauer.m func_mapping_u.m func_mapping_v.m func_Phi_bi_eff.m func_potential_2D.m func_potential_constant_bnd.m \
         func_potential_linear_bnd.m func_potential_parabolic_bnd.m func_TFET_verilog.m func_Ttun_B2B.m func_Ttun.m \
	 func_Ttun_Michi.m func_Ttun_TAT.m func_Vgs_eff.m func_xmax_TGR.m func_xTA_ll.m func_xTA_ul.m

matlabversion = 2018a
DELETE_FILES =
BIN = ../bin
RP_DIR = $(shell . /etc/environ.sh; use -e -r rappture; echo $${RAPPTURE_PATH})

MCCFLAGS = -v -C -m -R -nodisplay
MCCINCLUDES = -I $(RP_DIR)/lib/matlab

$(APP): $(APP).m $(MFILES)
	mcc $(MCCFLAGS) $(MCCINCLUDES) $(APP).m $(MFILES)
	patchrunscript.sh run_$(APP).sh run_$(APP).sh 1

all:
	. /etc/environ.sh; use -e -r matlab-$(matlabversion); make $(APP)

install: all
	install --mode 0755 -D run_$(APP).sh $(BIN)
	install --mode 0755 -D $(APP) $(BIN)
	install --mode 0644 -D readme.txt $(BIN)/$(APP).readme
	if [ -e $(APP).ctf ] ; then \
        mv $(APP).ctf $(BIN); \
        cd $(BIN); \
        . /etc/environ.sh; \
        use -e -r matlab-$(matlabversion); \
        extractCTF $(APP).ctf; \
    fi

clean:
	rm -f $(APP) $(APP).ctf \
         $(APP).prj run_$(APP).sh \
         $(APP)_main.c $(APP)_mcc_component_data.c \
         mccExcludedFiles.log readme.txt $(DELETE_FILES) \
         requiredMCRProducts.txt


distclean: clean
	rm -rf $(BIN)/$(APP) \
          $(BIN)/$(APP).ctf \
          $(BIN)/$(APP).readme \
          $(BIN)/$(APP)_mcr \
          $(BIN)/run_$(APP).sh

