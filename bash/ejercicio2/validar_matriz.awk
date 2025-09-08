#!/usr/bin/awk -f

BEGIN {
    FS=SEP;                  # Definimos el separador
    num_filas = 0;           # Contador de filas
    errores = 0;             # Contador de errores
}

{
   if (num_columnas == 0) {
        num_columnas = NF          # guardamos el número de columnas de la primera fila
    } else if (NF != num_columnas) {
        print "Error: la fila " num_filas " tiene " NF " columnas, se esperaban " num_columnas
        errores++
    }

    num_filas++;
    # Guardamos la fila en un array para validar simetría
    for (i=1; i<=NF; i++) {
        valor = $i
        # Validamos que sea número entero o decimal
        if (valor !~ /^[0-9]+(\.[0-9]+)?$/) {
            print "Error: valor no numérico en fila " num_filas ", columna " i ": " valor
            errores++
        }
        matriz[num_filas,i] = valor
    }
}

END {

    # Verificamos que todas las filas tengan el mismo número de columnas
    if (NF != num_filas) {
        print "Error: la matriz no es cuadrada (fila " num_filas " tiene " NF " columnas)"
        errores++
    }

    # Validamos simetría
    for (i=1; i<=num_filas; i++) {
        for (j=1; j<=num_filas; j++) {
            if (matriz[i,j] != matriz[j,i]) {
                print "Error: la matriz no es simétrica en (" i "," j ")"
                errores++
            }
        }
    }

    exit errores
}



