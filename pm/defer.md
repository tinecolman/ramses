The problem it solves
make_tree_fine walks grids in parallel. When a particle has drifted into a sister grid, check_tree must unlink it from its old grid and append it to the new one. Appending writes tailp of the destination — and two threads processing different source grids can be appending to the same destination. That's why the original code wrapped the splice in critical(omp_particle_list).

But a lock only guarantees the threads take turns, not in which order. Whichever thread reaches the lock first appends first, so the resulting list order changes from run to run — which is what breaks the MC tracers.

The three phases
1. Before the parallel region — call defer_reset(nthr) (line 271)

Allocates one buffer per thread on first use, and sets each n = 0. Nothing else.

2. Inside the parallel region — record instead of apply

The gather loop already builds ind_part (which particle) and ind_grid_part (which grid it came from). One line is added:


ind_key(ip) = defer_key(icpu, jgrid)
ind_key is a new threadprivate array alongside the existing ones. defer_key packs the traversal position into one 8-byte integer:


key = ishft(int(icpu, ikey), 32) + int(jgrid, ikey)
icpu in the high 32 bits, jgrid in the low 32 — so comparing keys compares (icpu, jgrid) lexicographically, which is exactly traversal order. It needs an explicit 8-byte kind: amr_parameters' i8b is selected_int_kind(9), only 4 bytes here, and the shift would silently produce garbage.

Then in check_tree, where remove_list/add_list used to be called:


call defer_push(defer_thread(), ind_key(j), DEFER_REMOVE_LIST, ind_part(j), list1(j))
call defer_push(defer_thread(), ind_key(j), DEFER_ADD_LIST,    ind_part(j), list2(j))
defer_push appends (key, op, particle, grid) to the calling thread's own buffer, growing it by doubling. No lock — each thread only touches its own buffer. The shared lists are not modified at all inside the parallel region.

3. After the parallel region — call defer_apply(nthr) (line 335)

Replays every recorded operation, serially, in key order, calling remove_list_one/add_list_one — the same pointer code the batch routines use, factored out so there's one implementation.

Why the replay is a merge, not a sort
Each thread's buffer is already sorted by key: !$omp do hands out iterations in increasing jgrid, and the do icpu loop enclosing it is sequential within a thread. So defer_apply just repeatedly picks whichever buffer has the smallest key at its current position — O(N·nthr), no sorting.

Because it's a stable merge and a grid is processed by exactly one thread, ties can't occur across buffers, and within a buffer the entries stay in jpart order. That's why the key only needs (icpu, jgrid) and not the particle's position within the grid.

Why the result equals the serial answer
Replaying in traversal order reproduces exactly the sequence of splices a serial run would have performed. That's the property that was measured: at 1 thread the output is bit-identical to the pre-change build (e7567df6), and at 2 threads — with virtual_tree_fine serialised — it's dec2a4dd on both runs, matching the fully-serialised reference.

Two things to keep in mind while reviewing
The REMOVE and ADD for one particle carry the same key, and are pushed in that order, so the merge keeps them adjacent and in the right sequence. But note this interleaves remove/add per particle, where the original did all removes for an nvector batch then all adds. That's safe — removal preserves the relative order of survivors, and a particle is never added before it's removed — and the bit-identical result confirms it, but it is a real change in the order of operations.

Second: this works only because traversal reads the frozen headp_old/nextp_old snapshot, so deferring the mutations can't disturb the walk. kill_tree_fine has no such snapshot and reads the live list — deferring there actually removes a pre-existing traverse-while-mutating hazard, and is safe because its destinations are at ilevel+1, which that traversal never visits.