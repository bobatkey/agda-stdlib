------------------------------------------------------------------------
-- Some Vec-related properties
------------------------------------------------------------------------

{-# OPTIONS --universe-polymorphism #-}

module Data.Vec.Properties where

open import Algebra
open import Data.Vec
open import Data.Nat
import Data.Nat.Properties as Nat
open import Data.Fin using (Fin; zero; suc; toℕ; fromℕ; fromℕ≤; reduce≥; inject+)
open import Data.Fin.Props
open import Function
open import Level
open import Relation.Binary

module UsingVectorEquality {s₁ s₂} (S : Setoid s₁ s₂) where

  private module SS = Setoid S
  open SS using () renaming (Carrier to A)
  import Data.Vec.Equality as VecEq
  open VecEq.Equality S

  replicate-lemma : ∀ {m} n x (xs : Vec A m) →
                    replicate {n = n}     x ++ (x ∷ xs) ≈
                    replicate {n = 1 + n} x ++      xs
  replicate-lemma zero    x xs = refl (x ∷ xs)
  replicate-lemma (suc n) x xs = SS.refl ∷-cong replicate-lemma n x xs

  xs++[]=xs : ∀ {n} (xs : Vec A n) → xs ++ [] ≈ xs
  xs++[]=xs []       = []-cong
  xs++[]=xs (x ∷ xs) = SS.refl ∷-cong xs++[]=xs xs

  map-++-commute : ∀ {b m n} {B : Set b}
                   (f : B → A) (xs : Vec B m) {ys : Vec B n} →
                   map f (xs ++ ys) ≈ map f xs ++ map f ys
  map-++-commute f []       = refl _
  map-++-commute f (x ∷ xs) = SS.refl ∷-cong map-++-commute f xs

open import Relation.Binary.PropositionalEquality as PropEq
open import Relation.Binary.HeterogeneousEquality as HetEq

-- lookup is natural.

lookup-natural : ∀ {a b n} {A : Set a} {B : Set b}
                 (f : A → B) (i : Fin n) →
                 lookup i ∘ map f ≗ f ∘ lookup i
lookup-natural f zero    (x ∷ xs) = refl
lookup-natural f (suc i) (x ∷ xs) = lookup-natural f i xs

-- lookup over allFin yields the index.

lookup-allFin : ∀ {n : ℕ} (i : Fin n) → lookup i (allFin n) ≡ i
lookup-allFin zero = refl 
lookup-allFin {suc n} (suc i) = begin
  lookup i (map suc (allFin n)) 
    ≡⟨ lookup-natural suc i _ ⟩
  suc (lookup i (allFin n))
    ≡⟨ PropEq.cong suc (lookup-allFin i) ⟩
  suc i 
    ∎
  where
  open ≡-Reasoning

lookup-++-< : ∀ {a} {A : Set a} {m n} (xs : Vec A m) (ys : Vec A n) 
                                      (i : Fin (m + n)) (i<m : toℕ i < m)
            → lookup i (xs ++ ys) ≡ lookup (fromℕ≤ i<m) xs
lookup-++-< [] ys i ()
lookup-++-< (x ∷ xs) ys zero (s≤s z≤n) = refl
lookup-++-< (x ∷ xs) ys (suc i) (s≤s (s≤s m≤n)) = lookup-++-< xs ys i (s≤s m≤n)

lookup-++-≥ : ∀ {a} {A : Set a} {m n} (xs : Vec A m) (ys : Vec A n) 
                                      (i : Fin (m + n)) (i≥m : toℕ i ≥ m)
            → lookup i (xs ++ ys) ≡ lookup (reduce≥ i i≥m) ys
lookup-++-≥ [] ys i i≥m = refl
lookup-++-≥ (x ∷ xs) ys zero ()
lookup-++-≥ (x ∷ xs) ys (suc i) (s≤s i≥m) = lookup-++-≥ xs ys i i≥m

lookup-++₁ : ∀ {a} {A : Set a} {m n} (xs : Vec A m) (ys : Vec A n) (i : Fin m)
            → lookup (inject+ n i) (xs ++ ys) ≡ lookup i xs
lookup-++₁ [] ys ()
lookup-++₁ (x ∷ xs) ys zero = refl
lookup-++₁ (x ∷ xs) ys (suc i) = lookup-++₁ xs ys i


lookup-++₂ : ∀ {a} {A : Set a} {m n} (xs : Vec A m) (ys : Vec A n) (i : Fin n)
            → lookup (fromℕ m +′ i) (xs ++ ys) ≡ lookup i ys
lookup-++₂ [] ys zero = refl
lookup-++₂ [] (y ∷ xs) (suc i) = lookup-++₂ [] xs i
lookup-++₂ (x ∷ xs) ys i = lookup-++₂ xs ys i

-- Constructor mangling

∷-cong : ∀ {a} {A : Set a} {n} {x y : A} {xs ys : Vec A n} → x ≡ y → xs ≡ ys → x ∷ xs ≡ y ∷ ys
∷-cong refl refl = refl

drop-head-≡ : ∀ {a} {A : Set a} {n} {x y : A} {xs ys : Vec A n} → x ∷ xs ≡ y ∷ ys → x ≡ y
drop-head-≡ refl = refl 

drop-tail-≡ : ∀ {a} {A : Set a} {n} {x y : A} {xs ys : Vec A n} → x ∷ xs ≡ y ∷ ys → xs ≡ ys
drop-tail-≡ refl = refl 

-- map is a congruence.

map-cong : ∀ {a b n} {A : Set a} {B : Set b} {f g : A → B} →
           f ≗ g → _≗_ {A = Vec A n} (map f) (map g)
map-cong f≗g []       = refl
map-cong f≗g (x ∷ xs) = PropEq.cong₂ _∷_ (f≗g x) (map-cong f≗g xs)

-- map is functorial.

map-id : ∀ {a n} {A : Set a} → _≗_ {A = Vec A n} (map id) id
map-id []       = refl
map-id (x ∷ xs) = PropEq.cong (_∷_ x) (map-id xs)

map-∘ : ∀ {a b c n} {A : Set a} {B : Set b} {C : Set c}
        (f : B → C) (g : A → B) →
        _≗_ {A = Vec A n} (map (f ∘ g)) (map f ∘ map g)
map-∘ f g []       = refl
map-∘ f g (x ∷ xs) = PropEq.cong (_∷_ (f (g x))) (map-∘ f g xs)

-- mapping lookup over all finite numbers yields the original list.

map-lookup-allFin : ∀ {a} {A : Set a} {n} (xs : Vec A n) → map (λ x → lookup x xs) (allFin n) ≡ xs
map-lookup-allFin [] = refl
map-lookup-allFin {n = suc n} (x ∷ xs) = ∷-cong refl (begin
  map (λ x' → lookup x' (x ∷ xs)) (map suc (allFin n))
    ≡⟨ PropEq.sym $ map-∘ (λ x' → lookup x' (x ∷ xs)) suc (allFin n) ⟩
  map (λ x' → lookup x' xs) (allFin n)
    ≡⟨ map-lookup-allFin xs ⟩
  xs
    ∎)
  where
  open ≡-Reasoning

-- sum commutes with _++_.

sum-++-commute : ∀ {m n} (xs : Vec ℕ m) {ys : Vec ℕ n} →
                 sum (xs ++ ys) ≡ sum xs + sum ys
sum-++-commute []            = refl
sum-++-commute (x ∷ xs) {ys} = begin
  x + sum (xs ++ ys)
    ≡⟨ PropEq.cong (λ p → x + p) (sum-++-commute xs) ⟩
  x + (sum xs + sum ys)
    ≡⟨ PropEq.sym (+-assoc x (sum xs) (sum ys)) ⟩
  sum (x ∷ xs) + sum ys
    ∎
  where
  open ≡-Reasoning
  open CommutativeSemiring Nat.commutativeSemiring hiding (_+_; sym)

-- foldr is a congruence.

foldr-cong : ∀ {a} {A : Set a}
               {b₁} {B₁ : ℕ → Set b₁}
               {f₁ : ∀ {n} → A → B₁ n → B₁ (suc n)} {e₁}
               {b₂} {B₂ : ℕ → Set b₂}
               {f₂ : ∀ {n} → A → B₂ n → B₂ (suc n)} {e₂} →
             (∀ {n x} {y₁ : B₁ n} {y₂ : B₂ n} →
                y₁ ≅ y₂ → f₁ x y₁ ≅ f₂ x y₂) →
             e₁ ≅ e₂ →
             ∀ {n} (xs : Vec A n) →
             foldr B₁ f₁ e₁ xs ≅ foldr B₂ f₂ e₂ xs
foldr-cong           _     e₁=e₂ []       = e₁=e₂
foldr-cong {B₁ = B₁} f₁=f₂ e₁=e₂ (x ∷ xs) =
  f₁=f₂ (foldr-cong {B₁ = B₁} f₁=f₂ e₁=e₂ xs)

-- foldl is a congruence.

foldl-cong : ∀ {a} {A : Set a}
               {b₁} {B₁ : ℕ → Set b₁}
               {f₁ : ∀ {n} → B₁ n → A → B₁ (suc n)} {e₁}
               {b₂} {B₂ : ℕ → Set b₂}
               {f₂ : ∀ {n} → B₂ n → A → B₂ (suc n)} {e₂} →
             (∀ {n x} {y₁ : B₁ n} {y₂ : B₂ n} →
                y₁ ≅ y₂ → f₁ y₁ x ≅ f₂ y₂ x) →
             e₁ ≅ e₂ →
             ∀ {n} (xs : Vec A n) →
             foldl B₁ f₁ e₁ xs ≅ foldl B₂ f₂ e₂ xs
foldl-cong           _     e₁=e₂ []       = e₁=e₂
foldl-cong {B₁ = B₁} f₁=f₂ e₁=e₂ (x ∷ xs) =
  foldl-cong {B₁ = B₁ ∘ suc} f₁=f₂ (f₁=f₂ e₁=e₂) xs

-- The (uniqueness part of the) universality property for foldr.

foldr-universal : ∀ {a b} {A : Set a} (B : ℕ → Set b)
                  (f : ∀ {n} → A → B n → B (suc n)) {e}
                  (h : ∀ {n} → Vec A n → B n) →
                  h [] ≡ e →
                  (∀ {n} x → h ∘ _∷_ x ≗ f {n} x ∘ h) →
                  ∀ {n} → h ≗ foldr B {n} f e
foldr-universal B f     h base step []       = base
foldr-universal B f {e} h base step (x ∷ xs) = begin
  h (x ∷ xs)
    ≡⟨ step x xs ⟩
  f x (h xs)
    ≡⟨ PropEq.cong (f x) (foldr-universal B f h base step xs) ⟩
  f x (foldr B f e xs)
    ∎
  where open ≡-Reasoning

-- A fusion law for foldr.

foldr-fusion : ∀ {a b c} {A : Set a}
                 {B : ℕ → Set b} {f : ∀ {n} → A → B n → B (suc n)} e
                 {C : ℕ → Set c} {g : ∀ {n} → A → C n → C (suc n)}
               (h : ∀ {n} → B n → C n) →
               (∀ {n} x → h ∘ f {n} x ≗ g x ∘ h) →
               ∀ {n} → h ∘ foldr B {n} f e ≗ foldr C g (h e)
foldr-fusion {B = B} {f} e {C} h fuse =
  foldr-universal C _ _ refl (λ x xs → fuse x (foldr B f e xs))

-- The identity function is a fold.

idIsFold : ∀ {a n} {A : Set a} → id ≗ foldr (Vec A) {n} _∷_ []
idIsFold = foldr-universal _ _ id refl (λ _ _ → refl)

-- Proof irrelevance of _[_]=_
[]=-irrelevance : ∀ {a} {A : Set a} {n} {xs : Vec A n} {i : Fin n} {x : A}
                  → (p q : xs [ i ]= x) → p ≡ q
[]=-irrelevance here here = refl
[]=-irrelevance (there xs[i]=x) (there xs[i]=x') = PropEq.cong there ([]=-irrelevance xs[i]=x xs[i]=x')
