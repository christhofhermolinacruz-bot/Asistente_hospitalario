"""
============================================================
  BACKEND PYTHON — Asistente Hospitalario
  Framework: Flask
  Base de datos: MySQL (mysql-connector-python)
  Encriptación: hashlib SHA-256
  Universidad Salesiana de Bolivia
============================================================

INSTALACIÓN (ejecutar en cmd/terminal):
    pip install flask
    pip install flask-cors
    pip install mysql-connector-python

EJECUTAR:
    python backend.py
    Servidor en: http://localhost:5000
============================================================
"""

# ── Librerías ──────────────────────────────────────────────
from flask import Flask, request, jsonify   # Framework web
from flask_cors import CORS                  # Permite conexión desde el HTML
import mysql.connector                       # Conexión a MySQL
from mysql.connector import Error
import hashlib                               # Encriptación de contraseña
import re                                    # Validación con expresiones regulares
from datetime import datetime

# ── Aplicación Flask ───────────────────────────────────────
app = Flask(__name__)
CORS(app)  # Habilita peticiones desde el navegador (HTML → Python)

# ── Configuración de la base de datos ─────────────────────
DB_CONFIG = {
    "host":     "localhost",
    "port":     3306,
    "user":     "root",        # Tu usuario MySQL
    "password": "",            # Tu contraseña (XAMPP = vacío)
    "database": "asistente_hospitalario"
}


# ============================================================
# FUNCIÓN: Conectar a MySQL
# ============================================================
def conectar_bd():
    """Retorna una conexión activa a la base de datos."""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except Error as e:
        print(f"❌ Error de conexión BD: {e}")
        return None


# ============================================================
# FUNCIÓN: Encriptar contraseña con SHA-256
# ============================================================
def encriptar_password(password: str) -> str:
    """
    Convierte la contraseña en texto plano a SHA-256.
    Ejemplo: 'mi123' → 'a4c2f8e...' (64 caracteres hex)
    """
    return hashlib.sha256(password.encode('utf-8')).hexdigest()


# ============================================================
# FUNCIÓN: Validar datos del formulario
# ============================================================
def validar_registro(data: dict) -> list:
    """
    Recibe el diccionario de datos del formulario.
    Retorna lista de errores (vacía si todo está bien).
    """
    errores = []

    if not data.get('nombre', '').strip():
        errores.append('El nombre es requerido')

    if not data.get('apellido', '').strip():
        errores.append('El apellido es requerido')

    if not data.get('usuario', '').strip():
        errores.append('El usuario es requerido')

    if len(data.get('password', '')) < 8:
        errores.append('La contraseña debe tener mínimo 8 caracteres')

    roles_validos = ['MEDICO', 'ENFERMERO', 'FAMILIAR', 'ADMIN']
    if data.get('rol') not in roles_validos:
        errores.append(f'Rol inválido. Debe ser uno de: {roles_validos}')

    # Validar email si se proporcionó
    email = data.get('email', '')
    if email and not re.match(r'^[^@]+@[^@]+\.[^@]+$', email):
        errores.append('El correo electrónico no es válido')

    return errores


# ============================================================
# RUTA: POST /registro
# Registra un nuevo miembro del personal médico
# ============================================================
@app.route('/registro', methods=['POST'])
def registro():
    """
    Recibe JSON desde el formulario HTML y guarda en la BD.

    JSON esperado:
    {
        "nombre":   "Carlos",
        "apellido": "Mamani",
        "rol":      "ENFERMERO",
        "usuario":  "cmamani",
        "password": "mi_clave_123",
        "email":    "c@hospital.bo"  (opcional)
    }
    """
    data = request.get_json()

    # 1. Validar datos
    errores = validar_registro(data)
    if errores:
        return jsonify({"exito": False, "errores": errores}), 400

    conn = conectar_bd()
    if not conn:
        return jsonify({"exito": False, "mensaje": "Error de conexión a la BD"}), 500

    try:
        cursor = conn.cursor(dictionary=True)

        # 2. Verificar que el usuario no exista ya
        cursor.execute(
            "SELECT id_usuario FROM usuarios_acceso WHERE usuario = %s",
            (data['usuario'],)
        )
        if cursor.fetchone():
            return jsonify({"exito": False, "mensaje": "El usuario ya existe"}), 409

        # 3. Insertar en personal_medico
        cursor.execute(
            """
            INSERT INTO personal_medico (nombre, apellido, rol)
            VALUES (%s, %s, %s)
            """,
            (
                data['nombre'].strip(),
                data['apellido'].strip(),
                data['rol']
            )
        )
        id_personal = cursor.lastrowid  # ID generado automáticamente

        # 4. Encriptar contraseña y guardar en usuarios_acceso
        hash_pwd = encriptar_password(data['password'])
        cursor.execute(
            """
            INSERT INTO usuarios_acceso (id_personal, usuario, contrasena_hash)
            VALUES (%s, %s, %s)
            """,
            (id_personal, data['usuario'].strip(), hash_pwd)
        )

        conn.commit()

        return jsonify({
            "exito":      True,
            "mensaje":    f"Usuario '{data['usuario']}' registrado correctamente",
            "id_personal": id_personal,
            "rol":         data['rol']
        }), 201

    except Error as e:
        conn.rollback()
        return jsonify({"exito": False, "mensaje": str(e)}), 500

    finally:
        cursor.close()
        conn.close()


