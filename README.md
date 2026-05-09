# BOM Explosion: Recursive Material Hierarchy Expansion

## Project Overview
This project implements a recursive algorithm to expand the Bill of Materials (BOM) hierarchy from production data.  
The input dataset contains `material → component` relationships for multiple production stages (8000 → 8001 → 8007 → 8002).  
**FIN materials** are the final sellable products. The goal is to reconstruct the full production chain for each FIN material:
`FIN → PROD materials (intermediate) → components (other PROD, ADD, RM)`.

## Folder Structure
bom_explosion/
├── src/ # Source code
│ └── bom_explosion.ipynb # Jupyter Notebook (Pandas solution)
├── data/ # Input data
│ └── task_2_data_ex.xlsx # BOM Excel file
├── output/ # Results
│ └── bom_explosion_result.csv # Exploded hierarchy
├── sql/ # SQL script (optional)
│ └── bom_explosion.sql # Recursive CTE for PostgreSQL/MySQL 8+
└── README.md # Project documentation

## Requirements
- Python 3.8 or higher
- Required libraries:
  ```bash
  pip install pandas numpy openpyxl```
-(SQL part) A DBMS that supports recursive CTE (PostgreSQL, MySQL 8+, SQLite 3.8.3+)

## Running the Pandas Solution
- Navigate to the project folder.
- Ensure the input file task_2_data_ex.xlsx is placed in the data/ folder.
- Open `src/bom_explosion.ipynb` in Jupyter, VS Code, or PyCharm.
- Run all cells (Run All).
- The result will be saved as output/bom_explosion_result.csv.

## Output Columns (all lowercase)

| Column | Description |
|--------|-------------|
| plant | Plant ID |
| fin_material_id | ID of the final sellable material (FIN) |
| fin_material_release_type | Release type: FIN |
| fin_material_production_type | Production stage (typically 8002) |
| fin_production_quantity | Quantity of the FIN material |
| prod_material_id | Parent PROD material at this level |
| prod_material_release_type | Release type: PROD |
| prod_material_production_type | Production stage of the parent |
| prod_material_production_quantity | Quantity of the parent material |
| component_id | Component ID |
| component_material_release_type | Component type (PROD/ADD/RM) |
| component_material_production_type | Production stage of the component (if any) |
| component_consumption_quantity | Quantity consumed |
| year | Year |

**Each row represents one relationship PROD material → component. All hierarchy levels (including ADD and RM components) are included.**

## SQL Solution
The file `sql/bom_explosion.sql` contains a recursive CTE that performs the same hierarchy expansion directly in a database.
**Steps:**
- Clean the plant_id column (forward fill).
- Recursive CTE starting from FIN materials.
- Recursively traverse components that are themselves PROD materials.
- Output the final columns.

**Usage:**
- Load the Excel data into a table named bom_staging.
- Execute the script.