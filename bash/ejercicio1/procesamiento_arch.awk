#!/usr/bin/awk -f

function isnumeric(x) {
    return (x ~ /^[-+]?[0-9]*\.?[0-9]+$/)
}

BEGIN {
    FS="|"
    errores = 0
}

{
    # Validar: deben existir 5 campos
    if (NF != 5) {
        printf "WARNING: Formato inválido en %s linea %d: NF=%d\n", FILENAME, FNR, NF > "/dev/stderr"
        errores++
        next
    }

    fecha = $2
    canal = $3
    tiempo = $4
    nota = $5

    # Trim simples (elimina espacios al inicio/fin)
    gsub(/^[ \t]+|[ \t]+$/, "", fecha)
    gsub(/^[ \t]+|[ \t]+$/, "", canal)
    gsub(/^[ \t]+|[ \t]+$/, "", tiempo)
    gsub(/^[ \t]+|[ \t]+$/, "", nota)

    # Validar que tiempo y nota sean numéricos
    if (!isnumeric(tiempo) || !isnumeric(nota)) {
        printf "WARNING: Valores no numéricos en %s linea %d: tiempo='%s' nota='%s'\n", FILENAME, FNR, tiempo, nota > "/dev/stderr"
        errores++
        next
    }

    split(fecha, f, " ")
    fecha = f[1]

    key = fecha "|" canal
    suma_tiempo[key] += (tiempo + 0)
    suma_nota[key]   += (nota + 0)
    cuenta[key]++
}

END {
    # Crear array ordenado de fechas
    n = 0
    for (key in suma_tiempo) {
        split(key, partes, "|")
        dia = partes[1]
        if (!(dia in dias_unicos)) {
            dias_unicos[dia] = 1
            dias_array[++n] = dia
        }
    }

    # Ordenar las fechas (array de strings que son fechas YYYY-MM-DD)
    for (i = 1; i <= n; i++) {
        for (j = i + 1; j <= n; j++) {
            if (dias_array[i] > dias_array[j]) {
                temp = dias_array[i]
                dias_array[i] = dias_array[j]
                dias_array[j] = temp
            }
        }
    }

    printf "{"
    firstDay = 1

    # Iterar por fechas ordenadas
    for (i = 1; i <= n; i++) {
        dia = dias_array[i]
        
        if (!firstDay) { printf "}," }
        printf "\"%s\":{", dia
        firstDay = 0
        
        sep_canal = ""
        # Obtener todos los canales para este día
        canal_count = 0
        for (key in suma_tiempo) {
            split(key, partes, "|")
            if (partes[1] == dia) {
                canal_array[++canal_count] = partes[2]
            }
        }
        
        # Ordenar canales alfabéticamente
        for (j = 1; j <= canal_count; j++) {
            for (k = j + 1; k <= canal_count; k++) {
                if (canal_array[j] > canal_array[k]) {
                    temp = canal_array[j]
                    canal_array[j] = canal_array[k]
                    canal_array[k] = temp
                }
            }
        }
        
        # Imprimir canales ordenados
        for (j = 1; j <= canal_count; j++) {
            canal = canal_array[j]
            key = dia "|" canal
            
            tiempo_prom = suma_tiempo[key] / cuenta[key]
            nota_prom   = suma_nota[key] / cuenta[key]
            
            if (sep_canal != "") { printf "," }
            # Formatear nota como entero si es un número entero
            if (nota_prom == int(nota_prom)) {
                printf "\"%s\":{\"tiempo_respuesta_promedio\":%.1f,\"nota_satisfaccion_promedio\":%d}", canal, tiempo_prom, int(nota_prom)
            } else {
                printf "\"%s\":{\"tiempo_respuesta_promedio\":%.1f,\"nota_satisfaccion_promedio\":%.2f}", canal, tiempo_prom, nota_prom
            }
            sep_canal = ","
        }
    }

    printf "}}"

    if (errores > 0) {
        printf "\nProcesamiento finalizado con %d errores\n", errores > "/dev/stderr"
        exit 1
    }
}
