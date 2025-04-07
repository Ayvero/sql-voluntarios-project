-- =====================================
-- 📊 CONSULTAS SQL - Base de datos de Voluntarios
-- Proyecto académico - Portfolio Back-End
-- =====================================
-- Las siguientes consultas fueron realizadas sobre una base de datos relacional PostgreSQL.
-- La estructura simula un sistema de gestión de voluntarios e instituciones.
-- Se incluye también una sección final con reglas de negocio expresadas en SQL.

-- =====================
-- 🟢 CONSULTAS SELECT
-- =====================

-- 1. Listar el ID y nombre de todas las instituciones cuyo nombre incluye la palabra "FUNDACION".
-- Útil para filtrar organizaciones del tipo fundación dentro del sistema.
SELECT id_institucion, nombre_institucion
FROM unc_esq_voluntario.institucion
WHERE nombre_institucion LIKE '%FUNDACION%';

-- 2. Obtener el apellido y tarea asignada de voluntarios que no tienen coordinador.
-- Puede servir para identificar casos donde falta supervisión.
SELECT apellido, id_tarea
FROM unc_esq_voluntario.voluntario
WHERE id_coordinador IS NULL;

-- 3. Listar apellido, nombre completo y correo de voluntarios cuyo teléfono comienza con +51 (Perú).
-- Se formatea el nombre completo y se personalizan los encabezados de columnas.
SELECT apellido || ', ' || nombre AS "Apellido y Nombre",
       e_mail AS "Dirección de mail"
FROM unc_esq_voluntario.voluntario
WHERE telefono LIKE '+51%';

-- 4. Mostrar la cantidad mínima, máxima y promedio estimado de horas aportadas
-- por voluntarios nacidos desde 1990 en adelante.
SELECT min_horas, max_horas,
       ((min_horas + max_horas) / 2) AS "Promedio estimado",
       v.nombre, v.fecha_nacimiento
FROM unc_esq_voluntario.tarea t
JOIN unc_esq_voluntario.voluntario v ON t.id_tarea = v.id_tarea
WHERE EXTRACT(YEAR FROM v.fecha_nacimiento) > 1989;

-- 5. Mostrar la cantidad de cumpleaños de voluntarios agrupados por mes.
-- Útil para planificar actividades o campañas mensuales.
SELECT EXTRACT(MONTH FROM fecha_nacimiento) AS "Mes",
       COUNT(*) AS "Cantidad"
FROM unc_esq_voluntario.voluntario
GROUP BY EXTRACT(MONTH FROM fecha_nacimiento)
ORDER BY "Mes";


-- 6. Obtener las dos instituciones con mayor cantidad de voluntarios registrados.
-- Permite identificar las organizaciones con mayor participación y alcance del voluntariado.
SELECT id_institucion, COUNT(nro_voluntario) AS "Cantidad de voluntarios"
FROM unc_esq_voluntario.voluntario
GROUP BY id_institucion
ORDER BY "Cantidad de voluntarios" DESC
LIMIT 2;

-- 7. Mostrar tareas cuyo promedio de horas aportadas por voluntarios nacidos desde 1995
-- supera el promedio general de ese grupo etario. Sirve para detectar tareas que reciben
-- mayor dedicación por parte de jóvenes y orientar programas futuros.
SELECT id_tarea, AVG(horas_aportadas) AS "Promedio de horas aportadas"
FROM unc_esq_voluntario.voluntario
WHERE EXTRACT(YEAR FROM fecha_nacimiento) > 1994
GROUP BY id_tarea
HAVING AVG(horas_aportadas) > (
    SELECT AVG(horas_aportadas)
    FROM unc_esq_voluntario.voluntario
    WHERE EXTRACT(YEAR FROM fecha_nacimiento) > 1994
);

-- 8. Contar cuántos voluntarios aportan horas activamente por cada institución.
-- Se excluyen voluntarios sin horas registradas. Útil para medir impacto real por institución.
SELECT i.nombre_institucion,
       COUNT(v.nro_voluntario) AS "Cantidad de voluntarios"
FROM unc_esq_voluntario.institucion i
JOIN unc_esq_voluntario.voluntario v ON i.id_institucion = v.id_institucion
WHERE v.horas_aportadas IS NOT NULL
GROUP BY i.nombre_institucion
ORDER BY i.nombre_institucion;

-- 9. Obtener cuántos coordinadores hay por país y continente.
-- Ayuda a analizar la distribución geográfica del liderazgo dentro del voluntariado.
SELECT COUNT(v.id_coordinador) AS "Número de coordinadores",
       p.nombre_pais,
       c.nombre_continente
