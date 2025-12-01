# Reglas para Pull Requests (PR)

## Objetivo
Garantizar calidad del código, trazabilidad y consistencia en el flujo de trabajo colaborativo del equipo.

---

## Reglas Generales

### 1. Rama destino
- Todo PR debe dirigirse a la rama `develop`.
- **Excepciones:**
  - PRs provenientes de una rama `release/*` pueden dirigirse a `main`.
  - PRs provenientes de `hotfix/*` deben dirigirse a `main` y luego replicarse en `develop`.

---

## Integración con CI/CD
- Todo PR debe disparar el pipeline CI automáticamente.
- El pipeline debe validar:
  - Compilación exitosa.
  - Pruebas unitarias.
  - Escaneo de vulnerabilidades (Trivy).
  - Análisis de código estático (SonarQube).

Si alguna validación falla, **el PR no puede ser aprobado**.

---

## Requisitos para aprobar un PR
- Mínimo **una aprobación obligatoria** de un miembro del equipo para los ambientes prod y stage.
- Revisión de código mediante checklist:
  - ¿Se siguen las convenciones de commits?
  - ¿Se mantiene el estándar de estructura del proyecto?
  - ¿No se exponen secretos o configuraciones sensibles?
  - ¿La funcionalidad coincide con la historia de usuario asignada?

---
