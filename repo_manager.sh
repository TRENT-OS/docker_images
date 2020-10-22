#!/bin/bash -e
# -e: Exit immediately if a command exits with a non-zero status.

# the actual submodules
SUBMODULES=""
# the list of submodules that the merge is targeting
TARGET_MODULES=""

GIT_OUTPUT_FILE="$PWD/repo_manager.out"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
L_GRAY='\033[0;37m'
NC='\033[0m'

USAGE_STRING="\nrepo_manager.sh <cmd> [<args>] [<opts>]\n
    \n Performs recursively actions thru the submodules tree, root included.
    \n Available actions are: branch, push, rebase, merge, delete
    \n\nExamples:\
    \n\t $./repo_manager.sh branch DEV_BRANCH_NAME [MASTER_BRANCH_NAME]
    \n\t checkout recursively 'DEV_BRANCH_NAME', if not yet existing the branch gets created from MASTER_BRANCH_NAME (if declared) or from the current branch\
    \n
    \n\t $./repo_manager.sh push DEV_BRANCH_NAME
    \n\t Push recursively all the commits for DEV_BRANCH_NAME\
    \n
    \n\t $./repo_manager.sh rebase DEV_BRANCH_NAME BASE_BRANCH_NAME
    \n\t Rebase recursively DEV_BRANCH_NAME on BASE_BRANCH_NAME. If there is a 'delta' in not yet merged commits between the DEV_BRANCH_NAME and BASE_BRANCH_NAME an interactive rebase on this amount of commits is proposed to the user.\
    \n
    \n\t $./repo_manager.sh merge SRC_BRANCH_NAME DST_BRANCH_NAME [git-merge options]
    \n\t Merge recursively SRC_BRANCH_NAME into DST_BRANCH_NAME. Interactively asks for rebasing first on SRC_BRANCH_NAME.
    \n\t Be aware: DST_BRANCH_NAME is locally checked out from origin with -f (force) option!
    \n
    \n\t $./repo_manager.sh delete DEV_BRANCH_NAME [MASTER_BRANCH_NAME]
    \n\t removes recursively 'DEV_BRANCH_NAME' on 'origin' or on local repository when MASTER_BRANCH_NAME is specified. Deletion happens anyway, be careful.\
\n Note: names of branches are supposed to be witout any prefix"

#-------------------------------------------------------------------------------
function echo_red()
{
    echo -e "${RED}$1${NC}"
}

#-------------------------------------------------------------------------------
function echo_green()
{
    echo -e "${GREEN}$1${NC}"
}

#-------------------------------------------------------------------------------
function echo_yellow()
{
    echo -e "${YELLOW}$1${NC}"
}

#-------------------------------------------------------------------------------
function echo_lgray()
{
    echo -e "${L_GRAY}$1${NC}"
}

#-------------------------------------------------------------------------------
function get_submodules()
{
    SUBMODULES="."$'\n'"`git submodule foreach --recursive | cut -d"'" -f 2`"
}

#-------------------------------------------------------------------------------
function show_submodules()
{
    echo "List of submodules:"
    for module in $SUBMODULES; do
        echo $module
    done
}

#-------------------------------------------------------------------------------
function check_branch()
{
    for branch in $@; do
        git rev-parse --verify $branch 1>>$GIT_OUTPUT_FILE 2>>$GIT_OUTPUT_FILE || return 1
    done
}

#-------------------------------------------------------------------------------
function get_confirmation()
{
    local response=0
    read -r -p "Are you sure? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            # do nothing
            ;;
        *)
            return 1
            ;;
    esac
}

#-------------------------------------------------------------------------------
function for_all()
{
    local modules=`echo "$TARGET_MODULES" | tac`
    for module in $modules; do
        (
        echo "-> $module"
        cd $module
        $@
        ) || return 1
    done
}

