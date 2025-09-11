#!/usr/bin/awk -f
BEGIN {
    for(i = 1 ; i <= 4 ; i++){
        conexiones[i] = 0
    }
    n = 0
    count = 1
}

{
    n++
    for(j = 1 ; j <= NF ; j++){
        val = $j + 0
        if(n != j && val != 0){
            conexiones[n]++
        }
    }
}

END {
    estHub = "1"
    conexMax = conexiones[1]
    for(i = 2 ; i <= n ; i++){
        if(conexiones[i] > conexMax){
            estHub = "" i
            conexMax = conexiones[i]
            count = 1
        }
        else if(conexiones[i] == conexMax){
            estHub = estHub " " i
            count++
        }
    }

    if(count == 1){
         printf("**Hub de la red:** Estación %s (%d conexiones)\n", estHub, conexMax)
    }
    else{
        printf("**Hub de la red:** Estaciones %s (%d conexiones)\n", estHub, conexMax)
    }
}