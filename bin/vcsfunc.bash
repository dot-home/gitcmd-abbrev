# Shell functions for version-control system operations.

# path_recurse_up <path> <test> <arg> ...
#
# Execute <test> <arg> ... for every directory from <path> upwards,
# until <test> returns success, or until the root directory is reached,
# in which case failure is returned. If <path> is not itself a
# directory, it will start at the directory containing <path>.
#
path_recurse_up() {
    local dir=$([ -d "$1" ] && echo "$1" || dirname "$1"); shift
    dir=$(cd "$dir" && pwd -P)
    while [ "$dir" != / ]; do
        "$@" "$dir" && return \
                    || dir=$(dirname "$dir")
    done
    return 1
}

# Given the root of a repo checkout or clone, echo the VCS for it. If
# the VCS can't be detected, nothing is echoed and failure is returned.
#
vcs_for_root() {
    [ -e "$1/.git" ] && { echo git; return; }
    [ -d "$1/.hg" ]  && { echo hg;  return; }
    [ -d "$1/.svn" ] && { echo svn; return; }
    [ -d "$1/CVS" ]  && { echo cvs; return; }
    return 1
}

# Given a path within a repo checkout or clone, echo the VCS for it. If
# the VCS can't be detected, nothing is echoed and failure is returned.
#
vcs_for_path() {
    path_recurse_up "$1" vcs_for_root
}

has_subentry() { test -e "$2/$1" && echo $2 || return 1; }
not_subdir() { ! test -d "$2/$1" && echo $2 || return 1; }

# Given a path within a repo checkout (or clone), echo the root of that
# checkout. If the path does not appear to be pointing into a checkout,
# a message is printed to stderr and failure is returned.
#
vcs_root() {
    vcs=$(vcs_for_path "$1")
    case $vcs in
        git|hg)         path_recurse_up "$1" has_subentry .$vcs ;;
        svn)            path_recurse_up "$1" not_subdir ../.svn ;;
        cvs)            path_recurse_up "$1" not_subdir ../CVS ;;
        '')             echo ;;
        *)              echo 1>&2 "ERROR: vcs_root doesn't know VCS $vcs" ;;
    esac
}

vcs_git_submodules() {
    #   Given a git repo working copy root "$1", print its git submodule paths
    #   relative to the root of the repo, one per line. (This will print
    #   nothing if there are no submodules, and still exit with success.)
    #   The output is intended to be read with `while read path; do ...`.
    [[ -z ${1:-} ]] && { echo 1>&2 INTERNAL ERROR; exit 9; }

    [[ -r $1/.gitmodules ]] || return 0     # prints nothing

    git config -f "$1"/.gitmodules -l \
        | sed -n -e 's/^submodule\.//' -e 's/.*\.path=//p'
}
