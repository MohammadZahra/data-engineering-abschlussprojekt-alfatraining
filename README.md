# Bank Card Transaction Analysis

A compact Data Engineering project developed as the final project of my alfatraining training program. The goal was to build an analytical solution for bank card transactions. The project starts with a relational business database and ends with a queryable Data Warehouse.

## Project Overview

The source system models customers, accounts, cards, merchants, merchant categories and card transactions.

The analytical layer is implemented as a Star Schema with one transaction fact table and four dimensions:

- Customer
- Card
- Merchant
- Time

The Data Warehouse supports analyses such as spending by region and merchant category, transaction trends over time, card-type performance and customer-group behavior.

## Data Engineering Flow

`Source Data → Staging → Business DB → Data Warehouse → Analytical Queries`

The main project steps were:

1. Create and populate staging tables with AI-generated sample banking data.
2. Explore, clean and load the relational Business Database.
3. Design the multidimensional model and logical Star Schema.
4. Create the physical Data Warehouse in SQL Server.
5. Define source-to-target mappings for dimensions and the fact table.
6. Implement the ETL process using Stored Procedures.
7. Perform incremental loading, currency conversion and ETL validation.
8. Query the completed Data Warehouse to answer analytical business questions.

## Technologies & Concepts

- Microsoft SQL Server / T-SQL
- Relational database design
- Data cleaning and staging
- Data Warehouse modelling
- Star Schema
- Multidimensional modelling
- ETL with Stored Procedures
- Source-to-target mapping
- Slowly Changing Dimensions (SCD)
- Incremental loading
- Data-quality validation
- Analytical SQL queries

## Repository Structure

```text
Project/
├── Business_DB/
│   ├── Scripts/        # staging, cleaning, loading and verification
│   ├── Draw.io/        # ER models
│   └── *.pdf           # design and import documentation
│
├── DWH/
│   ├── Scripts/        # Data Warehouse creation
│   ├── Draw.io/        # mER, Star Schema and SCD models
│   └── *.pdf           # DWH design documentation
│
└── ETL/
    ├── Scripts/        # ETL procedures, execution, testing and analytical queries
    └── ETL_Mapping_BankCardDWH.xlsx

Presentation/           # final project presentation
Project Brief/          # project description
Daily - Agile Work/     # daily project reports
```

## About the Project

The repository contains more than the final SQL implementation. It documents the complete workflow from source-system design and data preparation to Data Warehouse modelling, ETL implementation, validation and analytical querying.
