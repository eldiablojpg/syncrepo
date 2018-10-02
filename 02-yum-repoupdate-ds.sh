#!/bin/bash
# Yum repository updater script for CentOS (downstream)
# Currently syncs CentOS, EPEL, and EPEL Testing
# Version 1.4.2 updated 20181003 by <AfroThundr>

# Version handler
for i in "$@"; do
    if [ "$i" = "-v" ]; then
        v=$(head -4 "$0" | tail -1)
        printf '%s\n' "$v"
        exit 0
    fi
done

# Declare some variables (modify as necessary)
repodir=/srv/repository
centosrepo=$repodir/centos
epelrepo=$repodir/epel
mirror=yum.dmz.lab.local
centoshost=$mirror::centos
epelhost=$mirror::fedora-epel
lockfile=/var/lock/subsys/yum_rsync
logfile=/var/log/yum_rsync.log
progfile=/var/log/yum_rsync_prog.log

# Build the commands, with more variables
rsync="rsync -hlmprtzDHS --stats --no-motd --del --delete-excluded --log-file=$progfile"
teelog="tee -a $logfile $progfile"

# Here we go...
printf '%s: Progress log reset.\n' "$(date -u +%FT%TZ)" > $progfile
printf '%s: Started synchronization of CentOS and EPEL repositories.\n' "$(date -u +%FT%TZ)" | $teelog
printf '%s: Use tail -f %s to view progress.\n\n' "$(date -u +%FT%TZ)" "$progfile"

# Check if the rsync script is already running
if [ -f $lockfile ]; then
    printf '%s: Error: Repository updates are already running.\n\n' "$(date -u +%FT%TZ)" | $teelog
    exit 10

# Check that we can reach the public mirror
elif ! ping -c 5 $mirror &> /dev/null; then
    printf '%s: Error: Cannot reach the %s mirror server.\n\n' "$(date -u +%FT%TZ)" "$mirror" | $teelog
    exit 20

# Check that the repository is mounted
elif ! mount | grep $repodir &> /dev/null; then
    printf '%s: Error: Directory %s is not mounted.\n\n' "$(date -u +%FT%TZ)" "$repodir" | $teelog
    exit 30

else

    # Just sync everything since we're downstream

    # Create lockfile, sync centos repo, delete lockfile
    printf '%s: Beginning rsync of CentOS repo from %s.\n' "$(date -u +%FT%TZ)" "$centoshost" | $teelog
    touch $lockfile
    $rsync "$centoshost/" "$centosrepo/"
    rm -f $lockfile
    printf '%s: Done.\n\n' "$(date -u +%FT%TZ)" | $teelog

    # Create lockfile, sync epel repo, delete lockfile
    printf '%s: Beginning rsync of EPEL repo from %s.\n' "$(date -u +%FT%TZ)" "$epelhost" | $teelog
    touch $lockfile
    $rsync "$epelhost/" "$epelrepo/"
    rm -f $lockfile
    printf '%s: Done.\n\n' "$(date -u +%FT%TZ)" | $teelog

fi

# Now we're done
printf '%s: Completed synchronization of CentOS and EPEL repositories.\n\n' "$(date -u +%FT%TZ)" | $teelog
exit 0