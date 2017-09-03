/*
    Projekt cislo 3, PRL 2016/2017
    Dominika Regeciova, xregec00
*/

#include <mpi.h>
#include <iostream>
#include <fstream>
#include <string>
#include <sstream>

using namespace std;

#define TAG 0

// Zasli vsem kontrolni tag
void Send_All(int numProcs, int info)
{
    int i;
    for (i = 1; i <numProcs; i++)
    {
        MPI_Send(&info, 1, MPI_INT, i, TAG, MPI_COMM_WORLD);
    }
}

// Funkce pro cteni ze souboru
int Read_File(char *file, int *mat, int rows, int cols)
{
    int linfo = 0;
    ifstream fmat (file);
    if (fmat.is_open())
    {
        int counter = 0;
        string line;
        getline(fmat, line);
        while(getline (fmat, line))
        {
            if (line.empty())
                continue;
            stringstream ss(line);
            for (int i = 0; i < cols; i++)
            {
                ss >> mat[counter];
                // Nasla se neciselna hodnota
                if (ss.fail())
                {
                    cout << "Soubor ma obsahovat pouze cisla!" << endl;
                    linfo = -1;
                    ss.clear();
                    break;
                }
                counter++;
            }
        }
        fmat.close();
        // Nesedi pocet prvku v souboru mat
        if (counter != rows * cols)
            linfo = -1;
    }
    else
        linfo = -1;
    return linfo;
}

