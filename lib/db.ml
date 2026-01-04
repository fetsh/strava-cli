let config_dir =
  let home = Sys.getenv "HOME" in
  Filename.concat home ".config/strava-cli"

let db_path = Filename.concat config_dir "strava.db"

let ensure_config_dir () =
  if not (Sys.file_exists config_dir) then
    Unix.mkdir config_dir 0o700

let init_db db =
  let sql = {|
    CREATE TABLE IF NOT EXISTS credentials (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      client_id TEXT NOT NULL,
      client_secret TEXT NOT NULL,
      access_token TEXT NOT NULL,
      refresh_token TEXT NOT NULL,
      expires_at INTEGER NOT NULL
    )
  |} in
  match Sqlite3.exec db sql with
  | Sqlite3.Rc.OK -> ()
  | rc -> failwith (Printf.sprintf "DB init failed: %s" (Sqlite3.Rc.to_string rc))

let with_db f =
  ensure_config_dir ();
  let db = Sqlite3.db_open db_path in
  init_db db;
  let result = f db in
  ignore (Sqlite3.db_close db);
  result

type credentials = {
  client_id: string;
  client_secret: string;
  access_token: string;
  refresh_token: string;
  expires_at: int;
}

let save_credentials creds =
  with_db (fun db ->
    let sql = {|
      INSERT OR REPLACE INTO credentials
      (id, client_id, client_secret, access_token, refresh_token, expires_at)
      VALUES (1, ?, ?, ?, ?, ?)
    |} in
    let stmt = Sqlite3.prepare db sql in
    ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT creds.client_id));
    ignore (Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT creds.client_secret));
    ignore (Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT creds.access_token));
    ignore (Sqlite3.bind stmt 4 (Sqlite3.Data.TEXT creds.refresh_token));
    ignore (Sqlite3.bind stmt 5 (Sqlite3.Data.INT (Int64.of_int creds.expires_at)));
    match Sqlite3.step stmt with
    | Sqlite3.Rc.DONE -> ignore (Sqlite3.finalize stmt)
    | rc -> failwith (Printf.sprintf "Save failed: %s" (Sqlite3.Rc.to_string rc))
  )

let load_credentials () =
  with_db (fun db ->
    let sql = "SELECT client_id, client_secret, access_token, refresh_token, expires_at FROM credentials WHERE id = 1" in
    let stmt = Sqlite3.prepare db sql in
    match Sqlite3.step stmt with
    | Sqlite3.Rc.ROW ->
      let get_text i = match Sqlite3.column stmt i with
        | Sqlite3.Data.TEXT s -> s
        | _ -> failwith "Expected TEXT"
      in
      let get_int i = match Sqlite3.column stmt i with
        | Sqlite3.Data.INT i -> Int64.to_int i
        | _ -> failwith "Expected INT"
      in
      let result = Some {
        client_id = get_text 0;
        client_secret = get_text 1;
        access_token = get_text 2;
        refresh_token = get_text 3;
        expires_at = get_int 4;
      } in
      ignore (Sqlite3.finalize stmt);
      result
    | Sqlite3.Rc.DONE ->
      ignore (Sqlite3.finalize stmt);
      None
    | rc ->
      failwith (Printf.sprintf "Load failed: %s" (Sqlite3.Rc.to_string rc))
  )

let update_tokens ~access_token ~refresh_token ~expires_at =
  with_db (fun db ->
    let sql = "UPDATE credentials SET access_token = ?, refresh_token = ?, expires_at = ? WHERE id = 1" in
    let stmt = Sqlite3.prepare db sql in
    ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT access_token));
    ignore (Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT refresh_token));
    ignore (Sqlite3.bind stmt 3 (Sqlite3.Data.INT (Int64.of_int expires_at)));
    match Sqlite3.step stmt with
    | Sqlite3.Rc.DONE -> ignore (Sqlite3.finalize stmt)
    | rc -> failwith (Printf.sprintf "Update failed: %s" (Sqlite3.Rc.to_string rc))
  )
