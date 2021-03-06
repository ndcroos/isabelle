(*  Title:      HOL/Number_Theory/Totient.thy
    Author:     Jeremy Avigad
    Author:     Florian Haftmann
    Author:     Manuel Eberl
*)

section \<open>Fundamental facts about Euler's totient function\<close>

theory Totient
imports
  Complex_Main
  "~~/src/HOL/Computational_Algebra/Primes"
  "~~/src/HOL/Number_Theory/Cong"
begin
  
definition totatives :: "nat \<Rightarrow> nat set" where
  "totatives n = {k \<in> {0<..n}. coprime k n}"
  
lemma in_totatives_iff: "k \<in> totatives n \<longleftrightarrow> k > 0 \<and> k \<le> n \<and> coprime k n"
  by (simp add: totatives_def)
  
lemma totatives_code [code]: "totatives n = Set.filter (\<lambda>k. coprime k n) {0<..n}"
  by (simp add: totatives_def Set.filter_def)
  
lemma finite_totatives [simp]: "finite (totatives n)"
  by (simp add: totatives_def)
    
lemma totatives_subset: "totatives n \<subseteq> {0<..n}"
  by (auto simp: totatives_def)
    
lemma zero_not_in_totatives [simp]: "0 \<notin> totatives n"
  by (auto simp: totatives_def)
    
lemma totatives_le: "x \<in> totatives n \<Longrightarrow> x \<le> n"
  by (auto simp: totatives_def)
    
lemma totatives_less: 
  assumes "x \<in> totatives n" "n > 1"
  shows   "x < n"
proof -
  from assms have "x \<noteq> n" by (auto simp: totatives_def)
  with totatives_le[OF assms(1)] show ?thesis by simp
qed

lemma totatives_0 [simp]: "totatives 0 = {}"
  by (auto simp: totatives_def)

lemma totatives_1 [simp]: "totatives 1 = {Suc 0}"
  by (auto simp: totatives_def)

lemma totatives_Suc_0 [simp]: "totatives (Suc 0) = {Suc 0}"
  by (auto simp: totatives_def)

lemma one_in_totatives [simp]: "n > 0 \<Longrightarrow> Suc 0 \<in> totatives n"
  by (auto simp: totatives_def)

lemma totatives_eq_empty_iff [simp]: "totatives n = {} \<longleftrightarrow> n = 0"
  using one_in_totatives[of n] by (auto simp del: one_in_totatives)
    
lemma minus_one_in_totatives:
  assumes "n \<ge> 2"
  shows "n - 1 \<in> totatives n"
  using assms coprime_minus_one_nat [of n] by (simp add: in_totatives_iff)

lemma totatives_prime_power_Suc:
  assumes "prime p"
  shows   "totatives (p ^ Suc n) = {0<..p^Suc n} - (\<lambda>m. p * m) ` {0<..p^n}"
proof safe
  fix m assume m: "p * m \<in> totatives (p ^ Suc n)" and m: "m \<in> {0<..p^n}"
  thus False using assms by (auto simp: totatives_def gcd_mult_left)
next
  fix k assume k: "k \<in> {0<..p^Suc n}" "k \<notin> (\<lambda>m. p * m) ` {0<..p^n}"
  from k have "\<not>(p dvd k)" by (auto elim!: dvdE)
  hence "coprime k (p ^ Suc n)"
    using prime_imp_coprime[OF assms, of k] by (intro coprime_exp) (simp_all add: gcd.commute)
  with k show "k \<in> totatives (p ^ Suc n)" by (simp add: totatives_def)
qed (auto simp: totatives_def)

lemma totatives_prime: "prime p \<Longrightarrow> totatives p = {0<..<p}"
  using totatives_prime_power_Suc[of p 0] by fastforce

lemma bij_betw_totatives:
  assumes "m1 > 1" "m2 > 1" "coprime m1 m2"
  shows   "bij_betw (\<lambda>x. (x mod m1, x mod m2)) (totatives (m1 * m2)) 
             (totatives m1 \<times> totatives m2)"
  unfolding bij_betw_def
