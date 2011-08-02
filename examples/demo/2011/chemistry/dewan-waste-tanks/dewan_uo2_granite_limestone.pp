#*******************************************************************************
# INPUTS_ASCEM: Two-phase model with tracers
# new input format
#*******************************************************************************
# Geometry
# --------
geometry.coord_sys   = 0    
geometry.prob_lo     = 0. 0. 
geometry.prob_hi     = 16 16
geometry.is_periodic = 0 0

geometry.region = Limestone_Backfill_Region Granite_Backfill_Region Waste_Region 

geometry.Limestone_Backfill_Region
{
  purpose = 0
  type = 1
  param = 0 12 16 16
}

geometry.Granite_Backfill_Region
{
   purpose = 0
   type = 1
   param = 0 0 16 15
}

geometry.Waste_Region
{
  purpose = 0
  type = 1
  param = 6 10 10 14
}


# Rock
# ----

rock.rock = Limestone_Backfill Granite_Backfill Waste

rock.Limestone_Backfill
{
  density = 2.63e3
  porosity = 0.35
  permeability = 75.0 75.0
  kr_type = 3
  kr_param = 0.11238 0.1893 0
  cpl_type = 3
  cpl_param = 0.11238 78 0.1893 0
}

rock.Granite_Backfill
{
  density = 2.63e3
  porosity = 0.35
  permeability = 78.58 78.58
  kr_type = 3
  kr_param = 0.11238 0.1893 0
  cpl_type = 3
  cpl_param = 0.11238 78 0.1893 0
}

rock.Waste
{
  density = 2.63e3
  porosity = 0.35
  permeability = 50.0 50.0
  kr_type = 3
  kr_param = 0.11238 0.1893 0
  cpl_type = 3
  cpl_param = 0.11238 78 0.1893 0
}


rock.assign = Granite_Backfill_Region Limestone_Backfill_Region Waste_Region


rock.Granite_Backfill_Region
{
  type = Granite_Backfill
  phi = 1
  kappa = 1
}

rock.Limestone_Backfill_Region
{
   type = Limestone_Backfill
   phi = 1
   kappa = 1
}

rock.Waste_Region
{
  type = Waste
  phi = 1
  kappa = 1
}

rock.permeability_file = test/kp
rock.porosity_file = test/pp

# phase and components
# --------------------
phase.phase  = Liquid Gas
# water must come before air for now.
comp.comp = Water Air
comp.Water
{
  phase = Liquid
  density = 1.0e3
  viscosity = 1.0
  diffusivity = 0.0
}
comp.Air
{
  phase = Gas
  density = 1.2
  viscosity = 0.018
  diffusivity = 0.0
}

comp.dominant = Air
comp.lo_bc = 4 1 
comp.hi_bc = 4 1
comp.init = ALL
comp.ALL
{
  type = zero_total_velocity
  inflow = -2.53e-8
}

# boundary conditions
comp.inflow = YHIBC YLOBC

comp.YHIBC
{
   type = zero_total_velocity
   rock = Backfill
   inflow = -2.535e-8
}

comp.YLOBC
{
   type = scalar
   Water = 1000
   Air = 0.
}



# tracer
# ------


tracer.ntracer = 15
tracer.group   = Total Solid Absorbed
tracer.tracer =  Al+++ H+ HPO4-- SiO2 UO2++ Ca++ Kaolinite Quartz Calcite SAl+++ SH+ SHPO4-- SSiO2 SUO2++ SCa++ 

tracer.Al+++
{
	group = Total
}

tracer.H+
{
	group = Total
}

tracer.HPO4--
{
	group = Total
}

tracer.HCO3-
{
        group = Total
}


tracer.SiO2
{
	group = Total
}

tracer.UO2++
{
	group = Total
}

tracer.Ca++
{
	group = Total
}

tracer.Kaolinite
{
	group = Solid
}

tracer.Quartz
{
	group = Solid
}

tracer.Calcite
{
	group = Solid
}

tracer.SAl+++
{
	group = Absorbed
}

tracer.SH+
{
	group = Absorbed
}

tracer.SHPO4--
{
	group = Absorbed
}

tracer.SSiO2
{
	group = Absorbed
}

tracer.SUO2++
{
	group = Absorbed
}

tracer.SCa++
{
	group = Absorbed
}

tracer.init = Granite_Backfill_Region Limestone_Backfill_Region Waste_Region

tracer.Granite_Backfill_Region
{
type = scalar
Al+++ = 6.5874e-9
H+ = -3.1408e-7
#HPO4-- = 1.00e-6
HPO4-- = 0.0
HCO3- = 0.0
SiO2 = 1.8703e-4
UO2++ = 1.0e-15
Ca++ = 0.0
Kaolinite = 0.0
Quartz = 0.0
Calcite = 0.0
SAl+++ = 0.0
SH+ = 0.0
SHPO4-- = 0.0
SSiO2 = 0.0
SUO2++ = 0.0
SCa++ = 0.0
}

tracer.Limestone_Backfill_Region
{
type = scalar
Al+++ = 6.5874e-9
H+ = -3.1408e-7
#HPO4-- = 1.00e-6
HPO4-- = 0.0
HCO3- = 1.0e-6
SiO2 = 1.8703e-4
UO2++ = 1.0e-15
Ca++ = 1.0e-5
Kaolinite = 0.0
Quartz = 0.0
Calcite = 0.0
SAl+++ = 0.0
SH+ = 0.0
SHPO4-- = 0.0
SSiO2 = 0.0
SUO2++ = 0.0
SCa++ = 1.0
}



