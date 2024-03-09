Pydio container release featuring:

* regular and timely application updates
* easy user mappings (PGID, PUID)
* custom base image with s6 overlay
* weekly base OS updates with common layers across the entire LinuxServer.io ecosystem to minimise space usage, down time and bandwidth
* regular security updates

[Pydio-cells](https://pydio.com/) is the nextgen file sharing platform for organizations. It is a full rewrite of the Pydio project using the Go language following a micro-service architecture.

[![pydio-cells](https://raw.githubusercontent.com/wiki/pydio/cells/images/PydioCellsColor.png)](https://pydio.com/)

## Supported Architectures

We utilise the docker manifest for multi-platform awareness. More information is available from docker [here](https://distribution.github.io/distribution/spec/manifest-v2-2/#manifest-list) and our announcement [here](https://blog.linuxserver.io/2019/02/21/the-lsio-pipeline-project/).

Simply pulling `lscr.io/linuxserver/pydio-cells:latest` should retrieve the correct image for your arch, but you can also pull specific arch images via tags.

The architectures supported by this image are:

| Architecture | Available | Tag |
| :----: | :----: | ---- |
| x86-64 | ✅ | amd64-\<version tag\> |
| arm64 | ✅ | arm64v8-\<version tag\> |

## Application Setup

You must first create a mysql database for Pydio Cells. Using our [mariadb image](https://hub.docker.com/r/linuxserver/mariadb) is recommended.  

Then access the web gui setup wizard at `https://SERVER_IP:8080` if accessing locally (must set `SERVER_IP` env var), or at `https://pydio-cells.domain.com` if reverse proxying.

### Strict reverse proxies

This image uses a self-signed certificate by default. This naturally means the scheme is `https`.
If you are using a reverse proxy which validates certificates, you need to [disable this check for the container](https://docs.linuxserver.io/faq#strict-proxy).

## Usage

To help you get started creating a container from this image you can either use docker-compose or the docker cli.

### docker-compose

```yaml
---
services:
  pydio-cells:
    image: lscr.io/linuxserver/pydio-cells:latest
    container_name: pydio-cells
    hostname: pydio-cells
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - EXTERNALURL=yourdomain.url
      - SERVER_IP=0.0.0.0 #optional
    volumes:
      - /path/to/appdata/config:/config
    ports:
      - 8080:8080
      - 33060:33060 #optional
    restart: unless-stopped
```

### docker cli

```bash
docker run -d \
  --name=pydio-cells \
  --hostname=pydio-cells \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -e EXTERNALURL=yourdomain.url \
  -e SERVER_IP=0.0.0.0 `#optional` \
  -p 8080:8080 \
  -p 33060:33060 `#optional` \
  -v /path/to/appdata/config:/config \
  --restart unless-stopped \
  lscr.io/linuxserver/pydio-cells:latest
```

## Parameters

Containers are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| :----: | --- |
| `--hostname=` | Pydio Cells uses the hostname to verify local files. This setting is required and should not be changed after it has been set. |
| `-p 8080` | Http port |
| `-p 33060` | gRPC port (required for CellsSync). |
| `-e PUID=1000` | for UserID - see below for explanation |
| `-e PGID=1000` | for GroupID - see below for explanation |
| `-e TZ=Etc/UTC` | specify a timezone to use, see this [list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List). |
| `-e EXTERNALURL=yourdomain.url` | The external url you would like to use to access Pydio Cells (Can be https://domain.url or https://IP:PORT). |
| `-e SERVER_IP=0.0.0.0` | Enter the LAN IP of the docker server. Required for local access by IP, added to self signed cert as SAN (not required if accessing only through reverse proxy). |
| `-v /config` | All the config files reside here. |

## Environment variables from files (Docker secrets)

You can set any environment variable from a file by using a special prepend `FILE__`.

As an example:

```bash
-e FILE__MYVAR=/run/secrets/mysecretvariable
```

Will set the environment variable `MYVAR` based on the contents of the `/run/secrets/mysecretvariable` file.

## Umask for running applications

For all of our images we provide the ability to override the default umask settings for services started within the containers using the optional `-e UMASK=022` setting.
Keep in mind umask is not chmod it subtracts from permissions based on it's value it does not add. Please read up [here](https://en.wikipedia.org/wiki/Umask) before asking for support.

## User / Group Identifiers

When using volumes (`-v` flags), permissions issues can arise between the host OS and the container, we avoid this issue by allowing you to specify the user `PUID` and group `PGID`.

Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.

In this instance `PUID=1000` and `PGID=1000`, to find yours use `id your_user` as below:

```bash
id your_user
```

Example output:

```text
uid=1000(your_user) gid=1000(your_user) groups=1000(your_user)
```

## Updating Info

Most of our images are static, versioned, and require an image update and container recreation to update the app inside. With some exceptions (noted in the relevant readme.md), we do not recommend or support updating apps inside the container. Please consult the [Application Setup](#application-setup) section above to see if it is recommended for the image.

Below are the instructions for updating containers:

### Via Docker Compose

* Update images:
    * All images:

        ```bash
        docker-compose pull
        ```

    * Single image:

        ```bash
        docker-compose pull pydio-cells
        ```

* Update containers:
    * All containers:

        ```bash
        docker-compose up -d
        ```

    * Single container:

        ```bash
        docker-compose up -d pydio-cells
        ```

* You can also remove the old dangling images:

    ```bash
    docker image prune
    ```

### Via Docker Run

* Update the image:

    ```bash
    docker pull lscr.io/linuxserver/pydio-cells:latest
    ```

* Stop the running container:

    ```bash
    docker stop pydio-cells
    ```

* Delete the container:

    ```bash
    docker rm pydio-cells
    ```

* Recreate a new container with the same docker run parameters as instructed above (if mapped correctly to a host folder, your `/config` folder and settings will be preserved)
* You can also remove the old dangling images:

    ```bash
    docker image prune
    ```

### Image Update Notifications - Diun (Docker Image Update Notifier)

**tip**: We recommend [Diun](https://crazymax.dev/diun/) for update notifications. Other tools that automatically update containers unattended are not recommended or supported.

## Building locally

If you want to make local modifications to these images for development purposes or just to customize the logic:

```bash
git clone https://github.com/linuxserver/docker-pydio-cells.git
cd docker-pydio-cells
docker build \
  --no-cache \
  --pull \
  -t lscr.io/linuxserver/pydio-cells:latest .
```

The ARM variants can be built on x86_64 hardware using `multiarch/qemu-user-static`

```bash
docker run --rm --privileged multiarch/qemu-user-static:register --reset
```

Once registered you can define the dockerfile to use with `-f Dockerfile.aarch64`.
