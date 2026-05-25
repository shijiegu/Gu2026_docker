# gucompaper_docker

Instructions for running the **Gu, Chen, Gillespie et al., 2026** paper analysis notebooks in a Docker container, using pre-built images published to Docker Hub. The analysis [code](https://github.com/shijiegu/Gu2026), dependencies, and the machinery needed to pull data from the associated data in the cloud [**Dandi Set**](https://dandiarchive.org/dandiset/001836) are all packaged in the Docker image. Once you get the Docker running, everything is included. This is the one-stop shop for the instructions to set up Docker containers.

## High-level overview

**What you will run**

Two containers, started together via `docker compose`:

- `collab_hub` — JupyterLab on host port **8888**, with the notebooks, the `gucompaper` source, and the full conda environment baked in.
- `collab_db` — MySQL on host port **3306**, pre-populated with the paper's exported database.

Both images live on Docker Hub:

- `shijiegu7/spyglass-hub-Gu2026:latest`
- `shijiegu7/spyglass-db-Gu2026:latest`

**What you will not do**

You do **not** need to install Python, conda, MySQL, or any paper dependency — everything is inside the images. You do not need a Docker Hub account or docker login — the published images are public.

## Passwords and credentials

| What | Value | When you'll need it |
| --- | --- | --- |
| JupyterLab login password | `Gu2026` | When the browser prompts you at `http://localhost:8888/lab` |
| MySQL root password | `tutorial` | Already wired into the notebooks via `.env`; only needed if you manually shell into the db container |
| MySQL user | `root` | Same — already used automatically by DataJoint inside the hub container |
| MySQL host (inside Docker network) | `db` | Automatic; the hub container resolves this internally |
| MySQL host port (from your laptop) | `localhost:3306` | Only if you want to connect to the db with an external MySQL client |

All of these are stored in [.env](.env). Do **not** edit that file.

## Prerequisites

1. Install [Docker](https://docs.docker.com/get-docker/).
2. Install `make` (available by default on Linux/macOS; on Windows use `choco install make` or run inside WSL).

You do **not** need a Docker Hub account or `docker login` — the published images are public.

## Files you need
All four are in this repo; just follow the **Step-by-step** below.

Put all four of the following in the same directory:

| File | Purpose |
| --- | --- |
| `.env` | Environment variables: image names, MySQL credentials, Jupyter password |
| `docker-compose-collab.yml` | Defines the two containers, ports, and persistent volumes |
| `Makefile` | Provides the `make run` shortcut |
| `config/mysqld.cnf` | MySQL server config (bind-mounted into the db container) |



## Step-by-step

### 1. Clone and enter

```bash
git clone <this-repo-url> gucompaper_docker
cd gucompaper_docker
```

### 2. Launch the containers

```bash
make run
```

That target is defined in the Makefile as:

```bash
docker compose -f docker-compose-collab.yml up -d
```

What happens:

- `docker compose` reads `.env` to resolve `${HUB_IMAGE_NAME}` → `shijiegu7/spyglass-hub-Gu2026` and `${DB_IMAGE_NAME}` → `shijiegu7/spyglass-db-Gu2026`.
- Because these images are not yet on your machine, Docker pulls them from Docker Hub. (First time only; subsequent runs reuse the local copies.)
- Docker starts `collab_hub` and `collab_db` containers and creates three named volumes the first time: `conda`, `notebooks`, `db_data`. The `notebooks` volume is seeded from `/home/joyvan/notebooks` inside the hub image, so you start with the paper's notebooks. Your edits in subsequent sessions persist in that volume.
- The hub container connects to the db container via the internal hostname `db` (from `MYSQL_HOST=db` in `.env`) using `MYSQL_ROOT_PASSWORD=tutorial`.

### 3. Open the notebooks

Visit **[http://localhost:8888/lab](http://localhost:8888/lab)** in your browser.

Password: **`Gu2026`** (the value of `PAPER_ID` in `.env`, wired in via `JUPYTER_SERVER_APP_PASSWORD=${PAPER_ID}`).

JupyterLab opens with the paper's notebooks. The correct conda kernel is preselected. Run any cell — the notebooks already know how to find the database.

### 4. Stop the containers

```bash
make down
```

Your notebook edits and database state survive in the named volumes. The next `make run` will pick up where you left off.

To fully wipe state (start over from the image defaults), additionally remove the volumes:

```bash
docker volume rm gucompaper_docker_notebooks gucompaper_docker_conda gucompaper_docker_db_data
```

## Caveats

- **The Makefile only exposes `make run` and `make down`.** Both are safe to run any number of times.
- **Do not edit `.env`.** In particular, `DOCKER_HUB_USER=shijiegu7` is what points Docker at the right published images. `SPYGLASS_BASE_DIR` is unused for `make run` but is left in for reference.

## Troubleshooting

Check container status:

```bash
docker ps -a
```

If `collab_hub` or `collab_db` shows status `Restarting` or `Exited`, inspect the logs:

```bash
docker logs collab_hub
docker logs collab_db
```

Common issues:

- **Port 8888 or 3306 already in use** on your host. Stop the conflicting process or edit the port mappings in `docker-compose-collab.yml`.
- **First `make run` is slow.** Pulling ~several GB from Docker Hub takes time. Subsequent runs are immediate.
