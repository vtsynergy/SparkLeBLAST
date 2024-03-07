#!/bin/bash
#PJM -L elapse=1:00:00
#PJM -L node=1
#PJM -g ra000012
#PJM --llio localtmp-size=20Gi
#PJM -L jobenv=singularity
#PJM -x PJM_LLIO_GFSCACHE=/vol0004
#PJM -x SINGULARITY_TMPDIR=/local

export TMPDIR=/worktmp
singularity build --fakeroot --no-setgroups sparkleblast_latest.sif fsparkleblast_latest.def

echo "DONE"
