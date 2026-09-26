-- Enable RLS for dna_analysis
ALTER TABLE dna_analysis ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view DNA analysis for their own sheep
CREATE POLICY "Users can view dna_analysis for own sheep"
ON dna_analysis FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM sheep
        WHERE sheep.id = dna_analysis.sheep_id
        AND sheep.owner_id = auth.uid()
    )
);

-- Policy: Users can insert DNA analysis for their own sheep
CREATE POLICY "Users can insert dna_analysis for own sheep"
ON dna_analysis FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM sheep
        WHERE sheep.id = dna_analysis.sheep_id
        AND sheep.owner_id = auth.uid()
    )
);

-- Policy: Users can delete DNA analysis for their own sheep (if needed for cleanup)
CREATE POLICY "Users can delete dna_analysis for own sheep"
ON dna_analysis FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM sheep
        WHERE sheep.id = dna_analysis.sheep_id
        AND sheep.owner_id = auth.uid()
    )
);
