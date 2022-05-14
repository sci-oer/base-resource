#!/bin/bash

# start the ssh service
sudo service ssh start

#sudo su $UNAME


# fix permissions, is this desired?
#chown -R 1000 /course

# configure git to be able to commit within the container
if [[ ! -z "${GIT_EMAIL}" ]]; then
    git config --global user.email "$GIT_EMAIL"
fi

if [[ ! -z "${GIT_NAME}" ]]; then
    git config --global user.name "$GIT_NAME"
fi

# Setup directories in the potentially mounted volume
LOGDIR="/course/logs"
mkdir -p "/course/wiki" \
        "/course/jupyter/notebooks/tutorials"  \
        "/course/coursework" \
        "/course/lectures" \
        "/course/practiceProblems" \
        "$LOGDIR"

GLOBIGNORE="*.async.sh:/scripts/entrypoint.sh"
for file in /scripts/*.sh; do
  case "$file" in
       *.async.sh ) continue;;
  esac

  base=$(basename $file .sh)
  ( $file > $LOGDIR/$base-out.log 2> $LOGDIR/$base-err.log )
done

GLOBIGNORE="/scripts/entrypoint.sh"
for file in /scripts/*.async.sh; do
  base=$(basename $file .sh)

  ( $file > $LOGDIR/$base-out.log 2> $LOGDIR/$base-err.log & )
done

cat /scripts/motd.txt


# if it is not interactive then print an error message with suggestion to use docker run -it instead
if [ ! -t 1 ] ; then
       # see if it supports colors...
    ncolors=$(tput colors)

    if test -n "$ncolors" && test $ncolors -ge 8; then
        bold="$(tput bold)"
        underline="$(tput smul)"
        standout="$(tput smso)"
        normal="$(tput sgr0)"
        black="$(tput setaf 0)"
        red="$(tput setaf 1)"
        green="$(tput setaf 2)"
        yellow="$(tput setaf 3)"
        blue="$(tput setaf 4)"
        magenta="$(tput setaf 5)"
        cyan="$(tput setaf 6)"
        white="$(tput setaf 7)"
    fi

    echo "${red}ERROR!! This container must be run interactivly try again with: ${yellow}`docker run -it`${normal}"
    exit -2
fi

#su -l student
bash
