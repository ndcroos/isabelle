(*
  Author:     Jeremy Dawson and Gerwin Klein, NICTA

  Consequences of type definition theorems, and of extended type definition.
*)

section \<open>Type Definition Theorems\<close>

theory Misc_Typedef
imports Main
begin

section "More lemmas about normal type definitions"

lemma
  tdD1: "type_definition Rep Abs A \<Longrightarrow> \<forall>x. Rep x \<in> A" and
  tdD2: "type_definition Rep Abs A \<Longrightarrow> \<forall>x. Abs (Rep x) = x" and
  tdD3: "type_definition Rep Abs A \<Longrightarrow> \<forall>y. y \<in> A \<longrightarrow> Rep (Abs y) = y"
  by (auto simp: type_definition_def)

lemma td_nat_int:
  "type_definition int nat (Collect (op <= 0))"
  unfolding type_definition_def by auto

context type_definition
begin

declare Rep [iff] Rep_inverse [simp] Rep_inject [simp]

lemma Abs_eqD: "Abs x = Abs y ==> x \<in> A ==> y \<in> A ==> x = y"
  by (simp add: Abs_inject)

lemma Abs_inverse':
  "r : A ==> Abs r = a ==> Rep a = r"
  by (safe elim!: Abs_inverse)

lemma Rep_comp_inverse:
  "Rep \<circ> f = g ==> Abs \<circ> g = f"
  using Rep_inverse by auto

lemma Rep_eqD [elim!]: "Rep x = Rep y ==> x = y"
  by simp

lemma Rep_inverse': "Rep a = r ==> Abs r = a"
  by (safe intro!: Rep_inverse)

lemma comp_Abs_inverse:
  "f \<circ> Abs = g ==> g \<circ> Rep = f"
  using Rep_inverse by auto

lemma set_Rep:
  "A = range Rep"
proof (rule set_eqI)
  fix x
  show "(x \<in> A) = (x \<in> range Rep)"
    by (auto dest: Abs_inverse [of x, symmetric])
qed

lemma set_Rep_Abs: "A = range (Rep \<circ> Abs)"
proof (rule set_eqI)
  fix x
  show "(x \<in> A) = (x \<in> range (Rep \<circ> Abs))"
    by (auto dest: Abs_inverse [of x, symmetric])
qed

lemma Abs_inj_on: "inj_on Abs A"
  unfolding inj_on_def
  by (auto dest: Abs_inject [THEN iffD1])

lemma image: "Abs ` A = UNIV"
  by (auto intro!: image_eqI)

lemmas td_thm = type_definition_axioms

lemma fns1:
  "Rep \<circ> fa = fr \<circ> Rep | fa \<circ> Abs = Abs \<circ> fr ==> Abs \<circ> fr \<circ> Rep = fa"
  by (auto dest: Rep_comp_inverse elim: comp_Abs_inverse simp: o_assoc)

lemmas fns1a = disjI1 [THEN fns1]
lemmas fns1b = disjI2 [THEN fns1]

lemma fns4:
  "Rep \<circ> fa \<circ> Abs = fr ==>
   Rep \<circ> fa = fr \<circ> Rep & fa \<circ> Abs = Abs \<circ> fr"
  by auto

end

interpretation nat_int: type_definition int nat "Collect (op <= 0)"
  by (rule td_nat_int)

declare
  nat_int.Rep_cases [cases del]
  nat_int.Abs_cases [cases del]
  nat_int.Rep_induct [induct del]
  nat_int.Abs_induct [induct del]


subsection "Extended form of type definition predicate"

lemma td_conds:
  "norm \<circ> norm = norm ==> (fr \<circ> norm = norm \<circ> fr) =
    (norm \<circ> fr \<circ> norm = fr \<circ> norm & norm \<circ> fr \<circ> norm = norm \<circ> fr)"
  apply safe
    apply (simp_all add: comp_assoc)
   apply (simp_all add: o_assoc)
  done

lemma fn_comm_power:
  "fa \<circ> tr = tr \<circ> fr ==> fa ^^ n \<circ> tr = tr \<circ> fr ^^ n"
  apply (rule ext)
  apply (induct n)
   apply (auto dest: fun_cong)
  done

