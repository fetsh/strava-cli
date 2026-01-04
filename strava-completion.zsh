#compdef strava
# Zsh completion script for strava CLI

_strava() {
    local -a commands
    commands=(
        'init:Initialize strava-cli with API credentials'
        'athlete:Get authenticated athlete profile'
        'stats:Get athlete statistics'
        'zones:Get heart rate and power zones'
        'activities:List activities'
        'activity:Get activity by ID'
        'streams:Get activity streams'
        'laps:Get activity laps'
        'azones:Get activity zones'
        'comments:Get activity comments'
        'kudos:Get activity kudos'
        'last:Get last N activities'
        'today:Get today activities'
        'week:Get this week activities'
        'segment:Get segment by ID'
        'starred:Get starred segments'
        'explore:Explore segments in area'
        'efforts:Get segment efforts'
        'effort:Get segment effort by ID'
        'gear:Get gear by ID'
        'route:Get route by ID'
        'routes:List routes'
    )

    local -a common_opts
    common_opts=(
        '--raw[Output JSON to stdout]'
        '--output[Output file path]:file:_files'
        '--quiet[No output]'
        '--help[Show help]'
    )

    _arguments -C \
        '1: :->command' \
        '*::arg:->args'

    case $state in
        command)
            _describe 'strava command' commands
            ;;
        args)
            case ${words[1]} in
                activity)
                    _arguments \
                        '--efforts[Include segment efforts]' \
                        $common_opts
                    ;;
                activities|starred|routes)
                    _arguments \
                        '--page[Page number]:page:' \
                        '--per-page[Items per page]:per-page:' \
                        $common_opts
                    ;;
                explore)
                    _arguments \
                        '--bounds[Bounds (SW_LAT,SW_LNG,NE_LAT,NE_LNG)]:bounds:' \
                        '--type[Activity type]:type:(running riding)' \
                        '--min-cat[Minimum category]:min-cat:' \
                        '--max-cat[Maximum category]:max-cat:' \
                        $common_opts
                    ;;
                efforts)
                    _arguments \
                        '--segment[Segment ID]:segment:' \
                        '--start[Start date]:start:' \
                        '--end[End date]:end:' \
                        '--per-page[Items per page]:per-page:' \
                        $common_opts
                    ;;
                streams)
                    _arguments \
                        '*:stream type:(time distance latlng altitude velocity_smooth heartrate cadence watts temp moving grade_smooth)' \
                        $common_opts
                    ;;
                *)
                    _arguments $common_opts
                    ;;
            esac
            ;;
    esac
}

_strava "$@"
