BEGIN{
    #convierto la lista en una array y la hago case-insensitive 
    n = split(tolower(lista), claves, ",")
    #separo lista, lo guardo en claves, y se separa por coma
    bandera = 0
}

{
    linea = tolower($0)
    for(i=1; i<=n; i++){
        if(index(linea, claves[i]) > 0){
            conteo[claves[i]]++
            bandera = 1
        }
    }
}

END{
    if(bandera == 0){
        printf("No hubieron ocurrencias\n")
    }
    else{
        for (p in conteo) {
            print p ": " conteo[p]
        }
    }
}