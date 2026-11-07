# openGym MCP Docker (GHCR + Unraid)

Standalone container for [openGym's official MCP server](https://github.com/DuarteSantos8/openGym/tree/main/mcp). The upstream server speaks **stdio**, so this image uses [Supergateway](https://github.com/supercorp-ai/supergateway) to offer a **Streamable HTTP** endpoint at `/mcp`.

The container reads the existing openGym API's JSON state from a **read-only volume**. It does not require you to exec into the original application container. The `log_workout` write tool is part of upstream MCP but is not configured to write in this template (no `OPENGYM_URL`/`OPENGYM_TOKEN`).

## 1. Publish the image with GitHub

1. Create a public GitHub repository named `opengym-mcp-docker` and upload/commit the contents of this folder, including `.github/workflows/publish.yml`.
2. Push to `main`. In **Actions**, watch the **Build and publish container** workflow. It publishes `linux/amd64` and `linux/arm64` images to **GitHub Container Registry** (GHCR).
3. Under your GitHub profile **Packages** (or the repo's linked package), change the container package visibility to **Public** if it is private. A public package can be pulled by Unraid without a registry login.
4. Your image will be `ghcr.io/YOUR_GITHUB_USERNAME/opengym-mcp-docker:latest` (lowercase owner/repo is recommended). Version tags such as `v0.1.0` also publish images with matching tags. A push to main replaces `latest`.

**Source versions:** Docker builds openGym from the fixed upstream tag `v1.4.4` and installs Supergateway `4.2.1`. To update openGym, change `OPENGYM_REF` in the Dockerfile, commit, and let Actions rebuild. A release tag is a version pin, but for stronger supply-chain reproducibility prefer a full verified git commit SHA (and change the clone to fetch that commit explicitly).

## 2. Install from Unraid's Docker interface

The XML template lives at `unraid/opengym-mcp.xml`.

1. **Before importing**, replace every `REPLACE_GITHUB_OWNER` in the XML with your GitHub username. If your repository has a different name, also change the image and links.
2. Put the edited XML in `/boot/config/plugins/dockerMan/templates-user/my-opengym-mcp.xml` on your Unraid server. You can do this over SSH or via the flash share.
3. Open **Docker → Add Container**, select the `openGym-MCP` template, then adjust its settings:
   - **Repository:** `ghcr.io/YOUR_GITHUB_USERNAME/opengym-mcp-docker:latest`.
   - **MCP HTTP port:** 8000 (change the *host* port if occupied).
   - **openGym API data directory:** the existing API container's **host** volume path holding `db.json` and `state-<uid>.json` — the example path is only a placeholder. Keep the mount **Read Only**.
   - **MCP API key:** generate with `openssl rand -hex 32`. Required: the container refuses to launch without one.
   - **openGym profile ID:** leave empty for a single user, or set to the corresponding `users[].id` in `db.json`.
4. Apply, and check **Docker → openGym-MCP → Logs** for a `serving profile ...` message.

The gateway binds port 8000 **inside** the container. When Unraid maps the host port, it is generally accessible on the host's network interfaces. Do **not** router-forward the raw port onto the internet. Restrict it with your firewall or an authenticated HTTPS reverse proxy. The API key protects `/mcp`, but `/healthz` is an unauthenticated availability endpoint.

### Local test

```sh
curl -i http://UNRAID_IP:8000/healthz
# Expected: HTTP 200 and "ok" if gateway is running.
# This checks the gateway, not whether openGym's data loaded correctly.
```

Use an MCP client that supports **Streamable HTTP** with an authorization header:

```
MCP URL: http://UNRAID_IP:8000/mcp
Authorization: Bearer YOUR_MCP_API_KEY
```

**ChatGPT caveat:** A raw API-key-protected MCP endpoint does not necessarily satisfy ChatGPT's connector authentication requirements. You may need OAuth-compatible fronting and a publicly reachable HTTPS URL. This package does **not** provide OAuth.

## 3. Alternative: Docker Compose

Copy `.env.example` to `.env`, fill in the values, then run `docker compose up -d`. Unlike the Unraid XML approach, the example Compose mapping defaults to loopback-only on the host.

## Troubleshooting

- **Image pull denied:** make the GHCR package public or authenticate Unraid to GHCR.
- **Failed to locate profile / missing state:** check the openGym **API** container's host volume mapping; don't blindly use the example data path. Set `OPENGYM_UID` if there are multiple profiles.
- **Container exits immediately:** set `SUPERGATEWAY_API_KEY` to a nonempty secret.
- **Gateway starts but tools fail:** `/healthz` only checks the gateway. Look at Docker logs and verify the files and their permissions.
- **Port busy:** adjust the left/host side of the port mapping in Unraid.
- **Docker build error:** inspect the GitHub Actions logs; the upstream project can change even when the image package stays fixed. Pin dependencies as needed.

## Security and limitations

- Your openGym profile data (potentially including personal health and fitness information) is readable through the MCP tools by any client holding the API key. Protect the key and restrict network access.
- The mount is read-only and writing through `log_workout` is disabled **by configuration**, not by removing the upstream tool. Do not add `OPENGYM_URL`/`OPENGYM_TOKEN` unless you intentionally want write access.
- This is a community packaging project, not an official openGym image. The Docker build and endpoint have not been run end-to-end in this environment, so check the first GitHub Actions build and test with a compatible MCP client.
- Upstream source is AGPL-3.0-or-later. Review upstream licensing and attribution if you publish or redistribute the image.

Sources: [openGym MCP source](https://github.com/DuarteSantos8/openGym/tree/main/mcp), [Supergateway flags](https://github.com/supercorp-ai/supergateway).
