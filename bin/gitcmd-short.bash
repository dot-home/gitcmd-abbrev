#   Function (command) definitions for shortened Git commands.
#   `source` this file in your ~/.bashrc.

#   Is Git version on this host >= given version?
__git_tools_gitver_GE() {
    local vs=($(git --version | sed -e 's/git version //' -e 's/\./ /g'))
    local ws=($(echo "$@" | sed -e 's/\./ /g'))
    # For `-lt`, empty string is 0
    [[ ${vs[0]} -lt ${ws[0]} ]] && return 1
    [[ ${vs[1]} -lt ${ws[1]} ]] && return 1
    [[ ${vs[2]} -lt ${ws[2]} ]] && return 1
    [[ ${vs[3]} -lt ${ws[3]} ]] && return 1
    return 0
}

############################################################
# "Copy" git completion to our custom functions

#   Ensure we have __git_wrap__git_main
[ -f /usr/share/bash-completion/completions/git ] \
    && source /usr/share/bash-completion/completions/git
[ -f /mingw64/share/git/completion/git-completion.bash ] \
    && source /mingw64/share/git/completion/git-completion.bash

copy_git_completion() {
    type -t __git_wrap__git_main >/dev/null || return 0
    local command="$1"; shift
    eval "
        function __copy_git_completion::$command {
            (( COMP_CWORD += 1 ))
            COMP_WORDS=("$@" \${COMP_WORDS[@]:1})
            (( COMP_POINT -= \${#COMP_LINE} ))
            COMP_LINE=\${COMP_LINE/$command/"$@"}
            (( COMP_POINT += \${#COMP_LINE} ))
            __git_wrap__git_main
        }
    "
    complete -o bashdefault -o default -o nospace \
        -F "__copy_git_completion::$command" "$command"
}

############################################################
# git log functions (completion setup at end)

log()  { git log "$@"; }

logs() {        # full paths of changed files
    git log --stat=999 --stat-graph-width=5 "$@"
}

logp() {        # log with patches
                # changed paths are truncated in stat, full in diff
    git log --stat -p "$@"
}

logp1() {       # most recent patch
    logp -1 "$@"
}

logb() {        # brief graph of current or specified branches
    # Use `-S` in less to switch to wrapped lines instead of sideways scrolling
    LESS="$LESS -SR" \
    git log --graph --abbrev-commit --pretty=oneline --decorate=short "$@"
}

logab() {       # brief graph of all branches
    local exclude_notes='--exclude=refs/notes/\*'
    __git_tools_gitver_GE 1.8 || exclude_notes=
    logb --all $exclude_notes "$@"
}

logh() {        # the "head" of the repo
    #   The idea is to get a quick overview of the relationships between
    #   the tips of recent branches that are at least moderately closely
    #   related to HEAD (or master?). This method of selecting the commits
    #   and limiting the number shown could probably be improved. In
    #   particular, it would be nice to show a bit of HEAD no matter how
    #   old it is.
    LESS="$LESS -E" logab --since '1 week ago' -n 30 "$@";
}

logm() {        # brief graph with commit metadata
    local sha='%C(auto)%h'
    # Truncated relative works better for quick review than %ad
    local date='%C(green)%<(12,trunc)%ar%C(auto)'
    local author='%C(black)%<(20,trunc)%ae%C(auto)'
    local branches='%C(auto)% D'
    local subject='%n%C(blue)%s'

    local format="$sha $date $author$branches$subject"
    logb --pretty="tformat:$format" "$@"
}

logmn() {       # logm without merges
    logm --no-merges "$@"
}

logbr() {   # XXX FIXME
    local -a argv=("$@")
    local branchref=@
    if [[ ${#argv[@]} -gt 0 ]] && [[ ${argv[-1]} != -* ]]; then
        local branchref="${argv[-1]}"
        unset 'argv[-1]'
    fi
    logs "${argv[@]}" $(mbase "$branchref").."$branchref"
}


for f in log logbr logb logab logh logm logmn logs logp logp1; do
    copy_git_completion $f git log
done

############################################################
# git diff, other repo search/browse/etc. functions

blame() { git blame "$@"; }; copy_git_completion blame git blame

slp1() {        # most recent patch with leading blank lines for readability
    local i; for i in 1 2 3 4 5; do echo; done
    logp1 "$@"
}; copy_git_completion slp1 git log

dif()   { git diff "$@"; }; copy_git_completion dif git diff
difs()  { dif --cached "$@"; }; copy_git_completion difs git diff
dift()  { git difftool -y "$@"; }; copy_git_completion dift git difftool

ggrep()         { git grep "$@"; }; copy_git_completion ggrep git grep
gfgrep()        { ggrep -F "$@"; }; copy_git_completion gfgrep git grep

gk()            {
    [ -n "$1" ] && { start="--select-commit=$1"; shift; }
    [ -n "$1" ] && { echo 1>&2 'Usage: gk [start-commitish]'; return 2; }
    gitk --all "$start";
}


############################################################
# git checkout, stage, commit, clean

co()        { git checkout "$@"; }; copy_git_completion co git checkout
#complete -r co 2>/dev/null  # Perhaps not necessary given all options below?

add()       { git add "$@"; }; copy_git_completion add git add

com()       { git commit -v "$@"; }; copy_git_completion com git commit
coma()      {
                # If we have changes staged in the index, assume we don't
                # want to commit unstaged changes.
                local _a=''
                git diff-index --quiet --cached HEAD -- && _a='-a'
                com $_a "$@";
            }; copy_git_completion coma git commit
cam()       { com --amend "$@"; }; copy_git_completion cam git commit
cpick()     { git cherry-pick "$@"; }; copy_git_completion cpick git cherry-pick

#   `git clean` with `-n` supplied for you unless you specify `-f`
clean()     {
    local noforce=-n
    for arg in "$@"; do case "$arg" in
        -*f*)  noforce=;;
    esac; done
    git clean $noforce "$@";
}; copy_git_completion clean git clean

#   Clean explicitly ignored files and directories
iclean()    { clean -dX "$@"; }; copy_git_completion iclean git clean

gsub()      { git submodule "$@"; }
copy_git_completion gsub git submodule

gpack()     {
    #   Pack down a repo to the minimun number of files. This is useful
    #   when archiving repos, sync'ing filesystems, etc.
    #   The gc ensures that we don't have unrefrenced objects, but will
    #   leave loose objects not referenced by branches (e.g., reflog
    #   stuff). The repack takes care of this.
    #   This also removes the pointless sample hooks that git loves to create.
    #
    #   XXX Argument handling is currently wrong. We should accept
    #   --aggressive to pass to `gc`, and any other args should be for
    #   `git` itself (e.g., --git-dir).
    #
    git gc "$@" || return
    git repack -adk         # Also packs unreachable objects
    local gitdir=$(git rev-parse --git-dir)
    rm "$gitdir"/hooks/*.sample "$gitdir"/modules/*/hooks/*.sample \
        2>/dev/null || true
    rmdir "$gitdir"/hooks "$gitdir"/modules/*/hooks 2>/dev/null || true
}


############################################################
# git branch

#   XXX TODO: This should always show the tracking branch and unpushed
#   commits (à la `git branch -vv`), and should probably be rewritten
#   to use `git for-each-ref`, or maybe just `git branch --format`.)
br() {
    local bropts grep_args=()
    while :; do case "$1" in
        -a) shift; bropts="-a -v";;
        -v) shift; bropts="-v";;
        -g) shift; grep_args+=("$1"); shift;;
        *)  break;;
    esac; done
    # Using '.' as the default grep argument will remove blank lines.
    # We can live with this here, since we expect none.
    git branch --color $bropts "$@" \
        | grep "${grep_args[@]:-.}" \
        | less -E -R -S -J -X
}; copy_git_completion br git branch
bra()           { br -a "$@"; };    copy_git_completion bra git branch
brag()          { br -a -g "$@"; }; copy_git_completion brag git branch
brv()           { br -v "$@"; };    copy_git_completion brv git branch

#   XXX FIXME: This is quite broken? It definitely doesn't handle repos
#   with `main` instead `master` as the main branch.
mbase() {
    local range_to=false
    [ _"$1" = _-t ] && { range_to=true; shift; }
    local here=${1:-HEAD}
    local there=${2:-master@{upstream}}

    local base=$(git merge-base "$here" "$there")
    if $range_to; then
        echo "$base..$here"
    else
        echo "$base"
    fi
}

############################################################
# git rebase, reset, similar

mergeff()       { git merge --ff-only "$@"; }   # Should be `integrate`?

gr()            { git rebase "$@"; }
grmu()          { git rebase "$@" master@{upstream}; }
grabort()       { git rebase --abort "$@"; }
grcontinue()    { git rebase --continue "$@"; }
grskip()        { git rebase --skip "$@"; }
gri()           {
    local arg=${1:-10}                  # default: 10 commits back
    [ $arg -lt 1000 ] 2>/dev/null \
        && git rebase -i "HEAD~$arg" \
        || git rebase -i "$arg^"
}
for f in gr grm grabort grcontinue grskip gri; do
    copy_git_completion $f git rebase
done

grwhere()       { logb ORIG_HEAD HEAD --not $(git merge-base ORIG_HEAD HEAD)^; }

gre()           { git reset "$@"; }
grehard()       { git reset -q --hard "$@" \
                  && echo 'Current and previous locations:' \
                  && git reflog show -2 #'HEAD@{1}'
                }
greupstream()   { grehard '@{upstream}'; }
for f in gre grehard greupstream; do
    copy_git_completion $f git reset
done

stash()         { if [ "$1" = "" ]
                    then echo; git stash list
                    else git stash "$@"
                    fi
                }
copy_git_completion stash git stash


############################################################
# git remote operations

# Most of these are planned to have further additional functionality,
# e.g., having `fetch` be able to take a list of paths to
# repos/workdirs and fetch in each of them.

#   List fetch URLs for the repos given on the command line.
#   Options:
#       -o  Show `origin` push URL only
#
#   XXX TODO: Fix -o so that it doesn't care about the remote name, but
#   shows the "primary" remote identified by the one whence the tracking
#   branch for `main` or `master` comes. (And possibly rename the option.)
#
gurl()  {
    local origin_only=''
    [[ $1 = -o ]] && { shift; origin_only='/^origin[[:space:]]/!d'; }
    [[ -n $1 ]] || set .    # default arg
    for dir in "$@"; do
        git -C "$dir" remote -v | sed \
            -e '/ (push)$/d' \
            -e 's/ (fetch)$//' \
            -e "$origin_only" \
            -e 's/^[^[:blank:]]*[[:space:]]*//'
    done
}

rem()   {
    local format_table='column -t'
    #   Without the `column` command (`bsdmainutils` package) we do a
    #   fixed 12-column format for repo names, overflowing if necessary.
    column </dev/null 2>/dev/null || format_table=cat

    if [[ ${#@} -gt 0 ]]; then
        git remote "$@"
    else
        # List all remotes with their push URLs.
        local rems
        mapfile -t rems < <(git remote)
        for rem in "${rems[@]}"; do
            printf "%-12s %s\n" "$rem" "$(git remote get-url --push "$rem")"
        done | $format_table
    fi
}; copy_git_completion rem git remote

# Given no args, fetch from remotes.default or, if not set, all remotes.
# Otherwise fetch from all listed remotes/`remotes.<group>` entries.
#
# I'd like to turn off the noise of fetch-pack (and unpack-objects)
# but --quiet here also turns off the names of the remotes being fetched
# and the status lines showing changed refs.
#
fetch() {
    local allarg='--all'
    for arg in "$@"; do
        # Disable --all if repo specified (arg without leading `-`)
        [[ ${arg#-} == $arg ]] && allarg=''
    done
    git fetch $allarg "$@" || return
    git status -bs
}; copy_git_completion fetch git fetch

pull()  { git pull --ff-only "$@"; }; copy_git_completion pull git pull

# Disallow use of -f and --force. If `pushf` doesn't work for you, you
# can use `git push --force`.
#
push()          {
    for i in "$@"; do case "$i" in
        -f)      echo 1>&2 "Do not use -f option, use pushf"; return 1;;
        --force) echo 1>&2 "Do not use --force option, use pushf"; return 1;;
    esac; done
    git push "$@";
}; copy_git_completion push git push

pushf()         {
    for i in "$@"; do case "$i" in
        -f) echo 1>&2 "Do not use -f option, use --force"; return 1;;
    esac; done
    git push --force-with-lease "$@";
}; copy_git_completion pushf git push

# Create upstream branch in given remote.
# This will unset any current upstream, if present.
# XXX This should be able to figure out a default remote.
#
pushu()         {
    # XXX This doesn't properly handle arguments before the <remote>
    [ -z "$1" ] && { echo 1>&2 "Usage: pushu <remote> [<branch>]"; return 2; }
    local -a argv=("$1"); shift
    [ -z "$1" ] && argv+=($(git rev-parse --abbrev-ref=strict HEAD))
    for i in "$@"; do argv+=("$i"); done
    git branch --unset-upstream 2>/dev/null || true
    push --set-upstream "${argv[@]}"
}; copy_git_completion pushu git push
