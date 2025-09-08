#!/usr/bin/awk -f

BEGIN {
  # Mapear letras a índices
  map["A"]=1; map["B"]=2; map["C"]=3; map["D"]=4
  rmap[1]="A"; rmap[2]="B"; rmap[3]="C"; rmap[4]="D"

  # Validar origen/destino
  if (!(ORIGEN in map) || !(DESTINO in map)) {
    print "Error: defina ORIGEN y DESTINO como A, B, C o D"
    exit 1
  }
  SRC = map[ORIGEN]
  DST = map[DESTINO]

  INF = 10^9
  n = 0
}

{
  # Leer la matriz (4x4)
  n++
  for (j=1; j<=NF; j++) {
    val = $j + 0
    if (n == j) {
      w[n,j] = 0      # diagonal
    } else if (val == 0) {
      w[n,j] = -1     # 0 fuera diagonal = sin conexión
    } else {
      w[n,j] = val
    }
  }
}

END {
  if (n != 4) {
    print "Error: se esperaban 4 filas con 4 columnas"
    exit 1
  }

  # Inicialización
  for (i=1; i<=4; i++) {
    dist[i] = INF
    prev[i] = 0
    visited[i] = 0
  }
  dist[SRC] = 0

  # Algoritmo de Dijkstra
  for (k=1; k<=4; k++) {
    u=0; best=INF
    for (i=1; i<=4; i++) {
      if (!visited[i] && dist[i] < best) {
        best = dist[i]; u=i
      }
    }
    if (u==0) break
    visited[u] = 1

    for (v=1; v<=4; v++) {
      if (w[u,v] >= 0) {
        alt = dist[u] + w[u,v]
        if (alt < dist[v]) {
          dist[v] = alt
          prev[v] = u
        }
      }
    }
  }

  # Reconstrucción de camino
  if (dist[DST] >= INF/2) {
    printf("No existe camino de %s a %s\n", ORIGEN, DESTINO)
    exit
  }

  path=""
  cur = DST
  while (cur != 0) {
    if (path == "")
      path = rmap[cur]
    else
      path = rmap[cur] " -> " path
    cur = prev[cur]
  }

  printf("Camino más corto de %s a %s: costo = %d | %s\n", ORIGEN, DESTINO, dist[DST], path)
}