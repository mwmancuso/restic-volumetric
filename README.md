# multi-volume restic-backup-docker

this docker image aims to back up and restore docker volumes using restic, automatically. it:

- scans all docker volumes on the host
- backs up those labeled with `restic.backup.enabled=true` to individual restic repos
- optionally forgets old snapshots
- periodically updates a "metadata" repo with volume definitions (to facilitate restore on a fresh host)
- optionally restores all volumes on container startup if they're missing

## features

1. installs `restic`, `jq`, `docker` CLI, `cron`, etc.
2. uses a mount of `/var/run/docker.sock` and a bind mount of `/var/lib/docker/volumes`
3. can restore volumes on startup
4. scans volumes to see which are labeled for restic backups
5. each volume gets its own restic repo
6. periodic backups and forget operations
7. also backs up metadata about restic-enabled volumes

## environment variables

- **RESTIC_PREFIX** (default `local:/data/restic`): base location for your restic repos  
- **RESTIC_NODE_REPO_ROOT** (default `$RESTIC_PREFIX/nodes/$HOSTNAME`): top-level repo path for this node
- **RESTIC_NODE_META_REPO** (default `$RESTIC_NODE_REPO_ROOT/meta`): repo storing volume metadata
- **RESTIC_REPO_ROOT** (default `$RESTIC_PREFIX/volumes`): base repo path for volumes
- **RESTIC_PASSWORD**: default password
- **RESTIC_PASSWORD_FILE**: if set, restic loads password from file
- **SCAN_CRON**: cron expression for scanning volumes (default `* * * * *`)
- **META_ENABLED**: `true/false` (default `true`) – whether to back up metadata
- **INIT_ARGS**: extra arguments for `restic init`
- **RESTORE_ENABLED**: `true/false` (default `true`) – restore volumes on container start
- **RESTORE_ARGS**: extra args passed to `restic restore`
- **BACKUP_ENABLED**: `true/false` (default `false`) – whether backups are enabled at all
- **BACKUP_CRON**: cron expression for backups (default: `0 * * * *` = hourly)
- **BACKUP_ARGS**: extra args passed to `restic backup`
- **FORGET_ENABLED**: `true/false` (default `false`) – whether to run `restic forget`
- **FORGET_ARGS**: required if `FORGET_ENABLED` is `true`, e.g. `--keep-daily 7 --keep-weekly 4` etc.

## per-volume labels

- **restic.backup.enabled**: `true/false` – if `true`, volume is backed up
- **restic.repo**: override restic repo path for this volume
- **restic.password**: override restic password
- **restic.password.file**: override restic password file
- **restic.init.args**: extra init args for this volume
- **restic.restore.enabled**: `true/false` – restore volume on container start
- **restic.restore.args**: extra args for restore
- **restic.backup.args**: extra backup args (in addition to global)
- **restic.backup.cron**: (not fully implemented in this example) – ideally you'd run a custom cron job
- **restic.forget.enabled**: `true/false` – override forget behavior at volume-level
- **restic.forget.args**: extra forget args

## usage

### docker-compose example

For a local backup:
```yaml
name: restic-volumetric
services:
  core:
    container_name: restic-volumetric
    image: mwmancuso/restic-volumetric:latest
    privileged: true
    environment:
      - NODE_NAME=<your-hostname>
      - RESTIC_PREFIX=local:/data/restic
      - RESTIC_PASSWORD=<your-super-secret-password>
      - BACKUP_ENABLED=true
      - BACKUP_CRON=* * * * *
      - FORGET_ENABLED=true
      - FORGET_ARGS=--keep-daily 7 --keep-weekly 4 --prune
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes:rw
      - ./my-restic-data:/data/restic
    restart: unless-stopped
```

For an AWS S3 backup:
```yaml
name: restic-volumetric
services:
  core:
    container_name: restic-volumetric
    image: mwmancuso/restic-volumetric:latest
    privileged: true
    environment:
      - NODE_NAME=<your-hostname>
      - RESTIC_PREFIX=s3:https://s3.amazonaws.com/test-restic-volumetric
      - RESTIC_PASSWORD=<your-super-secret-password>
      - AWS_ACCESS_KEY_ID=<access-key-id>
      - AWS_SECRET_ACCESS_KEY=<access-key-secret>
      - BACKUP_ENABLED=true
      - BACKUP_CRON=* * * * *
      - FORGET_ENABLED=true
      - FORGET_ARGS=--keep-daily 7 --keep-weekly 4 --prune
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes:rw
    restart: unless-stopped
```