tracer.Waste_Region
{
type = scalar
Al+++ = 6.5874e-9
H+ = -3.1408e-7
#HPO4-- = 1.00e-6
HPO4-- = 0.0
HCO3- = 0.0
SiO2 = 1.8703e-4
UO2++ = 1.0e-5
Ca++ = 1.0e-5
Kaolinite = 0.0
Quartz = 0.0
Calcite = 0.0
SAl+++ = 0.0
SH+ = 0.0
SHPO4-- = 0.0
SSiO2 = 0.0
SUO2++ = 0.0
SCa++ = 0.0
}


tracer.inflow = YHIBC YLOBC

tracer.YHIBC
{
type = scalar
Al+++ = 6.5874e-9
H+ = -3.1408e-7
#HPO4-- = 1.00e-6
HPO4-- = 0.0
HCO3- = 0.0
SiO2 = 1.8703e-4
UO2++ = 1.0e-15
Ca++ = 0.0
Kaolinite = 0.0
Quartz = 0.0
Calcite = 0.0
SAl+++ = 0.0
SH+ = 0.0
SHPO4-- = 0.0
SSiO2 = 0.0
SUO2++ = 0.0
SCa++ = 0.0
}

tracer.YLOBC
{
type = scalar
Al+++ = 6.5874e-9
H+ = -3.1408e-7
#HPO4-- = 1.00e-6
HPO4-- = 0.0
HCO3- = 0.0
SiO2 = 1.8703e-4
UO2++ = 1.0e-15
Ca++ = 0.0
Kaolinite = 0.0
Quartz = 0.0
Calcite = 0.0
SAl+++ = 0.0
SH+ = 0.0
SHPO4-- = 0.0
SSiO2 = 0.0
SUO2++ = 0.0
SCa++ = 0.0
}


# chemistry
# ---------
prob.amanzi.file = uo2-7-component.bgd
prob.n_chem_interval = 0

prob.do_chem = 2

# pressure (atm)
# -------------

press.press_lo = 0 0
press.press_hi = 0 0
press.inflow_bc_lo  = 0 0 
press.inflow_bc_hi  = 0 1 
press.inflow_vel_lo = 0 0
press.inflow_vel_hi = 0 0
press.lo_bc = 4 1
press.hi_bc = 4 1
press.water_table_lo = 0
press.water_table_hi = 0

# source term
# -----------
source.do_source = 0
source.source = Infiltration 

#Discharge Tracer_Discharge

source.Infiltration
{
  var_type  = comp
  var_id    = Water
  region    = Top_Region
  dist_type = constant
  val       = 9.524e-6
}

# capillary pressure
prob.have_capillary = 1

# flow related
prob.model  = 2
prob.no_corrector = 0
prob.full_cycle = 1
prob.do_reflux  = 1
#amr.restart = temp/chk52600
amr.check_file = temp/chk
amr.plot_file = temp/plt
amr.max_grid_size = 64

amr.n_error_buf = 2 2 2 
amr.grid_eff = 0.75

#prob.fixed_dt  = 8000
max_step = 10000
#stop_time = 500000

#*******************************************************************************
# Number of cells in each coordinate direction at the coarsest level
amr.n_cell = 32 32

#*******************************************************************************
# Maximum level (defaults to 0 for single level calculation)
amr.max_level = 0

#*******************************************************************************

#Verbosity controls
amr.v = 2
mac.v = 3
mg.v  = 1
prob.v  = 3
cg.v  = 0
diffuse.v = 2

#Solver controls
#mac.use_cg_solver = 0
prob.visc_tol      = 1.e-12
prob.visc_abs_tol  = 1.e-14
mac.mac_tol      = 1.e-12
mac.mac_sync_tol = 1.e-12
mac.mac_abs_tol  = 1.e-14
#mac.use_fboxlib_mg = true
#diffuse.use_fboxlib_mg = true
mg.cg_solver = 1
mg.maxiter = 100
cg.unstable_criterion = 100
cg.use_jacobi_precond = 1
#mg.usecg = 2
#mg.use_jbb_precond = 1
#mg.maxiter = 100
##mg.nu_b = 4
#mg.nu_0 = 2
#mg.nu_1 = 4
#mg.nu_2 = 4
#mg.nu_f = 10
#mg.rtol_b = 1.e-4
mg.smooth_on_cg_unstable = 1	
#*******************************************************************************
# Interval (in number of level l timesteps) between regridding
amr.regrid_int		= 2 

#*******************************************************************************
# Refinement ratio as a function of level
amr.ref_ratio		= 2 2

#*******************************************************************************
# Interval (in number of coarse timesteps) between plotfiles / checkpoint files
amr.plot_int		= 100
amr.check_int		= 100

#*******************************************************************************

# CFL number to be used in calculating the time step : dt = dx / max(velocity)
prob.cfl                  = 0.8 # CFL number used to set dt

#*******************************************************************************

# Factor by which the first time is shrunk relative to CFL constraint
prob.init_shrink          = 1  # factor which multiplies the very first time step

#*******************************************************************************

# Name of the file which specifies problem-specific parameters (defaults to "probin")
amr.probin_file 	= probin


#*******************************************************************************

# Factor by which grids must be coarsenable.
amr.blocking_factor     = 16

#*******************************************************************************

# Add vorticity to the variables in the plot files.
amr.derive_plot_vars    = gradpx gradpy gradn

#*******************************************************************************
