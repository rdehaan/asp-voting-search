%%%
%%% FIND A SCORING RULE THAT SATISFIES PARETO OPTIMALITY, FOR LIMITED PROFILE SIZES
%%%

% define constants
#const n=3. % # voters
#const m=3. % # candidates
#const s=3. % maximum score (positive integers only)

% define auxiliary predicates
voter(1..n).
candidate(1..m).
position(1..m).
scoreval(0..s-1).

% guess a scoring vector (existential guess)
1 { score(C,S) : scoreval(S) } 1 :- candidate(C).

% guess a profile (universal guess)
profile(1;2).
1 { rank(P,N,C,R) : position(R) } 1 :- profile(P), voter(N), candidate(C).
1 { rank(P,N,C,R) : candidate(C) } 1 :- profile(P), voter(N), position(R).
prefers(P,N,C1,C2) :- profile(P), voter(N), rank(P,N,C1,R1), rank(P,N,C2,R2), R1 < R2.

% symmetry breaking in profile guessing (version 1)
profile_same_up_to(P,N1,N2,0) :- profile(P), voter(N1), voter(N2), N2=N1+1.
profile_same_up_to(P,N1,N2,R) :- profile(P), position(R), voter(N1), voter(N2), N2=N1+1, candidate(C),
  profile_same_up_to(P,N1,N2,R-1), rank(P,N1,C,R), rank(P,N2,C,R).
:- profile(P), voter(N1), voter(N2), N2=N1+1, profile_same_up_to(P,N1,N2,R), position(RR), RR = R+1,
  rank(P,N1,C1,RR), rank(P,N2,C2,RR), C2 < C1.

% symmetry breaking in profile guessing (version 2)
% profile_same_up_to(P,N1,N2,0) :- profile(P), voter(N1), voter(N2), N2 > N1.
% profile_same_up_to(P,N1,N2,R) :- profile(P), position(R), voter(N1), voter(N2), N2 > N1, candidate(C),
%   profile_same_up_to(P,N1,N2,R-1), rank(P,N1,C,R), rank(P,N2,C,R).
% :- profile(P), voter(N1), voter(N2), N2 > N1, profile_same_up_to(P,N1,N2,R), position(RR), RR = R+1,
%   rank(P,N1,C1,RR), rank(P,N2,C2,RR), C2 < C1.

% compute the outcome for the profiles (deterministic computation)
profile_score(P,C,D) :- profile(P), candidate(C), D = #sum { S,dummy(N,R,S) : score(R,S), rank(P,N,C,R) }.
1 { outcome_rank(P,C,R) : position(R) } 1 :- profile(P), candidate(C).
1 { outcome_rank(P,C,R) : candidate(C) } 1 :- profile(P), position(R).
outcome_prefers(P,C1,C2) :- profile(P), outcome_rank(P,C1,R1), outcome_rank(P,C2,R2), R1 < R2.
:- outcome_prefers(P,C1,C2), profile(P), profile_score(P,C1,D1), profile_score(P,C2,D2), D2 > D1.
:- outcome_prefers(P,C1,C2), profile(P), profile_score(P,C1,D), profile_score(P,C2,D), C2 > C1.
winner(P,C) :- outcome_rank(P,C,1).

% define Pareto optimality (deterministic computation)
pareto_dominates(1,C1,C2) :- profile(1), candidate(C1), candidate(C2), prefers(1,N,C1,C2) : voter(N).
non_pareto :- profile(1), outcome_prefers(1,C1,C2), pareto_dominates(1,C2,C1).
pareto :- not non_pareto.

% define strategyproofness (deterministic computation)
same_vote_on_candidate_in_both_profiles(N,C) :- voter(N), candidate(C), rank(1,N,C,R), rank(2,N,C,R).
same_vote_in_both_profiles(N) :- voter(N), same_vote_on_candidate_in_both_profiles(N,C) : candidate(C).
same_except_voter_in_both_profiles(N) :- voter(N),
  not same_vote_in_both_profiles(N), same_vote_in_both_profiles(M) : voter(M), N != M.
% strategizing :- same_except_voter_in_both_profiles(N), prefers(1,N,C1,C2), winner(1,C2), winner(2,C1).
strategizing :- same_except_voter_in_both_profiles(N), prefers(1,N,C1,C2),
  outcome_rank(1,C2,R1), outcome_rank(1,C1,R2), outcome_rank(2,C1,R1), R2 > R1,
  C = D : outcome_rank(1,C,R), outcome_rank(2,D,R), position(R), R < R1.
non_strategizing :- not strategizing.

% declare what is the desired outcome
% satisfied :- pareto.
satisfied :- non_strategizing.
% satisfied :- pareto, non_strategizing.

%%% perform two-layered optimization, using meta-programming, to simulate \exists\forall query
_criteria(2,1,score(N,S)) :- score(N,S).
_optimize(2,1,incl).

_criteria(1,1,satisfied) :- satisfied.
_optimize(1,1,card).

#show _criteria/3.
#show _optimize/3.

%%% declare what part of the solution to show

#show score/2.
#show satisfied/0.

%%% usage:
% clingo scoring-strategyproof-swf.lp -Wno-atom-undefined --pre | reify | clingo - meta.lp metaO.lp metaD.lp <(echo ":- output(satisfied,B), not conjunction(B).") -Wno-atom-undefined -n0 --project

% (the files meta*.lp are from https://potassco.org/labs/metasp/)

%%% example settings: (symmetry breaking: none / version 1 / version 2)
% - n=2, m=3, s=3 ~
% - n=2, m=3, s=4 ~
% - n=2, m=4, s=4 ~
% - n=3, m=3, s=3 ~
% - n=3, m=3, s=4 ~
% - n=3, m=3, s=5 ~
% - n=3, m=4, s=4 ~
% - n=4, m=4, s=4 ~
% - n=4, m=4, s=5 ~ 