FROM unc_esq_voluntario.voluntario v
JOIN unc_esq_voluntario.institucion i ON i.id_institucion = v.id_institucion
JOIN unc_esq_voluntario.direccion d ON d.id_direccion = i.id_direccion
JOIN unc_esq_voluntario.pais p ON p.id_pais = d.id_pais
JOIN unc_esq_voluntario.continente c ON c.id_continente = p.id_continente
GROUP BY p.nombre_pais, c.nombre_continente;

-- 10. Listar voluntarios que pertenecen a la misma institución que 'Zlotkey', excepto él mismo.
-- Permite identificar el entorno colaborativo inmediato de un voluntario específico.
SELECT apellido, nombre, fecha_nacimiento, id_institucion
FROM unc_esq_voluntario.voluntario
WHERE id_institucion IN (
    SELECT id_institucion
    FROM unc_esq_voluntario.voluntario
    WHERE apellido = 'Zlotkey'
)
AND apellido != 'Zlotkey'
ORDER BY apellido DESC;

-- 11. Voluntarios cuya cantidad de horas aportadas supera la media general.
-- Esta consulta permite destacar casos de alta dedicación dentro del voluntariado.
SELECT nro_voluntario, apellido, horas_aportadas
FROM unc_esq_voluntario.voluntario
GROUP BY nro_voluntario, apellido, horas_aportadas
HAVING horas_aportadas > (
    SELECT AVG(horas_aportadas)
    FROM unc_esq_voluntario.voluntario
)
ORDER BY horas_aportadas ASC;


-- ===========================
-- 🔒 REGLAS DE NEGOCIO / RESTRICCIONES
-- ===========================

-- 12. REGLA DE NEGOCIO: No puede haber voluntarios de más de 70 años.
-- Según la política de la organización, no pueden participar personas que superen esa edad.
SELECT nro_voluntario
FROM voluntario
WHERE fecha_nacimiento <= current_date - INTERVAL '70 years';

-- Comentario: Para cumplir esta restricción automáticamente, se sugiere aplicar una validación
-- a nivel de aplicación o una regla CHECK con triggers, ya que PostgreSQL no permite CHECKs
-- con funciones como current_date directamente.

-- 13. Ningún voluntario puede aportar más horas que su coordinador.
-- Asegura una lógica jerárquica y de coherencia en los aportes dentro del equipo.
SELECT v1.nro_voluntario, v1.horas_aportadas AS "Horas voluntario",
       v2.horas_aportadas AS "Horas coordinador"
FROM voluntario v1
JOIN voluntario v2 ON v1.id_coordinador = v2.nro_voluntario
WHERE v1.horas_aportadas > v2.horas_aportadas;

-- Comentario: Esta restricción tampoco puede implementarse directamente con un CHECK.
-- Se sugiere una ASSERTION (no soportada en PostgreSQL) o lógica de validación por trigger.

-- 14. Las horas aportadas por un voluntario deben estar dentro del rango definido en la tarea.
-- Asegura que los datos cargados respeten los parámetros establecidos por la organización.
SELECT v1.nro_voluntario
FROM voluntario v1
JOIN tarea t ON t.id_tarea = v1.id_tarea
WHERE v1.horas_aportadas NOT BETWEEN min_horas AND max_horas;

-- 15. El voluntario debe tener asignada la misma tarea que su coordinador.
-- Refleja una estructura donde el coordinador lidera un grupo que realiza una tarea específica.
SELECT v1.nro_voluntario
FROM voluntario v1
JOIN voluntario v2 ON v1.id_coordinador = v2.nro_voluntario
WHERE v1.id_tarea <> v2.id_tarea;

-- 16. Validar que en el histórico, la fecha de inicio sea anterior a la de finalización.
-- Evita errores en el registro cronológico de actividades pasadas del voluntario.
SELECT nro_voluntario, fecha_inicio, fecha_fin
FROM historico
WHERE fecha_fin < fecha_inicio;

























-- 6. Mostrar las dos instituciones que más voluntarios tienen registrados.
SELECT id_institucion, COUNT(nro_voluntario) AS "Cantidad de voluntarios"
FROM unc_esq_voluntario.voluntario
GROUP BY id_institucion
ORDER BY "Cantidad de voluntarios" DESC
LIMIT 2;

