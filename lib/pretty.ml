open Yojson.Safe.Util

(* Emoji helpers *)
let sport_emoji = function
  | "Run" -> "🏃"
  | "Ride" -> "🚴"
  | "Swim" -> "🏊"
  | "Walk" -> "🚶"
  | "Hike" -> "🥾"
  | "VirtualRide" -> "🎮"
  | "VirtualRun" -> "🎮"
  | _ -> "⚡"

(* Time formatting *)
let format_duration seconds =
  let hours = seconds / 3600 in
  let minutes = (seconds mod 3600) / 60 in
  let secs = seconds mod 60 in
  if hours > 0 then
    Printf.sprintf "%dh %02dm %02ds" hours minutes secs
  else if minutes > 0 then
    Printf.sprintf "%dm %02ds" minutes secs
  else
    Printf.sprintf "%ds" secs

let format_pace distance_m seconds =
  if distance_m > 0.0 then
    let distance_km = distance_m /. 1000.0 in
    let pace_seconds = int_of_float (float_of_int seconds /. distance_km) in
    let mins = pace_seconds / 60 in
    let secs = pace_seconds mod 60 in
    Printf.sprintf "%d:%02d /km" mins secs
  else
    "-"

let format_distance meters =
  let km = meters /. 1000.0 in
  if km >= 1.0 then
    Printf.sprintf "%.2f km" km
  else
    Printf.sprintf "%.0f m" meters

let format_speed mps =
  let kmh = mps *. 3.6 in
  Printf.sprintf "%.1f km/h" kmh

let format_date iso_date =
  if String.length iso_date >= 10 then
    String.sub iso_date 0 10
  else
    iso_date

(* Calculate visual width accounting for emojis *)
let visual_width s =
  let len = String.length s in
  let rec count_chars pos count =
    if pos >= len then count
    else
      let c = Char.code s.[pos] in
      if c >= 0xF0 then
        (* 4-byte emoji: displays as 2 terminal characters *)
        count_chars (pos + 4) (count + 2)
      else if c >= 0xE0 then
        (* 3-byte UTF-8 char: displays as 1 character *)
        count_chars (pos + 3) (count + 1)
      else if c >= 0xC0 then
        (* 2-byte UTF-8 char (like ×): displays as 1 character *)
        count_chars (pos + 2) (count + 1)
      else
        (* Regular ASCII: displays as 1 character *)
        count_chars (pos + 1) (count + 1)
  in
  count_chars 0 0

(* Table printing *)
let print_table headers rows =
  let num_cols = List.length headers in
  let col_widths = Array.make num_cols 0 in

  (* Calculate column widths using visual width *)
  List.iteri (fun i h ->
    col_widths.(i) <- max col_widths.(i) (visual_width h)
  ) headers;

  List.iter (fun row ->
    List.iteri (fun i cell ->
      if i < num_cols then
        col_widths.(i) <- max col_widths.(i) (visual_width cell)
    ) row
  ) rows;

  (* Print header *)
  List.iteri (fun i h ->
    let padding = col_widths.(i) - (visual_width h) + 2 in
    Printf.printf "%s%s" h (String.make padding ' ');
  ) headers;
  print_newline ();

  (* Print separator *)
  Array.iter (fun w ->
    Printf.printf "%s  " (String.make w '-')
  ) col_widths;
  print_newline ();

  (* Print rows *)
  List.iter (fun row ->
    List.iteri (fun i cell ->
      if i < num_cols then begin
        let padding = col_widths.(i) - (visual_width cell) + 2 in
        Printf.printf "%s%s" cell (String.make padding ' ')
      end
    ) row;
    print_newline ()
  ) rows

(* Pretty print activities list *)
let print_activities json =
  let activities = json |> to_list in
  let headers = ["ID"; "DATE"; "TYPE"; "NAME"; "DISTANCE"; "TIME"; "PACE"] in
  let rows = List.map (fun activity ->
    let id = activity |> member "id" |> to_int |> string_of_int in
    let date = activity |> member "start_date_local" |> to_string |> format_date in
    let sport = activity |> member "sport_type" |> to_string in
    let emoji = sport_emoji sport in
    let name = activity |> member "name" |> to_string in
    let name_truncated = if String.length name > 30 then String.sub name 0 27 ^ "..." else name in
    let distance = activity |> member "distance" |> to_float in
    let moving_time = activity |> member "moving_time" |> to_int in
    let pace = if sport = "Run" then format_pace distance moving_time else "-" in
    [
      id;
      date;
      emoji ^ " " ^ sport;
      name_truncated;
      format_distance distance;
      format_duration moving_time;
      pace;
    ]
  ) activities in
  print_table headers rows

