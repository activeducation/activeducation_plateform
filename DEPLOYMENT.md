# ActivEducation Deployment Guide

Complete deployment infrastructure for ActivEducation — a Node.js/Express backend + static HTML frontend platform with PostgreSQL and Redis.

## Architecture Overview

- **Backend**: Node.js/Express running on port 3001
- **Frontend**: Static HTML files served by nginx on port 80/443
- **Database**: PostgreSQL 15 with persistent volume
- **Cache**: Redis 7 for session management
- **Orchestration**: Docker Compose for multi-container management

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- At least 2GB free disk space
- Ports 80, 443, 3001, 5432, and 6379 available

## Quick Start (5 Steps)

### 1. Clone/Setup

```bash
cd /path/to/ActivEducation
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your configuration
nano .env
```

### 3. Run Deployment Script

```bash
chmod +x deploy.sh
./deploy.sh
```

The script will:
- Check Docker/docker-compose installation
- Create and configure the .env file
- Build all Docker images
- Start all services with health checks
- Wait for PostgreSQL to be ready
- Run database migrations and seed data
- Display success message with service URLs

### 4. Verify Deployment

```bash
# Check all services are running
docker-compose ps

# View logs
docker-compose logs -f

# Test API health
curl http://localhost/api/v1/health
```

### 5. Access Services

- **Frontend**: http://localhost
- **API**: http://localhost/api/v1
- **Health Check**: http://localhost/api/v1/health

## Manual Setup (Without Docker)

If you prefer to run services manually:

### 1. PostgreSQL Setup

```bash
# Install PostgreSQL 15
# Create database
createdb -U postgres activeducation

# Run schema
psql -U postgres -d activeducation -f server/schema.sql

# Run seed data
psql -U postgres -d activeducation -f server/seed.sql
```

### 2. Backend Setup

```bash
cd server
npm install
cp .env.example .env
# Edit .env with your configuration
npm start
```

### 3. Redis Setup (Optional)

```bash
# Install Redis
redis-server
```

### 4. Frontend Setup

```bash
# Install nginx
# Copy configuration
sudo cp nginx.conf /etc/nginx/nginx.conf

# Start nginx
sudo systemctl start nginx
```

## Environment Variables Reference

### Database Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | - | PostgreSQL connection string |
| `DB_HOST` | postgres | Database hostname |
| `DB_PORT` | 5432 | Database port |
| `DB_NAME` | activeducation | Database name |
| `DB_USER` | aeuser | Database user |
| `DB_PASSWORD` | aepassword | Database password |

### JWT Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `JWT_SECRET` | - | JWT signing key (min 32 chars) |
| `JWT_REFRESH_SECRET` | - | Refresh token signing key |

### Server Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 3001 | Backend server port |
| `NODE_ENV` | production | Node environment (development/production) |
| `FRONTEND_URL` | http://localhost | Frontend URL for CORS |

### Optional Services

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENAI_API_KEY` | - | OpenAI API key (optional) |
| `REDIS_URL` | redis://redis:6379 | Redis connection string |

## API Endpoints Summary

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login user
- `POST /api/v1/auth/refresh` - Refresh JWT token
- `POST /api/v1/auth/logout` - Logout user

### Health Check
- `GET /api/v1/health` - Service health status

### Users
- `GET /api/v1/users` - List all users
- `GET /api/v1/users/:id` - Get user details
- `PUT /api/v1/users/:id` - Update user
- `DELETE /api/v1/users/:id` - Delete user

### Mentors
- `GET /api/v1/mentors` - List all mentors
- `GET /api/v1/mentors/:id` - Get mentor details
- `POST /api/v1/mentors` - Create mentor
- `PUT /api/v1/mentors/:id` - Update mentor

### Courses
- `GET /api/v1/courses` - List all courses
- `GET /api/v1/courses/:id` - Get course details
- `POST /api/v1/courses` - Create course
- `PUT /api/v1/courses/:id` - Update course

## Demo Account Credentials

After seed data is loaded:

| Field | Value |
|-------|-------|
| Email | demo@activeducation.com |
| Password | Demo123!@# |
| Role | Student |

Use these credentials to test login functionality.

## Project Structure

```
ActivEducation/
├── docker-compose.yml      # Multi-service orchestration
├── nginx.conf              # Nginx configuration
├── deploy.sh               # Automated deployment script
├── .env.example            # Environment template
├── .dockerignore            # Docker build exclusions
├── DEPLOYMENT.md           # This file
├── server/
│   ├── Dockerfile          # Backend container image
│   ├── server.js           # Express application
│   ├── package.json        # Node dependencies
│   ├── schema.sql          # Database schema
│   ├── seed.sql            # Seed data
│   ├── config/
│   │   └── database.js     # Database configuration
│   ├── routes/             # API routes
│   ├── middleware/         # Express middleware
│   └── services/           # Business logic
├── dashboard.html          # Frontend dashboard
├── login.html              # Login page
├── home.html               # Home page
└── 404.html               # Error page
```

## Troubleshooting

### Services won't start

```bash
# Check Docker daemon
docker ps

