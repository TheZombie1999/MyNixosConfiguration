# - name: Load encrypted credentials
#   community.sops.load_vars:
#     file: ../Secrets/secrets.yaml
#     config_path: ../.sops.yaml

# - name: Debug
#   debug:
#     msg: "The expression is {{ autoPullPublicKey }}"
