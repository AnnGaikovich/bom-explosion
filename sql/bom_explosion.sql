-- First, clean the plant_id column (assuming a staging table)
CREATE TABLE bom_staging AS
SELECT 
    year, month,
    produced_material,
    produced_material_production_type,
    produced_material_release_type,
    produced_material_quantity,
    component_material,
    component_material_production_type,
    component_material_release_type,
    component_material_quantity,
    -- forward fill plant_id (simplified: use a window function)
    FIRST_VALUE(plant_id) OVER (PARTITION BY grp ORDER BY idx) AS plant_id
FROM (
    SELECT *, 
           COUNT(CASE WHEN plant_id IS NOT NULL THEN 1 END) OVER (ORDER BY idx) AS grp,
           ROW_NUMBER() OVER () AS idx
    FROM raw_data
) t;

-- Recursive CTE
WITH RECURSIVE bom_hierarchy AS (
    -- Anchor: FIN materials
    SELECT 
        plant_id AS plant,
        year,
        produced_material AS fin_material,
        produced_material_release_type AS fin_release_type,
        produced_material_production_type AS fin_prod_type,
        produced_material_quantity AS fin_quantity,
        produced_material AS prod_material,
        produced_material_release_type AS prod_release_type,
        produced_material_production_type AS prod_prod_type,
        produced_material_quantity AS prod_quantity,
        component_material AS component_id,
        component_material_release_type AS comp_release_type,
        component_material_production_type AS comp_prod_type,
        component_material_quantity AS comp_quantity,
        1 AS level
    FROM bom_staging
    WHERE produced_material_release_type = 'FIN'
    
    UNION ALL
    
    -- Recursive: for each component that is a PROD material, get its components
    SELECT 
        h.plant,
        h.year,
        h.fin_material,
        h.fin_release_type,
        h.fin_prod_type,
        h.fin_quantity,
        c.produced_material AS prod_material,
        c.produced_material_release_type AS prod_release_type,
        c.produced_material_production_type AS prod_prod_type,
        c.produced_material_quantity AS prod_quantity,
        c.component_material AS component_id,
        c.component_material_release_type AS comp_release_type,
        c.component_material_production_type AS comp_prod_type,
        c.component_material_quantity AS comp_quantity,
        h.level + 1
    FROM bom_hierarchy h
    JOIN bom_staging c 
        ON h.component_id = c.produced_material
        AND h.year = c.year
        AND h.plant = c.plant_id
        AND c.produced_material_release_type = 'PROD'
)
-- Final output
SELECT DISTINCT
    plant,
    fin_material AS fin_material_id,
    fin_release_type AS fin_material_release_type,
    fin_prod_type AS fin_material_production_type,
    fin_quantity AS fin_production_quantity,
    prod_material AS prod_material_id,
    prod_release_type AS prod_material_release_type,
    prod_prod_type AS prod_material_production_type,
    prod_quantity AS prod_material_production_quantity,
    component_id,
    comp_release_type AS component_material_release_type,
    comp_prod_type AS component_material_production_type,
    comp_quantity AS component_consumption_quantity,
    year
FROM bom_hierarchy
ORDER BY plant, year, fin_material, prod_material, component_id;