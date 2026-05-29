#include <WiFi.h>
#include <WebServer.h>
#include <ESP32Servo.h>
#include "time.h"

const char* ssid = "Molina169";
const char* password = "1234abcdmolina";

const char* ntpServer = "pool.ntp.org";
const long gmtOffset_sec = -14400;
const int daylightOffset_sec = 0;

WebServer server(80);

Servo puerta;
Servo cama;

// ====== GPIO PARA ESP32-S3 ======
int led = 48;
int buzzer = 16;

// ================================

String historial = "";

// ====== FECHA Y HORA ======

String obtenerFechaHora(){

  struct tm timeinfo;

  if(!getLocalTime(&timeinfo)){
    return "Sin hora";
  }

  char buffer[30];

  strftime(buffer,30,"%d/%m/%Y %H:%M:%S",&timeinfo);

  return String(buffer);

}

// ===========================

void agregarHistorial(String texto){

  historial += obtenerFechaHora() + " - " + texto + "<br>";

}

// ====== PAGINA WEB ======

String pagina(){

String html = R"rawliteral(

<!DOCTYPE html>
<html>

<head>

<title>Asistente Hospitalario Inteligente</title>

<meta name="viewport" content="width=device-width, initial-scale=1">

<style>

body{
font-family:Arial;
background:#eaf4ff;
text-align:center;
padding:20px;
margin:0;
}

h1{
color:#1565c0;
margin-bottom:30px;
}

button{

width:240px;
height:65px;
font-size:18px;
margin:10px;
border:none;
border-radius:15px;
color:white;
cursor:pointer;
font-weight:bold;

}

button:hover{
opacity:0.85;
}

.luz{
background:#43a047;
}

.puerta{
background:#1e88e5;
}

.cama{
background:#fb8c00;
}

.alarma{
background:#e53935;
}

.borrar{
background:#212121;
}

.pdf{
background:#6a1b9a;
}

.historial{

width:90%;
margin:auto;
margin-top:30px;
background:white;
padding:20px;
border-radius:15px;
box-shadow:0px 0px 15px rgba(0,0,0,0.2);
text-align:left;
font-size:16px;

}

.estado{

margin-top:20px;
font-size:18px;
font-weight:bold;
color:#333;

}

</style>

</head>

<body>

<h1>ASISTENTE HOSPITALARIO</h1>

<div class="estado">
Sistema conectado correctamente
</div>

<br>

<button class='luz' onclick="fetch('/luzon').then(()=>location.reload())">
LUZ ON
</button>

<button class='luz' onclick="fetch('/luzoff').then(()=>location.reload())">
LUZ OFF
</button>

<br>

<button class='puerta' onclick="fetch('/abrir').then(()=>location.reload())">
ABRIR PUERTA
</button>

<button class='puerta' onclick="fetch('/cerrar').then(()=>location.reload())">
CERRAR PUERTA
</button>

<br>

<button class='cama' onclick="fetch('/subir').then(()=>location.reload())">
SUBIR CAMA
</button>

<button class='cama' onclick="fetch('/bajar').then(()=>location.reload())">
BAJAR CAMA
</button>

<br>

<button class='alarma' onclick="fetch('/alarma').then(()=>location.reload())">
ACTIVAR ALARMA
</button>

<br>

<button class='borrar' onclick="fetch('/borrar').then(()=>location.reload())">
BORRAR HISTORIAL
</button>

<button class='pdf' onclick="window.print()">
GUARDAR PDF
</button>

<div class='historial'>

<h2>Historial del Sistema</h2>

)rawliteral";

html += historial;

html += R"rawliteral(

</div>

</body>
</html>

)rawliteral";

return html;

}

// ==========================

void inicio(){

server.send(200,"text/html",pagina());

}

// ====== LUZ ======

void luzOn(){

digitalWrite(led,HIGH);

agregarHistorial("Luz encendida");

server.send(200,"text/plain","OK");

}

void luzOff(){

digitalWrite(led,LOW);

agregarHistorial("Luz apagada");

server.send(200,"text/plain","OK");

}

// ====== PUERTA ======

void abrirPuerta(){

puerta.write(90);

agregarHistorial("Puerta abierta");

server.send(200,"text/plain","OK");

}

void cerrarPuerta(){

puerta.write(0);

agregarHistorial("Puerta cerrada");

server.send(200,"text/plain","OK");

}

// ====== CAMA ======

void subirCama(){

cama.write(90);

agregarHistorial("Cama subida");

server.send(200,"text/plain","OK");

}

void bajarCama(){

cama.write(0);

agregarHistorial("Cama bajada");

server.send(200,"text/plain","OK");

}

// ====== ALARMA ======

void activarAlarma(){

digitalWrite(buzzer,HIGH);

delay(1000);

digitalWrite(buzzer,LOW);

agregarHistorial("Alarma activada");

server.send(200,"text/plain","OK");

}

// ====== BORRAR HISTORIAL ======

void borrarHistorial(){

historial = "";

agregarHistorial("Historial reiniciado");

server.send(200,"text/plain","OK");

}

// ====== SETUP ======

void setup(){

Serial.begin(115200);

pinMode(led,OUTPUT);

pinMode(buzzer,OUTPUT);

// ====== SERVOS ESP32-S3 ======

puerta.attach(18);

cama.attach(17);

// ==============================

WiFi.begin(ssid,password);

Serial.println("Conectando WiFi");

while(WiFi.status()!=WL_CONNECTED){

delay(500);

Serial.print(".");

}

Serial.println("");

Serial.println("WiFi conectado");

configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);

Serial.print("IP del ESP32: ");

Serial.println(WiFi.localIP());

server.on("/",inicio);

server.on("/luzon",luzOn);

server.on("/luzoff",luzOff);

server.on("/abrir",abrirPuerta);

server.on("/cerrar",cerrarPuerta);

server.on("/subir",subirCama);

server.on("/bajar",bajarCama);

server.on("/alarma",activarAlarma);

server.on("/borrar",borrarHistorial);

server.begin();

Serial.println("Servidor iniciado");

agregarHistorial("Sistema iniciado correctamente");

}

// ====== LOOP ======

void loop(){

server.handleClient();

}