proof
  show "inj_on (\<lambda>x. (x mod m1, x mod m2)) (totatives (m1 * m2))"
  proof (intro inj_onI, clarify)
    fix x y assume xy: "x \<in> totatives (m1 * m2)" "y \<in> totatives (m1 * m2)"
                       "x mod m1 = y mod m1" "x mod m2 = y mod m2"
    have ex: "\<exists>!z. z < m1 * m2 \<and> [z = x] (mod m1) \<and> [z = x] (mod m2)"
      by (rule binary_chinese_remainder_unique_nat) (insert assms, simp_all)
    have "x < m1 * m2 \<and> [x = x] (mod m1) \<and> [x = x] (mod m2)"
         "y < m1 * m2 \<and> [y = x] (mod m1) \<and> [y = x] (mod m2)"
      using xy assms by (simp_all add: totatives_less one_less_mult cong_nat_def)
    from this[THEN the1_equality[OF ex]] show "x = y" by simp
  qed
next
  show "(\<lambda>x. (x mod m1, x mod m2)) ` totatives (m1 * m2) = totatives m1 \<times> totatives m2"
  proof safe
    fix x assume "x \<in> totatives (m1 * m2)"
    with assms show "x mod m1 \<in> totatives m1" "x mod m2 \<in> totatives m2"
      by (auto simp: totatives_def coprime_mul_eq not_le simp del: One_nat_def intro!: Nat.gr0I)
  next
    fix a b assume ab: "a \<in> totatives m1" "b \<in> totatives m2"
    with assms have ab': "a < m1" "b < m2" by (auto simp: totatives_less)
    with binary_chinese_remainder_unique_nat[OF assms(3), of a b] obtain x
      where x: "x < m1 * m2" "x mod m1 = a" "x mod m2 = b" by (auto simp: cong_nat_def)
    from x ab assms(3) have "x \<in> totatives (m1 * m2)"
      by (auto simp: totatives_def coprime_mul_eq simp del: One_nat_def intro!: Nat.gr0I)
    with x show "(a, b) \<in> (\<lambda>x. (x mod m1, x mod m2)) ` totatives (m1*m2)" by blast
  qed
qed

lemma bij_betw_totatives_gcd_eq:
  fixes n d :: nat
  assumes "d dvd n" "n > 0"
  shows   "bij_betw (\<lambda>k. k * d) (totatives (n div d)) {k\<in>{0<..n}. gcd k n = d}"
  unfolding bij_betw_def
proof
  show "inj_on (\<lambda>k. k * d) (totatives (n div d))"
    by (auto simp: inj_on_def)
next
  show "(\<lambda>k. k * d) ` totatives (n div d) = {k\<in>{0<..n}. gcd k n = d}"
  proof (intro equalityI subsetI, goal_cases)
    case (1 k)
    thus ?case using assms
      by (auto elim!: dvdE simp: inj_on_def totatives_def mult.commute[of d]
                                 gcd_mult_right gcd.commute)
  next
    case (2 k)
    hence "d dvd k" by auto
    then obtain l where k: "k = l * d" by (elim dvdE) auto
    from 2 and assms show ?case unfolding k
      by (intro imageI) (auto simp: totatives_def gcd.commute mult.commute[of d] 
                                    gcd_mult_right elim!: dvdE)
  qed
qed



definition totient :: "nat \<Rightarrow> nat" where
  "totient n = card (totatives n)"
  
primrec totient_naive :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> nat" where
  "totient_naive 0 acc n = acc"
| "totient_naive (Suc k) acc n =
     (if coprime (Suc k) n then totient_naive k (acc + 1) n else totient_naive k acc n)"
  
lemma totient_naive:
  "totient_naive k acc n = card {x \<in> {0<..k}. coprime x n} + acc"
proof (induction k arbitrary: acc)
  case (Suc k acc)
  have "totient_naive (Suc k) acc n = 
          (if coprime (Suc k) n then 1 else 0) + card {x \<in> {0<..k}. coprime x n} + acc"
    using Suc by simp
  also have "(if coprime (Suc k) n then 1 else 0) = 
               card (if coprime (Suc k) n then {Suc k} else {})" by auto
  also have "\<dots> + card {x \<in> {0<..k}. coprime x n} =
               card ((if coprime (Suc k) n then {Suc k} else {}) \<union> {x \<in> {0<..k}. coprime x n})"
    by (intro card_Un_disjoint [symmetric]) auto
  also have "((if coprime (Suc k) n then {Suc k} else {}) \<union> {x \<in> {0<..k}. coprime x n}) =
               {x \<in> {0<..Suc k}. coprime x n}" by (auto elim: le_SucE)
  finally show ?case .
