#!/usr/bin/env bash
set -euo pipefail
WORKSPACE=${WORKSPACE:-"/home/kavia/workspace/code-generation/online-bookstore-application-90744-90810/WebUIContainer"}
cd "$WORKSPACE"
# Detect meaningful package.json
if [ -f package.json ]; then
  if node -e "try{const p=require('./package.json'); if(p.name||Object.keys(p.scripts||{}).length||Object.keys(p.dependencies||{}).length) process.exit(0); else process.exit(2);}catch(e){process.exit(1)}"; then
    echo "Existing project detected - skipping scaffold" && exit 0
  else
    cp package.json package.json.bak.$(date +%s)
  fi
fi
# Minimal package.json with local react-scripts to ensure npm run build works
cat > package.json <<'JSON'
{
  "name": "webuicontainer",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "jest --runInBand"
  },
  "dependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  },
  "devDependencies": {
    "react-scripts": "^5.0.1",
    "serve": "^14.0.0"
  }
}
JSON
# Create basic files
cat > .gitignore <<'GIT'
node_modules
build
.env.local
.env
GIT
mkdir -p public src
[ -f public/index.html ] || cat > public/index.html <<'HTML'
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>WebUIContainer</title></head>
  <body><div id="root"></div></body>
</html>
HTML
[ -f src/index.js ] || cat > src/index.js <<'JS'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
const root = createRoot(document.getElementById('root'));
root.render(React.createElement(App));
JS
[ -f src/App.js ] || cat > src/App.js <<'JS'
import React from 'react';
export default function App(){return React.createElement('div', null, 'Hello from WebUIContainer');}
JS
# .env.example and create .env if missing
[ -f .env.example ] || cat > .env.example <<'ENV'
REACT_APP_API_URL=http://localhost:8000/api
ENV
[ -f .env ] || cp .env.example .env
# Minimal eslint and jest configs
[ -f .eslintrc.json ] || cat > .eslintrc.json <<'ESLINT'
{"env":{"browser":true,"es2021":true},"extends":["eslint:recommended"],"parserOptions":{"ecmaVersion":12,"sourceType":"module"},"rules":{}}
ESLINT
[ -f jest.config.cjs ] || cat > jest.config.cjs <<'JEST'
module.exports = { testEnvironment: 'node', testMatch: ['**/__tests__/**/*.js?(x)','**/?(*.)+(spec|test).js?(x)'] };
JEST
