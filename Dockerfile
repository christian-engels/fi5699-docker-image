FROM python:3.12-slim

# Install system dependencies: git, curl, and GitHub CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        curl \
        ca-certificates \
        sudo \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Install OpenCode
RUN curl -fsSL https://raw.githubusercontent.com/opencode-ai/opencode/refs/heads/main/install | bash \
    && mv /root/.local/bin/opencode /usr/local/bin/opencode 2>/dev/null || true

# Create a non-root user for the dev container
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME

# Pre-install the Python packages into uv's cache so uv add is near-instant
WORKDIR /tmp/warm-cache
RUN uv init \
    && uv add polars plotnine pyfixest diff-diff xlsxwriter tidyfinance pyarrow marginaleffects \
    && rm -rf /tmp/warm-cache

WORKDIR /workspace
CMD ["bash"]
