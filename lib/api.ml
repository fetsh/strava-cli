open Lwt.Syntax

let base_url = "https://www.strava.com/api/v3"

type api_error =
  | Unauthorized
  | RateLimited of { limit: string; usage: string }
  | HttpError of int * string
  | NetworkError of string

let pp_error = function
  | Unauthorized -> "Unauthorized (token expired?)"
  | RateLimited { limit; usage } ->
    Printf.sprintf "Rate limited. Limit: %s, Usage: %s" limit usage
  | HttpError (code, body) ->
    Printf.sprintf "HTTP %d: %s" code body
  | NetworkError msg ->
    Printf.sprintf "Network error: %s" msg

(* Make authenticated request *)
let request ?(meth=`GET) ?(body="") ~path () =
  let* token_result = Auth.get_valid_token () in
  match token_result with
  | Error e -> Lwt.return_error (NetworkError e)
  | Ok token ->
    let open Cohttp_lwt_unix in
    let uri = Uri.of_string (base_url ^ path) in
    let headers = Cohttp.Header.of_list [
      ("Authorization", "Bearer " ^ token);
      ("Content-Type", "application/json");
    ] in
    let body_arg = if body = "" then None else Some (Cohttp_lwt.Body.of_string body) in
    let* resp, resp_body =
      match meth with
      | `GET -> Client.get ~headers uri
      | `POST -> Client.post ~headers ?body:body_arg uri
      | `PUT -> Client.put ~headers ?body:body_arg uri
      | `DELETE -> Client.delete ~headers uri
    in
    let* body_str = Cohttp_lwt.Body.to_string resp_body in
    let status = Cohttp.Response.status resp in
    let code = Cohttp.Code.code_of_status status in
    let resp_headers = Cohttp.Response.headers resp in
    if code = 401 then
      Lwt.return_error Unauthorized
    else if code = 429 then begin
      let limit = Cohttp.Header.get resp_headers "X-RateLimit-Limit" |> Option.value ~default:"?" in
      let usage = Cohttp.Header.get resp_headers "X-RateLimit-Usage" |> Option.value ~default:"?" in
      Lwt.return_error (RateLimited { limit; usage })
    end
    else if Cohttp.Code.is_success code then
      Lwt.return_ok (Yojson.Safe.from_string body_str)
    else
      Lwt.return_error (HttpError (code, body_str))

(* GET request *)
let get path = request ~meth:`GET ~path ()

(* GET with query params *)
let get_with_params path params =
  let query = Uri.encoded_of_query (List.map (fun (k,v) -> (k, [v])) params) in
  let full_path = if query = "" then path else path ^ "?" ^ query in
  get full_path

(* POST with form data *)
let post_form path params =
  let body = Uri.encoded_of_query (List.map (fun (k,v) -> (k, [v])) params) in
  request ~meth:`POST ~body ~path ()

(* PUT with JSON body *)
let put path json =
  let body = Yojson.Safe.to_string json in
  request ~meth:`PUT ~body ~path ()

(* Specific endpoints *)

let get_athlete () = get "/athlete"

let get_athlete_stats athlete_id =
  get (Printf.sprintf "/athletes/%d/stats" athlete_id)

let get_athlete_zones () = get "/athlete/zones"

let update_athlete_weight weight =
  post_form "/athlete" [("weight", string_of_float weight)]

let get_activities ?page ?per_page ?after ?before () =
  let params = List.filter_map Fun.id [
    Option.map (fun p -> ("page", string_of_int p)) page;
    Option.map (fun p -> ("per_page", string_of_int p)) per_page;
    Option.map (fun a -> ("after", string_of_int a)) after;
    Option.map (fun b -> ("before", string_of_int b)) before;
  ] in
  get_with_params "/athlete/activities" params

let get_activity ?(include_all_efforts=false) id =
  let path = Printf.sprintf "/activities/%Ld" id in
  if include_all_efforts then
    get_with_params path [("include_all_efforts", "true")]
  else
    get path

let get_activity_streams id keys =
  let path = Printf.sprintf "/activities/%Ld/streams" id in
  get_with_params path [("keys", String.concat "," keys); ("key_by_type", "true")]

let get_activity_laps id =
  get (Printf.sprintf "/activities/%Ld/laps" id)

let get_activity_zones id =
  get (Printf.sprintf "/activities/%Ld/zones" id)

let get_activity_comments id =
  get (Printf.sprintf "/activities/%Ld/comments" id)

let get_activity_kudos id =
  get (Printf.sprintf "/activities/%Ld/kudos" id)

let create_activity ~name ~sport_type ~start_date_local ~elapsed_time
    ?description ?distance ?trainer ?commute () =
  let params = [
    ("name", name);
    ("sport_type", sport_type);
    ("start_date_local", start_date_local);
    ("elapsed_time", string_of_int elapsed_time);
  ] @ List.filter_map Fun.id [
    Option.map (fun d -> ("description", d)) description;
    Option.map (fun d -> ("distance", string_of_float d)) distance;
    Option.map (fun t -> ("trainer", if t then "1" else "0")) trainer;
    Option.map (fun c -> ("commute", if c then "1" else "0")) commute;
  ] in
  post_form "/activities" params

let update_activity id updates =
  put (Printf.sprintf "/activities/%Ld" id) updates

let get_segment id =
  get (Printf.sprintf "/segments/%Ld" id)

let get_starred_segments ?page ?per_page () =
  let params = List.filter_map Fun.id [
    Option.map (fun p -> ("page", string_of_int p)) page;
    Option.map (fun p -> ("per_page", string_of_int p)) per_page;
  ] in
  get_with_params "/segments/starred" params

let star_segment id starred =
  post_form (Printf.sprintf "/segments/%Ld/starred" id)
    [("starred", if starred then "true" else "false")]

let explore_segments ~bounds ?activity_type ?min_cat ?max_cat () =
  let params = [("bounds", bounds)] @ List.filter_map Fun.id [
    Option.map (fun t -> ("activity_type", t)) activity_type;
    Option.map (fun c -> ("min_cat", string_of_int c)) min_cat;
    Option.map (fun c -> ("max_cat", string_of_int c)) max_cat;
  ] in
  get_with_params "/segments/explore" params

let get_segment_efforts ~segment_id ?start_date ?end_date ?per_page () =
  let params = [("segment_id", string_of_int segment_id)] @ List.filter_map Fun.id [
    Option.map (fun d -> ("start_date_local", d)) start_date;
    Option.map (fun d -> ("end_date_local", d)) end_date;
    Option.map (fun p -> ("per_page", string_of_int p)) per_page;
  ] in
  get_with_params "/segment_efforts" params

let get_segment_effort id =
  get (Printf.sprintf "/segment_efforts/%Ld" id)

let get_gear id = get (Printf.sprintf "/gear/%s" id)

let get_route id = get (Printf.sprintf "/routes/%Ld" id)

let get_routes ?page ?per_page () =
  let params = List.filter_map Fun.id [
    Option.map (fun p -> ("page", string_of_int p)) page;
    Option.map (fun p -> ("per_page", string_of_int p)) per_page;
  ] in
  get_with_params "/athlete/routes" params