#-------------------------------------------------------------------------------
function branch()
{
    # create the branch if not existing already
    if ! check_branch $1 && ! check_branch origin/$1 ; then
        echo_lgray "creating branch '$1'."
        get_confirmation || return 0
        if [ "$2" != "" ]; then
            if ! check_branch $2 && ! check_branch origin/$2 ; then
                echo_yellow "'$2' not such a branch exists to branch from. Skipping."
                get_confirmation && return 0
            else
                checkout_and_pull $2 || return 1
            fi
        fi
        checkout -b $1
    else
        echo_green "branch already exists"
        checkout $1
    fi
}

#-------------------------------------------------------------------------------
function branch_all()
{
    for_all branch $@
}

#-------------------------------------------------------------------------------
function delete()
{
    if [ "$2" != "" ]; then
        if ! check_branch $1 ; then
            echo_lgray "not a such branch '$1' to delete on local"
        elif ! check_branch $2 ; then
            echo_lgray "not a such branch '$2' to checkout on local"
        else
            if checkout $2 &&
                git branch -D $1 1>>$GIT_OUTPUT_FILE 2>>$GIT_OUTPUT_FILE; then
                echo_green "successfully deleted branch $1 on local"
            else
                echo_yellow "could not delete branch '$1' on local"
            fi
        fi
    else
        if ! check_branch origin/$1 ; then
            echo_lgray "not a such branch '$1' to delete on origin"
        else
            if git push --delete origin $1 1>>$GIT_OUTPUT_FILE 2>>$GIT_OUTPUT_FILE ; then
                echo_green "successfully deleted branch $1 on origin"
            else
                echo_yellow "could not delete branch '$1' on origin"
            fi
        fi
    fi
}

#-------------------------------------------------------------------------------
function delete_all()
{
    for_all delete $@
}

#-------------------------------------------------------------------------------
function check_pushed()
{
    local log_diff
    local branch=`git rev-parse --abbrev-ref HEAD 2>>$GIT_OUTPUT_FILE`

    log_diff=`git log origin/$branch..$branch`
    if [ "$log_diff" != "" ]; then
        echo_yellow "you have commits in this module that are not yet pushed, continuing"
        get_confirmation || return 1
    fi
}

#-------------------------------------------------------------------------------
function check_pushed_all()
{
    for_all "check_pushed"
}

#-------------------------------------------------------------------------------
function rebase()
{
    local input=""
    local line_num=0
    local response=0

    local branch=`git rev-parse --abbrev-ref HEAD 2>>$GIT_OUTPUT_FILE`

    echo_lgray "rebasing on origin/$1"
    get_confirmation || return 0
    if git rebase origin/$1 1>>$GIT_OUTPUT_FILE 2>>$GIT_OUTPUT_FILE; then
        echo_green "successfully rebased"
    else
        echo_red "could not rebase"
    fi

    commits=`git log origin/$1..`
    if [ "$commits" != "" ]; then
        line_num=`echo $commits | grep commit | wc -l`

        echo_lgray "there are unpushed commits that may need to be squashed:\n$commits"
        read -r -p "is script running with 'yes |' ?" response
        case "$response" in
            [yY][eE][sS]|[yY])
                # do nothing
                ;;
            *)
                echo_lgray "performing an interactive 'rebase -i' after automatic rebase on '$1'"
                { get_confirmation && git rebase -i HEAD~$line_num; } || return 0
            ;;
        esac
    fi
}

#-------------------------------------------------------------------------------
function rebase_all()
{
    for_all rebase $@
}

#-------------------------------------------------------------------------------
function check_modified_files()
{
    local modified_list=`git ls-files --modified`

    if [ "$modified_list" != "" ]; then
        echo_yellow "you have uncommitted modified files, continuing."
        get_confirmation || return 1
    fi
}

