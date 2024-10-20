
# README.md


Scripts para a implementação de backup e restore no 3scale versão 2.13, que utiliza as bases de dados geradas pelo Operator.

Este script se baseia na documentação oficial disponível em: [Capítulo 9. Backup e restore do 3scale API Management](https://docs.redhat.com/en/documentation/red_hat_3scale_api_management/2.13/html/operating_3scale/threescale-backup-restore#threescale-backup-restore)

## Pré Requisitos:

O script foi testado com:

- yq versão version v4.43.1
- jq versão jq-1.7.1

## Processo de Backup

Todo o processo de backup é executado pelo script abaixo:


```
./backup.sh -n <NOME DA NAMESPACE>
```

O script irá gerar duas pastas:

- *./ocp/*: Contém as secrets e configmaps obtidas durante o processo de backup.
- *./dump/*: Manter os dumps das bases de dados e do filesystem do system-store.

## Restore

O procedimento de restore consiste na execução sequencial dos scripts:

| Script                    | Sintaxe                                           |
|----------------------------|--------------------------------------------------|
| `1-restore-secrets.sh`     | `./1-restore-secrets.sh -n <NOME DA NAMESPACE DO 3SCALE>`                         |
| `2-restore-system-database.sh` | `./2-restore-system-database.sh -n <NOME DA NAMESPACE DO 3SCALE>`             |
| `3-restore-zync-database.sh`   | `./3-restore-zync-database.sh -n <NOME DA NAMESPACE DO 3SCALE> -d <NOME DO API MANAGER>`               |
| `4-restore-redis.sh`       | `./4-restore-redis.sh -n <NOME DA NAMESPACE DO 3SCALE>`                           |
| `5-restore-rollout.sh`       | `./5-restore-rollout.sh -n <NOME DA NAMESPACE DO 3SCALE>`                           |
