BEGIN{
    #convierto la lista en una array y la hago case-insensitive 
    n = split(tolower(lista), claves, ",")
    #separo lista, lo guardo en claves, y se separa por coma
    print "se encontraron " n " palabras"
}

{
    linea = tolower($0)
    for(i=1; i<=n; i++){
        if(index(linea, claves[i]) > 0){
            conteo[claves[i]]++
        }
    }
}

END{
    for (p in conteo) {
        print p ": " conteo[p]
    }
}