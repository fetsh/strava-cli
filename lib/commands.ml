open Lwt.Syntax

(* Output handling *)
type output_mode =
  | ToFile of string option  (* None = auto temp file *)
  | ToStdout
  | Quiet
  | Pretty

let save_json ~mode ~prefix ?(pretty_printer = fun _ -> ()) json =
  match mode with
  | Quiet -> Lwt.return_ok ()
  | Pretty ->
    pretty_printer json;
    Lwt.return_ok ()
  | ToStdout ->
    print_endline (Yojson.Safe.pretty_to_string json);
    Lwt.return_ok ()
  | ToFile path_opt ->
    let path = match path_opt with
      | Some p -> p
      | None ->
        let ts = int_of_float (Unix.time ()) in
        Printf.sprintf "/tmp/strava-%s-%d.json" prefix ts
    in
    let oc = open_out path in
    output_string oc (Yojson.Safe.pretty_to_string json);
    close_out oc;
    Printf.printf "%s\n" path;
    Lwt.return_ok ()

let handle_result ~mode ~prefix ?pretty_printer result =
  match result with
  | Error e ->
    Printf.eprintf "Error: %s\n" (Api.pp_error e);
    Lwt.return 1
  | Ok json ->
    let* save_result = save_json ~mode ~prefix ?pretty_printer json in
    match save_result with
    | Ok () -> Lwt.return 0
    | Error e ->
      Printf.eprintf "Error saving: %s\n" e;
      Lwt.return 1

(* Athlete commands *)
let athlete ~mode () =
  let* result = Api.get_athlete () in
  handle_result ~mode ~prefix:"athlete" ~pretty_printer:Pretty.print_athlete result

let athlete_stats ~mode () =
  let* result = Api.get_athlete () in
  match result with
  | Error e -> Printf.eprintf "Error: %s\n" (Api.pp_error e); Lwt.return 1
  | Ok athlete_json ->
    let id = Yojson.Safe.Util.(athlete_json |> member "id" |> to_int) in
    let* stats_result = Api.get_athlete_stats id in
    handle_result ~mode ~prefix:"stats" ~pretty_printer:Pretty.print_stats stats_result

let athlete_zones ~mode () =
  let* result = Api.get_athlete_zones () in
  handle_result ~mode ~prefix:"zones" result

(* Activity commands *)
let activities ~mode ?page ?per_page () =
  let* result = Api.get_activities ?page ?per_page () in
  handle_result ~mode ~prefix:"activities" ~pretty_printer:Pretty.print_activities result

let activity ~mode ~include_efforts id =
  let* result = Api.get_activity ~include_all_efforts:include_efforts id in
  handle_result ~mode ~prefix:"activity" ~pretty_printer:Pretty.print_activity result

let activity_streams ~mode id keys =
  let* result = Api.get_activity_streams id keys in
  handle_result ~mode ~prefix:"streams" result

let activity_laps ~mode id =
  let* result = Api.get_activity_laps id in
  handle_result ~mode ~prefix:"laps" result

let activity_zones ~mode id =
  let* result = Api.get_activity_zones id in
  handle_result ~mode ~prefix:"zones" result

let activity_comments ~mode id =
  let* result = Api.get_activity_comments id in
  handle_result ~mode ~prefix:"comments" result

let activity_kudos ~mode id =
  let* result = Api.get_activity_kudos id in
  handle_result ~mode ~prefix:"kudos" result