#-------------------------------------------------------------------------------
function push()
{
    local branch=`git rev-parse --abbrev-ref HEAD 2>>$GIT_OUTPUT_FILE`

    check_modified_files || return 1

    git push --set-upstream origin $branch 1>>$GIT_OUTPUT_FILE 2>>$GIT_OUTPUT_FILE
    if [ $? != 0 ] && [ $1 == "prompt_force" ]; then
        echo_yellow "normal push failed proceeding with --force."
        get_confirmation || return 1
        if ! git push --force origin; then
            echo_red "could not push branch '$branch'"
            return 1
        fi
    fi
    echo_green "successfully pushed branch '$branch' on origin"
}

#-------------------------------------------------------------------------------
function push_all()
{
    for_all push $@
}

#-------------------------------------------------------------------------------
function checkout()
{
    if ! git checkout $@ 1>>$GIT_OUTPUT_FILE 2>>$GIT_OUTPUT_FILE; then
        echo_yellow "checkout with '$@' failed. Skipping."
        get_confirmation || return 1
    fi
}

#-------------------------------------------------------------------------------
function checkout_all()
{
    for_all checkout $@
}

#-------------------------------------------------------------------------------
function checkout_and_pull()
{
    checkout $@
    pull
}

#-------------------------------------------------------------------------------
function checkout_and_pull_all()
{
    for_all checkout_and_pull $@
}

#-------------------------------------------------------------------------------
function checkout_all_and_update_target()
{
    #### reset TARGET_MODULES as we are going to rebuild it based on different
    #### criteria
    TARGET_MODULES=""

    #### Identify which submodules are good candidates
    for module in $SUBMODULES; do
        local skip=false
        cd $module

        for branch in $@; do
            #echo_lgray "checking esistence of branch 'origin/$branch' in module '$module'"
            if ! check_branch $branch && ! check_branch origin/$branch; then
                echo_yellow "skipping '$module'"
                skip=true
                break;
            else
                continue
            fi
        done;

        if ! $skip; then
            checkout $1 >/dev/null || return 1
            echo_lgray "adding $module to target modules"
            if get_confirmation ; then
                TARGET_MODULES+=$module$'\n'
            else
                cd - > /dev/null
                continue
            fi
        fi

        cd - > /dev/null
    done
}

#-------------------------------------------------------------------------------
function fetch()
{
    git fetch 1>>$GIT_OUTPUT_FILE 2>>$GIT_OUTPUT_FILE ||
        { echo_red "fetch failed"; return 1; }
}

#-------------------------------------------------------------------------------
function pull()
{
    git pull origin 1>>$GIT_OUTPUT_FILE 2>>$GIT_OUTPUT_FILE ||
        { echo_red "pull failed"; return 1; }
}

#-------------------------------------------------------------------------------
function pull_all()
{
    for_all pull
}

#-------------------------------------------------------------------------------
function merge()
{
    checkout_and_pull -f $2
    git merge ${@:2} $1 1>>$GIT_OUTPUT_FILE 2>>$GIT_OUTPUT_FILE ||
        { echo_red "failed merging branch '$1'"; return 1; }
}

#-------------------------------------------------------------------------------
function merge_all()
{
    for_all merge $@
}

#-------------------------------------------------------------------------------
function reset_layout()
{
    echo_lgray "resetting the layout to '$1' branch"
    checkout_and_pull $1 &&
        git submodule update --init --recursive 1>>$GIT_OUTPUT_FILE 2>>$GIT_OUTPUT_FILE &&
        get_submodules &&
        show_submodules &&
        echo
}

function clean_exit()
{
    RET=0
    if [ "$1" != "" ]; then
        RET=$1
    fi
    echo_lgray "resetting layout to master branch"
    reset_layout "master"; exit $RET
}

#-------------------------------------------------------------------------------
function exit_msg()
{
    RET=0
    if [ "$1" != "" ]; then
        RET=$1
    fi
    echo -e $2; exit $RET
}

