(**
  * loggers.mli
  *
  * a module for KaSim
  * Jérôme Feret, projet Antique, INRIA Paris
  *
  * KaSim
  * Jean Krivine, Université Paris-Diderot, CNRS
  *
  * Creation: 26/01/2016
  * Last modification: 25/05/2016
  * *
  *
  *
  * Copyright 2016  Institut National de Recherche en Informatique et
  * en Automatique.  All rights reserved.  This file is distributed
  * under the terms of the GNU Library General Public License *)

type encoding =
  | HTML_Graph | HTML | HTML_Tabular | DOT | TXT | TXT_Tabular | XLS
type t

val refresh_id: t -> unit
val get_encoding_format: t -> encoding
val fprintf: t -> ('a, Format.formatter, unit) format -> 'a
val print_newline: t -> unit
val print_cell: t -> string -> unit
val print_as_logger: t -> (Format.formatter -> unit) -> unit
val flush_logger: t -> unit
val close_logger: t -> unit
val open_infinite_buffer: ?mode:encoding -> unit -> t
val open_circular_buffer: ?mode:encoding -> ?size:int -> unit -> t
val open_logger_from_formatter: ?mode:encoding -> Format.formatter -> t
val open_logger_from_channel: ?mode:encoding -> out_channel -> t
val open_row: t -> unit
val close_row: t -> unit
val print_breakable_space: t -> unit
val dummy_txt_logger: t
val dummy_html_logger: t
val redirect: t -> Format.formatter -> t
val formatter_of_logger: t -> Format.formatter option
val flush_buffer: t -> Format.formatter -> unit
val int_of_string_id: t -> string -> int
