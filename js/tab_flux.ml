module ApiTypes = ApiTypes_j
module Html5 = Tyxml_js.Html5
open ApiTypes
module UIState = Ui_state

let div_axis_select_id  = "plot-axis-select"
let display_id = "flux-map-display"
let export_id = "flux-export"
let svg_id = "fluxmap-svg"
let select_id = "select"

let rules_checkboxes_id = "rules-checkboxes"
let checkbox_self_influence_id = "checkbox_self_influence"

let state_fluxmap
    (state : ApiTypes.state option) : ApiTypes.flux_map list =
  match state with
  | None -> []
  | Some state -> state.ApiTypes.flux_maps
let serialize_json : (string -> unit) ref = ref (fun _ -> ())

let configuration : Widget_export.configuration =
  { Widget_export.id = export_id
  ; Widget_export.handlers =
      [ Widget_export.export_svg
        ~svg_div_id:display_id ()
      ; Widget_export.export_png
        ~svg_div_id:display_id ()
      ; { Widget_export.suffix = "json"
        ; Widget_export.label = "json"
        ; Widget_export.export =
          (fun filename -> (!serialize_json) filename)
        }
      ];
    show = React.S.map
           (fun state ->
             match state_fluxmap state with
             | [] -> false
             | _ -> true
           )
           UIState.model_runtime_state
  }

let content =
  let flux_select =
    Tyxml_js.R.Html5.select
      ~a:[ Html5.a_class ["form-control"]
         ; Html5.a_id select_id ]
      (let flux_list, flux_handle = ReactiveData.RList.create [] in
       let _ = React.S.map
         (fun state ->
           ReactiveData.RList.set
             flux_handle
             (List.mapi (fun i flux -> Html5.option
               ~a:[ Html5.a_value (string_of_int i) ]
               (Html5.pcdata
                  (Display_common.option_label flux.ApiTypes.flux_name)))
                (state_fluxmap state)
             )
         )
         UIState.model_runtime_state in
       flux_list
      )
  in
  let flux_label =
    Tyxml_js.R.Html5.li
      ~a:[ Html5.a_class ["list-group-item"] ]
      (let flux_list, flux_handle = ReactiveData.RList.create [] in
       let _ = React.S.map
         (fun state ->
           ReactiveData.RList.set
             flux_handle
             (match state_fluxmap state with
               head::[] -> [Html5.h4
                               [ Html5.pcdata
                                   (Display_common.option_label
                                      head.ApiTypes.flux_name)]]
             | _ -> [flux_select]
             )
         )
         UIState.model_runtime_state
       in
       flux_list
      )
  in
  let checkbox =
    Html5.input ~a:[ Html5.a_id "checkbox_self_influence"
                   ; Html5.a_class ["checkbox-control"]
                   ; Html5.a_input_type `Checkbox ] () in
  let export_controls =
    Widget_export.content configuration
  in
  <:html5<<div>
          <div class="row">
               <div class="center-block display-header">
                Dynamic influence map between t = <span id="begin_time"/>s
                and t = <span id="end_time"/>s (<span id="nb_events"/>events)
               </div>
             </div>

             <div class="row">
                <div id="control" class="col-sm-4">
                <ul class="list-group">
                   $flux_label$
                   <li class="list-group-item">
                      <h4 class="list-group-item-heading">Rules</h4>
                      <button class="btn,btn-default"
                              id="toggle_rule_selection">
                      Toggle selected rules
                      </button>
                      <p id="rules-checkboxes"></p>
                   </li>
                   <li class="list-group-item">
                    <div class="input-group">
                      <label class="checkbox-control">
                         $checkbox$
                         Self influence
                      </label>
                    </div>
                   </li>
                   <li class="list-group-item">
                    <div class="input-group">
                      <p>Correction
                      <select class="form-control"
                              id="select_correction">
                           <option value="none">None</option>
                           <option value="hits">Occurences</option>
                           <option value="time">Time</option>
                      </select>
                      </p>
                    </div>
                   </li>
                </ul>
             </div>
          <div id=$str:display_id$ class="col-sm-8"></div>
          </div>
          $export_controls$
     </div> >>

let navcontent =
  [ Html5.div
      ~a:[Tyxml_js.R.Html5.a_class
             (React.S.bind
                UIState.model_runtime_state
                (fun state -> React.S.const
                  (match state_fluxmap state with
                    [] -> ["hidden"]
                  | _::_ -> ["show"])
                )
             )]
      [content]
  ]
let update_flux_map
    (flux_js : Js_flux.flux_map Js.t)
    (flux_data : ApiTypes.flux_map) : unit =
  let flux_data : Js_flux.flux_data Js.t =
    Js_flux.create_data ~flux_begin_time:flux_data.flux_begin_time
      ~flux_end_time:flux_data.flux_end_time
      ~flux_rules:flux_data.flux_rules
      ~flux_hits:flux_data.flux_hits
      ~flux_fluxs:flux_data.flux_fluxs
  in
  flux_js##setFlux(flux_data)

let select_fluxmap flux_map =
  let index = Js.Opt.bind
    (Display_common.document##getElementById (Js.string select_id))
    (fun dom -> let select_dom : Dom_html.inputElement Js.t =
                  Js.Unsafe.coerce dom in
                let fileindex = Js.to_string (select_dom##value) in
                try Js.some (int_of_string fileindex) with
                  _ -> Js.null
    )
  in
  match (React.S.value UIState.model_runtime_state) with
    None -> ()
  | Some state -> let index = Js.Opt.get index (fun _ -> 0) in
                  if List.length state.ApiTypes.flux_maps > 0 then
                    update_flux_map
                      flux_map
                      (List.nth state.ApiTypes.flux_maps index)
                  else
                    ()

let navli = Display_common.badge (fun state -> List.length (state_fluxmap state))

let onload () =
  let () = Widget_export.onload configuration in
  let flux_configuration : Js_flux.flux_configuration Js.t =
    Js_flux.create_configuration
      ~short_labels:true
      ~begin_time_id:("begin_time")
      ~end_time_id:("end_time")
      ~select_correction_id:("select_correction")
      ~checkbox_self_influence_id:("checkbox_self_influence")
      ~toggle_rules_id:("toggle_rule_selection")
      ~nb_events_id:("nb_events")
      ~svg_id:svg_id
      ~rules_checkboxes_id:rules_checkboxes_id
      ~height:450
      ~width:360
  in
  let flux =
    Js_flux.create_flux_map flux_configuration in
  let () = serialize_json :=
    (fun f -> let filename = Js.string f in
              flux##exportJSON(filename))
  in
  let select_dom : Dom_html.inputElement Js.t =
    Js.Unsafe.coerce
      ((Js.Opt.get
          (Display_common.document##getElementById
             (Js.string select_id))
          (fun () -> assert false))
          : Dom_html.element Js.t) in
  let () = select_dom##onchange <- Dom_html.handler
    (fun _ ->
      let () = select_fluxmap flux
      in Js._true)
  in
  let div : Dom_html.element Js.t =
    Js.Opt.get
      (Display_common.document##getElementById
         (Js.string display_id))
      (fun () -> assert false) in
  let () = div##innerHTML <- Js.string
    ("<svg id=\""^
        svg_id^
        "\" width=\"300\" height=\"300\"><g/></svg>") in
  let () = Common.jquery_on "#navflux"
    "shown.bs.tab"
    (fun _ -> select_fluxmap flux)
  in
  select_fluxmap flux
