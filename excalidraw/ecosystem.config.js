module.exports = {
  apps: [
    {
      name: 'excalidraw-collab',
      script: './dist/index.js',
      cwd: '/home/ubuntu/workspace/my_excalidraw_cc/excalidraw-room',
      instances: 1,
      env: {
        NODE_ENV: 'development',
        PORT: 3002
      }
    },
    {
      name: 'excalidraw-frontend',
      script: 'npx',
      cwd: '/home/ubuntu/workspace/my_excalidraw_cc/excalidraw/excalidraw-app',
      args: 'vite --host --port 3001',
      instances: 1
    }
  ]
};
