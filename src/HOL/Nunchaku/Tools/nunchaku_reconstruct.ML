(*  Title:      HOL/Nunchaku/Tools/nunchaku_reconstruct.ML
    Author:     Jasmin Blanchette, Inria Nancy, LORIA, MPII
    Copyright   2015, 2016

Reconstruction of Nunchaku models in Isabelle/HOL.
*)

signature NUNCHAKU_RECONSTRUCT =
sig
  type nun_model = Nunchaku_Model.nun_model

  type typ_entry = typ * term list
  type term_entry = term * term

  type isa_model =
    {type_model: typ_entry list,
     free_model: term_entry list,
     pat_complete_model: term_entry list,
     pat_incomplete_model: term_entry list,
     skolem_model: term_entry list}

  val str_of_isa_model: Proof.context -> isa_model -> string

  val isa_model_of_nun: Proof.context -> term list -> (typ option * string list) list ->
    nun_model -> isa_model
end;

structure Nunchaku_Reconstruct : NUNCHAKU_RECONSTRUCT =
struct

open Nunchaku_Util;
open Nunchaku_Problem;
open Nunchaku_Translate;
open Nunchaku_Model;

type typ_entry = typ * term list;
type term_entry = term * term;

type isa_model =
  {type_model: typ_entry list,
   free_model: term_entry list,
   pat_complete_model: term_entry list,
   pat_incomplete_model: term_entry list,
   skolem_model: term_entry list};

val anonymousN = "anonymous";
val irrelevantN = "irrelevant";
val unparsableN = "unparsable";

val nun_arrow_exploded = String.explode nun_arrow;

val is_ty_meta = member (op =) (String.explode "()->,");

