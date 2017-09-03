/*
    Projekt cislo 2, PRL 2016/2017
    Dominika Regeciova, xregec00
*/

#include <mpi.h>
#include <iostream>
#include <fstream>

using namespace std;

#define TAG 0

int main(int argc, char *argv[])
{
    // Pocet procesoru (n+1)
    int numProcs;
    // Moje ID
    int myID;
    // struktura s kodem, tagem a chybovymi hlasenimi
    MPI_Status stat;

    //Prvky procesoru dle algoritmu
    // Prvek xi
    int x;
    bool nonEmptyX = false;
    // Postupne x1...xn
    int y;
    bool nonEmptyY = false;
    // Pocet prvku mensich nez xi (t.j. kolikrat byl Yi <= Xi)
    // Krok 1) Nastavim vsechny registry C na hodnotu 1
    int c = 1;
    // Serazeny prvek Yi
    int z;
    // Promenne na mereni casu
    //double startTime;
    //double endTime;

    // MPI Init
    // Inicializace MPI
    MPI_Init(&argc, &argv);
    // Pocet bezicich procesoru
    MPI_Comm_size(MPI_COMM_WORLD, &numProcs);
    // ID meho procesu
    MPI_Comm_rank(MPI_COMM_WORLD, &myID);
    
    // Procesoru, ktere opravdu radi cisla je n, stejne jako mame n cisel
    numProcs--;
    // Vstup
    int* buffer = new int [numProcs];
    // Vystup
    int* result = new int [numProcs]; 

    // Nacteni souboru
    // Procesor s rankem 0 je ve vedeni
    if (myID == 0)
    {
        // Jmeno souboru
        char input[] = "numbers";
        // Hodnota pri nacitani souboru
        int number;
        // Invariant
        int inVar = 0;
        // Handle pro cteni ze souboru
        fstream fin;
        fin.open(input, ios::in);
        
        while(fin.good())
        {
            number = fin.get();
            // Cti do EOF
            if(!fin.good()) 
                break;
            // Ulozeni cisla do vstupniho bufferu
            buffer[inVar] = number;
            // Vypis cisla na vystup
            if (inVar < (numProcs - 1))
                cout << buffer[inVar] << " ";
            else
                cout << buffer[inVar] << endl;
            inVar++;         
        }
        fin.close();
        //startTime = MPI_Wtime();
    }
    

    // Krok 2) Samotne razeni
    for (int k = 1; k <= (2 * numProcs); k++)
    {
        int h;
        if (k <= numProcs) 
            h = 1;
        else
            h = k - numProcs;

        // Porovnavani xi a yi
        if ((myID >= h) && nonEmptyX && nonEmptyY)
        {       
            // Uprava algortimu pro stejna cisla podle
            // http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.106.4976&rep=rep1&type=pdf
            // Hodnotu j pocitam podle k-myID
            if ((k-myID) < myID) 
            {
                if (x >= y)
                    c = c + 1;
            }
            if ((k-myID) >= myID)
            {
              if (x > y)
                    c = c + 1;
            }
        }

        // Posun y hodnoty sousedovi
        if ((myID >= h) && (myID <= min(numProcs-1,k)) && nonEmptyY)
        {
            MPI_Send(&y, 1, MPI_INT, (myID + 1), TAG, MPI_COMM_WORLD);      
        }
        if ((myID > h) && (myID <= min(numProcs,k)))
        {
            MPI_Recv(&y, 1, MPI_INT, (myID - 1), TAG, MPI_COMM_WORLD, &stat);
            nonEmptyY = true;
        }
        
        // Rozeslani dalsi hodnoty ze vstupu (hodnoty beru od konce, jako v prikladu)
        if ((myID == 0) && (k <= numProcs))
        {       
            MPI_Send(&buffer[numProcs-k], 1, MPI_INT, 1, TAG, MPI_COMM_WORLD);
            MPI_Send(&buffer[numProcs-k], 1, MPI_INT, k, TAG, MPI_COMM_WORLD);
        }
        if ((myID == 1) && (k <= numProcs))
        {
            MPI_Recv(&y, 1, MPI_INT, 0, TAG, MPI_COMM_WORLD, &stat);
            nonEmptyY = true;
        }
        if ((myID == k) && (k <= numProcs))
        {
            MPI_Recv(&x, 1, MPI_INT, 0, TAG, MPI_COMM_WORLD, &stat);
            nonEmptyX = true;
        }
        
        // Aby prijimaci procesor vedel, ze ma cekat z, rozeslu mezi procesory
        // aktualni cil
        int to;
        if (k>numProcs)
        {
            if (myID == h)
                to = c;
             MPI_Bcast(&to, 1, MPI_INT, h, MPI_COMM_WORLD);
        }
        
        if ((myID == h) && (k > numProcs))
        {
            MPI_Send(&x, 1, MPI_INT, to, TAG, MPI_COMM_WORLD);  
        }
        if ((myID == to) && (k > numProcs))
        {
            MPI_Recv(&z, 1, MPI_INT, h, TAG, MPI_COMM_WORLD, &stat);
        }
    }
    
    // Ve 3. kroku procesory posouvaji registry Z doprava
    // procesor Pn produkuje serazenou posloupnost
    for (int k = 1; k <= numProcs; k++)
    {
        if (myID == numProcs) 
            MPI_Send(&z, 1, MPI_INT, 0, TAG, MPI_COMM_WORLD);
        if (myID == 0)
            MPI_Recv(&result[numProcs - k], 1, MPI_INT, numProcs, TAG, MPI_COMM_WORLD, &stat);
        for (int i = (numProcs - 1); i >= k; i--)
        {
            if (myID == i)
                 MPI_Send(&z, 1, MPI_INT, myID + 1, TAG, MPI_COMM_WORLD);
            if (myID == i+1)
                MPI_Recv(&z, 1, MPI_INT, myID - 1, TAG, MPI_COMM_WORLD, &stat);
        }
    }

    // Vypis vysledku
    if (myID == 0)
    {
        //endTime = MPI_Wtime();
        //cout << endTime - startTime << endl;
        for (int i = 0; i < numProcs; i++)
        {
            cout << result[i] << endl;
        }
        // Uvolneni pameti
        delete buffer;
        delete result;
    }
    
    MPI_Finalize();
    return 0;
}