qed simp_all
  
lemma totient_code_naive [code]: "totient n = totient_naive n 0 n"
  by (subst totient_naive) (simp add: totient_def totatives_def)

lemma totient_le: "totient n \<le> n"
proof -
  have "card (totatives n) \<le> card {0<..n}"
    by (intro card_mono) (auto simp: totatives_def)
  thus ?thesis by (simp add: totient_def)
qed
  
lemma totient_less: 
  assumes "n > 1"
  shows   "totient n < n"
proof -
  from assms have "card (totatives n) \<le> card {0<..<n}"
    using totatives_less[of _ n] totatives_subset[of n] by (intro card_mono) auto
  with assms show ?thesis by (simp add: totient_def)
qed    

lemma totient_0 [simp]: "totient 0 = 0"
  by (simp add: totient_def)

lemma totient_Suc_0 [simp]: "totient (Suc 0) = Suc 0"
  by (simp add: totient_def)

lemma totient_1 [simp]: "totient 1 = Suc 0"
  by simp

lemma totient_0_iff [simp]: "totient n = 0 \<longleftrightarrow> n = 0"
  by (auto simp: totient_def)

lemma totient_gt_0_iff [simp]: "totient n > 0 \<longleftrightarrow> n > 0"
  by (auto intro: Nat.gr0I)

lemma card_gcd_eq_totient:
  "n > 0 \<Longrightarrow> d dvd n \<Longrightarrow> card {k\<in>{0<..n}. gcd k n = d} = totient (n div d)"
  unfolding totient_def by (rule sym, rule bij_betw_same_card[OF bij_betw_totatives_gcd_eq])
  
lemma totient_divisor_sum: "(\<Sum>d | d dvd n. totient d) = n"
proof (cases "n = 0")
  case False
  hence "n > 0" by simp
  define A where "A = (\<lambda>d. {k\<in>{0<..n}. gcd k n = d})"
  have *: "card (A d) = totient (n div d)" if d: "d dvd n" for d
    using \<open>n > 0\<close> and d unfolding A_def by (rule card_gcd_eq_totient)  
  have "n = card {1..n}" by simp
  also have "{1..n} = (\<Union>d\<in>{d. d dvd n}. A d)" by safe (auto simp: A_def)
  also have "card \<dots> = (\<Sum>d | d dvd n. card (A d))"
    using \<open>n > 0\<close> by (intro card_UN_disjoint) (auto simp: A_def)
  also have "\<dots> = (\<Sum>d | d dvd n. totient (n div d))" by (intro sum.cong refl *) auto
  also have "\<dots> = (\<Sum>d | d dvd n. totient d)" using \<open>n > 0\<close>
    by (intro sum.reindex_bij_witness[of _ "op div n" "op div n"]) (auto elim: dvdE)
  finally show ?thesis ..
qed auto

lemma totient_mult_coprime:
  assumes "coprime m n"
  shows   "totient (m * n) = totient m * totient n"
proof (cases "m > 1 \<and> n > 1")
  case True
  hence mn: "m > 1" "n > 1" by simp_all
  have "totient (m * n) = card (totatives (m * n))" by (simp add: totient_def)
  also have "\<dots> = card (totatives m \<times> totatives n)"
    using bij_betw_totatives [OF mn \<open>coprime m n\<close>] by (rule bij_betw_same_card)
  also have "\<dots> = totient m * totient n" by (simp add: totient_def)
  finally show ?thesis .
next
  case False
  with assms show ?thesis by (cases m; cases n) auto
qed

lemma totient_prime_power_Suc:
  assumes "prime p"
  shows   "totient (p ^ Suc n) = p ^ n * (p - 1)"