(* Pretty print single activity *)
let print_activity json =
  let get_string key = try json |> member key |> to_string with _ -> "-" in
  let get_float key = try json |> member key |> to_float with _ -> 0.0 in
  let get_int key = try json |> member key |> to_int with _ -> 0 in

  let id = get_int "id" in
  let name = get_string "name" in
  let sport = get_string "sport_type" in
  let emoji = sport_emoji sport in
  let date = get_string "start_date_local" in
  let distance = get_float "distance" in
  let moving_time = get_int "moving_time" in
  let elapsed_time = get_int "elapsed_time" in
  let elevation = get_float "total_elevation_gain" in
  let avg_speed = get_float "average_speed" in
  let avg_hr = get_int "average_heartrate" in
  let max_hr = get_int "max_heartrate" in
  let avg_watts = get_int "average_watts" in

  Printf.printf "\n%s %s\n" emoji name;
  Printf.printf "%s\n\n" (String.make (String.length name + 3) '=');

  Printf.printf "🆔 ID:            %d\n" id;
  Printf.printf "📅 Date:          %s\n" (format_date date);
  Printf.printf "🏃 Sport:         %s\n" sport;
  Printf.printf "📏 Distance:      %s\n" (format_distance distance);
  Printf.printf "⏱️  Moving time:   %s\n" (format_duration moving_time);
  Printf.printf "⏰ Elapsed time:  %s\n" (format_duration elapsed_time);
  Printf.printf "⬆️  Elevation:     %.0f m\n" elevation;
  Printf.printf "🚀 Avg speed:     %s\n" (format_speed avg_speed);

  if sport = "Run" then
    Printf.printf "👟 Avg pace:      %s\n" (format_pace distance moving_time);

  if avg_hr > 0 then begin
    Printf.printf "❤️  Avg HR:        %d bpm\n" avg_hr;
    Printf.printf "💓 Max HR:        %d bpm\n" max_hr;
  end;

  if avg_watts > 0 then
    Printf.printf "⚡ Avg power:     %d W\n" avg_watts;

  print_newline ()

(* Pretty print gears (bikes and shoes) *)
let print_gears json =
  let bikes = try json |> member "bikes" |> to_list with _ -> [] in
  let shoes = try json |> member "shoes" |> to_list with _ -> [] in
  let all_gears = bikes @ shoes in

  if List.length all_gears > 0 then begin
    Printf.printf "\n🛠️  Gear\n";
    Printf.printf "=====\n\n";

    let headers = ["ID"; "TYPE"; "NAME"; "DISTANCE"; "PRIMARY"; "RETIRED"] in
    let rows = List.map (fun gear ->
      let id = try gear |> member "id" |> to_string with _ -> "-" in
      let name = try gear |> member "name" |> to_string with _ -> "-" in
      let distance = try gear |> member "converted_distance" |> to_float with _ -> 0.0 in
      let primary = try gear |> member "primary" |> to_bool with _ -> false in
      let retired = try gear |> member "retired" |> to_bool with _ -> false in
      let gear_type = if String.length id > 0 && id.[0] = 'b' then "🚴 Bike" else "👟 Shoe" in
      [
        id;
        gear_type;
        (if String.length name > 30 then String.sub name 0 27 ^ "..." else name);
        Printf.sprintf "%.1f km" distance;
        if primary then "Yes" else "No";
        if retired then "Yes" else "No";
      ]
    ) all_gears in
    print_table headers rows;
    print_newline ()
  end

(* Pretty print athlete *)
let print_athlete json =
  let get_string key = try json |> member key |> to_string with _ -> "-" in
  let get_float key = try json |> member key |> to_float with _ -> 0.0 in

  let firstname = get_string "firstname" in
  let lastname = get_string "lastname" in
  let city = get_string "city" in
  let country = get_string "country" in
  let weight = get_float "weight" in
  let created = get_string "created_at" in

  Printf.printf "\n👤 Athlete Profile\n";
  Printf.printf "==================\n\n";
  Printf.printf "Name:     %s %s\n" firstname lastname;
  Printf.printf "Location: %s, %s\n" city country;
  if weight > 0.0 then
    Printf.printf "Weight:   %.1f kg\n" weight;
  Printf.printf "Member since: %s\n" (format_date created);

  print_gears json

