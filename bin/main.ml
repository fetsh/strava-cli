open Cmdliner

(* Common options *)
let raw_flag =
  Arg.(value & flag & info ["raw"] ~doc:"Output JSON to stdout")

let output_opt =
  Arg.(value & opt (some string) None & info ["o"; "output"] ~doc:"Output file path")

let quiet_flag =
  Arg.(value & flag & info ["q"; "quiet"] ~doc:"No output")

let pretty_flag =
  Arg.(value & flag & info ["pretty"] ~doc:"Pretty print output with tables")

let output_mode raw output quiet pretty =
  if quiet then Strava.Commands.Quiet
  else if pretty then Strava.Commands.Pretty
  else if raw then Strava.Commands.ToStdout
  else Strava.Commands.ToFile output

let output_term = Term.(const output_mode $ raw_flag $ output_opt $ quiet_flag $ pretty_flag)

(* Init command *)
let init_cmd =
  let run () =
    print_string "Client ID: ";
    let client_id = read_line () in
    print_string "Client Secret: ";
    let client_secret = read_line () in
    Lwt_main.run (
      let open Lwt.Syntax in
      let* result = Strava.Auth.init ~client_id ~client_secret in
      match result with
      | Ok () -> Lwt.return 0
      | Error e -> Printf.eprintf "Error: %s\n" e; Lwt.return 1
    )
  in
  let doc = "Initialize strava-cli with your API credentials" in
  Cmd.v (Cmd.info "init" ~doc) Term.(const run $ const ())

(* Athlete command *)
let athlete_cmd =
  let run mode () = Lwt_main.run (Strava.Commands.athlete ~mode ()) in
  let doc = "Get authenticated athlete" in
  Cmd.v (Cmd.info "athlete" ~doc) Term.(const run $ output_term $ const ())

let athlete_stats_cmd =
  let run mode () = Lwt_main.run (Strava.Commands.athlete_stats ~mode ()) in
  let doc = "Get athlete stats" in
  Cmd.v (Cmd.info "stats" ~doc) Term.(const run $ output_term $ const ())

let athlete_zones_cmd =
  let run mode () = Lwt_main.run (Strava.Commands.athlete_zones ~mode ()) in
  let doc = "Get athlete zones" in
  Cmd.v (Cmd.info "zones" ~doc) Term.(const run $ output_term $ const ())

(* Activities command *)
let page_opt =
  Arg.(value & opt (some int) None & info ["page"] ~doc:"Page number")

let per_page_opt =
  Arg.(value & opt (some int) None & info ["per-page"] ~doc:"Items per page")

let activities_cmd =
  let run mode page per_page =
    Lwt_main.run (Strava.Commands.activities ~mode ?page ?per_page ())
  in
  let doc = "List activities" in
  Cmd.v (Cmd.info "activities" ~doc)
    Term.(const run $ output_term $ page_opt $ per_page_opt)

(* Activity command *)
let activity_id =
  Arg.(required & pos 0 (some int64) None & info [] ~docv:"ID" ~doc:"Activity ID")

let efforts_flag =
  Arg.(value & flag & info ["efforts"] ~doc:"Include segment efforts")

let activity_cmd =
  let run mode id efforts =
    Lwt_main.run (Strava.Commands.activity ~mode ~include_efforts:efforts id)
  in
  let doc = "Get activity by ID" in
  Cmd.v (Cmd.info "activity" ~doc)
    Term.(const run $ output_term $ activity_id $ efforts_flag)

(* Last command *)
let n_arg =
  Arg.(value & pos 0 int 1 & info [] ~docv:"N" ~doc:"Number of activities")

let last_cmd =
  let run mode n = Lwt_main.run (Strava.Commands.last ~mode n) in
  let doc = "Get last N activities with full details" in
  Cmd.v (Cmd.info "last" ~doc) Term.(const run $ output_term $ n_arg)

(* Today command *)
let today_cmd =
  let run mode () = Lwt_main.run (Strava.Commands.today ~mode ()) in
  let doc = "Get today's activities with full details" in
  Cmd.v (Cmd.info "today" ~doc) Term.(const run $ output_term $ const ())

(* Week command *)
let week_cmd =
  let run mode () = Lwt_main.run (Strava.Commands.week ~mode ()) in
  let doc = "Get this week's activities with full details" in
  Cmd.v (Cmd.info "week" ~doc) Term.(const run $ output_term $ const ())

(* Activity subcommands *)
let stream_keys =
  Arg.(value & pos_all string [] & info [] ~docv:"KEYS" ~doc:"Stream keys (time,distance,latlng,altitude,heartrate,cadence,watts,etc)")

let activity_streams_cmd =
  let run mode id keys =
    Lwt_main.run (Strava.Commands.activity_streams ~mode id keys)
  in
  let doc = "Get activity streams" in
  Cmd.v (Cmd.info "streams" ~doc)
    Term.(const run $ output_term $ activity_id $ stream_keys)

let activity_laps_cmd =
  let run mode id =
    Lwt_main.run (Strava.Commands.activity_laps ~mode id)
  in
  let doc = "Get activity laps" in
  Cmd.v (Cmd.info "laps" ~doc)
    Term.(const run $ output_term $ activity_id)

let activity_zones_cmd =
  let run mode id =
    Lwt_main.run (Strava.Commands.activity_zones ~mode id)
  in
  let doc = "Get activity zones" in
  Cmd.v (Cmd.info "azones" ~doc)
    Term.(const run $ output_term $ activity_id)