(* Convenience commands *)
let last ~mode n =
  let* result = Api.get_activities ~per_page:n () in
  match result with
  | Error e -> Printf.eprintf "Error: %s\n" (Api.pp_error e); Lwt.return 1
  | Ok activities_json ->
    let open Yojson.Safe.Util in
    let activities = activities_json |> to_list in
    let* detailed = Lwt_list.map_s (fun a ->
      let id = a |> member "id" |> to_int |> Int64.of_int in
      Api.get_activity id
    ) activities in
    let successful = List.filter_map (function Ok j -> Some j | Error _ -> None) detailed in
    if n = 1 then begin
      match successful with
      | [single] ->
        let* _ = save_json ~mode ~prefix:"last" ~pretty_printer:Pretty.print_activity single in
        Lwt.return 0
      | _ ->
        let combined = `List successful in
        let* _ = save_json ~mode ~prefix:"last" ~pretty_printer:Pretty.print_activities combined in
        Lwt.return 0
    end else begin
      let combined = `List successful in
      let* _ = save_json ~mode ~prefix:"last" ~pretty_printer:Pretty.print_activities combined in
      Lwt.return 0
    end

let today ~mode () =
  let now = Unix.time () in
  let today_start =
    let tm = Unix.localtime now in
    let midnight = { tm with Unix.tm_hour = 0; tm_min = 0; tm_sec = 0 } in
    int_of_float (fst (Unix.mktime midnight))
  in
  let* result = Api.get_activities ~after:today_start () in
  match result with
  | Error e -> Printf.eprintf "Error: %s\n" (Api.pp_error e); Lwt.return 1
  | Ok activities_json ->
    let open Yojson.Safe.Util in
    let activities = activities_json |> to_list in
    let* detailed = Lwt_list.map_s (fun a ->
      let id = a |> member "id" |> to_int |> Int64.of_int in
      Api.get_activity id
    ) activities in
    let successful = List.filter_map (function Ok j -> Some j | Error _ -> None) detailed in
    let combined = `List successful in
    let* _ = save_json ~mode ~prefix:"today" ~pretty_printer:Pretty.print_activities combined in
    Lwt.return 0

let week ~mode () =
  let now = Unix.time () in
  let week_ago = int_of_float now - (7 * 24 * 60 * 60) in
  let* result = Api.get_activities ~after:week_ago () in
  match result with
  | Error e -> Printf.eprintf "Error: %s\n" (Api.pp_error e); Lwt.return 1
  | Ok activities_json ->
    let open Yojson.Safe.Util in
    let activities = activities_json |> to_list in
    let* detailed = Lwt_list.map_s (fun a ->
      let id = a |> member "id" |> to_int |> Int64.of_int in
      Api.get_activity id
    ) activities in
    let successful = List.filter_map (function Ok j -> Some j | Error _ -> None) detailed in
    let combined = `List successful in
    let* _ = save_json ~mode ~prefix:"week" ~pretty_printer:Pretty.print_activities combined in
    Lwt.return 0

(* Segment commands *)
let segment ~mode id =
  let* result = Api.get_segment id in
  handle_result ~mode ~prefix:"segment" result

let segments_starred ~mode ?page ?per_page () =
  let* result = Api.get_starred_segments ?page ?per_page () in
  handle_result ~mode ~prefix:"segments-starred" ~pretty_printer:Pretty.print_segments result

let segments_explore ~mode ~bounds ?activity_type ?min_cat ?max_cat () =
  let* result = Api.explore_segments ~bounds ?activity_type ?min_cat ?max_cat () in
  handle_result ~mode ~prefix:"segments-explore" result

let segment_efforts ~mode ~segment_id ?start_date ?end_date ?per_page () =
  let* result = Api.get_segment_efforts ~segment_id ?start_date ?end_date ?per_page () in
  handle_result ~mode ~prefix:"efforts" result

let segment_effort ~mode id =
  let* result = Api.get_segment_effort id in
  handle_result ~mode ~prefix:"effort" result

(* Gear commands *)
let gear ~mode id =
  let* result = Api.get_gear id in
  handle_result ~mode ~prefix:"gear" ~pretty_printer:Pretty.print_gear result

(* Route commands *)
let route ~mode id =
  let* result = Api.get_route id in
  handle_result ~mode ~prefix:"route" result

let routes ~mode ?page ?per_page () =
  let* result = Api.get_routes ?page ?per_page () in
  handle_result ~mode ~prefix:"routes" ~pretty_printer:Pretty.print_routes result
