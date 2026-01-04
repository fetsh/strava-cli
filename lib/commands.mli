type output_mode =
  | ToFile of string option
  | ToStdout
  | Quiet
  | Pretty

(* Athlete commands *)
val athlete : mode:output_mode -> unit -> int Lwt.t
val athlete_stats : mode:output_mode -> unit -> int Lwt.t
val athlete_zones : mode:output_mode -> unit -> int Lwt.t

(* Activity commands *)
val activities : mode:output_mode -> ?page:int -> ?per_page:int -> unit -> int Lwt.t
val activity : mode:output_mode -> include_efforts:bool -> int64 -> int Lwt.t
val activity_streams : mode:output_mode -> int64 -> string list -> int Lwt.t
val activity_laps : mode:output_mode -> int64 -> int Lwt.t
val activity_zones : mode:output_mode -> int64 -> int Lwt.t
val activity_comments : mode:output_mode -> int64 -> int Lwt.t
val activity_kudos : mode:output_mode -> int64 -> int Lwt.t

(* Convenience commands *)
val last : mode:output_mode -> int -> int Lwt.t
val today : mode:output_mode -> unit -> int Lwt.t
val week : mode:output_mode -> unit -> int Lwt.t

(* Segment commands *)
val segment : mode:output_mode -> int64 -> int Lwt.t
val segments_starred : mode:output_mode -> ?page:int -> ?per_page:int -> unit -> int Lwt.t
val segments_explore : mode:output_mode -> bounds:string -> ?activity_type:string -> ?min_cat:int -> ?max_cat:int -> unit -> int Lwt.t
val segment_efforts : mode:output_mode -> segment_id:int -> ?start_date:string -> ?end_date:string -> ?per_page:int -> unit -> int Lwt.t
val segment_effort : mode:output_mode -> int64 -> int Lwt.t

(* Gear commands *)
val gear : mode:output_mode -> string -> int Lwt.t

(* Route commands *)
val route : mode:output_mode -> int64 -> int Lwt.t
val routes : mode:output_mode -> ?page:int -> ?per_page:int -> unit -> int Lwt.t
