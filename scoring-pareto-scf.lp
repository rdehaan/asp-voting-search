%%%
%%% FIND A SCORING RULE THAT SATISFIES PARETO OPTIMALITY, FOR LIMITED PROFILE SIZES
%%%

% define constants
#const n=2. % # voters
#const m=3. % # candidates
#const s=3. % maximum score (positive integers only)

% define auxiliary predicates
voter(1..n).
candidate(1..m).
scoreval(0..s-1).

% guess a scoring vector (existential guess)
1 { score(C,S) : scoreval(S) } 1 :- candidate(C).

% guess a profile (universal guess)
profile(1).
1 { rank(P,N,C,R) : candidate(R) } 1 :- profile(P), voter(N), candidate(C).
1 { rank(P,N,C,R) : candidate(C) } 1 :- profile(P), voter(N), candidate(R).
prefers(P,N,C1,C2) :- profile(P), voter(N), rank(P,N,C1,R1), rank(P,N,C2,R2), R1 < R2.

% compute the outcome for the profiles (deterministic computation)
profile_score(P,C,D) :- profile(P), candidate(C), D = #sum { S,dummy(N,R,S) : score(R,S), rank(P,N,C,R) }.
max_score(P,M) :- profile(P), M = #max { D,dummy(C) : profile_score(P,C,D) }.
winners(P,C) :- profile(P), max_score(P,M), profile_score(P,C,M).
1 { winner(P,C) : winners(P,C) } 1 :- profile(P).
:- profile(P), winner(P,C2), winners(P,C1), C1 < C2.

% define Pareto optimality (deterministic computation)
pareto_dominates(1,C1,C2) :- profile(1), candidate(C1), candidate(C2), prefers(1,N,C1,C2) : voter(N).
non_pareto :- profile(1), winner(1,C), pareto_dominates(1,_,C).
pareto :- not non_pareto.

% declare what is the desired outcome
satisfied :- pareto.

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
% clingo scoring-pareto-scf.lp -Wno-atom-undefined --pre | reify | clingo - meta.lp metaO.lp metaD.lp <(echo ":- output(satisfied,B), not conjunction(B).") -Wno-atom-undefined -n0 --project

% (the files meta*.lp are from https://potassco.org/labs/metasp/)

%%% example settings:
% - n=2, m=3, s=3 ~ 2 seconds
% - n=2, m=3, s=4 ~ 5 seconds
% - n=2, m=4, s=4 ~ 60 seconds
% - n=3, m=3, s=3 ~ 6 seconds
% - n=3, m=3, s=4 ~ 42 seconds
% - n=3, m=3, s=5 ~ 215 seconds
