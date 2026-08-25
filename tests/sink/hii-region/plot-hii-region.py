"""Plot results of the sink HII region test"""
import matplotlib
matplotlib.use('Agg')

from matplotlib import pyplot as plt
import numpy as np
import visu_ramses

out_end = 2

data = visu_ramses.load_snapshot(out_end, read_rt=True)

x = data["data"]["x"]
y = data["data"]["y"]
z = data["data"]["z"]
dx = data["data"]["dx"]
rho = data["data"]["density"]
xHII = data["data"]["scalar_00"]

# Temperature in code units, as in stellar-HII
data["data"]["temperature"] = data["data"]["pressure"] / data["data"]["density"]

# The ionising source sits on the sink, which does not move (no gravity)
xs = data["sinks"]["x"][0]
ys = data["sinks"]["y"][0]
zs = data["sinks"]["z"][0]

r = np.sqrt((x - xs)**2 + (y - ys)**2 + (z - zs)**2)

# Slice of thickness one cell through the source
cut = np.abs(z - zs) < 0.5 * dx

fig, ax = plt.subplots(nrows=1, ncols=3, figsize=(15, 4.5))

im = ax[0].scatter(x[cut], y[cut], c=np.log10(np.maximum(xHII[cut], 1.0e-20)), s=4, marker='s')
plt.colorbar(im, ax=ax[0], label='log(x$_{HII}$)')
ax[0].scatter([xs], [ys], s=40, marker='x', color='red')
ax[0].set_xlabel('x [pc]')
ax[0].set_ylabel('y [pc]')
ax[0].set_title('Ionised fraction in the z = z$_{sink}$ slice')

ax[1].plot(r, np.maximum(xHII, 1.0e-20), ',')
ax[1].set_xlabel('r from the source [pc]')
ax[1].set_ylabel('x$_{HII}$')
ax[1].set_yscale('log')

ax[2].plot(r, rho, ',')
ax[2].set_xlabel('r from the source [pc]')
ax[2].set_ylabel('Density [H/cc]')

fig.savefig('hii-region.pdf', bbox_inches='tight')

# Check results against reference solution
for key in data["sinks"].keys():
    data["data"]["sink_" + key] = data["sinks"][key]
visu_ramses.check_solution(data["data"], 'hii-region', threshold=1e-30, overwrite=False)
