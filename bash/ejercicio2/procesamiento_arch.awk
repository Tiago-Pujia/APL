#!/usr/bin/awk -f

BEGIN {
  SRC = ORIGEN + 0
  DST = DESTINO + 0

  INF = 10^9
  n = 0
}

{
  # Leer la matriz
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


  # Inicialización
  for (i=1; i<=n; i++) {
    dist[i] = INF
    prev[i] = 0
    visited[i] = 0
  }
  dist[SRC] = 0

  # Algoritmo de Dijkstra
  for (k=1; k<=n; k++) {
    u=0; best=INF
    for (i=1; i<=n; i++) {
      if (!visited[i] && dist[i] < best) {
        best = dist[i]; u=i
      }
    }
    if (u==0) break
    visited[u] = 1

    for (v=1; v<=n; v++) {
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
    printf("No existe camino de %d a %d\n", ORIGEN, DESTINO)
    exit
  }

  path=""
  cur = DST
  while (cur != 0) {
    if (path == "")
      path = cur
    else
      path = cur " -> " path
    cur = prev[cur]
  }

  printf("Camino más corto de %d a %d: costo = %d | %s\n", ORIGEN, DESTINO, dist[DST], path)
}