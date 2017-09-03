{- |FLP projekt za rok 2016/2017. 
    Funcionalni projekt v jazyce Haskell.
    Varianta rv-2-rka.
    Vypracovala Dominika Regeciova, xregec00.
-}

module Main where

import Control.Applicative
import Data.Char
import Data.List (intercalate, sortBy)
import Data.Monoid (mconcat)
import Data.Ord (comparing)
import System.Environment
import System.IO

{- |Neuplny binarni strom pro RV, * ma pouze pravy podstrom.
-}
data Tree
    = Empty
    | Symbol Char
    | Dot Tree Tree
    | Plus Tree Tree
    | Star Tree
    deriving Show

-- |Zasobnik pro nacteni RV
type Stack = [Tree]

{- |Rozsireny konecny automat (Extended finite-state machine)
    Konecny stav je pouze jeden, protoze pouzivany algortimus jich vic nevytvari.
-}
data EFSM = EFSM
    { states:: [EFSMState]
    , start:: EFSMState
    , end:: EFSMState
    , trans:: [EFSMTrans]
    }
    deriving Show

data EFSMTrans  = EFSMTrans
    { from:: EFSMState
    , symbol:: Char
    , to:: EFSMState
    }
    deriving (Eq,Show)

type EFSMState = Int

{- |Kontrola vstupnich argumentu.
    Vraci chybove hlaseni, nebo spousti funkci pro nacteni vstupu. 
-}
main :: IO()
main = do
    c <- checkArgs <$> getArgs
    case c of
        Left msg -> putStrLn msg
        Right (rkaBool, inFile) -> readInputFile (rkaBool,inFile)
    return()

{- |Ziskani vstupu ze souboru, nebo stdin.
    Dale predava volbu zpracovani a vstupni retezec.
    Pozn.: V obou pripadech nacitam pouze jeden radek.
-}
readInputFile:: (Bool, String) -> IO ()
readInputFile (rkaBool,inFile) = do
    if inFile == ""
        then do input <- getLine
                taskManager (rkaBool, input)
        else do hInFile <- openFile inFile ReadMode
                input <- hGetLine hInFile 
                taskManager (rkaBool, input)
                hClose hInFile

{- |Zpracovani voleb programu.
    Pokud rkaBool == True, pak dojde k vytvoreni RKA a jeho vypisu.
    Pokud rkaBool == False, pak precte vstup, ulozi ho do vnitrni struktury a znovu vypise.
-}
taskManager:: (Bool, String) -> IO()
taskManager (rkaBool,input) = do 
    if rkaBool
        then putStrLn $ showEFSM $ sortRules $ createEFSM $ unStack $ parseInput input
        else putStrLn $ showTree $ unStack $ parseInput input

{- |Vypis konecneho automatu dle zadani.
    Vypis RKA pro prazdny RV je osetren zvlast, intercalate mi vkladal prazdny radek navic.
-}
showEFSM:: EFSM -> String
showEFSM e =
    if (trans e) == []
    then intercalate "\n" (states' : start' : end' : [])
    else intercalate "\n" (states' : start' : end' : trans' : [])
    where
        states' = intercalate "," $ map show $ states e
        start' = show $ start e
        end' = show $ end e
        trans' = intercalate "\n" $ map showTrans $  trans e

-- |Podfunkce pro vypis automatu
showTrans:: EFSMTrans -> String
showTrans t = from' ++ "," ++ symbol' ++ "," ++ to'
    where
        from' = show $ from t
        symbol' = filter (/=' ')$ filter (/='\'') $ show $ symbol t
        to' = show $ to t