# Check logs
docker-compose logs backend
docker-compose logs postgres
docker-compose logs frontend

# Rebuild images
docker-compose down
docker-compose up --build -d
```

### Database connection errors

```bash
# Verify PostgreSQL is running
docker-compose exec postgres pg_isready -U aeuser

# Check connection string in .env
# Ensure DB_PASSWORD matches POSTGRES_PASSWORD

# Manual connection test
docker-compose exec postgres psql -U aeuser -d activeducation -c "SELECT 1"
```

### Port conflicts

```bash
# Check which process is using a port
lsof -i :80    # Frontend
lsof -i :3001  # Backend
lsof -i :5432  # Database
lsof -i :6379  # Redis

# Kill process on port (example: port 80)
kill -9 $(lsof -t -i :80)
```

### High memory usage

```bash
# Prune Docker images and volumes
docker system prune -a

# Reduce container memory limits in docker-compose.yml
```

## Useful Docker Commands

```bash
# View all services
docker-compose ps

# View logs
docker-compose logs -f              # All services
docker-compose logs -f backend      # Specific service
docker-compose logs --tail=100      # Last 100 lines

# Access services
docker-compose exec backend bash    # Backend shell
docker-compose exec postgres bash   # Database shell

# Stop services
docker-compose down                 # Stop all
docker-compose down -v              # Stop and remove volumes

# Restart services
docker-compose restart              # Restart all
docker-compose restart backend      # Restart specific

# Build only
docker-compose build --no-cache     # Rebuild without cache

# Scale services
docker-compose up -d --scale backend=2  # Run 2 backend instances
```

## Performance Optimization

### Nginx Caching

Static assets (CSS, JS, images) are cached for 1 year:
- `.js`, `.css` files - Cached with immutable header
- Images (`.png`, `.jpg`, `.gif`, `.svg`) - Cached for 1 year
- HTML files - Not cached (checked on every request)

### Database Optimization

- Connection pooling enabled
- SSL connections in production
- Health checks ensure availability
- Persistent volume for data retention

### Backend Optimization

- Node.js alpine image (smaller footprint)
- Non-root user for security
- Multi-stage Docker build
- Production-only dependencies
- Health check endpoint

## Security Considerations

1. **Environment Variables**: Change all default values in .env
2. **JWT Secrets**: Use strong, randomly generated secrets (min 32 characters)
3. **Database Password**: Use strong, unique password
4. **HTTPS**: Configure SSL certificates for production (update nginx.conf)
5. **CORS**: Set correct FRONTEND_URL to prevent unauthorized access
6. **Rate Limiting**: Backend includes rate limiting middleware

### HTTPS Setup (Production)

```bash
# Create ssl directory
mkdir ssl

# Generate self-signed certificate (testing only)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/activeducation.key \
  -out ssl/activeducation.crt

# Or use Let's Encrypt with certbot
certbot certonly --standalone -d your-domain.com
```

Update nginx.conf to use HTTPS:

```nginx
server {
  listen 443 ssl http2;
  ssl_certificate /etc/nginx/ssl/activeducation.crt;
  ssl_certificate_key /etc/nginx/ssl/activeducation.key;
  # ... rest of configuration
}
```

## Monitoring

### Health Checks

All services include health checks:

```bash
# View health status
docker-compose ps

# Check specific service health
curl http://localhost/api/v1/health
```

### Logging

```bash
# View all logs
docker-compose logs -f

# View specific service
docker-compose logs -f backend

# Follow with timestamp
docker-compose logs -f --timestamps

# Filter logs
docker-compose logs backend | grep error
```

### Resource Usage

```bash
# Monitor container stats
docker stats activeducation-backend
docker stats activeducation-postgres

# Check disk usage
docker system df
```

## Backup and Recovery

### Database Backup

```bash
# Backup PostgreSQL
docker-compose exec -T postgres pg_dump -U aeuser activeducation > backup.sql

# Restore from backup
docker-compose exec -T postgres psql -U aeuser activeducation < backup.sql
```

### Data Volumes

```bash
# List volumes
docker volume ls

# Backup volume
docker run --rm -v activeducation_postgres-data:/data \
  -v $(pwd):/backup alpine tar czf /backup/postgres-backup.tar.gz /data

# Restore volume
docker run --rm -v activeducation_postgres-data:/data \
  -v $(pwd):/backup alpine tar xzf /backup/postgres-backup.tar.gz -C /
```

## Support

For issues and questions:
1. Check logs: `docker-compose logs -f`
2. Review troubleshooting section above
3. Check API documentation: `server/API_EXAMPLES.md`
4. Review environment configuration in `.env`

## License

ISC