#-------------------------------------------------------------------------------
function exec_branch()
{
    if [ "$2" != "" ]; then
        echo -n "Checkout '$2' and update submodules.."
        reset_layout $2 > /dev/null || exit_msg 1 "FAILED"
        echo "OK"
    fi
    branch_all $@
}

#-------------------------------------------------------------------------------
function exec_push()
{
    checkout_all_and_update_target $1 &&
        push_all "prompt_force"
}

#-------------------------------------------------------------------------------
function exec_rebase()
{
    checkout_all_and_update_target $@ &&
        pull_all &&
        rebase_all $2
}

#-------------------------------------------------------------------------------
function exec_delete()
{
    if [ "$2" != "" ]; then
        echo -n "Checkout '$2' and update submodules.."
        reset_layout $2 > /dev/null || exit_msg 1 "FAILED"
        echo "OK"
    fi

    delete_all $@
}

#-------------------------------------------------------------------------------
function exec_merge()
{
    local SRC_BRANCH=$1
    local DST_BRANCH=$2

    reset_layout $SRC_BRANCH || exit 1

    #### Sanity tests
    check_branch origin/$SRC_BRANCH origin/$DST_BRANCH ||
        exit_msg 1 "source or destination branches are not valid for this root folder"

    #### Identify which submodules are good candidates and checkout the target branch
    checkout_all_and_update_target $SRC_BRANCH $DST_BRANCH

    pull_all

    #### Take care that they are all in sync with origin
    echo
    echo_lgray ">>> Checking whether all is in sync to origin in modules. Pull all and check whether there is anything to push."
    echo

    check_pushed_all || exit 1

    #### Rebase all on origin/$DST_BRANCH
    echo
    echo_lgray ">>> Rebasing all on 'origin/$DST_BRANCH'."
    if get_confirmation; then
        rebase_all $DST_BRANCH $SRC_BRANCH || exit 1

        #### Push all
        echo
        echo_lgray ">>> Pushing all of the rebased modules."
        get_confirmation || exit 1
        echo

        push_all "prompt_force" || exit 1
    fi
    echo

    #### Change to DST_BRANCH and pull and merge all locally
    echo
    echo_lgray ">>> Preparing the merge, changing to destination branch '$DST_BRANCH', pulling origin and merging from source branch '$SRC_BRANCH'."
    echo
    merge_all $SRC_BRANCH ${@:2} || clean_exit 1

    ##### Final push
    echo
    echo_lgray ">>> Ready to perform final push."
    get_confirmation || clean_exit 1
    echo

    push_all "prompt_force"

    #### Cleanup
    echo
    echo_lgray ">>> Deleting '$SRC_BRANCH' from origin."
    get_confirmation || clean_exit 0
    echo

    delete_all $SRC_BRANCH

    clean_exit $?
}

case "$1" in
    "branch")
        if [ "$2" == "" ]; then
            exit_msg 1 "$USAGE_STRING"
        fi
    ;;
    "push")
        if [ "$2" == "" ]; then
            exit_msg 1 "$USAGE_STRING"
        fi
    ;;
    "rebase")
        if [ "$2" == "" ] || [ "$3" == "" ]; then
            exit_msg 1 "$USAGE_STRING"
        fi
    ;;
    "merge")
        if [ "$2" == "" ] || [ "$3" == "" ]; then
            exit_msg 1 "$USAGE_STRING"
        fi
    ;;
    "delete")
        if [ "$2" == "" ]; then
            exit_msg 1 "$USAGE_STRING"
        fi
    ;;
    *)
        exit_msg 1 "$USAGE_STRING"
    ;;
esac

# cleanup git output file
echo > $GIT_OUTPUT_FILE

#### Prepare the layout
echo_lgray ">>> Preparing the layout."

echo -n "Fetch origin.."
fetch > /dev/null || exit_msg 1 "FAILED"
echo "OK"

#### Prepare a default value for those vars
get_submodules
TARGET_MODULES=$SUBMODULES

exec_$1 ${@:2}