-- | Postupne razeni pravidel dle from, symbol, to.
sortRules:: EFSM -> EFSM
sortRules e = EFSM {states = states e, start = start e, end = end e, trans = trans'}
    where 
        -- vytvoreno pomoci napovedy z:
        -- http://martijn.van.steenbergen.nl/journal/2008/12/21/comparing-multiple-criteria/
        trans' = sortBy (mconcat [comparing from, comparing symbol, comparing to]) (trans e)

{- |Vytvareni RKA.
    Pripad prazdneho RV je resen zvlast pro zjednoduseni.
    Nejdrive si vypocitam pocet stavu, urcim pocatecni a koncovy stav.
    Pote jiz jen poslu strom, pocatecni a koncovy stav a dostanu mnozinu pravidel.
    Princip je blize popsan v README.
-}
createEFSM:: Tree -> EFSM
createEFSM Empty  = EFSM {states = [0,1], start = 0, end = 1, trans = []}
createEFSM t = 
    EFSM {states = [s..n], start = s, end = n, trans = trans'}    
    where
        n = sizeForTree t - 1
        s = 0 
        (_, _, trans') = genRules (t, s, n, [])

{- |Ziskavani pravidel. Krome seznamu pravidel, ktere postupne doplnuji,
    si predavam i aktualni zacatek a aktualni konec podautomatu.
    Diky tomu nemusim prepocitavat stavy a kazdy podautomati vi, s jakymi stavy
    ma volat sve podstromy (podstrom). Diky tomu pravidla pouze pridavam a nemusim je menit.
-}
genRules:: (Tree, Int, Int, [EFSMTrans]) -> (Int, Int, [EFSMTrans])
genRules ((Symbol c), start', _, trans') =
    (start', (start'+1), trans' ++ [EFSMTrans{from=start',symbol=c,to=(start'+1)}])
genRules ((Plus l r), start', end', trans') =
    ((a-1), (d+1), trans' ++ transL ++ transR ++ transPlus)
    where
        (a, b, transL) = genRules(l, (start'+1), end', trans')
        (c, d, transR) = genRules(r, (b+1), end', trans')
        transPlus = EFSMTrans{from=(a-1),symbol= ' ',to=a}
                    : EFSMTrans{from=(a-1),symbol= ' ',to=c}
                    : EFSMTrans{from=b,symbol= ' ',to=(d+1)}
                    : EFSMTrans{from=d,symbol= ' ',to=(d+1)} : []
genRules ((Star r), start', end', trans') =
    ((a-1), (b+1), trans' ++ transR ++ transStar)
    where
        (a, b, transR) = genRules(r, (start'+1), end', trans')
        transStar = EFSMTrans{from=(a-1),symbol= ' ',to=(b+1)}
                    : EFSMTrans{from=(a-1),symbol= ' ',to=a}
                    : EFSMTrans{from=b,symbol= ' ',to=(b+1)}
                    : EFSMTrans{from=b,symbol= ' ',to=a} : []
genRules ((Dot l r), start', end', trans') =
    (a, d, trans' ++ transL ++ transR)
    where
        (a, b, transL) = genRules(l, start', end', trans')
        (_, d, transR) = genRules(r, b, end', trans')
genRules (_,_,_,_) = error "Neco se pokazilo"

{- |Vypis stromu. 
    Slozitost je sice O(n^2), ale zapis je takto prehlednejsi.
    Navic nepredpokladam RV natolik rozsahly, aby byla doba vypoctu
    neunosne velka. 
-}
showTree:: Tree -> String
showTree Empty      = []
showTree (Symbol c) = filter (/='\'') (show c)
showTree (Dot l r)  = showTree l ++ showTree r ++ ['.']
showTree (Plus l r) = showTree l ++ showTree r ++ ['+']
showTree (Star r)   = showTree r ++ ['*'] 

{- |Vypocet velikosti automatu dle stromu RV.
    Diky vlastnostem algostimu lze deterministicky urcit, kolik stavu budu potrebovat.
    Pro praci je nutno odecist 1, pokud se stavy cisluji od 0.
-}
sizeForTree:: Tree -> Int
sizeForTree  Empty = 0
sizeForTree (Symbol _) = 2
sizeForTree (Dot l r)  = sizeForTree l + sizeForTree r - 1
sizeForTree (Plus l r) = sizeForTree l + sizeForTree r + 2
sizeForTree (Star r)   = sizeForTree r + 2

{- |Po nacteni RV zustane pouze 1 stromova struktura, zasobniku se tedy muzeme zbavit.
-}
unStack:: Stack -> Tree
unStack [t] = t
unStack _ = Empty

{- |Nacitani vstupu.
    Pokud je vstup prazdny, vrati Empty, jinak spousti parsovani.
-}
parseInput:: String -> Stack
parseInput input
    | input == "" = [Empty]
    | otherwise = foldl parseIt [] input

{- |Prevod postfixove notace do stromove struktury.
    Nad prazdnym seznamem si postupne buduje strom dle aktualniho symbolu na vstupu.     
-}
parseIt:: Stack -> Char -> Stack
parseIt (r:l:s) c
    | c == '.' = (Dot l r):s
    | c == '+' = (Plus l r):s
parseIt (r:s) '*' = (Star r):s
parseIt s c =
    if isAlpha c 
        then (Symbol c):s 
        else error "Neplatny RV"

-- |Kontrola vstupnich argumentu.
checkArgs:: [String] -> Either String (Bool, String)
checkArgs [] = Left $ printErrorArgs
checkArgs [x]
    | x == "-h" = Left $ printHelp
    | x == "-r" = Right $ (False, "")
    | x == "-t" = Right $ (True, "")
    | otherwise = Left $ printErrorArgs
checkArgs [x, y]
    | x == "-r" = Right $ (False, y)
    | x == "-t" = Right $ (True, y)
    | otherwise = Left $ printErrorArgs
checkArgs _ = Left $ printErrorArgs

-- |Text chyboveho hlaseni.
printErrorArgs :: String
printErrorArgs = "Program nebyl spusten se spravnymi argumenty.\
                 \ Pouzijte '-h' pro vypsani napovedy." 

-- |Text napovedy.
printHelp :: String
printHelp = "\n FLP projekt rv-2-rka \n \ 
            \ \t Pouziti: \n \
            \ \t\t rv-2-rka [volby] [vstup] \n \
            \ \t Volby: \n \
            \ \t\t -r vypis RV \n \
            \ \t\t -t vypis RKA \n \
            \ \t Vstup: \n \
            \ \t\t nepovinny vstupni soubor, defaultne stdin \n"

