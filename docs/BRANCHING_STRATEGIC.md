## Estrategia de branching (Git)

Ramas principales:
- `main`: contiene las versiones estables, listas para producción.
- `develop`: integración continua de funcionalidades del sprint.

Ramas auxiliares:
- `feature/<nombre>`: desarrollo de nuevas features. Base = `develop`.
- `hotfix/<nombre>`: correcciones urgentes sobre producción. Base = `main`.

Flujo:
1. Se crea una issue en Jira (historia de usuario).
2. Se crea una rama `feature/<issue-id>-<nombre>` desde `develop`.
3. Se realiza el desarrollo y se envía un Pull Request hacia `develop`.
4. Tras revisión y aprobación, se hace merge a `develop`.
5. Al cerrar el sprint o preparar una release, se mergea `develop` en `main` y se crea un tag.
