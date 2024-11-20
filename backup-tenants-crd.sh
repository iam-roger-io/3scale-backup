#!/bin/bash

# Verifica se o parâmetro -n foi passado para o nome da namespace
while getopts "n:" opt; do
  case $opt in
    n)
      namespace="$OPTARG"
      ;;
    *)
      echo "Uso: $0 -n <namespace>"
      exit 1
      ;;
  esac
done

# Se o parâmetro -n não for passado, define a namespace padrão
namespace="${namespace:-3scale-amp}"

# Diretório para salvar os backups
backup_dir="./ocp/tenants"

# Verifica se a pasta ./ocp/tenants existe
if [ -d "$backup_dir" ]; then
    # Se existe, apaga a pasta
    rm -rf "$backup_dir"
fi

mkdir -p "$backup_dir"

# Lista todos os tenants na namespace
tenant_list=$(oc get tenant -n "$namespace" -o jsonpath='{.items[*].metadata.name}')

# Verifica se a lista de tenants está vazia
if [ -z "$tenant_list" ]; then
  echo "No tenants found in the '$namespace' namespace."
  exit 0
fi

# Salva cada tenant em um arquivo separado
for tenant_name in $tenant_list; do
  echo "Backing up tenant: $tenant_name"

  # Exporta o tenant para um arquivo YAML
  oc get tenant -n "$namespace" "$tenant_name" -o yaml > "$backup_dir/$tenant_name.yaml"

  # Remove as propriedades indesejadas
  yq eval 'del(.metadata.creationTimestamp, .metadata.generation, .metadata.namespace, .metadata.resourceVersion, .metadata.uid, .status)' -i "$backup_dir/$tenant_name.yaml"

  echo "Backup saved to: $backup_dir/$tenant_name.yaml"
done

echo "Backup of all tenants completed."
