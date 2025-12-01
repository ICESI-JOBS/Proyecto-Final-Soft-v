# Estrategia de Branching — GitFlow

Este documento define el flujo de ramas utilizado para el proyecto

---

## Ramas Principales

### `main`
- Contiene únicamente versiones estables.
- Toda entrega a producción proviene desde una rama `release/*` o `hotfix/*`.

### `develop`
- Rama donde se integran todas las funcionalidades del sprint.
- Punto de partida para cualquier nueva feature.

---

## Ramas Auxiliares

### `feature/<issue-id>-<nombre>`
- Usadas para desarrollar nuevas funcionalidades.
- Se crean desde `develop`.
- Deben tener un Pull Request (PR) hacia `develop`.

### `release/<version>`
- Se crean desde `develop`.
- Permiten preparar una versión para producción.
- Al finalizar: merge a `main` y `develop`, y creación de tag.

### `hotfix/<nombre>`
- Se crean desde `main`.
- Se usan para corregir problemas críticos en producción.
- Se mergean a `main` y `develop`.

---

## Flujo de Trabajo Completo

1. Crear una historia de usuario en Jira.
2. Crear una rama basada en la historia:  
   `feature/PROY-XX-nombre-claro`
3. Implementar cambios y realizar commits siguiendo Conventional Commits.
4. Crear Pull Request hacia `develop`.
5. Obtener al menos **una aprobación obligatoria**.
6. Esperar validación del pipeline CI.
7. Mergear hacia `develop`.
8. Para entregar una versión:
   - Crear rama `release/X.Y.Z`.
   - Validar CI.
   - Merge en `main`.
   - Crear tag `vX.Y.Z`.

---

## Convenciones
- Nombre de ramas: `tipo/issue-descriptivo`.
- Commits basados en Conventional Commits.
- PRs obligatorios para todo merge.
