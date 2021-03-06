(*  Title:      HOL/Word/Tools/smt_word.ML
    Author:     Sascha Boehme, TU Muenchen

SMT setup for words.
*)

structure SMT_Word: sig end =
struct

open Word_Lib


(* SMT-LIB logic *)

(* "QF_AUFBV" is too restrictive for Isabelle's problems, which contain aritmetic and quantifiers.
   Better set the logic to "" and make at least Z3 happy. *)
fun smtlib_logic ts =
  if exists (Term.exists_type (Term.exists_subtype is_wordT)) ts then SOME "" else NONE


(* SMT-LIB builtins *)

local
  val smtlibC = SMTLIB_Interface.smtlibC

  val wordT = @{typ "'a::len word"}

  fun index1 s i = "(_ " ^ s ^ " " ^ string_of_int i ^ ")"
  fun index2 s i j = "(_ " ^ s ^ " " ^ string_of_int i ^ " " ^ string_of_int j ^ ")"

  fun word_typ (Type (@{type_name word}, [T])) = Option.map (index1 "BitVec") (try dest_binT T)
    | word_typ _ = NONE

  fun word_num (Type (@{type_name word}, [T])) k =
        Option.map (index1 ("bv" ^ string_of_int k)) (try dest_binT T)
    | word_num _ _ = NONE

  fun if_fixed pred m n T ts =
    let val (Us, U) = Term.strip_type T
    in
      if pred (U, Us) then SOME (n, length Us, ts, Term.list_comb o pair (Const (m, T))) else NONE
    end

  fun if_fixed_all m = if_fixed (forall (can dest_wordT) o (op ::)) m
  fun if_fixed_args m = if_fixed (forall (can dest_wordT) o snd) m

  fun add_word_fun f (t, n) =
    let val (m, _) = Term.dest_Const t
    in SMT_Builtin.add_builtin_fun smtlibC (Term.dest_Const t, K (f m n)) end

  val mk_nat = HOLogic.mk_number @{typ nat}

  fun mk_shift c [t, u] = Const c $ t $ mk_nat (snd (HOLogic.dest_number u))
    | mk_shift c ts = raise TERM ("bad arguments", Const c :: ts)

  fun shift m n T ts =
    let val U = Term.domain_type T
    in
      (case (can dest_wordT U, try (snd o HOLogic.dest_number o hd o tl) ts) of
        (true, SOME i) =>
          SOME (n, 2, [hd ts, HOLogic.mk_number U i], mk_shift (m, T))
      | _ => NONE)   (* FIXME: also support non-numerical shifts *)
    end

  fun mk_extract c i ts = Term.list_comb (Const c, mk_nat i :: ts)

  fun extract m n T ts =
    let val U = Term.range_type (Term.range_type T)
    in
      (case (try (snd o HOLogic.dest_number o hd) ts, try dest_wordT U) of
        (SOME lb, SOME i) =>
          SOME (index2 n (i + lb - 1) lb, 1, tl ts, mk_extract (m, T) lb)
      | _ => NONE)
    end

  fun mk_extend c ts = Term.list_comb (Const c, ts)

  fun extend m n T ts =
    let val (U1, U2) = Term.dest_funT T
    in
      (case (try dest_wordT U1, try dest_wordT U2) of
        (SOME i, SOME j) =>
          if j-i >= 0 then SOME (index1 n (j-i), 1, ts, mk_extend (m, T))
          else NONE
      | _ => NONE)
    end

  fun mk_rotate c i ts = Term.list_comb (Const c, mk_nat i :: ts)

  fun rotate m n T ts =
    let val U = Term.domain_type (Term.range_type T)
    in
      (case (can dest_wordT U, try (snd o HOLogic.dest_number o hd) ts) of
        (true, SOME i) => SOME (index1 n i, 1, tl ts, mk_rotate (m, T) i)
      | _ => NONE)
    end
in

val setup_builtins =
  SMT_Builtin.add_builtin_typ smtlibC (wordT, word_typ, word_num) #>
  fold (add_word_fun if_fixed_all) [
    (@{term "uminus :: 'a::len word \<Rightarrow> _"}, "bvneg"),
    (@{term "plus :: 'a::len word \<Rightarrow> _"}, "bvadd"),
    (@{term "minus :: 'a::len word \<Rightarrow> _"}, "bvsub"),
    (@{term "times :: 'a::len word \<Rightarrow> _"}, "bvmul"),
    (@{term "bitNOT :: 'a::len word \<Rightarrow> _"}, "bvnot"),
    (@{term "bitAND :: 'a::len word \<Rightarrow> _"}, "bvand"),
    (@{term "bitOR :: 'a::len word \<Rightarrow> _"}, "bvor"),
    (@{term "bitXOR :: 'a::len word \<Rightarrow> _"}, "bvxor"),
    (@{term "word_cat :: 'a::len word \<Rightarrow> _"}, "concat") ] #>
  fold (add_word_fun shift) [
    (@{term "shiftl :: 'a::len word \<Rightarrow> _ "}, "bvshl"),
    (@{term "shiftr :: 'a::len word \<Rightarrow> _"}, "bvlshr"),
    (@{term "sshiftr :: 'a::len word \<Rightarrow> _"}, "bvashr") ] #>
  add_word_fun extract
    (@{term "slice :: _ \<Rightarrow> 'a::len word \<Rightarrow> _"}, "extract") #>
  fold (add_word_fun extend) [
    (@{term "ucast :: 'a::len word \<Rightarrow> _"}, "zero_extend"),
    (@{term "scast :: 'a::len word \<Rightarrow> _"}, "sign_extend") ] #>
  fold (add_word_fun rotate) [
    (@{term word_rotl}, "rotate_left"),
    (@{term word_rotr}, "rotate_right") ] #>
  fold (add_word_fun if_fixed_args) [
    (@{term "less :: 'a::len word \<Rightarrow> _"}, "bvult"),
    (@{term "less_eq :: 'a::len word \<Rightarrow> _"}, "bvule"),
    (@{term word_sless}, "bvslt"),
    (@{term word_sle}, "bvsle") ]

end


(* setup *)

val _ = Theory.setup (Context.theory_map (
  SMTLIB_Interface.add_logic (20, smtlib_logic) #>
  setup_builtins))

end;
