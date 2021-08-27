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

fig, ax = plt.subplots(nrows=4, ncols=3, figsize=(8, 8), sharex=True, sharey=True)

fig_rho, ax_rho = plt.subplots(nrows=1, ncols=1, figsize=(3, 3))


# plot density maps
rho_init = 0.28954719470909174

rho_proj1 = my_proj(z1, axis=1) #proj along x-axis
rho_proj2 = my_proj(z1, axis=0) #proj along y-axis
rho_proj3 = my_proj(z1, axis=2) #proj along z-axis
#rho_proj1 = z1[int(nx/2),:,:]
#rho_proj2 = z1[:,int(nx/2),:]
#rho_proj3 = z1[:,:,int(nx/2)]

im1 = ax[0,0].imshow(rho_proj1, origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], norm=LogNorm())#vmin=rho_init*0.1, vmax=rho_init*10))
im2 = ax[0,1].imshow(rho_proj2.T, origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], norm=LogNorm())#vmin=rho_init*0.1, vmax=rho_init*10))
im3 = ax[0,2].imshow(rho_proj3, origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], norm=LogNorm())#vmin=rho_init*0.1, vmax=rho_init*10))

im3_rho = ax_rho.imshow(rho_proj3, origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], norm=LogNorm())#vmin=rho_init*0.1, vmax=rho_init*10))

# plot velocity projections
#vlim=12.5
vlim=2
im4 = ax[1,0].imshow(my_proj(z2, axis=1)  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im5 = ax[1,1].imshow(my_proj(z2, axis=0).T  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax],cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im6 = ax[1,2].imshow(my_proj(z2, axis=2)  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im7 = ax[2,0].imshow(my_proj(z3, axis=1)  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im8 = ax[2,1].imshow(my_proj(z3, axis=0).T  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im9 = ax[2,2].imshow(my_proj(z3, axis=2) , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im10 = ax[3,0].imshow(my_proj(z4, axis=1)  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im11 = ax[3,1].imshow(my_proj(z4, axis=0).T  , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)
im12 = ax[3,2].imshow(my_proj(z4, axis=2) , origin="lower", aspect='equal', extent=[xmin, xmax, ymin, ymax], cmap='coolwarm')#, vmin=-vlim, vmax=vlim)

# add colorbars
plt.colorbar(im3, ax=ax[0,2], label='density')
plt.colorbar(im6, ax=ax[1,2], label='Velocity_x')
plt.colorbar(im9, ax=ax[2,2], label='Velocity_y')
plt.colorbar(im12, ax=ax[3,2], label='Velocity_z')

plt.colorbar(im3_rho, ax=ax_rho, label='density')

# labels
ax[3,0].set_xlabel('y')
ax[3,1].set_xlabel('x')
ax[3,2].set_xlabel('x')


for i in range(4):
    ax[i,0].set_ylabel('z')
    ax[i,1].set_ylabel('z')
    ax[i,2].set_ylabel('y')

plt.subplots_adjust(hspace=0.2, wspace=0.0)

fig.savefig('anisotropic.pdf',bbox_inches='tight')
fig_rho.savefig('rho.png',bbox_inches='tight')


# Check results against reference solution
visu_ramses.check_solution(data["data"],'anisotropic', threshold=1e-30, overwrite=True)
