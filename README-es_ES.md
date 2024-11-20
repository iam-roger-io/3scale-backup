# README.md

Scripts para la implementación de backup y restore en 3scale versión 2.14, que utiliza las bases de datos generadas por el Operator.

Este script se basa en la documentación oficial disponible en: [Capítulo 9. Backup y restore de 3scale API Management](https://access.redhat.com/documentation/en-us/red_hat_3scale_api_management/2.14/html/operating_red_hat_3scale_api_management/threescale-backup-restore)

## Requisitos previos:

El script fue probado con:

- yq versión v4.43.1 (https://github.com/mikefarah/yq/releases/download/v4.43.1/yq_linux_amd64.tar.gz)
- jq versión jq-1.7.1

## Proceso de Backup

Todo el proceso de backup se ejecuta mediante el siguiente script:

```
./backup.sh -n <NOME DA NAMESPACE>
```

El script generará dos carpetas:

- *./ocp/*: Contiene los secrets, configmaps y CRDs obtenidos durante el proceso de backup.
- *./dump/*: Mantiene los dumps de las bases de datos y del filesystem del system-store.

## Restore

El procedimiento de restore consiste en la ejecución secuencial de los scripts:

| Script                    | Sintaxis                                           |
|----------------------------|--------------------------------------------------|
| `1-restore-secrets.sh`     | `./1-restore-secrets.sh -n <NOMBRE DEL NAMESPACE DE 3SCALE>`                         |
| `2-restore-system-database.sh` | `./2-restore-system-database.sh -n <NOMBRE DEL NAMESPACE DE 3SCALE>`             |
| `3-restore-zync-database.sh` | `./3-restore-zync-database.sh -n <NOMBRE DEL NAMESPACE DE 3SCALE> -d <NOMBRE DEL API MANAGER : - Este parámetro especifica el nombre del API Manager según lo definido en el APIcast CRD (Custom Resource Definition).>`      |
| `4-restore-redis.sh`       | `./4-restore-redis.sh -n <NOMBRE DEL NAMESPACE DE 3SCALE>`                           |
| `5-restore-rollout.sh`     | `./5-restore-rollout.sh -n <NOMBRE DEL NAMESPACE DE 3SCALE>`                           |

> *IMPORTANT:* Después de ejecutar el script *1-restore-secrets.sh*, el API Manager debe ser instalado antes de la ejecución de los demás scripts.
