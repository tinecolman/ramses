"""Plot results of the sink supernova blast test"""
import matplotlib
matplotlib.use('Agg')

from matplotlib import pyplot as plt
import numpy as np
import visu_ramses

out_end = 2

# Code units of the run (see the &UNITS_PARAMS block of sn-blast.nml)
unit_d = 1.66e-24
unit_t = 3.004683525921981e15
unit_l = 3.08567758128200e+18
unit_v = unit_l / unit_t

MH = 1.6737236e-24  # g
KB = 1.38064852e-16  # cm^2 g s^-2 K^-1

data = visu_ramses.load_snapshot(out_end)

x = data["data"]["x"]
y = data["data"]["y"]
z = data["data"]["z"]
dx = data["data"]["dx"]
rho = data["data"]["density"]
p = data["data"]["pressure"] * unit_d * unit_l**2 / unit_t**2
vx = data["data"]["velocity_x"]
vy = data["data"]["velocity_y"]
vz = data["data"]["velocity_z"]

temperature = p / (rho * unit_d) * 2.37 * MH / KB

# The supernova goes off on the sink, which does not move (no gravity)
xs = data["sinks"]["x"][0]
ys = data["sinks"]["y"][0]
zs = data["sinks"]["z"][0]

r = np.sqrt((x - xs)**2 + (y - ys)**2 + (z - zs)**2)
# Radial velocity, positive outwards
vr = ((x - xs) * vx + (y - ys) * vy + (z - zs) * vz) / np.maximum(r, 0.5 * dx)

# Slice of thickness one cell through the supernova centre
cut = np.abs(z - zs) < 0.5 * dx

fig, ax = plt.subplots(nrows=1, ncols=3, figsize=(15, 4.5))

im = ax[0].scatter(x[cut], y[cut], c=rho[cut], s=4, marker='s')
plt.colorbar(im, ax=ax[0], label='Density [H/cc]')
ax[0].scatter([xs], [ys], s=40, marker='x', color='red')
ax[0].set_xlabel('x [pc]')
ax[0].set_ylabel('y [pc]')
ax[0].set_title('Density in the z = z$_{sink}$ slice')

ax[1].plot(r, rho, ',')
ax[1].set_xlabel('r from the supernova [pc]')
ax[1].set_ylabel('Density [H/cc]')
ax[1].set_yscale('log')

ax[2].plot(r, vr * unit_v / 1.0e5, ',')
ax[2].set_xlabel('r from the supernova [pc]')
ax[2].set_ylabel('Radial velocity [km/s]')

fig.savefig('sn-blast.pdf', bbox_inches='tight')

# Check results against reference solution
for key in data["sinks"].keys():
    data["data"]["sink_" + key] = data["sinks"][key]
visu_ramses.check_solution(data["data"], 'sn-blast', threshold=1e-30, overwrite=False)
