#!/usr/bin/env bash
# Bash completion script for strava CLI

_strava_completions() {
    local cur prev commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Main commands
    commands="init athlete stats zones activities activity streams laps azones comments kudos last today week segment starred explore efforts effort gear route routes"

    # Common options
    local common_opts="--raw --output --quiet --help"

    # If we're completing the first argument (command)
    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        return 0
    fi

    # Command-specific completions
    case "${COMP_WORDS[1]}" in
        activity)
            COMPREPLY=( $(compgen -W "--efforts ${common_opts}" -- ${cur}) )
            ;;
        activities|starred|routes)
            COMPREPLY=( $(compgen -W "--page --per-page ${common_opts}" -- ${cur}) )
            ;;
        explore)
            COMPREPLY=( $(compgen -W "--bounds --type --min-cat --max-cat ${common_opts}" -- ${cur}) )
            ;;
        efforts)
            COMPREPLY=( $(compgen -W "--segment --start --end --per-page ${common_opts}" -- ${cur}) )
            ;;
        streams)
            # Stream types
            if [ $COMP_CWORD -gt 2 ]; then
                local stream_types="time distance latlng altitude velocity_smooth heartrate cadence watts temp moving grade_smooth"
                COMPREPLY=( $(compgen -W "${stream_types}" -- ${cur}) )
            fi
            ;;
        *)
            COMPREPLY=( $(compgen -W "${common_opts}" -- ${cur}) )
            ;;
    esac

    # Complete file paths for --output
    if [[ ${prev} == "--output" || ${prev} == "-o" ]]; then
        COMPREPLY=( $(compgen -f -- ${cur}) )
        return 0
    fi
}

complete -F _strava_completions strava