fun next_token_lowlevel [] = (End_of_Stream, [])
  | next_token_lowlevel (c :: cs) =
    if Char.isSpace c then
      next_token_lowlevel cs
    else if not (is_ty_meta c) then
      let val n = find_index (Char.isSpace orf is_ty_meta) cs in
        (if n = ~1 then (cs, []) else chop n cs)
        |>> (cons c #> String.implode #> ident_of_str #> Ident)
      end
    else if is_prefix (op =) nun_arrow_exploded (c :: cs) then
      (Ident nun_arrow, tl cs)
    else
      (Symbol (String.str c), cs);

val tokenize_lowlevel =
  let
    fun toks cs =
      (case next_token_lowlevel cs of
        (End_of_Stream, []) => []
      | (tok, cs') => tok :: toks cs');
  in
    toks o String.explode
  end;

fun parse_lowlevel_ty tok =
  (Scan.optional
     (parse_sym "(" |-- Scan.repeat (parse_lowlevel_ty --| Scan.option (parse_sym ",")) --|
      parse_sym ")")
     []
   -- parse_ident >> (swap #> NType)) tok;

val ty_of_lowlevel_str = fst o parse_lowlevel_ty o tokenize_lowlevel;

fun ident_of_const (NConst (id, _, _)) = id
  | ident_of_const _ = nun_dummy;

fun str_of_typ_entry ctxt (T, ts) =
  "type " ^ Syntax.string_of_typ ctxt T  ^
  " := {" ^ commas (map (Syntax.string_of_term ctxt) ts) ^ "}.";

fun str_of_term_entry ctxt (tm, value) =
  "val " ^ Syntax.string_of_term ctxt tm ^ " := " ^ Syntax.string_of_term ctxt value ^ ".";

fun str_of_isa_model ctxt
    {type_model, free_model, pat_complete_model, pat_incomplete_model, skolem_model} =
  map (str_of_typ_entry ctxt) type_model @ "" ::
  map (str_of_term_entry ctxt) free_model @ "" ::
  map (str_of_term_entry ctxt) pat_complete_model @ "" ::
  map (str_of_term_entry ctxt) pat_incomplete_model @ "" ::
  map (str_of_term_entry ctxt) skolem_model
  |> cat_lines;

fun typ_of_nun ctxt =
  let
    fun typ_of (NType (id, tys)) =
      let val Ts = map typ_of tys in
        if id = nun_dummy then
          dummyT
        else if id = nun_prop then
          @{typ bool}
        else if id = nun_arrow then
          Type (@{type_name fun}, Ts)
        else
          (case try str_of_nun_tconst id of
            SOME (args, s) =>
            let val tys' = map ty_of_lowlevel_str args in
              Type (s, map typ_of (tys' @ tys))
            end
          | NONE =>
            (case try str_of_nun_tfree id of
              SOME s => TFree (Proof_Context.check_tfree ctxt (flip_quote s, dummyS))
            | NONE => raise Fail ("unknown type constructor: " ^ quote (str_of_ident id))))
      end;
  in
    typ_of
  end;

fun one_letter_of s =
  let val c = String.sub (Long_Name.base_name s, 0) in
    String.str (if Char.isAlpha c then c else #"x")
  end;

fun base_of_typ (Type (s, _)) = s
  | base_of_typ (TFree (s, _)) = flip_quote s
  | base_of_typ (TVar ((s, _), _)) = flip_quote s;

fun term_of_nun ctxt atomss =
  let
    val thy = Proof_Context.theory_of ctxt;

    val typ_of = typ_of_nun ctxt;

    fun nth_atom T j =
      let val ss = these (triple_lookup (typ_match thy) atomss T) in
        if j >= 0 andalso j < length ss then nth ss j
        else one_letter_of (base_of_typ T) ^ nat_subscript (j + 1)
      end;

    fun term_of _ (NAtom (j, ty)) =
        let val T = typ_of ty in Var ((nth_atom T j, 0), T) end
      | term_of bounds (NConst (id, tys0, ty)) =
        if id = nun_conj then
          HOLogic.conj
        else if id = nun_disj then
          HOLogic.disj
        else if id = nun_choice then
          Const (@{const_name Eps}, typ_of ty)
        else if id = nun_equals then
          Const (@{const_name HOL.eq}, typ_of ty)
        else if id = nun_false then
          @{const False}
        else if id = nun_if then
          Const (@{const_name If}, typ_of ty)
        else if id = nun_implies then
          @{term implies}
        else if id = nun_unique then
          Const (@{const_name The}, typ_of ty)
        else if id = nun_unique_unsafe then
          Const (@{const_name The_unsafe}, typ_of ty)
        else if id = nun_true then
          @{const True}
        else if String.isPrefix nun_anon_fun_prefix id then
          let val j = Int.fromString (unprefix nun_anon_fun_prefix id) |> the_default ~1 in
            Var ((anonymousN ^ nat_subscript (j + 1), 0), typ_of ty)
          end
        else if id = nun_irrelevant then
          (* FIXME: get bounds from Nunchaku *)
          list_comb (Var ((irrelevantN, 0), map (typ_of o safe_ty_of) bounds ---> typ_of ty),
            map Bound (length bounds - 1 downto 0))
        else if id = nun_unparsable then
          (* FIXME: get bounds from Nunchaku *)
          list_comb (Var ((unparsableN, 0), typ_of ty), map Bound (length bounds - 1 downto 0))
        else
          (case try str_of_nun_const id of
            SOME (args, s) =>
            let val tys = map ty_of_lowlevel_str args in
              Sign.mk_const thy (s, map typ_of (tys @ tys0))
            end
          | NONE =>
            (case try str_of_nun_free id of
              SOME s => Free (s, typ_of ty)
            | NONE =>
              (case try str_of_nun_var id of
                SOME s => Var ((s, 0), typ_of ty)
              | NONE =>
                (case find_index (fn bound => ident_of_const bound = id) bounds of
                  ~1 => Var ((str_of_ident id, 0), typ_of ty) (* shouldn't happen? *)
                | j => Bound j))))
      | term_of bounds (NAbs (var, body)) =
        let val T = typ_of (safe_ty_of var) in
          Abs (one_letter_of (base_of_typ T), T, term_of (var :: bounds) body)
        end
      | term_of bounds (NApp (func, arg)) =
        let
          fun same () = term_of bounds func $ term_of bounds arg;
        in
          (case (func, arg) of
            (NConst (id, _, _), NAbs _) =>
            if id = nun_mu then
              let val Abs (s, T, body) = term_of bounds arg in
                Const (@{const_name The}, (T --> HOLogic.boolT) --> T)
                $ Abs (s, T, HOLogic.eq_const T $ Bound 0 $ body)
              end
            else
              same ()
          | _ => same ())
        end
      | term_of _ (NMatch _) = raise Fail "unexpected match";
  in
    term_of []
  end;

fun isa_typ_entry_of_nun ctxt atomss (ty, atoms) =
  (typ_of_nun ctxt ty, map (term_of_nun ctxt atomss) atoms);

fun isa_term_entry_of_nun ctxt atomss (tm, value) =
  (term_of_nun ctxt atomss tm, term_of_nun ctxt atomss value);

fun isa_model_of_nun ctxt pat_completes atomss {type_model, const_model, skolem_model} =
  let
    val free_and_const_model = map (isa_term_entry_of_nun ctxt atomss) const_model;
    val (free_model, (pat_complete_model, pat_incomplete_model)) =
      List.partition (is_Free o fst) free_and_const_model
      ||> List.partition (member (op aconv) pat_completes o fst);
  in
    {type_model = map (isa_typ_entry_of_nun ctxt atomss) type_model, free_model = free_model,
     pat_complete_model = pat_complete_model, pat_incomplete_model = pat_incomplete_model,
     skolem_model = map (isa_term_entry_of_nun ctxt atomss) skolem_model}
  end;

end;
