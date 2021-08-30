import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
import matplotlib.cm as cmx
import numpy as np
from scipy.interpolate import griddata
import visu_ramses

def my_proj(var, axis):
    return np.max(var, axis=axis)

# Load RAMSES output
data = visu_ramses.load_snapshot(2)
x      = data["data"]["x"]
y      = data["data"]["y"]
z      = data["data"]["z"]
dx     = data["data"]["dx"]
rho    = data["data"]["density"]
vx     = data["data"]["velocity_x"]
vy     = data["data"]["velocity_y"]
vz     = data["data"]["velocity_z"]

# grid
nx  = 2**6
xmin = np.amin(x-0.5*dx)
xmax = np.amax(x+0.5*dx)
ymin = np.amin(y-0.5*dx)
ymax = np.amax(y+0.5*dx)
zmin = np.amin(z-0.5*dx)
zmax = np.amax(z+0.5*dx)
dpx = (xmax-xmin)/float(nx)
dpy = (ymax-ymin)/float(nx)
dpz = (zmax-zmin)/float(nx)
xpx = np.linspace(xmin+0.5*dpx,xmax-0.5*dpx,nx)
ypx = np.linspace(ymin+0.5*dpy,ymax-0.5*dpy,nx)
zpx = np.linspace(zmin+0.5*dpz,zmax-0.5*dpz,nx)
grid_x, grid_y, grid_z = np.meshgrid(xpx,ypx,zpx)
points = np.transpose([x,y,z])
z1 = griddata(points,rho,(grid_x,grid_y,grid_z),method='nearest')
z2 = griddata(points,vx ,(grid_x,grid_y,grid_z),method='nearest')
z3 = griddata(points,vy ,(grid_x,grid_y,grid_z),method='nearest')
z4 = griddata(points,vz ,(grid_x,grid_y,grid_z),method='nearest')

fig, ax = plt.subplots(nrows=1, ncols=3, figsize=(10, 2.5), sharex=True, sharey=True)

# plot density maps
rho_init = 0.28954719470909174
rho_proj3 = my_proj(z1, axis=2) #proj along z-axis
im0 = ax[0].imshow(rho_proj3, origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], norm=LogNorm())

# plot velocity projections
#vlim=12.5
vlim=max(np.max(my_proj(z2, axis=2)), np.max(my_proj(z3, axis=2)))
im1 = ax[1].imshow(my_proj(z2, axis=2)  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm', vmin=-vlim, vmax=vlim)
im2 = ax[2].imshow(my_proj(z3, axis=2) , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm', vmin=-vlim, vmax=vlim)
#im3 = ax[3].imshow(my_proj(z4, axis=2) , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)

# add colorbars
plt.colorbar(im0, ax=ax[0])
plt.colorbar(im1, ax=ax[1])
plt.colorbar(im2, ax=ax[2])
#plt.colorbar(im3, ax=ax[3], label='Velocity_z')
ax[0].set_title('density')
ax[1].set_title('x velocity')
ax[2].set_title('y velocity')

# labels
for i in range(3):
    ax[i].set_xlabel('x')
    ax[i].set_ylabel('y')

#plt.subplots_adjust(hspace=0.2, wspace=0.0)

fig.savefig('2D-anisotropic.pdf',bbox_inches='tight')

# Check results against reference solution
visu_ramses.check_solution(data["data"],'2D-anisotropic', threshold=1e-30, overwrite=False)
