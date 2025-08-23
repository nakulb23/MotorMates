# MotorMates Server Setup Guide 🖥️

This guide will help you set up a backend server for the MotorMates iOS app on your secondary PC.

## 🏗️ Server Architecture Overview

The MotorMates backend will provide:
- **REST API** for iOS app communication
- **User Authentication** with JWT tokens
- **Database** for posts, routes, and user data
- **File Storage** for images and media
- **Real-time Features** via WebSockets (optional)

## 🛠️ Technology Stack Recommendations

### Option 1: Node.js + Express (Recommended)
```bash
# Fast development, great iOS integration
- Node.js + Express.js
- PostgreSQL or MongoDB database
- JWT for authentication
- Multer for file uploads
- Socket.io for real-time features
```

### Option 2: Python + FastAPI
```bash
# Python ecosystem, excellent documentation
- Python 3.9+
- FastAPI framework
- SQLAlchemy + PostgreSQL
- JWT authentication
- AWS S3 or local file storage
```

### Option 3: Swift Vapor
```bash
# Same language as iOS app
- Swift Vapor framework
- PostgreSQL database
- JWT authentication
- Native Swift integration
```

## 🚀 Quick Start (Node.js + Express)

### Prerequisites
- **Node.js 18+** installed
- **PostgreSQL** or **MongoDB** installed
- **Git** installed

### Step 1: Create Server Project

```bash
# Create new directory
mkdir motormates-server
cd motormates-server

# Initialize Node.js project
npm init -y

# Install dependencies
npm install express cors helmet morgan dotenv
npm install jsonwebtoken bcryptjs multer
npm install pg sequelize  # PostgreSQL
# OR
npm install mongodb mongoose  # MongoDB

# Install dev dependencies
npm install --save-dev nodemon @types/node
```

### Step 2: Basic Server Structure

Create the following files:

```bash
motormates-server/
├── src/
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── postsController.js
│   │   ├── routesController.js
│   │   └── usersController.js
│   ├── middleware/
│   │   ├── auth.js
│   │   └── upload.js
│   ├── models/
│   │   ├── User.js
│   │   ├── Post.js
│   │   └── Route.js
│   ├── routes/
│   │   ├── auth.js
│   │   ├── posts.js
│   │   ├── routes.js
│   │   └── users.js
│   └── app.js
├── uploads/              # File storage
├── .env                 # Environment variables
├── .gitignore
└── package.json
```

### Step 3: Environment Configuration

Create `.env` file:
```bash
# Server Configuration
PORT=3000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=motormates
DB_USER=your_username
DB_PASSWORD=your_password

# JWT Secret
JWT_SECRET=your-super-secret-jwt-key-change-this

# File Upload
UPLOAD_PATH=./uploads
MAX_FILE_SIZE=10485760  # 10MB

# CORS
ALLOWED_ORIGINS=*  # For development, restrict in production
```

### Step 4: Basic Express Server

Create `src/app.js`:
```javascript
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
        service: 'MotorMates API'
    });
});

// API Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/posts', require('./routes/posts'));
app.use('/api/routes', require('./routes/routes'));
app.use('/api/users', require('./routes/users'));

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
});

module.exports = app;
```

## 📊 Database Schema

