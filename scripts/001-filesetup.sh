#!/bin/bash

# copy the wiki database if it is not already there
cp /opt/wiki/database.sqlite /course/wiki/database.sqlite

# Copy the builtin content to the mounted volume
cp -n -r -u -v /builtin/jupyter/. /course/jupyter/notebooks/tutorials/
cp -n -r -u -v /builtin/coursework/. /course/coursework/
cp -n -r -u -v /builtin/lectures/. /course/lectures/
cp -n -r -u -v /builtin/practiceProblems/. /course/practiceProblems/

