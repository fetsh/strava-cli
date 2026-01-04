type api_error =
  | Unauthorized
  | RateLimited of { limit: string; usage: string }
  | HttpError of int * string
  | NetworkError of string

val pp_error : api_error -> string

val get_athlete : unit -> (Yojson.Safe.t, api_error) result Lwt.t
val get_athlete_stats : int -> (Yojson.Safe.t, api_error) result Lwt.t
val get_athlete_zones : unit -> (Yojson.Safe.t, api_error) result Lwt.t
val update_athlete_weight : float -> (Yojson.Safe.t, api_error) result Lwt.t

val get_activities :
  ?page:int -> ?per_page:int -> ?after:int -> ?before:int ->
  unit -> (Yojson.Safe.t, api_error) result Lwt.t

val get_activity :
  ?include_all_efforts:bool -> int64 -> (Yojson.Safe.t, api_error) result Lwt.t

val get_activity_streams :
  int64 -> string list -> (Yojson.Safe.t, api_error) result Lwt.t

val get_activity_laps : int64 -> (Yojson.Safe.t, api_error) result Lwt.t
val get_activity_zones : int64 -> (Yojson.Safe.t, api_error) result Lwt.t
val get_activity_comments : int64 -> (Yojson.Safe.t, api_error) result Lwt.t
val get_activity_kudos : int64 -> (Yojson.Safe.t, api_error) result Lwt.t

val create_activity :
  name:string -> sport_type:string -> start_date_local:string ->
  elapsed_time:int -> ?description:string -> ?distance:float ->
  ?trainer:bool -> ?commute:bool -> unit -> (Yojson.Safe.t, api_error) result Lwt.t

val update_activity : int64 -> Yojson.Safe.t -> (Yojson.Safe.t, api_error) result Lwt.t

val get_segment : int64 -> (Yojson.Safe.t, api_error) result Lwt.t
val get_starred_segments : ?page:int -> ?per_page:int -> unit -> (Yojson.Safe.t, api_error) result Lwt.t
val star_segment : int64 -> bool -> (Yojson.Safe.t, api_error) result Lwt.t
val explore_segments :
  bounds:string -> ?activity_type:string -> ?min_cat:int -> ?max_cat:int ->
  unit -> (Yojson.Safe.t, api_error) result Lwt.t

val get_segment_efforts :
  segment_id:int -> ?start_date:string -> ?end_date:string -> ?per_page:int ->
  unit -> (Yojson.Safe.t, api_error) result Lwt.t

val get_segment_effort : int64 -> (Yojson.Safe.t, api_error) result Lwt.t

val get_gear : string -> (Yojson.Safe.t, api_error) result Lwt.t
val get_route : int64 -> (Yojson.Safe.t, api_error) result Lwt.t
val get_routes : ?page:int -> ?per_page:int -> unit -> (Yojson.Safe.t, api_error) result Lwt.t