### PostgreSQL Tables

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    auth_provider VARCHAR(50) DEFAULT 'email',
    provider_user_id VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    profile_photo_url TEXT,
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Posts table
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    caption TEXT NOT NULL,
    location VARCHAR(255),
    image_urls TEXT[], -- Array of image URLs
    tags TEXT[],       -- Array of hashtags
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Routes table
CREATE TABLE routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    start_location VARCHAR(255),
    end_location VARCHAR(255),
    distance DECIMAL(10,2),
    estimated_duration INTEGER, -- in minutes
    difficulty VARCHAR(50),
    category VARCHAR(50),
    coordinates JSONB, -- GeoJSON format
    photos TEXT[],     -- Array of photo URLs
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cars table
CREATE TABLE cars (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER NOT NULL,
    color VARCHAR(50),
    engine VARCHAR(100),
    horsepower INTEGER,
    is_project BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🔐 API Endpoints

### Authentication Routes
```bash
POST   /api/auth/register          # Create new account
POST   /api/auth/login             # Email/password login
POST   /api/auth/refresh           # Refresh JWT token
POST   /api/auth/apple             # Apple Sign-In
POST   /api/auth/google            # Google Sign-In
POST   /api/auth/logout            # Logout user
```

### Posts Routes
```bash
GET    /api/posts/feed             # Get posts for feed
POST   /api/posts                  # Create new post
GET    /api/posts/:id              # Get specific post
PUT    /api/posts/:id              # Update post (owner only)
DELETE /api/posts/:id              # Delete post (owner only)
POST   /api/posts/:id/like         # Toggle like on post
```

### Routes Routes
```bash
GET    /api/routes/discover        # Get public routes
POST   /api/routes                 # Create new route
GET    /api/routes/:id             # Get specific route
PUT    /api/routes/:id             # Update route (owner only)
DELETE /api/routes/:id             # Delete route (owner only)
GET    /api/routes/user/:userId    # Get user's routes
```

### Users Routes
```bash
GET    /api/users/profile          # Get current user profile
PUT    /api/users/profile          # Update user profile
POST   /api/users/profile/photo    # Upload profile photo
GET    /api/users/:id              # Get public user profile
```

## 🌐 Deployment Options

### Option 1: Local Development Server
```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Server will run on http://localhost:3000
```

### Option 2: VPS Deployment (DigitalOcean, AWS EC2)
```bash
# 1. Set up Ubuntu server
# 2. Install Node.js and PostgreSQL
# 3. Clone repository
# 4. Install dependencies
# 5. Set up reverse proxy (Nginx)
# 6. Use PM2 for process management
# 7. Set up SSL certificate
```

### Option 3: Docker Deployment
```dockerfile
# Create Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY src ./src
EXPOSE 3000
CMD ["node", "src/app.js"]
```

## 📱 iOS App Integration

### Update iOS App Configuration

In your iOS app, update the base URL for API calls:

```swift
// In your services or configuration
private let baseURL = "http://YOUR_SERVER_IP:3000/api"

// For local development
private let baseURL = "http://localhost:3000/api"
```

### Test API Connection

Add this test endpoint to verify connection:

```javascript
// In your server
app.get('/api/test-ios', (req, res) => {
    res.json({ 
        message: 'MotorMates server is connected!',
        timestamp: new Date().toISOString()
    });
});
```

## 🔧 Development Tips

### Database Management
```bash
# Create database
createdb motormates

# Run migrations
psql -d motormates -f schema.sql

# Backup database
pg_dump motormates > backup.sql
```

### Testing API Endpoints
```bash
# Use curl or Postman
curl -X GET http://localhost:3000/health
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"Test User"}'
```

### Logging and Monitoring
```bash
# View logs
tail -f logs/app.log

# Monitor with PM2
pm2 logs
pm2 monit
```

## 🚨 Security Considerations

1. **Environment Variables**: Never commit `.env` files
2. **JWT Security**: Use strong secrets, implement token rotation
3. **Input Validation**: Validate all user inputs
4. **Rate Limiting**: Implement rate limiting for API endpoints
5. **HTTPS**: Always use HTTPS in production
6. **Database Security**: Use parameterized queries, least privilege access
7. **File Upload Security**: Validate file types, implement size limits

## 📞 Troubleshooting

### Common Issues

**Port Already in Use**
```bash
# Find process using port 3000
lsof -i :3000
# Kill process
kill -9 <PID>
```

**Database Connection Issues**
```bash
# Check PostgreSQL status
systemctl status postgresql
# Restart PostgreSQL
sudo systemctl restart postgresql
```

**CORS Issues**
- Update `ALLOWED_ORIGINS` in `.env`
- Check iOS app's base URL configuration

## 🔄 Next Steps

1. Set up the basic server structure
2. Implement authentication endpoints
3. Test API connection from iOS app
4. Add database schema and migrations
5. Implement core API endpoints
6. Add file upload functionality
7. Deploy to production server

## 📞 Support

For server setup questions:
1. Check the logs for error messages
2. Review the API documentation
3. Test endpoints with Postman/curl
4. Open an issue on GitHub

---

Happy coding! 🚗💨