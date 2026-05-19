#!/bin/bash
# Simple build wrapper - run this after use_idf5
cd "$(dirname "$0")"
idf.py build
