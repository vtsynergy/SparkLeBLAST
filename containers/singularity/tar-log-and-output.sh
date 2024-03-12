#!/bin/bash

tar czf sparkle-logs-and-output-$(date -I).tgz mkdb.tmp.* output.* run log work data/out/*/sharedout_formatting_logs
