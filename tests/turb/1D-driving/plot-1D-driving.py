import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import matplotlib.cm as cmx
import numpy as np
from scipy.interpolate import griddata
import visu_ramses


fig, ax = plt.subplots(nrows=2, ncols=2, figsize=(8, 8))

# initial conditions
rho_init = 0.28954719470909174
ax[0,0].plot([0,1], [rho_init,rho_init], color='black', label='t=0.0')
ax[0,1].plot([0,1], [0,0], color='black')
ax[1,0].plot([0,1], [0,0], color='black')
ax[1,1].plot([0,1], [0,0], color='black')

# define colors for plotting time evolution
cNorm  = colors.Normalize(vmin=0, vmax=7)
cmap = plt.cm.get_cmap('inferno')
scalarMap = cmx.ScalarMappable(norm=cNorm, cmap=cmap)
colorVals = []
for val in range(0,7):
    color = cmap(cNorm(val))
    colorVals.append(color)

for snap in range(2,7):
    # Load RAMSES output
    data = visu_ramses.load_snapshot(snap)
    x      = data["data"]["x"]
    y      = data["data"]["y"]
    z      = data["data"]["z"]
    dx     = data["data"]["dx"]
    rho    = data["data"]["density"]
    vx     = data["data"]["velocity_x"]
    vy     = data["data"]["velocity_y"]
    vz     = data["data"]["velocity_z"]

    # get 1 d arrays
    x_sorted=sorted(x)
    rho_sorted = [i for _,i in sorted(zip(x,rho))]
    vx_sorted = [i for _,i in sorted(zip(x,vx))]
    vy_sorted = [i for _,i in sorted(zip(x,vy))]
    vz_sorted = [i for _,i in sorted(zip(x,vz))]

    # plot quantities
    ax[0,0].plot(x_sorted, rho_sorted, label='t={:.1f}'.format(0.2*(snap-1)), color=colorVals[snap])
    ax[0,1].plot(x_sorted, vx_sorted, color=colorVals[snap])
    ax[1,0].plot(x_sorted, vy_sorted, color=colorVals[snap])
    ax[1,1].plot(x_sorted, vz_sorted, color=colorVals[snap])

# axis layout
for i in [0,1]:
    for j in [0,1]:
        ax[i,j].set_xlabel('x')
        ax[i,j].set_xlim(0,1)
ax[0,1].set_ylabel('velocity x')
ax[1,0].set_ylabel('velocity y')
ax[1,1].set_ylabel('velocity z')
ax[0,0].set_ylabel('density')
ax[0,0].set_yscale('log')
ax[0,0].legend()

fig.savefig('1D-driving.pdf',bbox_inches='tight')

# Check results against reference solution
visu_ramses.check_solution(data["data"],'1D-driving', threshold=1e-30, overwrite=False)
