# Source this file in your .zshrc to setup a chpwd function that will
# maintain some helpful repo-related aliases for you.  These aliases
# change based on what kind of repo you've cd'ed into.
# 
# The aliases default to the following 2-letter commands (though you
# can configure them down in the repo_chpwd function):
#
# ad     Repo's "add" command.
#
# ci     Does a checkin, defaulting to the committing of all changed
#        files unless an arg beyond "-m msg" is specified (e.g. one or
#        more filenames).  For git, you can also specify a trailing -i
#        if you want to turn off the -a option without specifying any
#        files (and thus just commit things that have been explicitly
#        added).
#
# co     Does a checkout, for things like changing branches or updating
#        files to different versions.
#
# di     Repo's "diff" command.  Auto-pages.
#
# lo     Repo's "log" command.  Auto-pages.  The -v option can be used
#        to request that file names be included in the commit output,
#        even in git.  The -s option can be used in a git-svn repo to
#        ask for the "git svn log" output.
#
# st     Repo's "status" command.  For cvs, this uses a helper script
#        (cvs-status) to output status ala svn, with the default being
#        local-only output, and remote-status added in via -u (though
#        local cvs status does not include info on unknown files).  For
#        git, this hides a non-zero exit status (not needed for 1.7).
#
# pu     Push the currently-checked-in changes.  This has no effect in
#        svn or cvs.  For git, it will do the right thing in a git-svn
#        checkout, as well as a custom cvs-modifying git checkout (see
#        the helper-script git-cvs-push).
#
# up     Update from the saved remote repo location.  For git, this
#        defaults to doing a "git pull --rebase" for a normal repo, or
#        a "git svn rebase" for a git-svn repo.
#
# pa     Repo's "diff" command. Without auto-pages.
#
# ss     Temporarily remove non-commited changes. Only defined for git.
#
# The commands that "auto-page" pipe their output through "less -F" so
# that you get a pager if the output is long, and normal output if it is
# not.  It helps to have a modern version of less to avoid jumping down
# to the bottom of the screen when that is not needed.  Note that git
# auto-pages by default, so we leave it alone (which ensures auto-color
# is unaffected).
#
# The aliases that use helper functions get a compdef setting that makes
# them share their repo's command-line completion.
#
# See: http://opencoder.net/repos/ for more info and the helper scripts.

# Written by: Wayne Davison <wayne@opencoder.net>
# Freely redistributable.

function paged_cvs
{
    cvs "${@}" | less -F
}
compdef _cvs paged_cvs=cvs

function paged_svn
{
    svn "${@}" | less -F
}
compdef _subversion paged_svn=svn

function paged_bzr
{
    bzr "${@}" | less -F
}
compdef _bzr paged_bzr=bzr

function paged_hg
{
    hg "${@}" | less -F
}
compdef _mercurial paged_hg=hg

# This changes the default behavior of a git commit to assume the --all
# option unless it is overridden by explicit filenames or other options.
# To override this (committing just queued changes), this supports a trailing
# -i option (-i normally takes an arg, but has the new meaning if last).
function git4commit
{
    local arg args
    args=( commit )
    shift # discard "commit" arg
    # This makes -a the default with no args or just a -m arg.
    if [[ $# == 0 || ($# == 2 && x$1 == x-m) ]]; then
	args+=-a
    fi
    args+=( "${@}" )
    # This removes a trailing -i option (used to override the default -a
    # behavior and just commit what has been manually added).
    if [[ x$args[-1] == x-i ]]; then
	args[-1]=( )
    fi
    git $args
}
compdef _git git4commit=git

# This adds 2 new log options for git repos:
#   -v -> --name-stats
#   -s -> run "git svn log" instead of "git log".
function git4log
{
    local arg args
    args=( log )
    shift # discard "log" arg
    for arg in "${@}"; do
	if [[ x$arg == x-s && $REPOS_ZSH_GIT_TYPE == svn ]]; then
	    args=(svn $args)
	    continue
	fi
	if [[ x$arg == x-v && $args[1] == log ]]; then
	    arg=--name-status
	fi
	args+=$arg
    done
    git $args
}
compdef _git git4log=git

# This just forces the return code from "git status" to always be 0.  Since
# git 1.7 no longer has this issue, this will go away at some point.
function git4status
{
    git "${@}"
    return 0
}
compdef _git git4status=git

# This ensures that if something like "git init" is run on the current
# directory, we don't need a chdir event to figure out that we're now
# in an scm dir.
function recheck_scm_dir
{
    local x=$1
    shift
    repo_chpwd
    case $aliases[$x] in
    *recheck_scm_dir*) echo "You are not in an scm dir." ;;
    *) $=aliases[$x] "${@}" ;;
    esac
}

