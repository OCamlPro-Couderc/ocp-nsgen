open Config
open Cmo_format
open Cmx_format

let units : (string * string list) list ref = ref []
let print = ref false
let prefix = ref ""

let args = [
  "-list", Arg.Set print, "List all the available units";
  "-prefix", Arg.String ((:=) prefix), "Removes the given prefix of aliases";
]

let usage =
  "ocp-nsgen <option(s)> <cm(x)a file(s)>\n\
   Generate aliases wrapper on the standard output from OCaml libraries (.cma \
   or .cmxa).\n"

let read_cma f =
  let obj = open_in f in
  let len = String.length cma_magic_number in
  let magic_number = really_input_string obj len in
  if magic_number <> cma_magic_number then failwith "Not a correct cma file";
  let toc_pos = input_binary_int obj in
  seek_in obj toc_pos;
  let cmo = (input_value obj : library) in
  close_in obj;
  cmo

let read_cmxa f =
  let obj = open_in f in
  let len = String.length cmxa_magic_number in
  let magic_number = really_input_string obj len in
  if magic_number <> cmxa_magic_number then failwith "Not a correct cmxa file";
  let li = (input_value obj : library_infos) in
  close_in obj;
  li

let list_units f =
  if Filename.check_suffix f ".cma" then
    let cma = read_cma f in
    List.map (fun cu -> cu.cu_name) cma.lib_units
  else if Filename.check_suffix f ".cmxa" then
    let cmxa = read_cmxa f in
    List.map (fun (ui, _) -> ui.ui_name) cmxa.lib_units
  else
    failwith "Not a library"

let remove_prefix unit pre =
  let len_unit = String.length unit in
  let len_pre = String.length pre in
  (* >= :---> Avoid the case where the unit has the exact same name *)
  if len_pre >= len_unit || len_pre = 0 then unit
  else try
      for i = 0 to len_pre-1 do
        if not (String.get unit i = String.get pre i) then raise Not_found
      done;
      String.sub unit len_pre (len_unit - len_pre) |> String.capitalize
    with Not_found -> unit

let gen_struct (f, l) =
  let open Parsetree in
  f, List.map (fun (alias, md) ->
      let modexpr = {
        pmod_desc = Pmod_ident (Location.mknoloc (Longident.Lident md));
        pmod_loc = Location.none;
        pmod_attributes = []
      } in
      let modbind = {
        pmb_name = Location.mknoloc alias;
        pmb_expr = modexpr;
        pmb_attributes = [];
        pmb_loc = Location.none;
      } in
      {
        pstr_desc = Pstr_module modbind;
        pstr_loc = Location.none
      }) l

let gen_structs l =
  List.map gen_struct l

let print_units () =
  Format.printf "@[";
  List.iter (fun (f, un) ->
      Format.printf "%s:\n" f;
    List.iter (Format.printf "@[%s@] ") un) !units;
  Format.printf "@]\n%!"

let _ =
  Arg.parse args
    (fun f -> units := (f, list_units f) :: !units)
    usage;
  if !print then print_units ();
  let units = List.map (fun (f, units) ->
      f, List.map (fun unit ->
          (remove_prefix unit !prefix, unit)) units)
    !units in (* TODO: Rename using prefix *)
  let gen = gen_structs units in
  List.iter (fun (f, strc) ->
      Format.printf "@[(* Autogenerated from \"%s\" *)@]\n%a\n%!"
        (Filename.basename f) Pprintast.structure strc) gen