proof -
  from assms have "totient (p ^ Suc n) = card ({0<..p ^ Suc n} - op * p ` {0<..p ^ n})"
    unfolding totient_def by (subst totatives_prime_power_Suc) simp_all
  also from assms have "\<dots> = p ^ Suc n - card (op * p ` {0<..p^n})"
    by (subst card_Diff_subset) (auto intro: prime_gt_0_nat)
  also from assms have "card (op * p ` {0<..p^n}) = p ^ n"
    by (subst card_image) (auto simp: inj_on_def)
  also have "p ^ Suc n - p ^ n = p ^ n * (p - 1)" by (simp add: algebra_simps)
  finally show ?thesis .
qed

lemma totient_prime_power:
  assumes "prime p" "n > 0"
  shows   "totient (p ^ n) = p ^ (n - 1) * (p - 1)"
  using totient_prime_power_Suc[of p "n - 1"] assms by simp

lemma totient_imp_prime:
  assumes "totient p = p - 1" "p > 0"
  shows   "prime p"
proof (cases "p = 1")
  case True
  with assms show ?thesis by auto
next
  case False
  with assms have p: "p > 1" by simp
  have "x \<in> {0<..<p}" if "x \<in> totatives p" for x
    using that and p by (cases "x = p") (auto simp: totatives_def)
  with assms have *: "totatives p = {0<..<p}"
    by (intro card_subset_eq) (auto simp: totient_def)
  have **: False if "x \<noteq> 1" "x \<noteq> p" "x dvd p" for x
  proof -
    from that have nz: "x \<noteq> 0" by (auto intro!: Nat.gr0I)
    from that and p have le: "x \<le> p" by (intro dvd_imp_le) auto
    from that and nz have "\<not>coprime x p" by auto
    hence "x \<notin> totatives p" by (simp add: totatives_def)
    also note *
    finally show False using that and le by auto
  qed
  hence "(\<forall>m. m dvd p \<longrightarrow> m = 1 \<or> m = p)" by blast
  with p show ?thesis by (subst prime_nat_iff) (auto dest: **)
qed
    
lemma totient_prime:
  assumes "prime p"
  shows   "totient p = p - 1"
  using totient_prime_power_Suc[of p 0] assms by simp

lemma totient_2 [simp]: "totient 2 = 1"
  and totient_3 [simp]: "totient 3 = 2"
  and totient_5 [simp]: "totient 5 = 4"
  and totient_7 [simp]: "totient 7 = 6"
  by (subst totient_prime; simp)+
    
lemma totient_4 [simp]: "totient 4 = 2"
  and totient_8 [simp]: "totient 8 = 4"
  and totient_9 [simp]: "totient 9 = 6"
  using totient_prime_power[of 2 2] totient_prime_power[of 2 3] totient_prime_power[of 3 2] 
  by simp_all
    
lemma totient_6 [simp]: "totient 6 = 2"
  using totient_mult_coprime[of 2 3] by (simp add: gcd_non_0_nat)    

lemma totient_even:
  assumes "n > 2"
  shows   "even (totient n)"
proof (cases "\<exists>p. prime p \<and> p \<noteq> 2 \<and> p dvd n")
  case True
  then obtain p where p: "prime p" "p \<noteq> 2" "p dvd n" by auto
  from \<open>p \<noteq> 2\<close> have "p = 0 \<or> p = 1 \<or> p > 2" by auto
  with p(1) have "odd p" using prime_odd_nat[of p] by auto
  define k where "k = multiplicity p n"
  from p assms have k_pos: "k > 0" unfolding k_def by (subst multiplicity_gt_zero_iff) auto
  have "p ^ k dvd n" unfolding k_def by (simp add: multiplicity_dvd)
  then obtain m where m: "n = p ^ k * m" by (elim dvdE)
  with assms have m_pos: "m > 0" by (auto intro!: Nat.gr0I)
  from k_def m_pos p have "\<not>p dvd m"
    by (subst (asm) m) (auto intro!: Nat.gr0I simp: prime_elem_multiplicity_mult_distrib 
                          prime_elem_multiplicity_eq_zero_iff)
  hence "coprime (p ^ k) m" by (intro coprime_exp_left prime_imp_coprime[OF p(1)])
  thus ?thesis using p k_pos \<open>odd p\<close> 
    by (auto simp add: m totient_mult_coprime totient_prime_power)
