# Project Overview

This project appears to be a database design and implementation for an academic or educational institution. It includes a Data Definition Language (DDL) script to create the database schema, Data Manipulation Language (DML) scripts to populate the database with sample data, and additional documentation outlining changes and specific table details.

The database schema defines entities such as students (`estudante`), instructors (`docente`), courses (`curso`), classes (`turma`), evaluations (`avaliacao`), and financial aspects like tuition fees (`propina`).

## Key Files

*   `ddl.sql`: Defines the entire database schema, including table creation, primary keys, and foreign key constraints for an Oracle SQL database.
*   `dml.sql`: Contains `INSERT` statements to populate the database with sample data for various tables. The data appears to be a mix of generated and somewhat realistic entries.
*   `alteracoes.txt`: Documents proposed and implemented changes to the database schema, including additions of columns and modifications to table relationships.
*   `notas.txt`: Provides detailed documentation for specific tables, such as `tipo_avaliacao`, explaining the purpose and properties of different evaluation types.
*   `DER.png`, `DER_v2.png`: Entity-Relationship Diagram images, likely depicting the database structure.
*   `apresentacao.pptx`: A presentation file, probably related to the project's overview or a specific phase.
*   `Relatorio_fase1.docx`, `Relatorio_fase1.pdf`: Project reports, indicating different phases of development.

## Building and Running

This project primarily involves SQL scripts for database creation and data population.

### Database Setup

To set up the database, you would typically execute the `ddl.sql` script using an Oracle SQL client (e.g., SQL Developer, SQL*Plus). This script will create all the necessary tables and define their relationships.

\`\`\`sql
-- Example command to run DDL (actual command may vary based on client)
@ddl.sql
\`\`\`

### Data Population

After the schema is created, the `dml.sql` script can be executed to populate the tables with initial data.

\`\`\`sql
-- Example command to run DML (actual command may vary based on client)
@dml.sql
\`\`\`

## Development Conventions

*   **Database System:** Oracle SQL (based on the DDL script headers).
*   **Schema Design:** Follows a relational model with clear primary and foreign key relationships.
*   **Documentation:** Important changes and table details are documented in `alteracoes.txt` and `notas.txt`, which is a good practice for tracking evolution and understanding specific design choices.
*   **Data Generation:** Sample data in `dml.sql` appears to be programmatically generated, which is common for testing and development purposes.

## Further Exploration

*   Examine the `DER` directory for more detailed Entity-Relationship Model files (`.dmd` files).
*   Review `ddlv3.sql` to understand any later iterations of the DDL.
