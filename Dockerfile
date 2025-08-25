######################################################################
# Why This Design Works:
#
# - Separation of Concerns:
#   All build logic related to the containerized environment is scoped
#   to this file, not mixed into code or runtime config.
#
# - Reproducibility:
#   Ensures consistent results regardless of where it's run — CI, dev machine,
#   or production container registry.
#
# - Portability:
#   Based on official Node.js image, which guarantees compatibility
#   across platforms and cloud services.
#
# - Maintainability:
#   Logical steps (install, copy, run) are organized and easy to extend
#   with logging, versioning, or testing later.
#
# - Developer Onboarding:
#   With just Docker installed, any developer can spin up the assistant
#   without needing local Node/npm access.
######################################################################

# 🟢 Use the official Node.js 20 LTS base image
FROM node:20

# 📁 Set working directory inside the container
WORKDIR /app

# 📦 Copy package.json and package-lock.json first
# Enables layer caching of `npm install` if deps haven't changed
COPY package*.json ./

# 📥 Install NPM dependencies
RUN npm install

# 📂 Copy the full project source into the image
COPY . .

# ✅ Reinstall critical runtime packages to ensure compatibility
# Helps avoid "missing module" errors in minimal base images
RUN npm install dotenv readline openai

# 🚀 Start the assistant CLI by default
CMD ["node", "index.js"]
