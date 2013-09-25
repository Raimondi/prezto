## figure out what the PATH should be
typeset -U common_paths
if { [[ ${OSTYPE} == darwin* && -x /usr/libexec/path_helper ]] } {
  # system-wide environment settings for zsh(1)
  eval `/usr/libexec/path_helper -s`
}

common_paths=(
  ${HOME}/bin					# personal stuff
  ${HOME}/.local/bin				# personal stuff
  ${HOME}/.cabal/bin				# personal stuff
  #/usr/games					# fun stuff
  #/var/qmail/bin				# qmail - uncomment if desired
  #/usr/platform/$(uname -i)/sbin		# solaris - hardware dependent
  #/usr/ccs/bin					# solaris - C Compilation System
  /sw/bin /sw/sbin                      	# Mac OS X - fink
  /opt/local/bin /opt/local/sbin /opt/SUNWspro/bin	# solaris
  /opt/local/Library/Frameworks/Python.framework/Versions/2.7/bin
  #/usr/xpg4/bin /usr/xpg6/bin			# solaris - X/Open Portability Guide
  #/usr/sfw/bin /usr/sfw/sbin			# solaris - sun free-ware
  #/usr/ucb					# solaris - BSD
  #/usr/pkg/bin /usr/pkg/sbin			# ???
  /usr/X11R6/bin				# X11
  /usr/local/bin /usr/local/sbin		# freeBSD
  /bin /sbin /usr/bin /usr/sbin			# good places to look
  ${path} ${=$(command -p getconf PATH 2> /dev/null)//:/ } # what the system thinks PATH should be
  )
unset PATH_tmp
unsetopt NOMATCH
for temp_path in ${common_paths}
do
  #echo $temp_path
  if [[ ${OSTYPE} == solaris* ]] {
    ## solaris may has some of these directories owned by "bin:bin" (uid 2)
    ## observed on: SunOS 5.10 Generic_120011-14 sparc, core install
    test -d "${temp_path}"(u0r^IWt,u2r^IWt,Ur^IWt) && PATH_tmp="${PATH_tmp}:${temp_path}"
  } elif [[ ${OSTYPE} == *freebsd* && \
    1 == "`/sbin/sysctl -n security.jail.jailed`" ]] 2> /dev/null {
    ## in a bsd jail, look for symlinks, not just directories
    test -e "${temp_path}"(-/u0r^IWt,-/Ur^IWt) && PATH_tmp="${PATH_tmp}:${temp_path}"
  } elif [[ ${OSTYPE} == cygwin ]] {
    ## f**king windoze - trying to enforce reasonable security here will just break things
    test -e "${temp_path}"(/F) && PATH_tmp="${PATH_tmp}:${temp_path}"
  } else {
    ## this is the normal case
    #test -d "${temp_path}"(u0r^IWt,Ur^IWt) && PATH_tmp="${temp_path}:${PATH_tmp}"
    test -d "${temp_path}" && PATH_tmp="${PATH_tmp}:${temp_path}"
  }
done
setopt NOMATCH
#export PATH=${PATH_tmp/%:/}
export PATH=${PATH_tmp#:}
unset common_paths temp_path PATH_tmp
