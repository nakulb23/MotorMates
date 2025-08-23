#!/bin/bash

# MotorMates Server Quick Start Script
# Run this on your secondary PC to set up the backend server

echo "🚗 MotorMates Server Quick Start"
echo "================================"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    echo "   Download from: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js version: $(node --version)"

# Create server directory
echo "📁 Creating server directory..."
mkdir -p motormates-server
cd motormates-server

# Initialize package.json
echo "📦 Initializing Node.js project..."
cat > package.json << 'EOF'
{
  "name": "motormates-server",
  "version": "1.0.0",
  "description": "Backend server for MotorMates iOS app",
  "main": "src/app.js",
  "scripts": {
    "start": "node src/app.js",
    "dev": "nodemon src/app.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": ["motormates", "automotive", "api", "express"],
  "author": "Nakul Bhatnagar",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "morgan": "^1.10.0",
    "dotenv": "^16.3.1",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3",
    "multer": "^1.4.5-lts.1",
    "pg": "^8.11.3",
    "sequelize": "^6.35.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  }
}
EOF

# Install dependencies
echo "⬇️  Installing dependencies..."
npm install

# Create directory structure
echo "🏗️  Creating server structure..."
mkdir -p src/{controllers,middleware,models,routes} uploads

# Create basic app.js
cat > src/app.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS || '*',
    credentials: true
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Static files
app.use('/uploads', express.static('uploads'));

// Health check
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        timestamp: new Date().toISOString(),
        service: 'MotorMates API',
        message: 'Server is running! 🚗'
    });
});

// Test endpoint for iOS app
app.get('/api/test-ios', (req, res) => {
    res.json({ 
        message: 'MotorMates server is connected!',
        timestamp: new Date().toISOString(),
        success: true
    });
});

// Basic route
app.get('/', (req, res) => {
    res.json({
        message: 'Welcome to MotorMates API!',
        version: '1.0.0',
        endpoints: {
            health: '/health',
            test: '/api/test-ios'
        }
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ 
        error: 'Something went wrong!',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Route not found' });
});

app.listen(PORT, () => {
    console.log(`🚗 MotorMates Server running on port ${PORT}`);
    console.log(`🏥 Health check: http://localhost:${PORT}/health`);
    console.log(`📱 iOS test: http://localhost:${PORT}/api/test-ios`);
    console.log('');
    console.log('Next steps:');
    console.log('1. Update your iOS app base URL to: http://YOUR_IP:' + PORT + '/api');
    console.log('2. Test the connection from your iOS app');
    console.log('3. Follow SERVER_SETUP.md for full implementation');
});

module.exports = app;
EOF

# Create .env file
cat > .env << 'EOF'
# Server Configuration
PORT=3000
NODE_ENV=development

# Database (update when you set up PostgreSQL)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=motormates
DB_USER=your_username
DB_PASSWORD=your_password

# JWT Secret (change this!)
JWT_SECRET=your-super-secret-jwt-key-change-this-immediately

# File Upload
UPLOAD_PATH=./uploads
MAX_FILE_SIZE=10485760

# CORS
ALLOWED_ORIGINS=*
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
node_modules/
.env
.env.local
.env.production
uploads/*
!uploads/.gitkeep
logs/
*.log
.DS_Store
EOF

# Create uploads directory with gitkeep
touch uploads/.gitkeep

echo ""
echo "✅ Server setup complete!"
echo ""
echo "🚀 To start the server:"
echo "   cd motormates-server"
echo "   npm run dev"
echo ""
echo "🔗 Server will be available at:"
echo "   http://localhost:3000"
echo "   http://YOUR_IP_ADDRESS:3000"
echo ""
echo "📖 Next steps:"
echo "   1. Start the server: npm run dev"
echo "   2. Test health endpoint: curl http://localhost:3000/health"
echo "   3. Update your iOS app base URL"
echo "   4. Follow SERVER_SETUP.md for full implementation"
echo ""
echo "🎉 Happy coding!"
EOF

chmod +x server-quickstart.sh