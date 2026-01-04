open Lwt.Syntax

let oauth_base = "https://www.strava.com/oauth"
let redirect_uri = "http://localhost:8888/callback"
let scopes = "read_all,activity:read_all,activity:write,profile:read_all,profile:write"

let authorization_url ~client_id =
  Printf.sprintf
    "%s/authorize?client_id=%s&response_type=code&redirect_uri=%s&scope=%s"
    oauth_base client_id redirect_uri scopes

(* Exchange code for tokens *)
let exchange_code ~client_id ~client_secret ~code =
  let open Cohttp_lwt_unix in
  let uri = Uri.of_string (oauth_base ^ "/token") in
  let params = [
    ("client_id", client_id);
    ("client_secret", client_secret);
    ("code", code);
    ("grant_type", "authorization_code");
  ] in
  let body = Uri.encoded_of_query (List.map (fun (k,v) -> (k, [v])) params) in
  let headers = Cohttp.Header.init_with "Content-Type" "application/x-www-form-urlencoded" in
  let* resp, body = Client.post ~headers ~body:(Cohttp_lwt.Body.of_string body) uri in
  let* body_str = Cohttp_lwt.Body.to_string body in
  let status = Cohttp.Response.status resp in
  if Cohttp.Code.is_success (Cohttp.Code.code_of_status status) then
    Lwt.return_ok (Yojson.Safe.from_string body_str)
  else
    Lwt.return_error (Printf.sprintf "Token exchange failed: %s" body_str)

(* Refresh access token *)
let refresh_token ~client_id ~client_secret ~refresh_token:rt =
  let open Cohttp_lwt_unix in
  let uri = Uri.of_string (oauth_base ^ "/token") in
  let params = [
    ("client_id", client_id);
    ("client_secret", client_secret);
    ("refresh_token", rt);
    ("grant_type", "refresh_token");
  ] in
  let body = Uri.encoded_of_query (List.map (fun (k,v) -> (k, [v])) params) in
  let headers = Cohttp.Header.init_with "Content-Type" "application/x-www-form-urlencoded" in
  let* resp, body = Client.post ~headers ~body:(Cohttp_lwt.Body.of_string body) uri in
  let* body_str = Cohttp_lwt.Body.to_string body in
  let status = Cohttp.Response.status resp in
  if Cohttp.Code.is_success (Cohttp.Code.code_of_status status) then
    Lwt.return_ok (Yojson.Safe.from_string body_str)
  else
    Lwt.return_error (Printf.sprintf "Token refresh failed: %s" body_str)

(* Parse token response *)
let parse_token_response json =
  let open Yojson.Safe.Util in
  let access_token = json |> member "access_token" |> to_string in
  let refresh_token = json |> member "refresh_token" |> to_string in
  let expires_at = json |> member "expires_at" |> to_int in
  (access_token, refresh_token, expires_at)

(* Local server to receive OAuth callback *)
let wait_for_callback () =
  let code_received = ref None in
  let callback _conn req _body =
    let uri = Cohttp.Request.uri req in
    let path = Uri.path uri in
    if path = "/callback" then begin
      let query = Uri.query uri in
      (match List.assoc_opt "code" query with
       | Some [code] -> code_received := Some code
       | _ -> ());
      let body = "Authorization successful! You can close this window." in
      Cohttp_lwt_unix.Server.respond_string ~status:`OK ~body ()
    end else
      Cohttp_lwt_unix.Server.respond_string ~status:`Not_found ~body:"Not found" ()
  in
  let server = Cohttp_lwt_unix.Server.make ~callback () in
  let stop, stopper = Lwt.wait () in
  let _ =
    let* () = Lwt_unix.sleep 0.5 in
    let rec wait () =
      match !code_received with
      | Some _ -> Lwt.wakeup stopper (); Lwt.return_unit
      | None -> let* () = Lwt_unix.sleep 0.1 in wait ()
    in
    wait ()
  in
  let* () = Cohttp_lwt_unix.Server.create
    ~stop
    ~mode:(`TCP (`Port 8888))
    server
  in
  match !code_received with
  | Some code -> Lwt.return_ok code
  | None -> Lwt.return_error "No code received"

(* Open browser - cross platform *)
let open_browser url =
  let cmd =
    if Sys.file_exists "/usr/bin/xdg-open" then "xdg-open"
    else if Sys.file_exists "/usr/bin/open" then "open"  (* macOS *)
    else "xdg-open"
  in
  ignore (Unix.system (Printf.sprintf "%s '%s' 2>/dev/null &" cmd url))

(* Full init flow *)
let init ~client_id ~client_secret =
  let url = authorization_url ~client_id in
  Printf.printf "Opening browser for authorization...\n%!";
  Printf.printf "If browser doesn't open, visit:\n%s\n%!" url;
  open_browser url;
  let* code_result = wait_for_callback () in
  match code_result with
  | Error e -> Lwt.return_error e
  | Ok code ->
    let* token_result = exchange_code ~client_id ~client_secret ~code in
    match token_result with
    | Error e -> Lwt.return_error e
    | Ok json ->
      let access_token, refresh_token, expires_at = parse_token_response json in
      Db.save_credentials {
        client_id; client_secret; access_token; refresh_token; expires_at
      };
      Printf.printf "Authorization successful!\n%!";
      Lwt.return_ok ()

(* Get valid token, refreshing if needed *)
let get_valid_token () =
  match Db.load_credentials () with
  | None -> Lwt.return_error "Not authenticated. Run 'strava init' first."
  | Some creds ->
    let now = int_of_float (Unix.time ()) in
    (* Refresh if expires in less than 5 minutes *)
    if creds.expires_at - now < 300 then begin
      let* result = refresh_token
        ~client_id:creds.client_id
        ~client_secret:creds.client_secret
        ~refresh_token:creds.refresh_token
      in
      match result with
      | Error e -> Lwt.return_error e
      | Ok json ->
        let access_token, refresh_token, expires_at = parse_token_response json in
        Db.update_tokens ~access_token ~refresh_token ~expires_at;
        Lwt.return_ok access_token
    end else
      Lwt.return_ok creds.access_token
