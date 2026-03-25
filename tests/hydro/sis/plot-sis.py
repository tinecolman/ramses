import matplotlib as mpl
mpl.use('Agg')
import numpy as np
import matplotlib.pyplot as plt
import f90nml
import visu_ramses
from scipy.interpolate import griddata

namelist = f90nml.read("output_00001/namelist.txt")
mu_gas = namelist['cooling_params']['mu_gas']

# Fundamental constants
MH = 1.6737236e-24 #g                      # hydrogen mass
KB = 1.38064852e-16 #cm^2 g s^-2 K^-1      # Boltzman constant
AU = 1.49597871e13 #cm                     # 1 astronomical unit

fig, ax = plt.subplots(nrows=1, ncols=2, figsize=(10, 5))

# Load RAMSES output
data = visu_ramses.load_snapshot(2)
unit_d = data["data"]["unit_d"]
unit_t = data["data"]["unit_t"]
unit_l = data["data"]["unit_l"]
rho  =  data["data"]["density"] * unit_d
p    =  data["data"]["pressure"] * unit_d * unit_l**2 / unit_t**2
T    = p/rho * mu_gas * MH /KB

# ------------------------------
# density - temperature diagram
# ------------------------------

# histogram bin edges
dmin = -18.5
dmax = -3.0
tmin = 0.5
tmax = np.log10(max(T)) + 0.5
nx = 129
d_edges = np.linspace(dmin,dmax,nx)
t_edges = np.linspace(tmin,tmax,nx)

# compute histogram
za, yedges1, xedges1 = np.histogram2d(np.log10(T),np.log10(rho),bins=(t_edges,d_edges))

# bin centers
d_mesh = np.zeros([nx-1])
t_mesh = np.zeros([nx-1])
for i in range(nx-1):
    d_mesh[i] = 0.5*(d_edges[i]+d_edges[i+1])
    t_mesh[i] = 0.5*(t_edges[i]+t_edges[i+1])

# plot contour of histogram
ax[0].contour(d_mesh,t_mesh,za,colors='r',levels=[1.0])

# overplot analytical solution EOS
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
ax[0].plot(np.log10(rho_ana), np.log10(T_ana), color='black')

# layout
ax[0].set_xlabel('log(rho)')
ax[0].set_ylabel('log(T)')


# -------------------
# density projection
# -------------------

x    = (data["data"]["x"] - 0.5*data["data"]["boxlen"]) * unit_l / AU
y    = (data["data"]["y"] - 0.5*data["data"]["boxlen"]) * unit_l / AU
z    = (data["data"]["z"] - 0.5*data["data"]["boxlen"]) * unit_l / AU

# we want to zoom in on the center
nx = 2**7
dxmin = data["data"]["boxlen"] / (2**namelist['amr_params']['levelmax']) * unit_l / AU 
zoom = nx*dxmin
filt = np.where((abs(x)<zoom)&(abs(y<zoom))&(abs(z<zoom)))

# generate grid points for interpolation
xpx = np.linspace(-0.5*zoom + 0.5*dxmin, 0.5*zoom - 0.5*dxmin,nx)
grid_x, grid_y, grid_z = np.meshgrid(xpx,xpx,xpx)
points = np.transpose([x,y,z])

# interpolate
z1 = griddata(points,rho,(grid_x,grid_y, grid_z),method='nearest')

# project and plot
rho_proj = np.sum(z1, axis=2) #proj along x-axis
im1 = ax[1].imshow(rho_proj, origin="lower", aspect='equal', 
                   extent=[-0.5*zoom, 0.5*zoom, -0.5*zoom, 0.5*zoom])

plt.colorbar(im1, ax=ax[1], label='density')
ax[1].set_xlabel('x [AU]')
ax[1].set_ylabel('y [AU]')

# --------------------
# Output test results
# --------------------

fig.savefig('sis.pdf',bbox_inches='tight')

# Check results against reference solution
visu_ramses.check_solution(data["data"],'sis', overwrite=True)
