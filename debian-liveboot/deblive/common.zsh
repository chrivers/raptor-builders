autoload -U colors; colors

: ${opt_break:=}

function Log() {
    local color=$1
    local mark=$2
    shift 2

    echo "${fg_bold[blue]}[${color}${mark}${fg_bold[blue]}]${reset_color} $*" > /dev/stderr
}

function Line() {
    Log "${fg_bold[white]}" "|" $*
}

function Debug() {
    Log "${fg_bold[green]}" "D" $*
}

function Info() {
    Log "${fg_bold[green]}" "*" $*
}

function Warn() {
    Log "${fg_bold[yellow]}" "W" $*
}

function Error() {
    Log "${fg_bold[red]}" "E" $*
}

function maybe-break() {
    if [[ ",${opt_break}," == *,$1,* ]]; then
        Info "-------- Breaking at stage $1 --------"
        Line "process will continue after shell exit"
        zsh
    else
        Debug "no break at $1";
    fi
}
