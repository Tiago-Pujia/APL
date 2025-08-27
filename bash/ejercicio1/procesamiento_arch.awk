#!/usr/bin/awk -f

BEGIN {
    FS="|"
}

NR > 1 {
    # Se crean los arrays asociativos:
    #   suma_tiempo[(fecha, canal)]  -> suma de tiempos
    #   suma_nota[(fecha, canal)]    -> suma de notas
    #   cuenta[(fecha, canal)]       -> cantidad de registros
    #
    # Para cada registro:
    #   1. Extraer fecha, canal, tiempo y nota
    #   2. Acumular tiempo y nota por (fecha, canal)
    #   3. Contar cantidad de registros por (fecha, canal)
    
    # Variables:
    fecha = $2
    canal = $3
    tiempo = $4
    nota = $5

    # Extraemos fecha (sin hora)
    split(fecha, f, " ") # Separo fecha y hora
    fecha = f[1] # Me quedo con la fecha

    # Acumulo en arrays asociativos
    key = fecha "|" canal

    suma_tiempo[key] += tiempo
    suma_nota[key]   += nota
    cuenta[key]++
}

END { # CALCULO FINAL
    printf "{"
    sep_dia = ""

    for (k in suma_tiempo) {
        split(k, partes, "|")
        dia   = partes[1]
        canal = partes[2]

        tiempo_prom = suma_tiempo[k] / cuenta[k]
        nota_prom   = suma_nota[k] / cuenta[k]

        if (!(dia in usado_dia)) {
            # Si ya había otro día, cierro el anterior
            if (sep_dia != "") {
                printf "}"
                printf ","
            }
            printf "\"%s\":{", dia
            usado_dia[dia] = 1
            sep_canal[dia] = ""
            sep_dia = ","
        }

        if (sep_canal[dia] != "") {
            printf ","
        }

        printf "\"%s\":{\"tiempo_respuesta_promedio\":%.2f,\"nota_satisfaccion_promedio\":%.2f}", canal, tiempo_prom, nota_prom
        sep_canal[dia] = ","
    }

    printf "}}"
}