(* Pretty print athlete stats *)
let print_stats json =
  let print_totals title totals =
    let count = totals |> member "count" |> to_int in
    (* distance can be int or float depending on the totals type *)
    let distance =
      try totals |> member "distance" |> to_int |> float_of_int
      with _ -> totals |> member "distance" |> to_float
    in
    (* moving_time can be int or float depending on the totals type *)
    let moving_time =
      try totals |> member "moving_time" |> to_int
      with _ -> totals |> member "moving_time" |> to_float |> int_of_float
    in
    (* elevation_gain can be int or float *)
    let elevation =
      try totals |> member "elevation_gain" |> to_int |> float_of_int
      with _ -> totals |> member "elevation_gain" |> to_float
    in

    if count > 0 then begin
      Printf.printf "\n%s\n" title;
      Printf.printf "%s\n" (String.make (String.length title) '-');
      Printf.printf "Activities:  %d\n" count;
      Printf.printf "Distance:    %s\n" (format_distance distance);
      Printf.printf "Moving time: %s\n" (format_duration moving_time);
      Printf.printf "Elevation:   %.0f m\n" elevation;
    end
  in

  Printf.printf "\n📊 Athlete Statistics\n";
  Printf.printf "=====================\n";

  (* YTD (Year to Date) *)
  (try
    let ytd_run = json |> member "ytd_run_totals" in
    print_totals "🏃 YTD Runs" ytd_run
  with _ -> ());

  (try
    let ytd_ride = json |> member "ytd_ride_totals" in
    print_totals "🚴 YTD Rides" ytd_ride
  with _ -> ());

  (try
    let ytd_swim = json |> member "ytd_swim_totals" in
    print_totals "🏊 YTD Swims" ytd_swim
  with _ -> ());

  (* Recent (4 weeks) *)
  (try
    let recent_run = json |> member "recent_run_totals" in
    print_totals "🏃 Recent Runs (4 weeks)" recent_run
  with _ -> ());

  (try
    let recent_ride = json |> member "recent_ride_totals" in
    print_totals "🚴 Recent Rides (4 weeks)" recent_ride
  with _ -> ());

  (try
    let recent_swim = json |> member "recent_swim_totals" in
    print_totals "🏊 Recent Swims (4 weeks)" recent_swim
  with _ -> ());

  (* All Time *)
  (try
    let all_run = json |> member "all_run_totals" in
    print_totals "🏃 All Time Runs" all_run
  with _ -> ());

  (try
    let all_ride = json |> member "all_ride_totals" in
    print_totals "🚴 All Time Rides" all_ride
  with _ -> ());

  (try
    let all_swim = json |> member "all_swim_totals" in
    print_totals "🏊 All Time Swims" all_swim
  with _ -> ());

  print_newline ()

(* Pretty print segments *)
let print_segments json =
  let segments = json |> to_list in
  let headers = ["ID"; "NAME"; "DISTANCE"; "AVG GRADE"; "ELEV"; "CITY"] in
  let rows = List.map (fun seg ->
    let id = seg |> member "id" |> to_int |> string_of_int in
    let name = seg |> member "name" |> to_string in
    let name_truncated = if String.length name > 30 then String.sub name 0 27 ^ "..." else name in
    let distance = seg |> member "distance" |> to_float in
    let grade = try seg |> member "average_grade" |> to_float with _ -> 0.0 in
    let elev = try seg |> member "elevation_high" |> to_float with _ -> 0.0 in
    let city = try seg |> member "city" |> to_string with _ -> "-" in
    [
      id;
      name_truncated;
      format_distance distance;
      Printf.sprintf "%.1f%%" grade;
      Printf.sprintf "%.0f m" elev;
      city;
    ]
  ) segments in
  print_table headers rows

(* Pretty print routes *)
let print_routes json =
  let routes = json |> to_list in
  let headers = ["ID"; "NAME"; "DISTANCE"; "ELEV GAIN"; "TYPE"] in
  let rows = List.map (fun route ->
    let id = route |> member "id" |> to_int |> string_of_int in
    let name = route |> member "name" |> to_string in
    let name_truncated = if String.length name > 30 then String.sub name 0 27 ^ "..." else name in
    let distance = route |> member "distance" |> to_float in
    let elev = try route |> member "elevation_gain" |> to_float with _ -> 0.0 in
    let sport = try route |> member "type" |> to_string with _ -> "-" in
    [
      id;
      name_truncated;
      format_distance distance;
      Printf.sprintf "%.0f m" elev;
      sport_emoji sport ^ " " ^ sport;
    ]
  ) routes in
  print_table headers rows

(* Pretty print single gear *)
let print_gear json =
  let get_string key = try json |> member key |> to_string with _ -> "-" in
  let get_float key = try json |> member key |> to_float with _ -> 0.0 in
  let get_bool key = try json |> member key |> to_bool with _ -> false in

  let id = get_string "id" in
  let name = get_string "name" in
  let brand = get_string "brand_name" in
  let model = get_string "model_name" in
  let distance = get_float "converted_distance" in
  let primary = get_bool "primary" in
  let retired = get_bool "retired" in
  let notification_distance = get_float "notification_distance" in
  let description = get_string "description" in

  let gear_type = if String.length id > 0 && id.[0] = 'b' then "🚴 Bike" else "👟 Shoe" in
  let emoji = if String.length id > 0 && id.[0] = 'b' then "🚴" else "👟" in

  Printf.printf "\n%s %s\n" emoji name;
  Printf.printf "%s\n\n" (String.make (String.length name + 3) '=');

  Printf.printf "🆔 ID:            %s\n" id;
  Printf.printf "🏷️  Type:          %s\n" gear_type;
  Printf.printf "🏭 Brand:         %s\n" brand;
  Printf.printf "📦 Model:         %s\n" model;
  Printf.printf "📏 Distance:      %.1f km\n" distance;
  if primary then
    Printf.printf "⭐ Primary:       Yes\n";
  if retired then
    Printf.printf "🚫 Retired:       Yes\n";
  if notification_distance > 0.0 then
    Printf.printf "🔔 Alert at:      %.0f km\n" notification_distance;
  if description <> "-" then
    Printf.printf "📝 Description:   %s\n" description;

  print_newline ()
