(*  Title:      HOL/Real/HahnBanach/Aux.thy
    ID:         $Id$
    Author:     Gertrud Bauer, TU Munich
*)

header {* Auxiliary theorems *}

theory Aux = Real + Zorn:

text {* Some existing theorems are declared as extra introduction
or elimination rules, respectively. *}

lemmas [intro??] = isLub_isUb
lemmas [intro??] = chainD 
lemmas chainE2 = chainD2 [elimify]

text_raw {* \medskip *}
text{* Lemmas about sets. *}

lemma Int_singletonD: "[| A Int B = {v}; x:A; x:B |] ==> x = v"
  by (fast elim: equalityE)

lemma set_less_imp_diff_not_empty: "H < E ==> EX x0:E. x0 ~: H"
 by (force simp add: psubset_eq)

text_raw {* \medskip *}
text{* Some lemmas about orders. *}

lemma lt_imp_not_eq: "x < (y::'a::order) ==> x ~= y" 
  by (rule order_less_le[RS iffD1, RS conjunct2])

lemma le_noteq_imp_less: 
  "[| x <= (r::'a::order); x ~= r |] ==> x < r"
proof -
  assume "x <= (r::'a::order)" and ne:"x ~= r"
  hence "x < r | x = r" by (simp add: order_le_less)
  with ne show ?thesis by simp
qed

text_raw {* \medskip *}
text {* Some lemmas about linear orders. *}

theorem linorder_linear_split: 
"[| x < a ==> Q; x = a ==> Q; a < (x::'a::linorder) ==> Q |] ==> Q"
  by (rule linorder_less_linear [of x a, elimify]) force+

lemma le_max1: "x <= max x (y::'a::linorder)"
  by (simp add: le_max_iff_disj[of x x y])

lemma le_max2: "y <= max x (y::'a::linorder)" 
  by (simp add: le_max_iff_disj[of y x y])

text_raw {* \medskip *}
text{* Some lemmas for the reals. *}

lemma real_add_minus_eq: "x - y = (#0::real) ==> x = y"
  by simp

lemma abs_minus_one: "abs (- (#1::real)) = #1" 
  by simp


lemma real_mult_le_le_mono1a: 
  "[| (#0::real) <= z; x <= y |] ==> z * x  <= z * y"
proof -
  assume "(#0::real) <= z" "x <= y"
  hence "x < y | x = y" by (force simp add: order_le_less)
  thus ?thesis
  proof (elim disjE) 
   assume "x < y" show ?thesis by (rule real_mult_le_less_mono2) simp
  next 
   assume "x = y" thus ?thesis by simp
  qed
qed

lemma real_mult_le_le_mono2: 
  "[| (#0::real) <= z; x <= y |] ==> x * z <= y * z"
proof -
  assume "(#0::real) <= z" "x <= y"
  hence "x < y | x = y" by (force simp add: order_le_less)
  thus ?thesis
  proof (elim disjE) 
   assume "x < y" show ?thesis by (rule real_mult_le_less_mono1) simp
  next 
   assume "x = y" thus ?thesis by simp
  qed
qed

lemma real_mult_less_le_anti: 
  "[| z < (#0::real); x <= y |] ==> z * y <= z * x"
proof -
  assume "z < #0" "x <= y"
  hence "#0 < - z" by simp
  hence "#0 <= - z" by (rule real_less_imp_le)
  hence "x * (- z) <= y * (- z)" 
    by (rule real_mult_le_le_mono2)
  hence  "- (x * z) <= - (y * z)" 
    by (simp only: real_minus_mult_eq2)
  thus ?thesis by (simp only: real_mult_commute)
qed

lemma real_mult_less_le_mono: 
  "[| (#0::real) < z; x <= y |] ==> z * x <= z * y"
proof - 
  assume "#0 < z" "x <= y"
  have "#0 <= z" by (rule real_less_imp_le)
  hence "x * z <= y * z" 
    by (rule real_mult_le_le_mono2)
  thus ?thesis by (simp only: real_mult_commute)
qed

lemma real_rinv_gt_zero1: "#0 < x ==> #0 < rinv x"
proof - 
  assume "#0 < x"
  hence "0r < x" by simp
  hence "0r < rinv x" by (rule real_rinv_gt_zero)
  thus ?thesis by simp
qed

lemma real_mult_inv_right1: "x ~= #0 ==> x*rinv(x) = #1"
   by simp

lemma real_mult_inv_left1: "x ~= #0 ==> rinv(x)*x = #1"
   by simp

lemma real_le_mult_order1a: 
      "[| (#0::real) <= x; #0 <= y |] ==> #0 <= x * y"
proof -
  assume "#0 <= x" "#0 <= y"
    have "[|0r <= x; 0r <= y|] ==> 0r <= x * y"  
      by (rule real_le_mult_order)
    thus ?thesis by (simp!)
qed

lemma real_mult_diff_distrib: 
  "a * (- x - (y::real)) = - a * x - a * y"
proof -
  have "- x - y = - x + - y" by simp
  also have "a * ... = a * - x + a * - y" 
    by (simp only: real_add_mult_distrib2)
  also have "... = - a * x - a * y" 
    by (simp add: real_minus_mult_eq2 [RS sym] real_minus_mult_eq1)
  finally show ?thesis .
qed

lemma real_mult_diff_distrib2: "a * (x - (y::real)) = a * x - a * y"
proof - 
  have "x - y = x + - y" by simp
  also have "a * ... = a * x + a * - y" 
    by (simp only: real_add_mult_distrib2)
  also have "... = a * x - a * y"   
    by (simp add: real_minus_mult_eq2 [RS sym] real_minus_mult_eq1)
  finally show ?thesis .
qed

lemma real_minus_le: "- (x::real) <= y ==> - y <= x"
  by simp

lemma real_diff_ineq_swap: 
  "(d::real) - b <= c + a ==> - a - b <= c - d"
  by simp

end