next
  case False
  from assms have "n = (\<Prod>p\<in>prime_factors n. p ^ multiplicity p n)"
    by (intro Primes.prime_factorization_nat) auto
  also from False have "\<dots> = (\<Prod>p\<in>prime_factors n. if p = 2 then 2 ^ multiplicity 2 n else 1)"
    by (intro prod.cong refl) auto
  also have "\<dots> = 2 ^ multiplicity 2 n" 
    by (subst prod.delta[OF finite_set_mset]) (auto simp: prime_factors_multiplicity)
  finally have n: "n = 2 ^ multiplicity 2 n" .
  have "multiplicity 2 n = 0 \<or> multiplicity 2 n = 1 \<or> multiplicity 2 n > 1" by force
  with n assms have "multiplicity 2 n > 1" by auto
  thus ?thesis by (subst n) (simp add: totient_prime_power)
qed

lemma totient_prod_coprime:
  assumes "pairwise_coprime (f ` A)" "inj_on f A"
  shows   "totient (prod f A) = prod (\<lambda>x. totient (f x)) A"
  using assms
proof (induction A rule: infinite_finite_induct)
  case (insert x A)
  from insert.prems and insert.hyps have *: "coprime (prod f A) (f x)"
    by (intro prod_coprime[OF pairwise_coprimeD[OF insert.prems(1)]]) (auto simp: inj_on_def)
  from insert.hyps have "prod f (insert x A) = prod f A * f x" by simp
  also have "totient \<dots> = totient (prod f A) * totient (f x)"
    using insert.hyps insert.prems by (intro totient_mult_coprime *)
  also have "totient (prod f A) = (\<Prod>x\<in>A. totient (f x))" 
    using insert.prems by (intro insert.IH) (auto dest: pairwise_coprime_subset)
  also from insert.hyps have "\<dots> * totient (f x) = (\<Prod>x\<in>insert x A. totient (f x))" by simp
  finally show ?case .
qed simp_all

(* TODO Move *)
lemma prime_power_eq_imp_eq:
  fixes p q :: "'a :: factorial_semiring"
  assumes "prime p" "prime q" "m > 0"
  assumes "p ^ m = q ^ n"
  shows   "p = q"
proof (rule ccontr)
  assume pq: "p \<noteq> q"
  from assms have "m = multiplicity p (p ^ m)" 
    by (subst multiplicity_prime_power) auto
  also note \<open>p ^ m = q ^ n\<close>
  also from assms pq have "multiplicity p (q ^ n) = 0"
    by (subst multiplicity_distinct_prime_power) auto
  finally show False using \<open>m > 0\<close> by simp
qed

lemma totient_formula1:
  assumes "n > 0"
  shows   "totient n = (\<Prod>p\<in>prime_factors n. p ^ (multiplicity p n - 1) * (p - 1))"
proof -
  from assms have "n = (\<Prod>p\<in>prime_factors n. p ^ multiplicity p n)"
    by (rule prime_factorization_nat)
  also have "totient \<dots> = (\<Prod>x\<in>prime_factors n. totient (x ^ multiplicity x n))"
  proof (rule totient_prod_coprime)
    show "pairwise_coprime ((\<lambda>p. p ^ multiplicity p n) ` prime_factors n)"
    proof (standard, clarify, goal_cases)
      fix p q assume "p \<in># prime_factorization n" "q \<in># prime_factorization n" 
                     "p ^ multiplicity p n \<noteq> q ^ multiplicity q n"
      thus "coprime (p ^ multiplicity p n) (q ^ multiplicity q n)"
        by (intro coprime_exp2 primes_coprime[of p q]) auto
    qed
  next
    show "inj_on (\<lambda>p. p ^ multiplicity p n) (prime_factors n)"
    proof
      fix p q assume pq: "p \<in># prime_factorization n" "q \<in># prime_factorization n" 
                         "p ^ multiplicity p n = q ^ multiplicity q n"
      from assms and pq have "prime p" "prime q" "multiplicity p n > 0" 
        by (simp_all add: prime_factors_multiplicity)
      from prime_power_eq_imp_eq[OF this pq(3)] show "p = q" .
    qed
  qed
  also have "\<dots> = (\<Prod>p\<in>prime_factors n. p ^ (multiplicity p n - 1) * (p - 1))"
    by (intro prod.cong refl totient_prime_power) (auto simp: prime_factors_multiplicity)
  finally show ?thesis .