-- 7. Tareas cuyo promedio de horas aportadas por voluntarios nacidos desde 1995
-- es superior al promedio general de dicho grupo.
SELECT id_tarea, AVG(horas_aportadas) AS "Promedio de horas aportadas"
FROM unc_esq_voluntario.voluntario
WHERE EXTRACT(YEAR FROM fecha_nacimiento) > 1994
GROUP BY id_tarea
HAVING AVG(horas_aportadas) > (
    SELECT AVG(horas_aportadas)
    FROM unc_esq_voluntario.voluntario
    WHERE EXTRACT(YEAR FROM fecha_nacimiento) > 1994
);

-- 8. Listar cada institución junto con la cantidad de voluntarios que realizan aportes.
-- Solo se cuentan aquellos con horas registradas.
SELECT i.nombre_institucion,
       COUNT(v.nro_voluntario) AS "Cantidad de voluntarios"
FROM unc_esq_voluntario.institucion i
JOIN unc_esq_voluntario.voluntario v ON i.id_institucion = v.id_institucion
WHERE v.horas_aportadas IS NOT NULL
GROUP BY i.nombre_institucion
ORDER BY i.nombre_institucion;

-- 9. Contar la cantidad de coordinadores por país y continente.
SELECT COUNT(v.id_coordinador) AS "Número de coordinadores",
       p.nombre_pais,
       c.nombre_continente
FROM unc_esq_voluntario.voluntario v
JOIN unc_esq_voluntario.institucion i ON i.id_institucion = v.id_institucion
JOIN unc_esq_voluntario.direccion d ON d.id_direccion = i.id_direccion
JOIN unc_esq_voluntario.pais p ON p.id_pais = d.id_pais
JOIN unc_esq_voluntario.continente c ON c.id_continente = p.id_continente
GROUP BY p.nombre_pais, c.nombre_continente;

-- 10. Listar voluntarios que trabajan en la misma institución que el voluntario de apellido 'Zlotkey',
-- excluyéndolo del resultado.
SELECT apellido, nombre, fecha_nacimiento, id_institucion
FROM unc_esq_voluntario.voluntario
WHERE id_institucion IN (
    SELECT id_institucion
    FROM unc_esq_voluntario.voluntario
    WHERE apellido = 'Zlotkey'
)
AND apellido != 'Zlotkey'
ORDER BY apellido DESC;

-- 11. Voluntarios cuya cantidad de horas aportadas es mayor que la media.
SELECT nro_voluntario, apellido, horas_aportadas
FROM unc_esq_voluntario.voluntario
GROUP BY nro_voluntario, apellido, horas_aportadas
HAVING horas_aportadas > (
    SELECT AVG(horas_aportadas)
    FROM unc_esq_voluntario.voluntario
)
ORDER BY horas_aportadas ASC;

-- ================================
-- 🔒 REGLAS DE NEGOCIO / RESTRICCIONES
-- ================================

-- 12. No puede haber voluntarios de más de 70 años.
SELECT nro_voluntario
FROM voluntario
WHERE fecha_nacimiento <= current_date - INTERVAL '70 years';

-- CHECK sugerido (no compatible directamente con PostgreSQL sin trigger):
-- ALTER TABLE voluntario ADD CONSTRAINT ck_voluntario_edad
-- CHECK (fecha_nacimiento > current_date - INTERVAL '70 years');

-- 13. Ningún voluntario puede aportar más horas que su coordinador.
SELECT v1.nro_voluntario, v1.horas_aportadas, v2.horas_aportadas
FROM voluntario v1
JOIN voluntario v2 ON v1.id_coordinador = v2.nro_voluntario
WHERE v1.horas_aportadas > v2.horas_aportadas;

-- Assertion teórica:
-- CREATE ASSERTION horas_max
-- CHECK (NOT EXISTS (
--     SELECT 1 FROM voluntario v1
--     JOIN voluntario v2 ON v1.id_coordinador = v2.nro_voluntario
--     WHERE v1.horas_aportadas > v2.horas_aportadas
-- ));

-- 14. Las horas aportadas deben estar entre los valores mínimo y máximo definidos en la tarea.
SELECT v1.nro_voluntario
FROM voluntario v1
JOIN tarea t ON t.id_tarea = v1.id_tarea
WHERE v1.horas_aportadas NOT BETWEEN min_horas AND max_horas;

-- 15. Todos los voluntarios deben realizar la misma tarea que su coordinador.
SELECT v1.nro_voluntario
FROM voluntario v1
JOIN voluntario v2 ON v1.id_coordinador = v2.nro_voluntario
WHERE v1.id_tarea <> v2.id_tarea;

-- 16. En el histórico, la fecha de inicio debe ser anterior a la fecha de finalización.
SELECT nro_voluntario, fecha_inicio, fecha_fin
FROM historico
WHERE fecha_fin < fecha_inicio;