int main(int argc, char *argv[])
{
    // Pocet procesoru (m x k)
    int numProcs;
    // Moje ID
    int myID;
    // Struktura s kodem, tagem a chybovymi hlasenimi
    MPI_Status stat;

    // Prvky procesoru
    int a = 0;
    int b = 0;
    int c = 0;
    int info = 0;
    int rows_mat1;
    int cols_mat1;
    int rows_mat2;
    int cols_mat2;
    int rows_counter = 0;
    int cols_counter = 0;

    // Inicializace MPI
    MPI_Init(&argc, &argv);
    // Pocet bezicich procesoru
    MPI_Comm_size(MPI_COMM_WORLD, &numProcs);
    // ID meho procesu
    MPI_Comm_rank(MPI_COMM_WORLD, &myID);

    // Co prijde: $fmat1 $rows_mat1 $cols_mat1 $fmat2 $rows_mat2 $cols_mat2
    rows_mat1 = atoi(argv[2]);
    cols_mat1 = atoi(argv[3]);
    rows_mat2 = atoi(argv[5]);
    cols_mat2 = atoi(argv[6]);

    int* mat1;
    int* mat2;
    int* result;

    // Procesor 0 nacte oba vstupni soubory do matic
    if (myID == 0)
    {
        // Nacteni souboru
        mat1 = new int [rows_mat1 * cols_mat1];
        mat2 = new int [rows_mat2 * cols_mat2];
        int info1 = Read_File(argv[1], mat1, rows_mat1, cols_mat1);
        int info2 = Read_File(argv[4], mat2, rows_mat2, cols_mat2);
        if (info1 == -1 || info2 == -1)
            info = -1;

        // Kontrola, zda se neco nestalo pri cteni ze souboru
        if (info == -1)
        {
            Send_All(numProcs, info);
            free(mat1);
            free(mat2);
            MPI_Finalize();
            return 0;       
        }
        Send_All(numProcs, info);
    }
    else
    {
        // Procesy prijmou vysledek zpracovani vstupu
        MPI_Recv(&info, 1, MPI_INT, 0, TAG, MPI_COMM_WORLD, &stat);
        // Pokud se nekde stala chyba, nemohou pokracovat
        if (info == -1)
        {
            MPI_Finalize();
            return 0;
        }
    }

    // Dale rozposlu kopie matic procecosrum
    // Prvni sloupec dostane kopii mat1, prvni radek dostane kopii mat2
    if (myID == 0)
    {
        for (int i = 1; i < numProcs; i++)
        {
            if (i < cols_mat2)
                MPI_Send(mat2, rows_mat2 * cols_mat2, MPI_INT, i, TAG, MPI_COMM_WORLD);
             if (i % cols_mat2 == 0)
                MPI_Send(mat1, rows_mat1 * cols_mat1, MPI_INT, i, TAG, MPI_COMM_WORLD);
        }
    }

    // Prvni sloupec a prvni radek prijima kopii matic
    // Bez procesoru 0, ktery uz ma vysledek
    if ((myID < cols_mat2) && (myID != 0))
    {
        mat2 = new int [rows_mat2 * cols_mat2];
        MPI_Recv(mat2, rows_mat2 * cols_mat2, MPI_INT, 0, TAG, MPI_COMM_WORLD, &stat);
    }
    if ((myID % cols_mat2 == 0) && (myID != 0))
    {
        mat1 = new int [rows_mat1 * cols_mat1];
        MPI_Recv(mat1, rows_mat1 * cols_mat1, MPI_INT, 0, TAG, MPI_COMM_WORLD, &stat);
    }

    // Rozeslani hodnot a vypocet
    // Kazdy procesor obdrzi tolik hodnota a, b, kolik ma mat1 sloupcu
    for(int i = 0; i < cols_mat1; i++)
    {
        // Prvni sloupec procesoru cte mat1
        if (myID % cols_mat2 == 0) 
        {
            int row;
            if (myID == 0)
                row = 0;
            else
                row = myID / cols_mat2;  
            if (cols_counter < cols_mat1)
                a = mat1[row * cols_mat1 + cols_counter];
            cols_counter++;
        }

        // Prvni rada cte mat2
        if (myID < cols_mat2)
        {
            if (rows_counter < rows_mat2)
                b = mat2[rows_counter * cols_mat2 + myID];
            rows_counter++;   
        }

        // Procesory, ktere nectou, musi prijmout hodnoty a,b
        if (((myID % cols_mat2 != 0) && (myID >= cols_mat2)))
        {
            MPI_Recv(&a, 1, MPI_INT, myID - 1, TAG, MPI_COMM_WORLD, &stat);
            MPI_Recv(&b, 1, MPI_INT, myID - cols_mat2, TAG, MPI_COMM_WORLD, &stat);
            c += (a * b);
        }

        if (myID == 0)
            c += (a * b);
        
        // Procesory v prvni rade cekaji na b, 0. procesor jiz provedl operaci
        // Hodnotu b pak dostane od procesoru nad nim
        if ((myID % cols_mat2 == 0) && (myID != 0))
        {
            MPI_Recv(&b, 1, MPI_INT, myID - cols_mat2, TAG, MPI_COMM_WORLD, &stat);
            c += (a * b);
        }
    
        // Procesory v prvnim radku dostanou a od souseda z predchoziho sloupce
        if ((myID < cols_mat2) && (myID != 0))
        {
            MPI_Recv(&a, 1, MPI_INT, myID - 1, TAG, MPI_COMM_WORLD, &stat);
            c += (a * b);
        }   
    
        // Procesory, ktere nejsou hranicni, poslou a,b svym sousedum
        if ((myID+1) % cols_mat2 != 0)
            MPI_Send(&a, 1, MPI_INT, myID + 1, TAG, MPI_COMM_WORLD);

        if ((myID + cols_mat2) < (rows_mat1 * cols_mat2))
            MPI_Send(&b, 1, MPI_INT, myID + cols_mat2, TAG, MPI_COMM_WORLD);   
    }

    // Odeslani vysledku
    if (myID != 0)
        MPI_Send(&c, 1, MPI_INT, 0, TAG, MPI_COMM_WORLD);

    // Vypis vysledku
    if (myID == 0)
    {
        // Procesor 0 prijme vysledky
        result = new int [numProcs];
        result[0] = c;
        for (int i = 1; i < numProcs; i++)
            MPI_Recv(&result[i], 1, MPI_INT, i, TAG, MPI_COMM_WORLD, &stat);
        
        // A vypise vse na vystup
        cout << rows_mat1 << ":" << cols_mat2 << endl;
        for (int i = 0; i < numProcs; i++)
        {
            if ((i+1) % cols_mat2 == 0)
                cout << result[i] << endl;
            else
                cout << result[i] << " ";
        }   
        delete result;
    }

    if (myID % cols_mat2 == 0)
        delete mat1;
    if (myID < cols_mat2)
        delete mat2;
    
    // Radne ukonceni vsech procesu
    MPI_Finalize();
    return 0;
}
