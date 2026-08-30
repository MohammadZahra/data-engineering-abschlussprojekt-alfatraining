# Bank Card Transaction Analysis

A compact end-to-end Data Engineering project built as the final project of my alfatraining training program. The goal was to design a small analytical platform for bank card transactions — starting from a relational business database and ending with a queryable Data Warehouse.

## Project Overview

The source system models customers, accounts, cards, merchants, merchant categories and card transactions. The analytical layer is implemented as a **Star Schema** with one transaction fact table and four dimensions:

- Customer
- Card
- Merchant
- Time

The Data Warehouse supports analyses such as spending by region and merchant category, transaction trends over time, card-type performance and customer-group behavior.

## Data Engineering Flow

`Source Data → Staging → Business DB → Data Warehouse → Analytical Queries`

Main steps:

1. Create and populate staging tables with AI-generated sample banking data.
2. Explore, clean and load the normalized Business Database.
3. Design the multidimensional model and logical Star Schema.
4. Create the physical SQL Server Data Warehouse.
5. Define source-to-target mappings for all dimensions and the fact table.
6. Implement ETL with SQL Server Stored Procedures.
7. Perform incremental fact loading, currency conversion to EUR and ETL validation.
8. Run analytical SQL queries against the finished Data Warehouse.

## Key Technical Topics

- Microsoft SQL Server / T-SQL
- Relational database design and normalization
- Staging and data cleaning
- Data Warehouse modelling
- Star Schema and multidimensional modelling
- ETL with Stored Procedures
- Source-to-target mapping
- Slowly Changing Dimensions (SCD 0, 1 and 2)
- Incremental loading with a load-control table
- Data-quality and referential-integrity checks

## Repository Structure

```text
Project/
├── Business_DB/
│   ├── Scripts/        # staging, cleaning, loading and verification
│   ├── Draw.io/        # ER modelling files
│   └── *.pdf           # database design and import documentation
│
├── DWH/
│   ├── Scripts/        # Data Warehouse creation
│   ├── Draw.io/        # mER, Star Schema and SCD models
│   └── *.pdf           # DWH design and design decisions
│
└── ETL/
    ├── Scripts/        # ETL setup, dimensions, fact load, execution and testing
    └── ETL_Mapping_BankCardDWH.xlsx

Presentation/           # final project presentation
Project Brief/          # original project description
Daily - Agile Work/     # short daily project reports
```

## Design Notes

- Transaction amounts from multiple currencies are normalized to **EUR** during ETL using fixed reference exchange rates.
- Customer and Merchant dimensions contain separate Data Warehouse IDs and source-system IDs, allowing historical versions to be represented without introducing an additional SCD key.
- Type 2 history uses `ValidFrom` and `ValidTo` fields.
- The sample source data does not contain historical change timestamps; the initial SCD records therefore use a conventional initial validity date.

## Purpose

This repository documents the complete project workflow rather than only the final SQL scripts. It includes the modelling decisions, source-to-target mapping, implementation, validation and analytical queries so that the reasoning behind the Data Warehouse can be followed from source system to analysis.
