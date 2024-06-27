
-- Create a table to store vehicle mileage and oil life
CREATE TABLE IF NOT EXISTS oil_life (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_plate VARCHAR(50) NOT NULL UNIQUE,
    mileage FLOAT DEFAULT 0,
    oil_life FLOAT DEFAULT 100
);
