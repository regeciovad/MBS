/*
    FLP projekt za rok 2016/2017
    Logicky projekt v jazyce Prolog
    Varianta Patnactka
    Vypracovala Dominika Regeciova, xregec00
*/

%******************************************************************************
% Zpracovani vstupu
% Funkce read_lines, read_line, isEOFEOL, split_lines, split_line, cislo
% jsou inspirovany prikladem input2.pl
%******************************************************************************
% Nacteni vstupu
read_lines(Ls) :-
    read_line(L,C),
    ( C == end_of_file, Ls = [] ;
        read_lines(LLs), Ls = [L|LLs]).

% Nacitani vstupu, konec na LF nebo EOF
read_line(L,C) :-
    get_char(C),
        (isEOFEOL(C), L = [], !;
            read_line(LL,_),
            [C|LL] = L).

% Testovani, zda je znak  EOF nebo LF.
isEOFEOL(C) :-
    C == end_of_file;
   (char_code(C,Code), Code==10).

% Nacteni hlavolamu, kontrola a vytvoreni goal stavu
read_puzzle([],[]).
read_puzzle(LL,Q) :- 
    split_lines(LL,O), 
    to_numbers(O,P),
    % Nekdy mi z konce radku v seznamu zustava [] navic, to odstranim
    subtract(P,[[]],Q),
    flatten(Q,X),
    length(X,E),
    (E < 2 -> writeln('Chyba vstupu - prazdna krabicka'), halt;true),
    count_star(X,M),
    (M \= 1 -> writeln('Chyba vstupu - spatny pocet *'), halt;true),
    (equal_lengths(Q) -> true; writeln('Chyba vstupu - divna krabicka'), halt),
    nth0(0,Q,L),
    length(L,N),
    create_goal(Q,N).

% Kontrola poctu *
count_star([],0).
count_star([H|T],N) :- 
    (H == '*' -> count_star(T,N2), N is N2 + 1;
        count_star(T,N)).

% Jsou vsechny podseznamy stejne dlouhe?
equal_lengths([]).
equal_lengths([[]]).
equal_lengths([[_|_]]).
equal_lengths([X,Y|T]) :- 
    length(X, L), 
    length(Y, L), 
    equal_lengths([Y|T]).

% Vstupem je seznam radku (kazdy radek je seznam znaku)
split_lines([],[]).
split_lines([L|Ls],[H|T]) :- split_lines(Ls,T), split_line(L,H).

% Rozdeleni radku na podseznamy
split_line([],[[]]) :- !.
split_line([' '|T], [[]|S1]) :- !, split_line(T,S1).
% aby to fungovalo i s retezcem na miste seznamu
split_line([32|T], [[]|S1]) :- !, split_line(T,S1).
% G je prvni seznam ze seznamu seznamu G|S1
split_line([H|T], [[H|G]|S1]) :- split_line(T,[G|S1]).

% Prevod hadanky na seznam cisel (a hvezdicku)
to_numbers([],[]).
to_numbers([H|T], [C|CT]) :- row(H, C) ,to_numbers(T, CT).

row([],[]) :- !.
row([[]|T], CT) :- row(T, CT).
row([H|T],[C|CT]) :- cislo(H, C), row(T, CT).

% Prevod umi pracovat i se zapornymi cisly
cislo(N,X) :- cislo(N,0,X).
cislo(['*'],_,'*') :- !.
cislo([],F,F).
cislo(['.'|T],F,X) :- !, cislo(T,F,X,10).
cislo(['-'|T],_,X) :- !, cislo(T,-1,X).
cislo([H|T],F,X) :- atom_number(H, L), F == -1, FT is F*L, cislo(T,FT,X).
cislo([H|T],F,X) :- atom_number(H, L), F > -1, FT is 10*F+L, cislo(T,FT,X).
cislo([H|T],F,X) :- atom_number(H, L), F < -1, FT is 10*F-L, cislo(T,FT,X).
cislo([],F,F,_).
cislo([H|T],F,X,P) :- FT is F+H/P, PT is P*10, cislo(T,FT,X,PT).


