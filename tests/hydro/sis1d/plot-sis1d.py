import matplotlib as mpl
mpl.use('Agg')
import numpy as np
import matplotlib.pyplot as plt
import f90nml
import visu_ramses

namelist = f90nml.read("output_00001/namelist.txt")
mu_gas = namelist['cooling_params']['mu_gas']

# Fundamental constants
MH = 1.6737236e-24 #g                      # hydrogen mass
KB = 1.38064852e-16 #cm^2 g s^-2 K^-1      # Boltzman constant
AU = 1.49597871e13 #cm                     # 1 astronomical unit

fig, ax = plt.subplots(nrows=1, ncols=2, figsize=(12, 4))

# -------------------
# density profile evolution
# -------------------

for out in range(1,42,4):
   # Load RAMSES output
   data = visu_ramses.load_snapshot(out)
   unit_d = data["data"]["unit_d"]
   unit_t = data["data"]["unit_t"]
   unit_l = data["data"]["unit_l"]
   x    = (data["data"]["x"] - 0.5*data["data"]["boxlen"]) * unit_l / AU
   dx = data["data"]["dx"]
   rho  =  data["data"]["density"] * unit_d
   sorted_indices = np.argsort(x)
   ax[1].plot(x[sorted_indices],rho[sorted_indices])

ax[1].set_xlabel('x [AU]')
ax[1].set_ylabel('rho')
ax[1].set_xscale('log')
ax[1].set_yscale('log')

# ------------------------------
# density - temperature diagram
# ------------------------------

p    =  data["data"]["pressure"] * unit_d * unit_l**2 / unit_t**2
T    = p/rho * mu_gas * MH /KB
ax[0].scatter(rho,T,marker='o', color='red')

# overplot analytical solution EOS
dmin = -18.5
dmax = -3.0
polytrope_rho1 = 3.866301516e-15
polytrope_rho2 = 3.866301516e-10
polytrope_rho3 = 3.866301516e-05
polytrope_i1 = 0.4
polytrope_i2 = -0.3
polytrope_i3 = 0.56667
rho_ana = np.logspace(dmin,dmax,100)
factor1 = np.sqrt(1 + (rho_ana/polytrope_rho1)**(2*polytrope_i1))
factor2 = (1 + (rho_ana/polytrope_rho2))**polytrope_i2
factor3 = (1 + (rho_ana/polytrope_rho3))**polytrope_i3
T_ana = 10 * factor1 * factor2 * factor3
ax[0].plot(rho_ana, T_ana, color='black')

# layout
ax[0].set_xlabel('rho')
ax[0].set_ylabel('T')
ax[0].set_xscale('log')
ax[0].set_yscale('log')

# --------------------
# Output test results
# --------------------

fig.savefig('sis1d.pdf',bbox_inches='tight')

# Check results against reference solution
visu_ramses.check_solution(data["data"],'sis1d', overwrite=True)