# This is the main function -- it is run after each chdir and a couple other times.
function repo_chpwd
{
    # This section defines the alias names that will be created.  If  you
    # want to use a different set of alias than the default 2-letter ones
    # Wayne created, change the name after the equal (e.g. "local ad=add").
    local ad=ad
    local ci=ci
    local co=co
    local di=di
    local lo=lo
    local st=st
    local pu=pu
    local up=up
    local pa=pa
    local ss=ss

    # You can also tweak the aliases below to have the options you like best.
    # Finally, you may wish to tweak things like my change to make "ci" default
    # to committing with --all.  To do that, either stop using git4commit (change
    # that reference to just "git") or tweak the git4commit function (above).

    local inode prior_inode check_dir=.

    while : ; do
	inode=`stat -c %i $check_dir`
	if [[ $inode == $prior_inode ]]; then
	    alias $ad="recheck_scm_dir $ad"
	    alias $ci="recheck_scm_dir $ci"
	    alias $co="recheck_scm_dir $co"
	    alias $di="recheck_scm_dir $di"
	    alias $lo="recheck_scm_dir $lo"
	    alias $st="recheck_scm_dir $st"
	    alias $pu="recheck_scm_dir $pu"
	    alias $up="recheck_scm_dir $up"
	    alias $pa="recheck_scm_dir $pa"
	    alias $ss="recheck_scm_dir $ss"
	    REPOS_ZSH_TYPE=none
	    break
	fi
	if [[ -d $check_dir/.git ]]; then
	    alias $ad='git add'
	    alias $ci='git commit'
	    alias $co='git checkout'
	    alias $di='git diff --patience'
	    alias $lo='git4log log --patience'
	    alias $st='git4status status'
	    if [[ -d $check_dir/.git/svn ]]; then
		alias $pu='git svn dcommit'
		alias $up='git svn rebase'
		export REPOS_ZSH_TYPE=git-svn
	    elif [[ -d $check_dir/.git/cvs ]]; then
		alias $pu="git-cvs-push '$check_dir'"
		alias $up='git pull --rebase'
		export REPOS_ZSH_TYPE=git-cvs
	    else
		alias $pu='git push'
		alias $up='git pull --rebase'
		export REPOS_ZSH_TYPE=git
	    fi
	    alias $pa='git diff --word-diff=color --no-ext-diff -w'
	    alias $ss='git stash'
	    break
	fi
	if [[ -d $check_dir/.bzr ]]; then
	    alias $ad='bzr add'
	    alias $ci='bzr commit'
	    alias $co='bzr checkout'
	    alias $di='paged_bzr diff'
	    alias $lo='paged_bzr log'
	    alias $pu='bzr push'
	    alias $st='bzr st'
	    alias $up='bzr pull'
	    alias $pa='bzr diff'
	    alias $ss='echo "This is not a Git repository!"'
	    REPOS_ZSH_TYPE=bzr
	    break
	fi
	if [[ -d $check_dir/.hg ]]; then
	    alias $ad='hg add'
	    alias $ci='hg ci'
	    alias $co='hg update'
	    alias $di='paged_hg diff'
	    alias $lo='paged_hg log'
	    alias $pu='hg push'
	    alias $st='hg st'
	    alias $up='hg pull -u'
	    alias $pa='hg diff'
	    alias $ss='echo "This is not a Git repository!"'
	    REPOS_ZSH_TYPE=hg
	    break
	fi
	if [[ -z $prior_inode ]]; then
	    # Only check for .svn and CVS in the current dir.
	    if [[ -d $check_dir/.svn ]]; then
		alias $ad='svn add'
		alias $ci='svn ci'
		alias $co='svn update'
		alias $di='paged_svn diff --no-diff-deleted'
		alias $lo='paged_svn log'
		alias $pu='echo "This is an svn repository!"'
		alias $st='svn st'
		alias $up='svn up'
		alias $pa='svn diff'
		alias $ss='echo "This is not a Git repository!"'
		REPOS_ZSH_TYPE=svn
		break
	    fi
	    if [[ -d $check_dir/CVS ]]; then
		alias $ad='cvs add'
		alias $ci='cvs ci'
		alias $co='cvs update'
		alias $di='paged_cvs -q diff -up'
		alias $lo='paged_cvs log'
		alias $pu='echo "This is a cvs repository!"'
		alias $st='cvs-status'
		alias $up='cvs -q up -d -P'
		alias $pa='cvs diff -u'
		alias $ss='echo "This is not a Git repository!"'
		REPOS_ZSH_TYPE=cvs
		break
	    fi
	fi
	prior_inode=$inode
	check_dir=../$check_dir
    done
}

# If repo_chpwd isn't in the chpwd list of functions yet, add it.
case "$functions[chpwd]" in
*repo_chpwd*) ;;
*)
    functions[chpwd]+='
repo_chpwd'
    ;;
esac

# Initialize things by running the function once.
repo_chpwd

# vim: sw=4 ts=8 noet ft=zsh
