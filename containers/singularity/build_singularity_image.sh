#!/bin/bash
#PJM -L elapse=0:30:00
#PJM -L node=1
#PJM -x PJM_LLIO_GFSCACHE=/vol0004
#PJM -x SINGULARITY_TMPDIR=/local
#PJM -g ra000012
#PJM --llio localtmp-size=20Gi
#PJM -L jobenv=singularity

singularity pull -F docker://karimyoussef1991/sparkleblast:latest

echo "DONE"
