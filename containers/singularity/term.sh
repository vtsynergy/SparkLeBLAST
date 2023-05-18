#!/bin/bash

singularity exec --no-home --bind hosts:/etc/hosts sparkleblast_latest.sif /bin/bash
