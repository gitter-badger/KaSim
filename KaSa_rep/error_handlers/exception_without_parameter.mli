    (**
    * exception.ml
    * openkappa
    * Jérôme Feret, projet Abstraction, INRIA Paris-Rocquencourt
    *
    * Creation: 08/03/2010
    * Last modification: 05/02/2015
    * *
    * This library declares exceptions
    *
    * Copyright 2010 Institut National de Recherche en Informatique et
    * en Automatique.  All rights reserved.  This file is distributed
    *  under the terms of the GNU Library General Public License *)


type uncaught_exception
exception Uncaught_exception of uncaught_exception

type caught_exception
exception Caught_exception of caught_exception

type method_handler

val raise_exception: string option -> unit -> string option -> exn -> unit
val build_uncaught_exception: string option -> string option -> exn -> uncaught_exception
val build_caught_exception: string option -> string option -> exn -> string list -> caught_exception
val add_uncaught_error: uncaught_exception -> method_handler -> method_handler
val stringlist_of_exception: exn -> string list -> string list
val stringlist_of_uncaught: uncaught_exception -> string list -> string list
val stringlist_of_caught: caught_exception -> string list -> string list
val stringlist_of_caught_light: caught_exception -> string list -> string list


val empty_error_handler: method_handler
val get_caught_exception_list: method_handler -> caught_exception list
val get_uncaught_exception_list: method_handler -> uncaught_exception list
(*val handle_errors: method_handler -> unit -> unit -> unit -> unit * method_handler*)