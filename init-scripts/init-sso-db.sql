-- Create test user if it doesn't exist
INSERT INTO users (id, first_name, last_name, email, pass, admin_status, reset_pass)
VALUES ('test-user-id', 'Test', 'User', 'test@example.com', 'password123', false, false)
ON CONFLICT (id) DO NOTHING;

-- Create Mandible application if it doesn't exist
INSERT INTO applications (id, name, client_id, client_secret, redirect_uri, description)
VALUES ('mandible-app-id', 'Mandible', 'mandible-client-id', 'mandible-client-secret', 'http://localhost:8001/callback', 'Mandible Application')
ON CONFLICT (id) DO NOTHING;

-- Associate test user with Mandible application if not already associated
INSERT INTO application_users (id, user_id, application_id, user_role)
VALUES ('test-app-user-id', 'test-user-id', 'mandible-app-id', 'user')
ON CONFLICT (id) DO NOTHING;