lemmas fn_comm_power' =
  ext [THEN fn_comm_power, THEN fun_cong, unfolded o_def]


locale td_ext = type_definition +
  fixes norm
  assumes eq_norm: "\<And>x. Rep (Abs x) = norm x"
begin

lemma Abs_norm [simp]:
  "Abs (norm x) = Abs x"
  using eq_norm [of x] by (auto elim: Rep_inverse')

lemma td_th:
  "g \<circ> Abs = f ==> f (Rep x) = g x"
  by (drule comp_Abs_inverse [symmetric]) simp

lemma eq_norm': "Rep \<circ> Abs = norm"
  by (auto simp: eq_norm)

lemma norm_Rep [simp]: "norm (Rep x) = Rep x"
  by (auto simp: eq_norm' intro: td_th)

lemmas td = td_thm

lemma set_iff_norm: "w : A \<longleftrightarrow> w = norm w"
  by (auto simp: set_Rep_Abs eq_norm' eq_norm [symmetric])

lemma inverse_norm:
  "(Abs n = w) = (Rep w = norm n)"
  apply (rule iffI)
   apply (clarsimp simp add: eq_norm)
  apply (simp add: eq_norm' [symmetric])
  done

lemma norm_eq_iff:
  "(norm x = norm y) = (Abs x = Abs y)"
  by (simp add: eq_norm' [symmetric])

lemma norm_comps:
  "Abs \<circ> norm = Abs"
  "norm \<circ> Rep = Rep"
  "norm \<circ> norm = norm"
  by (auto simp: eq_norm' [symmetric] o_def)

lemmas norm_norm [simp] = norm_comps

lemma fns5:
  "Rep \<circ> fa \<circ> Abs = fr ==>
  fr \<circ> norm = fr & norm \<circ> fr = fr"
  by (fold eq_norm') auto

(* following give conditions for converses to td_fns1
  the condition (norm \<circ> fr \<circ> norm = fr \<circ> norm) says that
  fr takes normalised arguments to normalised results,
  (norm \<circ> fr \<circ> norm = norm \<circ> fr) says that fr
  takes norm-equivalent arguments to norm-equivalent results,
  (fr \<circ> norm = fr) says that fr
  takes norm-equivalent arguments to the same result, and
  (norm \<circ> fr = fr) says that fr takes any argument to a normalised result
  *)
lemma fns2:
  "Abs \<circ> fr \<circ> Rep = fa ==>
   (norm \<circ> fr \<circ> norm = fr \<circ> norm) = (Rep \<circ> fa = fr \<circ> Rep)"
  apply (fold eq_norm')
  apply safe
   prefer 2
   apply (simp add: o_assoc)
  apply (rule ext)
  apply (drule_tac x="Rep x" in fun_cong)
  apply auto
  done

lemma fns3:
  "Abs \<circ> fr \<circ> Rep = fa ==>
   (norm \<circ> fr \<circ> norm = norm \<circ> fr) = (fa \<circ> Abs = Abs \<circ> fr)"
  apply (fold eq_norm')
  apply safe
   prefer 2
   apply (simp add: comp_assoc)
  apply (rule ext)
  apply (drule_tac f="a \<circ> b" for a b in fun_cong)
  apply simp
  done

lemma fns:
  "fr \<circ> norm = norm \<circ> fr ==>
    (fa \<circ> Abs = Abs \<circ> fr) = (Rep \<circ> fa = fr \<circ> Rep)"
  apply safe
   apply (frule fns1b)
   prefer 2
   apply (frule fns1a)
   apply (rule fns3 [THEN iffD1])
     prefer 3
     apply (rule fns2 [THEN iffD1])
       apply (simp_all add: comp_assoc)
   apply (simp_all add: o_assoc)
  done

lemma range_norm:
  "range (Rep \<circ> Abs) = A"
  by (simp add: set_Rep_Abs)

end

lemmas td_ext_def' =
  td_ext_def [unfolded type_definition_def td_ext_axioms_def]

end

