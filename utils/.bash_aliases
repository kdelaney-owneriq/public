
# handy aliases and functions for local linux environment

# git aliases
git_diff ()
{
    local DIR="$(pwd)";
    case "${DIR}" in
        *custom*)
            DEFAULT_BRANCH="beta"
        ;;
        *)
            DEFAULT_BRANCH="master"
        ;;
    esac;
    local BRANCH=$(git branch | grep ^\* | cut -d ' ' -f 2);
    if [ -z "${BRANCH}" ]; then
        echo "no branch found";
        return 1;
    else
        if [ "${BRANCH}" == "master" ]; then
            echo "don't compare master to master";
            return 1;
        fi;
    fi;
    git diff --name-status ${DEFAULT_BRANCH}..${BRANCH}
}
alias gd="git_diff"
alias gs="git status"

get_repo_branch() {
  local repo_dir="${1}"
  local cwd=$(pwd)
  cd "$repo_dir"
  echo "${repo_dir}"
  git branch
  echo 
  cd ${cwd}
}

function list_branches() {
  
  # Function:
  # 1) get dynamic list of all local repos
  # 2) prompt user to select one of those
  # 3) then iterate to show all local branches for the selected repository
  
  local GITHUB_HOME="${HOME}/github"   # set to wherever repositories are locally stored
  [ -z "${REPOS}" ] && REPOS=( $( find "${GITHUB_HOME}" -mindepth 2 -maxdepth 2 -type d | sed "s|${GITHUB_HOME}/||" | grep -v "owneriq-dev" ) )
  
  local NUM_REPOS="${#REPOS[@]}"
 
  local msg="Please choose a repository (1-${NUM_REPOS})"
  printf "%s:\n\n" "${msg}"

  select REPO in ${REPOS[@]} ; do printf "\n"
      
      # validate input
      [[ "${REPLY}" =~ ^[0-9]+$ ]] && (( "${REPLY}" >= 1 )) && (( "${REPLY}" <= "${NUM_REPOS}" )) || { echo "${msg}" ; continue ; }
      
      local_branches=( $( find "${GITHUB_HOME}/${REPO}" -mindepth 2 -maxdepth 2 -type d | grep "${REPO##*/}$" ) )
      
      for local_branch in ${local_branches[@]}; do
        get_repo_branch "${local_branch}"
      done
      
      break
  done
}

alias lb="list_branches"

# monitor the processlist for the given job, and all children underneath it; continually refresh the view every 5 seconds until job is done
pv ()
{
    usage="Purpose: show process info.

USAGE: pv -p <process_name|process ID> (required) [-e] [-i]

Default shows process tree for a given process and it's children.
Option -e will show the given process without children.

Options:
    p ) (Required) process to grep for. An all-numeric argument is assumed to be a PID.
    e ) show instances of the process with columns: elapsed_time, start_time, PID, PPID, command arguments
    i ) case-insensitive grep
    h ) show usage";
    local process='';
    local case_insensitive='';
    local elapsed_view='';
    local OPTIND i e h p;
    while getopts "iehp:" Option; do
        case "$Option" in
            i)
                case_insensitive="-i"
            ;;
            e)
                elapsed_view="TRUE"
            ;;
            h)
                echo "${usage}";
                return 0
            ;;
            p)
                process="${OPTARG}"
            ;;
            *)
                echo "Unimplemented option chosen.";
                echo ${usage};
                return 1
            ;;
        esac;
    done;
    shift $((OPTIND-1));
    if [ ! -n "${process}" ]; then
        echo "${FUNCNAME} requires -p option with argument given for process to grep.";
        echo;
        echo "${usage}";
        return 1;
    fi;
    if [ "${elapsed_view}" == "TRUE" ]; then
        cmd="ps -eo etime,lstart,pid,ppid,args | grep -v grep | grep "${case_insensitive}" "${process}" | sort -k7,7";
    else
        if [[ "${process}" =~ ^[0-9]+$ ]]; then
            cmd="ps axjf | grep -v grep | grep "${case_insensitive}" "${process}"";
        else
            cmd="ps axjf | grep -v grep | grep -A 6 "${case_insensitive}" "${process}"";
        fi;
    fi;
    while true; do
        clear;
        echo "running command:   ${cmd}";
        echo;
        echo status as of $(date);
        echo;
        eval ${cmd};
        sleep 10s;
    done
}

function kill_job_group ()
{
    PGID="${1}";
    kill -TERM -- -"${PGID}"
}
alias kjg='kill_job_group'

alias vi='vim'
alias fd='find . -maxdepth 1 -type d | sort'
alias jobs='jobs -l'
alias j='jobs -l'

# Source a seperate file with user-specific passwords
    [ -e ~/.mysql_aliases ] && source ~/.mysql_aliases

# avro-tools cli
#  see documentation: https://github.com/miguno/avro-cli-examples?tab=readme-ov-file
function avro-tools() {
  local AVRO_TOOLS_JAR=${HOME}/tools/avro-tools-1.11.3.jar
  [ -f ${AVRO_TOOLS_JAR} ] || {
    echo "Jar file missing!  Not found: ${AVRO_TOOLS_JAR}"
    return 1
  }
  local commands="$@"
  java -jar ${AVRO_TOOLS_JAR} $commands
}
