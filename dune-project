(lang dune 3.0)
(name strava-cli)
(generate_opam_files true)

(package
 (name strava-cli)
 (synopsis "CLI for Strava API")
 (depends
  (ocaml (>= 4.14))
  dune
  cohttp-lwt-unix
  lwt
  yojson
  cmdliner
  sqlite3
  uri
  ptime
  logs
  fmt))
