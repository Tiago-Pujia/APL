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
    printf "{"
    firstDay = 1

    for (key in suma_tiempo) {
        split(key, partes, "|")
        dia = partes[1]
        canal = partes[2]

        tiempo_prom = suma_tiempo[key] / cuenta[key]
        nota_prom   = suma_nota[key] / cuenta[key]

        if (!(dia in usado_dia)) {
            if (!firstDay) { printf "}," }
            printf "\"%s\":{", dia
            usado_dia[dia] = 1
            firstDay = 0
            sep_canal = ""
        }

        if (sep_canal != "") { printf "," }
        printf "\"%s\":{\"tiempo_respuesta_promedio\":%.2f,\"nota_satisfaccion_promedio\":%.2f}", canal, tiempo_prom, nota_prom
        sep_canal = ","
    }

    printf "}}"

    if (errores > 0) {
        printf "\nProcesamiento finalizado con %d errores\n", errores > "/dev/stderr"
        exit 1
    }
}
