# Worksapce Key Cycling script

1. Creates a backup of the project's `workspace.yml` and `workspace.override.yml`
    a. `workspace.yml.orig`
    b. `workspace.override.yml.orig`
2. Reads all the encrypted secrets from the project's `workspace.yml`
3. Decrypts all the secrets using the `key('default'):` stored in the project's `workspace.override.yml`
4. Replaces the `key('default'):` in the project's `workspace.override.yml`
with a randomly generated Developement Key
5. Reencrypt all the secrets with the new Development key
6. Saves all the new encrypted secretes in the project's `workspace.yml`

## Testing

```bash
cd project/directory/
/path/to/wskeycycle.sh
```

Restore the original Workspace files

```bash
cp workspace.override.yml.orig workspace.override.yml
cp workspace.yml.orig workspace.yml
```

## TODO

* [ ] Fix the `replace_string_in_file` functions: `sed` fails to replace the encrypted key in the `workspace.yml` file