let activity_comments_cmd =
  let run mode id =
    Lwt_main.run (Strava.Commands.activity_comments ~mode id)
  in
  let doc = "Get activity comments" in
  Cmd.v (Cmd.info "comments" ~doc)
    Term.(const run $ output_term $ activity_id)

let activity_kudos_cmd =
  let run mode id =
    Lwt_main.run (Strava.Commands.activity_kudos ~mode id)
  in
  let doc = "Get activity kudos" in
  Cmd.v (Cmd.info "kudos" ~doc)
    Term.(const run $ output_term $ activity_id)

(* Segment commands *)
let segment_id =
  Arg.(required & pos 0 (some int64) None & info [] ~docv:"ID" ~doc:"Segment ID")

let segment_cmd =
  let run mode id =
    Lwt_main.run (Strava.Commands.segment ~mode id)
  in
  let doc = "Get segment by ID" in
  Cmd.v (Cmd.info "segment" ~doc)
    Term.(const run $ output_term $ segment_id)

let segments_starred_cmd =
  let run mode page per_page =
    Lwt_main.run (Strava.Commands.segments_starred ~mode ?page ?per_page ())
  in
  let doc = "Get starred segments" in
  Cmd.v (Cmd.info "starred" ~doc)
    Term.(const run $ output_term $ page_opt $ per_page_opt)

let bounds_arg =
  Arg.(required & opt (some string) None & info ["bounds"] ~docv:"BOUNDS" ~doc:"Bounds: SW_LAT,SW_LNG,NE_LAT,NE_LNG")

let activity_type_opt =
  Arg.(value & opt (some string) None & info ["type"] ~docv:"TYPE" ~doc:"Activity type (running/riding)")

let min_cat_opt =
  Arg.(value & opt (some int) None & info ["min-cat"] ~docv:"CAT" ~doc:"Minimum category")

let max_cat_opt =
  Arg.(value & opt (some int) None & info ["max-cat"] ~docv:"CAT" ~doc:"Maximum category")

let segments_explore_cmd =
  let run mode bounds activity_type min_cat max_cat =
    Lwt_main.run (Strava.Commands.segments_explore ~mode ~bounds ?activity_type ?min_cat ?max_cat ())
  in
  let doc = "Explore segments in area" in
  Cmd.v (Cmd.info "explore" ~doc)
    Term.(const run $ output_term $ bounds_arg $ activity_type_opt $ min_cat_opt $ max_cat_opt)

let segment_id_int =
  Arg.(required & opt (some int) None & info ["segment"] ~docv:"ID" ~doc:"Segment ID")

let start_date_opt =
  Arg.(value & opt (some string) None & info ["start"] ~docv:"DATE" ~doc:"Start date")

let end_date_opt =
  Arg.(value & opt (some string) None & info ["end"] ~docv:"DATE" ~doc:"End date")

let efforts_cmd =
  let run mode segment_id start_date end_date per_page =
    Lwt_main.run (Strava.Commands.segment_efforts ~mode ~segment_id ?start_date ?end_date ?per_page ())
  in
  let doc = "Get segment efforts" in
  Cmd.v (Cmd.info "efforts" ~doc)
    Term.(const run $ output_term $ segment_id_int $ start_date_opt $ end_date_opt $ per_page_opt)

let effort_id =
  Arg.(required & pos 0 (some int64) None & info [] ~docv:"ID" ~doc:"Effort ID")

let effort_cmd =
  let run mode id =
    Lwt_main.run (Strava.Commands.segment_effort ~mode id)
  in
  let doc = "Get segment effort by ID" in
  Cmd.v (Cmd.info "effort" ~doc)
    Term.(const run $ output_term $ effort_id)

(* Gear command *)
let gear_id =
  Arg.(required & pos 0 (some string) None & info [] ~docv:"ID" ~doc:"Gear ID")

let gear_cmd =
  let run mode id =
    Lwt_main.run (Strava.Commands.gear ~mode id)
  in
  let doc = "Get gear by ID" in
  Cmd.v (Cmd.info "gear" ~doc)
    Term.(const run $ output_term $ gear_id)

(* Route commands *)
let route_id =
  Arg.(required & pos 0 (some int64) None & info [] ~docv:"ID" ~doc:"Route ID")

let route_cmd =
  let run mode id =
    Lwt_main.run (Strava.Commands.route ~mode id)
  in
  let doc = "Get route by ID" in
  Cmd.v (Cmd.info "route" ~doc)
    Term.(const run $ output_term $ route_id)

let routes_cmd =
  let run mode page per_page =
    Lwt_main.run (Strava.Commands.routes ~mode ?page ?per_page ())
  in
  let doc = "List routes" in
  Cmd.v (Cmd.info "routes" ~doc)
    Term.(const run $ output_term $ page_opt $ per_page_opt)

(* Main *)
let main_cmd =
  let doc = "CLI for Strava API" in
  let info = Cmd.info "strava" ~version:"0.1.0" ~doc in
  Cmd.group info [
    init_cmd;
    athlete_cmd;
    athlete_stats_cmd;
    athlete_zones_cmd;
    activities_cmd;
    activity_cmd;
    activity_streams_cmd;
    activity_laps_cmd;
    activity_zones_cmd;
    activity_comments_cmd;
    activity_kudos_cmd;
    last_cmd;
    today_cmd;
    week_cmd;
    segment_cmd;
    segments_starred_cmd;
    segments_explore_cmd;
    efforts_cmd;
    effort_cmd;
    gear_cmd;
    route_cmd;
    routes_cmd;
  ]

let () = exit (Cmd.eval' main_cmd)
