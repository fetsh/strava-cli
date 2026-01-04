val init : client_id:string -> client_secret:string -> (unit, string) result Lwt.t
val get_valid_token : unit -> (string, string) result Lwt.t
