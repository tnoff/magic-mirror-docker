- Build on `node:25-bookworm-slim` instead of the full `node:25-bookworm`. The
  full variant carries ~950 MB of build toolchain the runtime never uses;
  dropping it takes the image from 2.13 GB to 1.18 GB with no functional change.