# ============================================================
# RUTA: POST /login
# Inicia sesión verificando usuario y contraseña
# ============================================================
@app.route('/login', methods=['POST'])
def login():
    """
    JSON esperado:
    {
        "usuario":  "cmamani",
        "password": "mi_clave_123"
    }
    """
    data = request.get_json()
    usuario  = data.get('usuario', '').strip()
    password = data.get('password', '')

    if not usuario or not password:
        return jsonify({"exito": False, "mensaje": "Usuario y contraseña requeridos"}), 400

    conn = conectar_bd()
    if not conn:
        return jsonify({"exito": False, "mensaje": "Error de conexión"}), 500

    try:
        cursor = conn.cursor(dictionary=True)

        # Buscar usuario con JOIN a personal_medico
        cursor.execute(
            """
            SELECT
                ua.id_usuario,
                ua.usuario,
                ua.contrasena_hash,
                pm.nombre,
                pm.apellido,
                pm.rol,
                pm.id_personal
            FROM usuarios_acceso ua
            JOIN personal_medico pm ON ua.id_personal = pm.id_personal
            WHERE ua.usuario = %s
            """,
            (usuario,)
        )
        user = cursor.fetchone()

        if not user:
            return jsonify({"exito": False, "mensaje": "Usuario no encontrado"}), 404

        # Verificar contraseña
        hash_ingresado = encriptar_password(password)
        if hash_ingresado != user['contrasena_hash']:
            return jsonify({"exito": False, "mensaje": "Contraseña incorrecta"}), 401

        # Actualizar último acceso
        cursor.execute(
            "UPDATE usuarios_acceso SET ultimo_acceso = %s WHERE usuario = %s",
            (datetime.now(), usuario)
        )
        conn.commit()

        return jsonify({
            "exito":      True,
            "mensaje":    "Sesión iniciada correctamente",
            "usuario":    user['usuario'],
            "nombre":     user['nombre'],
            "apellido":   user['apellido'],
            "rol":        user['rol'],
            "id_personal": user['id_personal']
        }), 200

    except Error as e:
        return jsonify({"exito": False, "mensaje": str(e)}), 500

    finally:
        cursor.close()
        conn.close()


# ============================================================
# RUTA: GET /usuarios
# Lista todos los usuarios registrados
# ============================================================
@app.route('/usuarios', methods=['GET'])
def listar_usuarios():
    conn = conectar_bd()
    if not conn:
        return jsonify({"exito": False}), 500

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT
                pm.id_personal,
                pm.nombre,
                pm.apellido,
                pm.rol,
                ua.usuario,
                ua.ultimo_acceso
            FROM personal_medico pm
            LEFT JOIN usuarios_acceso ua ON ua.id_personal = pm.id_personal
            ORDER BY pm.rol, pm.apellido
            """
        )
        usuarios = cursor.fetchall()

        # Convertir datetime a string para JSON
        for u in usuarios:
            if u.get('ultimo_acceso'):
                u['ultimo_acceso'] = str(u['ultimo_acceso'])

        return jsonify({"exito": True, "usuarios": usuarios}), 200

    except Error as e:
        return jsonify({"exito": False, "mensaje": str(e)}), 500

    finally:
        cursor.close()
        conn.close()


# ============================================================
# RUTA: DELETE /usuarios/<id>
# Elimina un usuario del sistema
# ============================================================
@app.route('/usuarios/<int:id_personal>', methods=['DELETE'])
def eliminar_usuario(id_personal):
    conn = conectar_bd()
    if not conn:
        return jsonify({"exito": False}), 500

    try:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM usuarios_acceso  WHERE id_personal = %s", (id_personal,))
        cursor.execute("DELETE FROM personal_medico  WHERE id_personal = %s", (id_personal,))
        conn.commit()
        return jsonify({"exito": True, "mensaje": "Usuario eliminado"}), 200

    except Error as e:
        conn.rollback()
        return jsonify({"exito": False, "mensaje": str(e)}), 500

    finally:
        cursor.close()
        conn.close()


# ============================================================
# RUTA: GET /pacientes
# Lista pacientes (para el selector de Familiar)
# ============================================================
@app.route('/pacientes', methods=['GET'])
def listar_pacientes():
    conn = conectar_bd()
    if not conn:
        return jsonify({"exito": False}), 500

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT p.id_paciente,
                   CONCAT(p.nombre,' ',p.apellido) AS nombre_completo,
                   hab.numero AS habitacion
            FROM pacientes p
            JOIN habitaciones hab ON p.id_habitacion = hab.id_habitacion
            ORDER BY p.apellido
            """
        )
        return jsonify({"exito": True, "pacientes": cursor.fetchall()}), 200

    except Error as e:
        return jsonify({"exito": False, "mensaje": str(e)}), 500

    finally:
        cursor.close()
        conn.close()


# ============================================================
# INICIO DEL SERVIDOR
# ============================================================
if __name__ == '__main__':
    print("="*55)
    print("  BACKEND — Asistente Hospitalario")
    print("="*55)
    print("  Servidor: http://localhost:5000")
    print("  Endpoints:")
    print("    POST /registro  → Crear usuario")
    print("    POST /login     → Iniciar sesión")
    print("    GET  /usuarios  → Listar usuarios")
    print("    GET  /pacientes → Listar pacientes")
    print("="*55)
    app.run(debug=True, port=5000)
