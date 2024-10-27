FROM ghcr.io/astral-sh/uv:python3.12-slim-bookworm

WORKDIR /app

# Copy the entire project
COPY . .

# Install the package and its dependencies
RUN uv pip install .

CMD ["uv", "run", "ai_labeler.main"]
