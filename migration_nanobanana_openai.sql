-- Migration: create initial schema for Nanobanana + ChatGPT Image Gen MVP
-- Run this on PostgreSQL (example: psql -f migration.sql)

-- Enable uuid-ossp or pgcrypto depending on your PG version
-- For pgcrypto:
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Organizations
CREATE TABLE IF NOT EXISTS organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  plan text NOT NULL DEFAULT 'starter',
  credits numeric DEFAULT 0,
  billing_info jsonb,
  created_at timestamptz DEFAULT now()
);

-- Users
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  role text NOT NULL,
  name text,
  email text UNIQUE NOT NULL,
  password_hash text,
  created_at timestamptz DEFAULT now()
);

-- Projects
CREATE TABLE IF NOT EXISTS projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  name text,
  status text DEFAULT 'draft',
  created_by uuid REFERENCES users(id),
  due_date date,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- Project assets (floorplans, photos, refs)
CREATE TABLE IF NOT EXISTS project_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  type text,
  url text,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- AI Jobs
CREATE TABLE IF NOT EXISTS ai_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  status text,
  prompt text,
  params jsonb,
  provider text NOT NULL DEFAULT 'nanobanana',
  fallback_provider text,
  provider_job_id text,
  quality_score numeric,
  cost numeric,
  result_url text,
  created_at timestamptz DEFAULT now()
);

-- Design outputs
CREATE TABLE IF NOT EXISTS design_outputs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id uuid REFERENCES ai_jobs(id) ON DELETE CASCADE,
  version integer DEFAULT 1,
  images jsonb,
  specs jsonb,
  approved_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now()
);

-- Comments
CREATE TABLE IF NOT EXISTS comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id),
  content text,
  linked_output uuid REFERENCES design_outputs(id),
  created_at timestamptz DEFAULT now()
);

-- Billing records
CREATE TABLE IF NOT EXISTS billing_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  amount numeric,
  type text,
  meta jsonb,
  created_at timestamptz DEFAULT now()
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_projects_org ON projects(org_id);
CREATE INDEX IF NOT EXISTS idx_ai_jobs_project ON ai_jobs(project_id);
CREATE INDEX IF NOT EXISTS idx_ai_jobs_provider ON ai_jobs(provider);

-- Example: seed a starter plan organization (optional)
-- INSERT INTO organizations (name, plan, credits) VALUES ('Test Firm', 'starter', 500);

-- End of migration