qed

lemma totient_dvd:
  assumes "m dvd n"
  shows   "totient m dvd totient n"
proof (cases "m = 0 \<or> n = 0")
  case False
  let ?M = "\<lambda>p m :: nat. multiplicity p m - 1"
  have "(\<Prod>p\<in>prime_factors m. p ^ ?M p m * (p - 1)) dvd
          (\<Prod>p\<in>prime_factors n. p ^ ?M p n * (p - 1))" using assms False
    by (intro prod_dvd_prod_subset2 mult_dvd_mono dvd_refl le_imp_power_dvd diff_le_mono
              dvd_prime_factors dvd_imp_multiplicity_le) auto
  with False show ?thesis by (simp add: totient_formula1)
qed (insert assms, auto)
  
lemma totient_dvd_mono:
  assumes "m dvd n" "n > 0"
  shows   "totient m \<le> totient n"
  by (cases "m = 0") (insert assms, auto intro: dvd_imp_le totient_dvd)

(* TODO Move *)
lemma prime_factors_power: "n > 0 \<Longrightarrow> prime_factors (x ^ n) = prime_factors x"
  by (cases "x = 0"; cases "n = 0")
     (auto simp: prime_factors_multiplicity prime_elem_multiplicity_power_distrib zero_power)

lemma totient_formula2:
  "real (totient n) = real n * (\<Prod>p\<in>prime_factors n. 1 - 1 / real p)"
proof (cases "n = 0")
  case False
  have "real (totient n) = (\<Prod>p\<in>prime_factors n. real
          (p ^ (multiplicity p n - 1) * (p - 1)))" 
    using False by (subst totient_formula1) simp_all
  also have "\<dots> = (\<Prod>p\<in>prime_factors n. real (p ^ multiplicity p n) * (1 - 1 / real p))"
    by (intro prod.cong refl) (auto simp add: field_simps prime_factors_multiplicity 
          prime_ge_Suc_0_nat of_nat_diff power_Suc [symmetric] simp del: power_Suc)
  also have "\<dots> = real (\<Prod>p\<in>prime_factors n. p ^ multiplicity p n) * 
                    (\<Prod>p\<in>prime_factors n. 1 - 1 / real p)" by (subst prod.distrib) auto
  also have "(\<Prod>p\<in>prime_factors n. p ^ multiplicity p n) = n"
    using False by (intro Primes.prime_factorization_nat [symmetric]) auto
  finally show ?thesis .
qed auto

lemma totient_gcd: "totient (a * b) * totient (gcd a b) = totient a * totient b * gcd a b"
proof (cases "a = 0 \<or> b = 0")
  case False
  let ?P = "prime_factors :: nat \<Rightarrow> nat set"
  have "real (totient a * totient b * gcd a b) = real (a * b * gcd a b) *
          ((\<Prod>p\<in>?P a. 1 - 1 / real p) * (\<Prod>p\<in>?P b. 1 - 1 / real p))"
    by (simp add: totient_formula2)
  also have "?P a = (?P a - ?P b) \<union> (?P a \<inter> ?P b)" by auto
  also have "(\<Prod>p\<in>\<dots>. 1 - 1 / real p) = 
                 (\<Prod>p\<in>?P a - ?P b. 1 - 1 / real p) * (\<Prod>p\<in>?P a \<inter> ?P b. 1 - 1 / real p)"
    by (rule prod.union_disjoint) blast+
  also have "\<dots> * (\<Prod>p\<in>?P b. 1 - 1 / real p) = (\<Prod>p\<in>?P a - ?P b. 1 - 1 / real p) * 
               (\<Prod>p\<in>?P b. 1 - 1 / real p) * (\<Prod>p\<in>?P a \<inter> ?P b. 1 - 1 / real p)" (is "_ = ?A * _")
    by (simp only: mult_ac)
  also have "?A = (\<Prod>p\<in>?P a - ?P b \<union> ?P b. 1 - 1 / real p)"
    by (rule prod.union_disjoint [symmetric]) blast+
  also have "?P a - ?P b \<union> ?P b = ?P a \<union> ?P b" by blast
  also have "real (a * b * gcd a b) * ((\<Prod>p\<in>\<dots>. 1 - 1 / real p) * 
                 (\<Prod>p\<in>?P a \<inter> ?P b. 1 - 1 / real p)) = real (totient (a * b) * totient (gcd a b))"
    using False by (simp add: totient_formula2 prime_factors_product prime_factorization_gcd)
  finally show ?thesis by (simp only: of_nat_eq_iff)
