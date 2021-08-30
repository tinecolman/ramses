import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
import matplotlib.cm as cmx
import numpy as np
from scipy.interpolate import griddata
import visu_ramses


def my_proj(var, axis):
    #return np.max(var, axis=axis)
    return np.sum(var, axis=axis)

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

xmin = np.amin(x-0.5*dx)
xmax = np.amax(x+0.5*dx)
ymin = np.amin(y-0.5*dx)
ymax = np.amax(y+0.5*dx)
zmin = np.amin(z-0.5*dx)
zmax = np.amax(z+0.5*dx)

nx  = 2**6
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

fig, ax = plt.subplots(nrows=3, ncols=4, figsize=(12, 6), sharex=True, sharey=True)

# plot density maps
rho_proj1 = my_proj(z1, axis=1) #proj along x-axis
rho_proj2 = my_proj(z1, axis=0) #proj along y-axis, not sure why these are reversed
rho_proj3 = my_proj(z1, axis=2) #proj along z-axis
im1 = ax[0,0].imshow(rho_proj1, origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], norm=LogNorm())#vmin=rho_init*0.1, vmax=rho_init*10))
im2 = ax[1,0].imshow(rho_proj2, origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], norm=LogNorm())#vmin=rho_init*0.1, vmax=rho_init*10))
im3 = ax[2,0].imshow(rho_proj3, origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], norm=LogNorm())#vmin=rho_init*0.1, vmax=rho_init*10))


# plot velocity projections
vlim=2
im4 = ax[0,1].imshow(my_proj(z2, axis=1)  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im5 = ax[1,1].imshow(my_proj(z2, axis=0)  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax],cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im6 = ax[2,1].imshow(my_proj(z2, axis=2)  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im7 = ax[0,2].imshow(my_proj(z3, axis=1)  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im8 = ax[1,2].imshow(my_proj(z3, axis=0)  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im9 = ax[2,2].imshow(my_proj(z3, axis=2) , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im10 = ax[0,3].imshow(my_proj(z4, axis=1)  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im11 = ax[1,3].imshow(my_proj(z4, axis=0)  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im12 = ax[2,3].imshow(my_proj(z4, axis=2) , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)

# add colorbars
plt.colorbar(im1, ax=ax[0,0])
plt.colorbar(im4, ax=ax[0,1])
plt.colorbar(im7, ax=ax[0,2])
plt.colorbar(im10, ax=ax[0,3])
plt.colorbar(im2, ax=ax[1,0])
plt.colorbar(im5, ax=ax[1,1])
plt.colorbar(im8, ax=ax[1,2])
plt.colorbar(im11, ax=ax[1,3])
plt.colorbar(im3, ax=ax[2,0])
plt.colorbar(im6, ax=ax[2,1])
plt.colorbar(im9, ax=ax[2,2])
plt.colorbar(im12, ax=ax[2,3])

ax[0,0].set_title('density')
ax[0,1].set_title('velocity_x')
ax[0,2].set_title('velocity_y')
ax[0,3].set_title('velocity_z')


# labels
for j in range(4):
    ax[0,j].set_xlabel('y') # x proj
    ax[0,j].set_ylabel('z')
    ax[1,j].set_xlabel('z') # y proj
    ax[1,j].set_ylabel('x')
    ax[2,j].set_xlabel('x') # z proj
    ax[2,j].set_ylabel('y')

#plt.subplots_adjust(hspace=0.0, wspace=0.0)

fig.savefig('driving-2d.pdf',bbox_inches='tight')

# Check results against reference solution
visu_ramses.check_solution(data["data"],'driving-2d', threshold=1e-30, overwrite=False)