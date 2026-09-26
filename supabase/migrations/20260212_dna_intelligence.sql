-- Create DNA Analysis table for advanced genetic tracking
CREATE TABLE IF NOT EXISTS dna_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sheep_id UUID REFERENCES sheep(id) ON DELETE CASCADE,
    markers JSONB NOT NULL DEFAULT '{}',
    risk_indicators JSONB NOT NULL DEFAULT '[]',
    confidence_level FLOAT DEFAULT 0,
    recommendations TEXT[] DEFAULT '{}',
    life_expectancy_min INT,
    life_expectancy_max INT,
    summary TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add reference to latest analysis in sheep table
ALTER TABLE sheep 
ADD COLUMN IF NOT EXISTS latest_analysis_id UUID REFERENCES dna_analysis(id);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_dna_analysis_sheep_id ON dna_analysis(sheep_id);