qed auto
  
lemma totient_mult: "totient (a * b) = totient a * totient b * gcd a b div totient (gcd a b)"
  by (subst totient_gcd [symmetric]) simp

lemma of_nat_eq_1_iff: "of_nat x = (1 :: 'a :: {semiring_1, semiring_char_0}) \<longleftrightarrow> x = 1"
  using of_nat_eq_iff[of x 1] by (simp del: of_nat_eq_iff)

(* TODO Move *)
lemma gcd_2_odd:
  assumes "odd (n::nat)"
  shows   "gcd n 2 = 1"
proof -
  from assms obtain k where n: "n = Suc (2 * k)" by (auto elim!: oddE)
  have "coprime (Suc (2 * k)) (2 * k)" by (rule coprime_Suc_nat)
  thus ?thesis using n by (subst (asm) coprime_mul_eq) simp_all
qed

lemma totient_double: "totient (2 * n) = (if even n then 2 * totient n else totient n)"
  by (subst totient_mult) (auto simp: gcd.commute[of 2] gcd_2_odd)

lemma totient_power_Suc: "totient (n ^ Suc m) = n ^ m * totient n"
proof (induction m arbitrary: n)
  case (Suc m n)
  have "totient (n ^ Suc (Suc m)) = totient (n * n ^ Suc m)" by simp
  also have "\<dots> = n ^ Suc m * totient n"
    using Suc.IH by (subst totient_mult) simp
  finally show ?case .
qed simp_all
  
lemma totient_power: "m > 0 \<Longrightarrow> totient (n ^ m) = n ^ (m - 1) * totient n"
  using totient_power_Suc[of n "m - 1"] by (cases m) simp_all

lemma totient_gcd_lcm: "totient (gcd a b) * totient (lcm a b) = totient a * totient b"
proof (cases "a = 0 \<or> b = 0")
  case False
  let ?P = "prime_factors :: nat \<Rightarrow> nat set" and ?f = "\<lambda>p::nat. 1 - 1 / real p"
  have "real (totient (gcd a b) * totient (lcm a b)) = real (gcd a b * lcm a b) * 
          (prod ?f (?P a \<inter> ?P b) * prod ?f (?P a \<union> ?P b))"
    using False unfolding of_nat_mult 
    by (simp add: totient_formula2 prime_factorization_gcd prime_factorization_lcm)
  also have "gcd a b * lcm a b = a * b" by simp
  also have "?P a \<union> ?P b = (?P a - ?P a \<inter> ?P b) \<union> ?P b" by blast
  also have "prod ?f \<dots> = prod ?f (?P a - ?P a \<inter> ?P b) * prod ?f (?P b)"
    by (rule prod.union_disjoint) blast+
  also have "prod ?f (?P a \<inter> ?P b) * \<dots> = 
               prod ?f (?P a \<inter> ?P b \<union> (?P a - ?P a \<inter> ?P b)) * prod ?f (?P b)"
    by (subst prod.union_disjoint) auto
  also have "?P a \<inter> ?P b \<union> (?P a - ?P a \<inter> ?P b) = ?P a" by blast
  also have "real (a * b) * (prod ?f (?P a) * prod ?f (?P b)) = real (totient a * totient b)"
    using False by (simp add: totient_formula2)
  finally show ?thesis by (simp only: of_nat_eq_iff)
qed auto    

end
