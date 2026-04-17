const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  const env = process.env.ENVIRONMENT || 'unknown';
  res.send(`✅ CI/CD Pipeline Test - Environment: ${env} - Node.js on AWS ECS - THIS IS TEST COMMIT`);
});

app.listen(port, '0.0.0.0', () => {
  console.log(`App listening at http://0.0.0.0:${port}`);
});
