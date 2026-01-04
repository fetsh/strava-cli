type credentials = {
  client_id: string;
  client_secret: string;
  access_token: string;
  refresh_token: string;
  expires_at: int;
}

val save_credentials : credentials -> unit
val load_credentials : unit -> credentials option
val update_tokens : access_token:string -> refresh_token:string -> expires_at:int -> unit
