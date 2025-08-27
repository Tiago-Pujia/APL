# !/bin/bash

# Lote 1
cat <<EOL > encuesta_1.txt
ID_ENCUESTA|FECHA|CANAL|TIEMPO_RESPUESTA|NOTA_SATISFACCION
101|2025-07-01 10:22:33|Telefono|5.5|4
102|2025-07-01 12:23:11|Email|120|5
103|2025-07-01 22:34:43|Chat|2.1|3
104|2025-07-01 09:15:00|Telefono|6.0|5
105|2025-07-01 14:40:21|Chat|3.2|4
106|2025-07-01 16:50:11|Email|100|4
EOL

# Lote 2
cat <<EOL > encuesta_2.txt
ID_ENCUESTA|FECHA|CANAL|TIEMPO_RESPUESTA|NOTA_SATISFACCION
201|2025-07-02 08:10:11|Telefono|4.5|3
202|2025-07-02 09:22:33|Email|110|5
203|2025-07-02 11:33:44|Chat|1.8|2
204|2025-07-02 12:55:22|Telefono|5.2|4
205|2025-07-02 15:40:00|Chat|2.5|3
EOL

# Lote 3
cat <<EOL > encuesta_3.txt
ID_ENCUESTA|FECHA|CANAL|TIEMPO_RESPUESTA|NOTA_SATISFACCION
301|2025-07-03 09:00:00|Email|130|5
302|2025-07-03 10:20:30|Telefono|6.8|4
303|2025-07-03 13:15:10|Chat|2.2|3
304|2025-07-03 14:00:00|Email|120|4
305|2025-07-03 18:30:45|Telefono|5.5|5
EOL

echo "Archivos de prueba creados en $(pwd)\n"


echo -e "\nIniciando tests con archivo 1..."
./ejercicio1.sh -d encuesta_1.txt -a test.json -p

echo -e "\nIniciando tests con archivo 2..."
./ejercicio1.sh -d encuesta_2.txt -a test.json -p

echo -e "\nIniciando tests con archivo 3..."
./ejercicio1.sh -d encuesta_3.txt -a test.json -p

rm encuesta_1.txt encuesta_2.txt encuesta_3.txt test.json
echo -e "\nArchivos de prueba eliminados."