%******************************************************************************
% Vytvoreni a ulozeni ciloveho stavu
%******************************************************************************
create_goal([],_) :- false.
create_goal(L,N) :- flatten(L,X), sort(X,Y), part(Y,N,Z), assert(goal(Z)).

part([],_,[]).
part(L, N, [H|HT]) :- length(H, N), append(H, LT, L), part(LT, N, HT).


%******************************************************************************
% Vypis hlavolamu a cesty k cilovemu stavu
%******************************************************************************
print_puzzle([]) :- writeln('').
print_puzzle([H|T]) :- print_row(H), print_puzzle(T).
print_row([]) :- writeln('').
print_row([H|T]) :- write(H), write(' '), print_row(T).

% Vypis cesty k reseni
print_solution(_,[]).
% Uz pocatecni stav muze byt cilovym
print_solution(R,[R|_]).
print_solution(R,[H|T]) :- print_solution(R,T), print_puzzle(H).


%******************************************************************************
% Reseni hlavolamu
%******************************************************************************
% Vyhledavam iterativne a pokud nenajdu cil, zvisim limit o 1
solve_puzzle(R,P) :- iterate(L,1), solve_puzzle(R,R,[],P,0,L).
solve_puzzle(_,S,P,P,D,L) :- D < L, goal(S).
solve_puzzle(C,S,V,P,D,L) :- 
    D < L, D2 is D + 1, make_move(S,NS),\+member(NS,V),
    solve_puzzle(C,NS,[NS|V],P,D2,L).

iterate(X,X).
iterate(X,N) :- N2 is N+1, iterate(X,N2).

% V hlavolamu je mozne posun * pouze 4 smery
% Pro zjednoduseni implementuji pouze posuv doleva a nahoru
% Dalsi dva provadim pomoci reverzace seznamu
make_move([],[]).
make_move(S,N) :- reverse(S,X), move_up(X,Y), reverse(Y,N).
%make_move(S,N) :- move_up(S,N).
make_move([S|ST],[N|NT]) :- 
    make_move(ST,NT), reverse(S,X),move_left(X,Y), reverse(Y,N).
make_move([S|ST],[N|NT]) :- make_move(ST,NT), move_left(S,N).
make_move(S,N) :- move_up(S,N).

% Posun doleva je mozny, pokud * neni v prvnim sloupci
% Test je tedy lehci, nez u varianty do prava
% Predavam si predchozi hodnotu, abych je pak mohl prohodit
move_left([],[]).
move_left([H|T],N) :- H \= '*', !, move_left(T,H,N).
move_left([],X,[X]).
move_left([H|T],P,[N|NT]) :- 
    (H == '*' ->  N = H, move_left(T, P, NT);
        N = P, move_left(T,H,NT)).

% Posun nahoru je mozny, pokud * neni v prvnim radku
move_up([H|T], N) :- move_up_row(H,[],X,_), move_up(T,X,N).
move_up([],X,[X]).
move_up([H|T], P, [N|NT]) :- move_up_row(H,P,X,N), move_up(T,X,NT).

move_up_row([],[],[],[]).
move_up_row([H|T],[],[X|XT],[N|NT]) :- 
    H \= '*', !,N = H, X = H, move_up_row(T,[],XT,NT).
move_up_row([H|T],[P|PT],[R|RT],[X|XT]) :- 
    (H == '*' -> X=H, R=P, move_up_row(T,PT,RT,XT);
        X=P, R=H, move_up_row(T,PT,RT,XT)).


%******************************************************************************
% Start
%******************************************************************************
start :-
    % Smazani promtu pri cteni
    prompt(_, ''),
    % Nacteni vstupu
    read_lines(LL),
    % Nacteni hadanky
    read_puzzle(LL, R),
    !,
    % Vypis pocatecni stav
    print_puzzle(R),
    % Najdi reseni
    solve_puzzle(R,P),
    % Vypis reseni
    print_solution(R,P),
    retractall(goal(_)),
    halt.

